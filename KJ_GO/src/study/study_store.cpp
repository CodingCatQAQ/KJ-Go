#include "study_store.h"

#include <algorithm>

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QVariantList>
#include <QVector>

namespace {

QString jsonText(const QJsonObject &object)
{
    return QString::fromUtf8(QJsonDocument(object).toJson(QJsonDocument::Compact));
}

QVariantMap promptText(const QString &text)
{
    QVariantMap prompt;
    prompt.insert(QStringLiteral("text"), text);
    return prompt;
}

QVariantMap promptAudio(const QString &audio)
{
    QVariantMap prompt;
    prompt.insert(QStringLiteral("audio"), audio);
    return prompt;
}

QVariantMap answerText(const QString &text, const QStringList &accept)
{
    QVariantMap answer;
    answer.insert(QStringLiteral("text"), text);
    answer.insert(QStringLiteral("accept"), accept);
    return answer;
}

QJsonObject objectFrom(const QVariant &value)
{
    return QJsonObject::fromVariantMap(value.toMap());
}

QString itemId(const QString &lang, const QString &reading)
{
    return lang + QStringLiteral(":syllable:") + reading;
}

struct Initial {
    int index;
    char group[8];
    char16_t jamo;
};

const Initial kInitials[] = {
    {0, "g", 0x3131},
    {2, "n", 0x3134},
    {3, "d", 0x3137},
    {5, "r", 0x3139},
    {6, "m", 0x3141},
    {7, "b", 0x3142},
    {9, "s", 0x3145},
    {11, "ng", 0x3147},
    {12, "j", 0x3148},
    {14, "ch", 0x314A},
    {15, "k", 0x314B},
    {16, "t", 0x314C},
    {17, "p", 0x314D},
    {18, "h", 0x314E},
};

const int kMedials[] = {0, 2, 4, 6, 8, 12, 13, 17, 18, 20};
const char *kVowels[] = {"a", "ya", "eo", "yeo", "o", "yo", "u", "yu", "eu", "i"};
const char16_t kVowelGlyphs[] = {0x314F, 0x3151, 0x3153, 0x3155, 0x3157, 0x315B, 0x315C, 0x3160, 0x3161, 0x3163};

QString hangulSyllable(int initial, int medial)
{
    return QString(QChar(0xAC00 + (initial * 21 + medial) * 28));
}

}

StudyStore::StudyStore(QObject *parent)
    : QObject(parent)
{
    if (!openDatabase() || !migrate() || !seedIfEmpty())
        return;
}

int StudyStore::revision() const
{
    return m_revision;
}

QString StudyStore::error() const
{
    return m_error;
}

bool StudyStore::openDatabase()
{
    if (!QSqlDatabase::isDriverAvailable(QStringLiteral("QSQLITE"))) {
        m_error = QStringLiteral("SQLite 驱动没有装上");
        return false;
    }

    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (dir.isEmpty() || !QDir().mkpath(dir)) {
        m_error = QStringLiteral("学习数据库目录没有创建");
        return false;
    }

    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    m_db.setDatabaseName(dir + QStringLiteral("/study.sqlite"));
    if (!m_db.open()) {
        m_error = QStringLiteral("学习数据库没有打开");
        return false;
    }

    QSqlQuery pragma(m_db);
    pragma.exec(QStringLiteral("PRAGMA foreign_keys = ON"));
    return true;
}

bool StudyStore::exec(const QString &sql)
{
    QSqlQuery query(m_db);
    if (query.exec(sql))
        return true;
    m_error = query.lastError().text();
    return false;
}

bool StudyStore::migrate()
{
    const QStringList statements = {
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS schema_meta ("
            "  key TEXT PRIMARY KEY,"
            "  value TEXT NOT NULL"
            ")"),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS items ("
            "  id TEXT PRIMARY KEY,"
            "  lang TEXT NOT NULL,"
            "  kind TEXT NOT NULL,"
            "  set_id TEXT NOT NULL,"
            "  payload TEXT NOT NULL,"
            "  links TEXT NOT NULL"
            ")"),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS faces ("
            "  id TEXT PRIMARY KEY,"
            "  item_id TEXT NOT NULL REFERENCES items(id),"
            "  prompt_kind TEXT NOT NULL,"
            "  prompt TEXT NOT NULL,"
            "  answer TEXT NOT NULL"
            ")"),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS layouts ("
            "  id TEXT PRIMARY KEY,"
            "  lang TEXT NOT NULL,"
            "  set_id TEXT NOT NULL,"
            "  eyebrow TEXT NOT NULL,"
            "  title TEXT NOT NULL,"
            "  column_serif INTEGER NOT NULL,"
            "  columns_json TEXT NOT NULL,"
            "  rows_json TEXT NOT NULL"
            ")"),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS memory ("
            "  item_id TEXT PRIMARY KEY REFERENCES items(id),"
            "  status TEXT NOT NULL,"
            "  last_result TEXT,"
            "  streak INTEGER NOT NULL,"
            "  due TEXT,"
            "  interval_days INTEGER,"
            "  ease REAL"
            ")"),
        QStringLiteral(
            "CREATE TABLE IF NOT EXISTS review_events ("
            "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
            "  item_id TEXT NOT NULL REFERENCES items(id),"
            "  at TEXT NOT NULL,"
            "  activity TEXT NOT NULL,"
            "  prompt TEXT NOT NULL,"
            "  result TEXT NOT NULL,"
            "  session_id TEXT"
            ")"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS idx_items_set ON items(set_id)"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS idx_faces_item ON faces(item_id)"),
        QStringLiteral("CREATE INDEX IF NOT EXISTS idx_events_item ON review_events(item_id)"),
    };

    for (const QString &statement : statements) {
        if (!exec(statement))
            return false;
    }

    QSqlQuery version(m_db);
    version.prepare(QStringLiteral("INSERT OR IGNORE INTO schema_meta (key, value) VALUES ('schema', '1')"));
    if (!version.exec()) {
        m_error = version.lastError().text();
        return false;
    }
    return upgradeMemory();
}

bool StudyStore::upgradeMemory()
{
    QSqlQuery version(m_db);
    if (!version.exec(QStringLiteral("SELECT value FROM schema_meta WHERE key = 'schema'")) || !version.next()) {
        m_error = version.lastError().text();
        return false;
    }
    if (version.value(0).toInt() >= 2)
        return true;

    if (!m_db.transaction())
        return false;
    const bool ok = exec(QStringLiteral("UPDATE review_events SET result = 'right' WHERE result = 'good'"))
        && exec(QStringLiteral("UPDATE review_events SET result = 'wrong' WHERE result = 'again' OR result = 'hard'"))
        && exec(QStringLiteral("UPDATE memory SET last_result = NULL"))
        && recomputeStatuses();
    QSqlQuery bump(m_db);
    bump.prepare(QStringLiteral("UPDATE schema_meta SET value = '2' WHERE key = 'schema'"));
    if (!ok || !bump.exec() || !m_db.commit()) {
        m_db.rollback();
        if (m_error.isEmpty())
            m_error = QStringLiteral("记忆状态没有升级");
        return false;
    }
    return true;
}

QString StudyStore::statusFor(const QString &itemId) const
{
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT result FROM review_events WHERE item_id = ? ORDER BY id DESC LIMIT 10"));
    query.addBindValue(itemId);
    if (!query.exec())
        return QStringLiteral("unlearned");

    int attempts = 0;
    int correct = 0;
    while (query.next()) {
        ++attempts;
        if (query.value(0).toString() == QStringLiteral("right"))
            ++correct;
    }
    if (attempts == 0 || correct * 2 < attempts)
        return QStringLiteral("unlearned");
    if (attempts >= 10 && correct * 10 >= attempts * 9)
        return QStringLiteral("mastered");
    return QStringLiteral("fuzzy");
}

bool StudyStore::recomputeStatuses()
{
    QSqlQuery ids(m_db);
    if (!ids.exec(QStringLiteral("SELECT item_id FROM memory"))) {
        m_error = ids.lastError().text();
        return false;
    }
    QStringList itemIds;
    while (ids.next())
        itemIds.append(ids.value(0).toString());

    for (const QString &itemId : itemIds) {
        QSqlQuery update(m_db);
        update.prepare(QStringLiteral("UPDATE memory SET status = ? WHERE item_id = ?"));
        update.addBindValue(statusFor(itemId));
        update.addBindValue(itemId);
        if (!update.exec()) {
            m_error = update.lastError().text();
            return false;
        }
    }
    return true;
}

bool StudyStore::insertItem(const QString &id, const QString &lang, const QString &setId, const QVariantMap &payload)
{
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO items (id, lang, kind, set_id, payload, links) VALUES (?, ?, 'syllable', ?, ?, '[]')"));
    query.addBindValue(id);
    query.addBindValue(lang);
    query.addBindValue(setId);
    query.addBindValue(jsonText(objectFrom(payload)));
    if (!query.exec()) {
        m_error = query.lastError().text();
        return false;
    }

    QSqlQuery memory(m_db);
    memory.prepare(QStringLiteral(
        "INSERT INTO memory (item_id, status, last_result, streak, due, interval_days, ease) "
        "VALUES (?, 'unlearned', NULL, 0, NULL, NULL, NULL)"));
    memory.addBindValue(id);
    if (!memory.exec()) {
        m_error = memory.lastError().text();
        return false;
    }
    return true;
}

bool StudyStore::insertFace(const QString &itemId, const QString &promptKind, const QVariantMap &prompt, const QVariantMap &answer)
{
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO faces (id, item_id, prompt_kind, prompt, answer) VALUES (?, ?, ?, ?, ?)"));
    query.addBindValue(itemId + QLatin1Char(':') + promptKind);
    query.addBindValue(itemId);
    query.addBindValue(promptKind);
    query.addBindValue(jsonText(objectFrom(prompt)));
    query.addBindValue(jsonText(objectFrom(answer)));
    if (query.exec())
        return true;
    m_error = query.lastError().text();
    return false;
}

bool StudyStore::seedIfEmpty()
{
    QSqlQuery count(m_db);
    if (!count.exec(QStringLiteral("SELECT COUNT(*) FROM items")) || !count.next()) {
        m_error = count.lastError().text();
        return false;
    }
    if (count.value(0).toInt() > 0)
        return true;

    if (!m_db.transaction())
        return false;
    if (!seedJapanese() || !seedKorean() || !m_db.commit()) {
        m_db.rollback();
        if (m_error.isEmpty())
            m_error = QStringLiteral("学习数据没有写入");
        return false;
    }
    return true;
}

bool StudyStore::seedJapanese()
{
    QFile file(QStringLiteral(":/study/seed_ja_seion.json"));
    if (!file.open(QIODevice::ReadOnly)) {
        m_error = QStringLiteral("五十音种子文件没有读到");
        return false;
    }
    const QJsonObject seed = QJsonDocument::fromJson(file.readAll()).object();
    if (seed.isEmpty()) {
        m_error = QStringLiteral("五十音种子文件是空的");
        return false;
    }

    const QString lang = seed.value(QStringLiteral("lang")).toString();
    const QString setId = seed.value(QStringLiteral("setId")).toString();
    const QString pairLeftLabel = seed.value(QStringLiteral("pairLeftLabel")).toString();
    const QString pairRightLabel = seed.value(QStringLiteral("pairRightLabel")).toString();
    const QString fallback = seed.value(QStringLiteral("fallbackMnemonic")).toString();
    const QJsonObject mnemonics = seed.value(QStringLiteral("mnemonics")).toObject();
    const QJsonArray columnLabels = seed.value(QStringLiteral("columnLabels")).toArray();
    const QJsonArray lookalikeGroups = seed.value(QStringLiteral("lookalikes")).toArray();

    QHash<QString, QJsonArray> lookalikes;
    for (const QJsonValue &groupValue : lookalikeGroups) {
        const QJsonArray group = groupValue.toArray();
        for (const QJsonValue &memberValue : group) {
            const QString member = memberValue.toString();
            QJsonArray others;
            for (const QJsonValue &otherValue : group) {
                const QString other = otherValue.toString();
                if (other != member && others.size() < 3)
                    others.append(itemId(lang, other));
            }
            lookalikes.insert(member, others);
        }
    }

    struct Pending {
        QString id;
        QJsonObject payload;
        QString glyph;
        QString glyphAlt;
        QString reading;
        QString audio;
    };
    QVector<Pending> pending;
    QJsonArray layoutRows;
    int position = 0;

    const QJsonArray rows = seed.value(QStringLiteral("rows")).toArray();
    for (const QJsonValue &rowValue : rows) {
        const QJsonObject row = rowValue.toObject();
        const QJsonArray hira = row.value(QStringLiteral("hira")).toArray();
        const QJsonArray kata = row.value(QStringLiteral("kata")).toArray();
        const QJsonArray reading = row.value(QStringLiteral("reading")).toArray();
        QJsonArray cells;
        const int columns = reading.size();
        for (int column = 0; column < columns; ++column) {
            const QString romaji = reading.at(column).toString();
            if (romaji.isEmpty()) {
                cells.append(QString());
                continue;
            }
            ++position;
            Pending item;
            item.id = itemId(lang, romaji);
            item.glyph = hira.at(column).toString();
            item.glyphAlt = kata.at(column).toString();
            item.reading = romaji;
            item.audio = romaji;
            const QString note = mnemonics.value(romaji).toString();
            item.payload = QJsonObject{
                {QStringLiteral("glyph"), item.glyph},
                {QStringLiteral("glyphAlt"), item.glyphAlt},
                {QStringLiteral("reading"), item.reading},
                {QStringLiteral("audio"), item.audio},
                {QStringLiteral("pairLeftLabel"), pairLeftLabel},
                {QStringLiteral("pairLeft"), item.glyph},
                {QStringLiteral("pairRightLabel"), pairRightLabel},
                {QStringLiteral("pairRight"), item.glyphAlt},
                {QStringLiteral("rowLabel"), row.value(QStringLiteral("label")).toString()},
                {QStringLiteral("columnLabel"), columnLabels.at(column).toString()},
                {QStringLiteral("column"), column},
                {QStringLiteral("position"), position},
                {QStringLiteral("mnemonic"), note.isEmpty() ? fallback.arg(romaji.toUpper()) : note},
                {QStringLiteral("lookalikes"), lookalikes.value(romaji)},
            };
            cells.append(item.id);
            pending.append(item);
        }
        layoutRows.append(QJsonObject{
            {QStringLiteral("short"), row.value(QStringLiteral("short")).toString()},
            {QStringLiteral("group"), row.value(QStringLiteral("group")).toString()},
            {QStringLiteral("cells"), cells},
        });
    }

    for (Pending &item : pending) {
        item.payload.insert(QStringLiteral("total"), pending.size());
        if (!insertItem(item.id, lang, setId, item.payload.toVariantMap()))
            return false;
        if (!insertFace(item.id, QStringLiteral("glyph-to-reading"),
                        promptText(item.glyph), answerText(item.reading, {item.reading})))
            return false;
        if (!insertFace(item.id, QStringLiteral("reading-to-glyph"),
                        promptText(item.reading), answerText(item.glyph, {item.glyph, item.glyphAlt})))
            return false;
        if (!insertFace(item.id, QStringLiteral("listen"),
                        promptAudio(item.audio), answerText(item.glyph, {item.glyph, item.glyphAlt})))
            return false;
    }

    QSqlQuery layout(m_db);
    layout.prepare(QStringLiteral(
        "INSERT INTO layouts (id, lang, set_id, eyebrow, title, column_serif, columns_json, rows_json) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?)"));
    layout.addBindValue(seed.value(QStringLiteral("layoutId")).toString());
    layout.addBindValue(lang);
    layout.addBindValue(setId);
    layout.addBindValue(seed.value(QStringLiteral("eyebrow")).toString());
    layout.addBindValue(seed.value(QStringLiteral("title")).toString());
    layout.addBindValue(seed.value(QStringLiteral("columnSerif")).toBool() ? 1 : 0);
    layout.addBindValue(QString::fromUtf8(QJsonDocument(seed.value(QStringLiteral("columns")).toArray()).toJson(QJsonDocument::Compact)));
    layout.addBindValue(QString::fromUtf8(QJsonDocument(layoutRows).toJson(QJsonDocument::Compact)));
    if (layout.exec())
        return true;
    m_error = layout.lastError().text();
    return false;
}

bool StudyStore::seedKorean()
{
    const QString lang = QStringLiteral("ko");
    const QString setId = QStringLiteral("ko-syllable");
    const QString pairLeftLabel = QString::fromUtf16(u"\u8f85\u97f3");
    const QString pairRightLabel = QString::fromUtf16(u"\u5143\u97f3");
    const QString rowSuffix = QString::fromUtf16(u" \u884c");

    struct Pending {
        QString id;
        QJsonObject payload;
        QString glyph;
        QString reading;
    };
    QVector<Pending> pending;
    QJsonArray layoutRows;
    QJsonArray columns;
    int position = 0;

    for (char16_t vowel : kVowelGlyphs)
        columns.append(QString(QChar(vowel)));

    for (const Initial &initial : kInitials) {
        const QString jamo(QChar(initial.jamo));
        const bool silent = jamo == QString(QChar(0x3147));
        QJsonArray cells;
        for (int column = 0; column < 10; ++column) {
            ++position;
            const QString reading = QString::fromLatin1(silent ? "" : initial.group) + QString::fromLatin1(kVowels[column]);
            const QString vowel(QChar(kVowelGlyphs[column]));
            Pending item;
            item.id = itemId(lang, reading);
            item.glyph = hangulSyllable(initial.index, kMedials[column]);
            item.reading = reading;
            item.payload = QJsonObject{
                {QStringLiteral("glyph"), item.glyph},
                {QStringLiteral("glyphAlt"), QString()},
                {QStringLiteral("reading"), item.reading},
                {QStringLiteral("audio"), QString()},
                {QStringLiteral("pairLeftLabel"), pairLeftLabel},
                {QStringLiteral("pairLeft"), jamo},
                {QStringLiteral("pairRightLabel"), pairRightLabel},
                {QStringLiteral("pairRight"), vowel},
                {QStringLiteral("rowLabel"), jamo + rowSuffix},
                {QStringLiteral("columnLabel"), vowel},
                {QStringLiteral("column"), column},
                {QStringLiteral("position"), position},
                {QStringLiteral("mnemonic"), QString()},
                {QStringLiteral("lookalikes"), QJsonArray()},
            };
            cells.append(item.id);
            pending.append(item);
        }
        layoutRows.append(QJsonObject{
            {QStringLiteral("short"), jamo},
            {QStringLiteral("group"), QString::fromLatin1(initial.group)},
            {QStringLiteral("cells"), cells},
        });
    }

    for (Pending &item : pending) {
        item.payload.insert(QStringLiteral("total"), pending.size());
        if (!insertItem(item.id, lang, setId, item.payload.toVariantMap()))
            return false;
        if (!insertFace(item.id, QStringLiteral("glyph-to-reading"),
                        promptText(item.glyph), answerText(item.reading, {item.reading})))
            return false;
        if (!insertFace(item.id, QStringLiteral("reading-to-glyph"),
                        promptText(item.reading), answerText(item.glyph, {item.glyph})))
            return false;
    }

    QSqlQuery layout(m_db);
    layout.prepare(QStringLiteral(
        "INSERT INTO layouts (id, lang, set_id, eyebrow, title, column_serif, columns_json, rows_json) "
        "VALUES (?, ?, ?, ?, ?, 1, ?, ?)"));
    layout.addBindValue(setId);
    layout.addBindValue(lang);
    layout.addBindValue(setId);
    layout.addBindValue(QStringLiteral("HANGUL") + QString::fromUtf16(u" \u00b7 \u97f3\u8282"));
    layout.addBindValue(QString(QChar(0xD55C)) + QChar(0xAE00));
    layout.addBindValue(QString::fromUtf8(QJsonDocument(columns).toJson(QJsonDocument::Compact)));
    layout.addBindValue(QString::fromUtf8(QJsonDocument(layoutRows).toJson(QJsonDocument::Compact)));
    if (layout.exec())
        return true;
    m_error = layout.lastError().text();
    return false;
}

QVariantMap StudyStore::layout(const QString &layoutId) const
{
    QVariantMap result;
    if (!m_db.isOpen())
        return result;

    QSqlQuery layout(m_db);
    layout.prepare(QStringLiteral(
        "SELECT set_id, eyebrow, title, column_serif, columns_json, rows_json FROM layouts WHERE id = ?"));
    layout.addBindValue(layoutId);
    if (!layout.exec() || !layout.next())
        return result;

    const QString setId = layout.value(0).toString();
    QHash<QString, QVariantMap> cards;
    QSqlQuery items(m_db);
    items.prepare(QStringLiteral(
        "SELECT i.id, i.payload, m.status "
        "FROM items i LEFT JOIN memory m ON m.item_id = i.id WHERE i.set_id = ?"));
    items.addBindValue(setId);
    if (items.exec()) {
        while (items.next()) {
            const QJsonObject payload = QJsonDocument::fromJson(items.value(1).toString().toUtf8()).object();
            const QString status = items.value(2).toString();
            cards.insert(items.value(0).toString(), QVariantMap{
                {QStringLiteral("id"), items.value(0).toString()},
                {QStringLiteral("glyph"), payload.value(QStringLiteral("glyph")).toString()},
                {QStringLiteral("glyphAlt"), payload.value(QStringLiteral("glyphAlt")).toString()},
                {QStringLiteral("reading"), payload.value(QStringLiteral("reading")).toString()},
                {QStringLiteral("audio"), payload.value(QStringLiteral("audio")).toString()},
                {QStringLiteral("status"), status.isEmpty() ? QStringLiteral("unlearned") : status},
            });
        }
    }

    QVariantList rows;
    const QJsonArray storedRows = QJsonDocument::fromJson(layout.value(5).toString().toUtf8()).array();
    for (const QJsonValue &rowValue : storedRows) {
        const QJsonObject row = rowValue.toObject();
        QVariantList cells;
        for (const QJsonValue &cellValue : row.value(QStringLiteral("cells")).toArray()) {
            const QString id = cellValue.toString();
            if (id.isEmpty() || !cards.contains(id))
                cells.append(QVariantMap{{QStringLiteral("id"), QString()}});
            else
                cells.append(cards.value(id));
        }
        rows.append(QVariantMap{
            {QStringLiteral("short"), row.value(QStringLiteral("short")).toString()},
            {QStringLiteral("group"), row.value(QStringLiteral("group")).toString()},
            {QStringLiteral("cells"), cells},
        });
    }

    const QJsonArray columns = QJsonDocument::fromJson(layout.value(4).toString().toUtf8()).array();
    QStringList columnTexts;
    for (const QJsonValue &column : columns)
        columnTexts.append(column.toString());

    result.insert(QStringLiteral("id"), layoutId);
    result.insert(QStringLiteral("setId"), setId);
    result.insert(QStringLiteral("eyebrow"), layout.value(1).toString());
    result.insert(QStringLiteral("title"), layout.value(2).toString());
    result.insert(QStringLiteral("columnSerif"), layout.value(3).toInt() != 0);
    result.insert(QStringLiteral("columns"), columnTexts);
    result.insert(QStringLiteral("rows"), rows);
    return result;
}

QVariantMap StudyStore::item(const QString &itemId) const
{
    QVariantMap result;
    if (!m_db.isOpen() || itemId.isEmpty())
        return result;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT i.lang, i.kind, i.set_id, i.payload, m.status, m.streak "
        "FROM items i LEFT JOIN memory m ON m.item_id = i.id WHERE i.id = ?"));
    query.addBindValue(itemId);
    if (!query.exec() || !query.next())
        return result;

    const QJsonObject payload = QJsonDocument::fromJson(query.value(3).toString().toUtf8()).object();
    QVariantList lookalikes;
    for (const QJsonValue &likeValue : payload.value(QStringLiteral("lookalikes")).toArray()) {
        QSqlQuery like(m_db);
        like.prepare(QStringLiteral("SELECT payload FROM items WHERE id = ?"));
        like.addBindValue(likeValue.toString());
        if (!like.exec() || !like.next())
            continue;
        const QJsonObject likePayload = QJsonDocument::fromJson(like.value(0).toString().toUtf8()).object();
        lookalikes.append(QVariantMap{
            {QStringLiteral("id"), likeValue.toString()},
            {QStringLiteral("glyph"), likePayload.value(QStringLiteral("glyph")).toString()},
            {QStringLiteral("glyphAlt"), likePayload.value(QStringLiteral("glyphAlt")).toString()},
        });
    }

    result.insert(QStringLiteral("id"), itemId);
    result.insert(QStringLiteral("lang"), query.value(0).toString());
    result.insert(QStringLiteral("kind"), query.value(1).toString());
    result.insert(QStringLiteral("setId"), query.value(2).toString());
    result.insert(QStringLiteral("glyph"), payload.value(QStringLiteral("glyph")).toString());
    result.insert(QStringLiteral("glyphAlt"), payload.value(QStringLiteral("glyphAlt")).toString());
    result.insert(QStringLiteral("reading"), payload.value(QStringLiteral("reading")).toString());
    result.insert(QStringLiteral("audio"), payload.value(QStringLiteral("audio")).toString());
    result.insert(QStringLiteral("pairLeftLabel"), payload.value(QStringLiteral("pairLeftLabel")).toString());
    result.insert(QStringLiteral("pairLeft"), payload.value(QStringLiteral("pairLeft")).toString());
    result.insert(QStringLiteral("pairRightLabel"), payload.value(QStringLiteral("pairRightLabel")).toString());
    result.insert(QStringLiteral("pairRight"), payload.value(QStringLiteral("pairRight")).toString());
    result.insert(QStringLiteral("rowLabel"), payload.value(QStringLiteral("rowLabel")).toString());
    result.insert(QStringLiteral("columnLabel"), payload.value(QStringLiteral("columnLabel")).toString());
    result.insert(QStringLiteral("position"), payload.value(QStringLiteral("position")).toInt());
    result.insert(QStringLiteral("total"), payload.value(QStringLiteral("total")).toInt());
    QString lastResult;
    QSqlQuery latest(m_db);
    latest.prepare(QStringLiteral(
        "SELECT result FROM review_events WHERE item_id = ? ORDER BY id DESC LIMIT 1"));
    latest.addBindValue(itemId);
    if (latest.exec() && latest.next())
        lastResult = latest.value(0).toString();

    result.insert(QStringLiteral("mnemonic"), payload.value(QStringLiteral("mnemonic")).toString());
    result.insert(QStringLiteral("lookalikes"), lookalikes);
    result.insert(QStringLiteral("status"), query.value(4).toString().isEmpty() ? QStringLiteral("unlearned") : query.value(4).toString());
    result.insert(QStringLiteral("streak"), query.value(5).toInt());
    result.insert(QStringLiteral("lastResult"), lastResult);
    return result;
}

void StudyStore::setMnemonic(const QString &itemId, const QString &text)
{
    if (!m_db.isOpen() || itemId.isEmpty())
        return;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral("SELECT payload FROM items WHERE id = ?"));
    query.addBindValue(itemId);
    if (!query.exec() || !query.next())
        return;

    QJsonObject payload = QJsonDocument::fromJson(query.value(0).toString().toUtf8()).object();
    if (payload.value(QStringLiteral("mnemonic")).toString() == text)
        return;
    payload.insert(QStringLiteral("mnemonic"), text);

    QSqlQuery update(m_db);
    update.prepare(QStringLiteral("UPDATE items SET payload = ? WHERE id = ?"));
    update.addBindValue(jsonText(payload));
    update.addBindValue(itemId);
    if (!update.exec())
        return;
    ++m_revision;
    emit changed();
}

QVariantMap StudyStore::counts(const QString &setId) const
{
    QVariantMap result{
        {QStringLiteral("total"), 0},
        {QStringLiteral("mastered"), 0},
        {QStringLiteral("fuzzy"), 0},
        {QStringLiteral("unlearned"), 0},
    };
    if (!m_db.isOpen())
        return result;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT m.status, COUNT(*) FROM memory m "
        "JOIN items i ON i.id = m.item_id WHERE i.set_id = ? GROUP BY m.status"));
    query.addBindValue(setId);
    if (!query.exec())
        return result;

    int total = 0;
    while (query.next()) {
        const QString status = query.value(0).toString();
        const int count = query.value(1).toInt();
        total += count;
        if (status == QStringLiteral("mastered"))
            result.insert(QStringLiteral("mastered"), count);
        else if (status == QStringLiteral("fuzzy"))
            result.insert(QStringLiteral("fuzzy"), count);
        else
            result.insert(QStringLiteral("unlearned"), result.value(QStringLiteral("unlearned")).toInt() + count);
    }
    result.insert(QStringLiteral("total"), total);
    return result;
}

QStringList StudyStore::weakIds(const QString &setId) const
{
    QStringList ids;
    if (!m_db.isOpen())
        return ids;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT m.item_id, i.payload FROM memory m "
        "JOIN items i ON i.id = m.item_id "
        "WHERE i.set_id = ? AND m.status = 'fuzzy'"));
    query.addBindValue(setId);
    if (!query.exec())
        return ids;

    QVector<QPair<int, QString>> ordered;
    while (query.next()) {
        const QJsonObject payload = QJsonDocument::fromJson(query.value(1).toString().toUtf8()).object();
        ordered.append({payload.value(QStringLiteral("position")).toInt(), query.value(0).toString()});
    }
    std::sort(ordered.begin(), ordered.end(), [](const QPair<int, QString> &left, const QPair<int, QString> &right) {
        return left.first < right.first;
    });
    for (const auto &entry : ordered)
        ids.append(entry.second);
    return ids;
}

QStringList StudyStore::itemIds(const QString &setId) const
{
    QStringList ids;
    if (!m_db.isOpen())
        return ids;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT i.id, i.payload FROM items i WHERE i.set_id = ?"));
    query.addBindValue(setId);
    if (!query.exec())
        return ids;

    QVector<QPair<int, QString>> ordered;
    while (query.next()) {
        const QJsonObject payload = QJsonDocument::fromJson(query.value(1).toString().toUtf8()).object();
        ordered.append({payload.value(QStringLiteral("position")).toInt(), query.value(0).toString()});
    }
    std::sort(ordered.begin(), ordered.end(), [](const QPair<int, QString> &left, const QPair<int, QString> &right) {
        return left.first < right.first;
    });
    for (const auto &entry : ordered)
        ids.append(entry.second);
    return ids;
}

QStringList StudyStore::reviewQueue(const QString &setId, int limit) const
{
    QStringList ids;
    if (!m_db.isOpen() || limit <= 0)
        return ids;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT i.id, i.payload, m.status FROM items i "
        "JOIN memory m ON m.item_id = i.id WHERE i.set_id = ?"));
    query.addBindValue(setId);
    if (!query.exec())
        return ids;

    struct Candidate {
        int bucket;
        int position;
        QString id;
    };
    QVector<Candidate> candidates;
    while (query.next()) {
        const QString status = query.value(2).toString();
        int bucket = -1;
        if (status == QStringLiteral("fuzzy"))
            bucket = 0;
        else if (status != QStringLiteral("mastered"))
            bucket = 1;
        if (bucket < 0)
            continue;
        const QJsonObject payload = QJsonDocument::fromJson(query.value(1).toString().toUtf8()).object();
        candidates.append({bucket, payload.value(QStringLiteral("position")).toInt(), query.value(0).toString()});
    }
    std::sort(candidates.begin(), candidates.end(), [](const Candidate &left, const Candidate &right) {
        if (left.bucket != right.bucket)
            return left.bucket < right.bucket;
        return left.position < right.position;
    });
    const int count = qMin(limit, static_cast<int>(candidates.size()));
    for (int i = 0; i < count; ++i)
        ids.append(candidates.at(i).id);
    return ids;
}

void StudyStore::rate(const QString &itemId, bool correct, const QString &activity, const QString &prompt)
{
    if (!m_db.isOpen() || itemId.isEmpty())
        return;

    int streak = 0;
    if (correct) {
        QSqlQuery current(m_db);
        current.prepare(QStringLiteral("SELECT streak FROM memory WHERE item_id = ?"));
        current.addBindValue(itemId);
        if (current.exec() && current.next())
            streak = current.value(0).toInt() + 1;
    }

    if (!m_db.transaction())
        return;

    QSqlQuery event(m_db);
    event.prepare(QStringLiteral(
        "INSERT INTO review_events (item_id, at, activity, prompt, result, session_id) "
        "VALUES (?, ?, ?, ?, ?, NULL)"));
    event.addBindValue(itemId);
    event.addBindValue(QDateTime::currentDateTimeUtc().toString(Qt::ISODateWithMs));
    event.addBindValue(activity);
    event.addBindValue(prompt);
    event.addBindValue(correct ? QStringLiteral("right") : QStringLiteral("wrong"));
    if (!event.exec()) {
        m_db.rollback();
        return;
    }

    QSqlQuery update(m_db);
    update.prepare(QStringLiteral("UPDATE memory SET status = ?, streak = ? WHERE item_id = ?"));
    update.addBindValue(statusFor(itemId));
    update.addBindValue(streak);
    update.addBindValue(itemId);

    if (!update.exec() || update.numRowsAffected() != 1 || !m_db.commit()) {
        m_db.rollback();
        return;
    }
    ++m_revision;
    emit changed();
}

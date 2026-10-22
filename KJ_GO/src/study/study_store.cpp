#include "study_store.h"

#include <algorithm>

#include <QDate>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSet>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QStringList>
#include <QUuid>
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

#include "ksx1001_hangul.inc"

const char *kInitialReading[] = {
    "g", "kk", "n", "d", "tt", "r", "m", "b", "pp", "s", "ss", "", "j", "jj", "ch", "k", "t", "p", "h",
};
const char16_t kInitialJamo[] = {
    0x3131, 0x3132, 0x3134, 0x3137, 0x3138, 0x3139, 0x3141, 0x3142, 0x3143,
    0x3145, 0x3146, 0x3147, 0x3148, 0x3149, 0x314A, 0x314B, 0x314C, 0x314D, 0x314E,
};
const char *kVowelReading[] = {
    "a", "ae", "ya", "yae", "eo", "e", "yeo", "ye", "o", "wa", "wae", "oe", "yo", "u", "wo", "we", "wi", "yu", "eu", "ui", "i",
};
const char *kFinalReading[] = {
    "", "k", "kk", "ks", "n", "nj", "nh", "t", "l", "lg", "lm", "lb", "ls", "lt", "lp", "lh", "m", "p", "ps", "s", "ss", "ng", "j", "ch", "kh", "th", "ph", "h",
};
const char16_t kFinalJamo[] = {
    0,
    0x3131, 0x3132, 0x3133, 0x3134, 0x3135, 0x3136, 0x3137,
    0x3139, 0x313A, 0x313B, 0x313C, 0x313D, 0x313E, 0x313F, 0x3140,
    0x3141, 0x3142, 0x3144, 0x3145, 0x3146, 0x3147, 0x3148,
    0x314A, 0x314B, 0x314C, 0x314D, 0x314E,
};

QString kanaText(char16_t first, char16_t second)
{
    if (second == 0)
        return QString(QChar(first));
    const char16_t pair[] = {first, second};
    return QString::fromUtf16(pair, 2);
}

QString kanaClip(const QString &reading)
{
    static const QHash<QString, QString> alias = {
        {QStringLiteral("sha"), QStringLiteral("sya")},
        {QStringLiteral("shu"), QStringLiteral("syu")},
        {QStringLiteral("sho"), QStringLiteral("syo")},
        {QStringLiteral("cha"), QStringLiteral("cya")},
        {QStringLiteral("chu"), QStringLiteral("cyu")},
        {QStringLiteral("cho"), QStringLiteral("cyo")},
        {QStringLiteral("ja"), QStringLiteral("zya")},
        {QStringLiteral("ju"), QStringLiteral("zyu")},
        {QStringLiteral("jo"), QStringLiteral("zyo")},
        {QStringLiteral("dya"), QStringLiteral("zya")},
        {QStringLiteral("dyu"), QStringLiteral("zyu")},
        {QStringLiteral("dyo"), QStringLiteral("zyo")},
    };
    const QString clip = alias.value(reading);
    return clip.isEmpty() ? reading : clip;
}

const QStringList kEditableFields = {
    QStringLiteral("gloss"),
    QStringLiteral("mnemonic"),
};

const char *kVocabTextKeys[] = {
    "pos",
    "gloss",
    "example",
    "mnemonic",
};

const char *kVocabDroppedKeys[] = {
    "reading",
    "group",
    "exampleGloss",
    "note",
    "lookalikes",
};

QString fieldText(const QVariantMap &fields, const char *key)
{
    return fields.value(QLatin1String(key)).toString().trimmed();
}

QString vocabPos(const QString &text)
{
    const QStringList known = {
        QStringLiteral("体词"),
        QStringLiteral("动词"),
        QStringLiteral("形容词"),
        QStringLiteral("副词"),
        QStringLiteral("助词"),
        QStringLiteral("冠形词"),
        QStringLiteral("语尾/助动词"),
        QStringLiteral("其他"),
    };
    const QString trimmed = text.trimmed();
    return known.contains(trimmed) ? trimmed : QStringLiteral("其他");
}

void writeVocabText(QJsonObject &payload, const QString &glyph, const QVariantMap &fields)
{
    payload.insert(QStringLiteral("glyph"), glyph);
    for (const char *key : kVocabTextKeys)
        payload.insert(QLatin1String(key), fieldText(fields, key));
    payload.insert(QStringLiteral("pos"), vocabPos(payload.value(QStringLiteral("pos")).toString()));
    for (const char *key : kVocabDroppedKeys)
        payload.remove(QLatin1String(key));
}

}

StudyStore::StudyStore(QObject *parent)
    : QObject(parent)
{
    if (!openDatabase() || !migrate() || !seedIfEmpty() || !ensureCharts())
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

    const QString fileName = QStringLiteral("study.sqlite");
    QString path;
#ifdef KJ_GO_SOURCE_DIR
    const QString projectDir = QString::fromUtf8(KJ_GO_SOURCE_DIR);
    if (QFileInfo(projectDir).isDir() && QFileInfo(projectDir).isWritable())
        path = QDir(projectDir).filePath(fileName);
#endif
    const QString appDataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    const QString previous = appDataDir.isEmpty() ? QString() : QDir(appDataDir).filePath(fileName);
    if (path.isEmpty()) {
        if (appDataDir.isEmpty() || !QDir().mkpath(appDataDir)) {
            m_error = QStringLiteral("学习数据库目录没有创建");
            return false;
        }
        path = previous;
    } else if (!QFile::exists(path) && !previous.isEmpty() && QFile::exists(previous) && !QFile::copy(previous, path)) {
        path = previous;
    }

    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    m_db.setDatabaseName(path);
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
    const int schema = version.value(0).toInt();
    if (schema >= 6)
        return true;

    if (!m_db.transaction())
        return false;

    bool ok = true;
    if (schema < 2) {
        ok = exec(QStringLiteral("UPDATE review_events SET result = 'right' WHERE result = 'good'"))
            && exec(QStringLiteral("UPDATE review_events SET result = 'wrong' WHERE result = 'again' OR result = 'hard'"))
            && exec(QStringLiteral("UPDATE memory SET last_result = NULL"))
            && recomputeStatuses();
    }
    if (ok && schema < 3) {
        ok = exec(QStringLiteral(
                "DELETE FROM review_events WHERE item_id IN (SELECT id FROM items WHERE kind = 'vocab')"))
            && exec(QStringLiteral(
                "DELETE FROM memory WHERE item_id IN (SELECT id FROM items WHERE kind = 'vocab')"))
            && exec(QStringLiteral(
                "DELETE FROM faces WHERE item_id IN (SELECT id FROM items WHERE kind = 'vocab')"))
            && exec(QStringLiteral("DELETE FROM items WHERE kind = 'vocab'"));
    }
    if (ok && schema < 4) {
        QSqlQuery vocab(m_db);
        ok = vocab.exec(QStringLiteral("SELECT id, payload FROM items WHERE kind = 'vocab'"));
        if (!ok)
            m_error = vocab.lastError().text();
        QVector<QPair<QString, QString>> updates;
        while (ok && vocab.next()) {
            QJsonObject payload = QJsonDocument::fromJson(vocab.value(1).toString().toUtf8()).object();
            bool changed = false;
            for (const char *key : kVocabDroppedKeys) {
                if (!payload.contains(QLatin1String(key)))
                    continue;
                payload.remove(QLatin1String(key));
                changed = true;
            }
            if (changed)
                updates.append({vocab.value(0).toString(), jsonText(payload)});
        }
        for (const auto &row : updates) {
            QSqlQuery update(m_db);
            update.prepare(QStringLiteral("UPDATE items SET payload = ? WHERE id = ?"));
            update.addBindValue(row.second);
            update.addBindValue(row.first);
            if (update.exec())
                continue;
            m_error = update.lastError().text();
            ok = false;
            break;
        }
    }
    if (ok && schema < 5) {
        QSqlQuery vocab(m_db);
        ok = vocab.exec(QStringLiteral("SELECT id, payload FROM items WHERE kind = 'vocab'"));
        if (!ok)
            m_error = vocab.lastError().text();
        QVector<QPair<QString, QString>> updates;
        while (ok && vocab.next()) {
            QJsonObject payload = QJsonDocument::fromJson(vocab.value(1).toString().toUtf8()).object();
            const QString pos = vocabPos(payload.value(QStringLiteral("pos")).toString());
            if (payload.value(QStringLiteral("pos")).toString() == pos)
                continue;
            payload.insert(QStringLiteral("pos"), pos);
            updates.append({vocab.value(0).toString(), jsonText(payload)});
        }
        for (const auto &row : updates) {
            QSqlQuery update(m_db);
            update.prepare(QStringLiteral("UPDATE items SET payload = ? WHERE id = ?"));
            update.addBindValue(row.second);
            update.addBindValue(row.first);
            if (update.exec())
                continue;
            m_error = update.lastError().text();
            ok = false;
            break;
        }
    }
    if (ok && schema < 6)
        ok = attachKanaAudio();

    QSqlQuery bump(m_db);
    bump.prepare(QStringLiteral("UPDATE schema_meta SET value = '6' WHERE key = 'schema'"));
    if (!ok || !bump.exec() || !m_db.commit()) {
        m_db.rollback();
        if (m_error.isEmpty()) {
            if (schema < 2)
                m_error = QStringLiteral("记忆状态没有升级");
            else if (schema < 3)
                m_error = QStringLiteral("预制词汇没有清掉");
            else if (schema < 4)
                m_error = QStringLiteral("词汇字段没有清掉");
            else if (schema < 5)
                m_error = QStringLiteral("词性没有归类");
            else
                m_error = QStringLiteral("浊音发音没有写上");
        }
        return false;
    }
    return true;
}

bool StudyStore::attachKanaAudio()
{
    QSqlQuery items(m_db);
    if (!items.exec(QStringLiteral(
            "SELECT id, payload FROM items WHERE set_id IN ('ja-dakuon', 'ja-handakuon', 'ja-youon')"))) {
        m_error = items.lastError().text();
        return false;
    }

    struct Row {
        QString id;
        QString payload;
    };
    QVector<Row> rows;
    while (items.next()) {
        Row row;
        row.id = items.value(0).toString();
        row.payload = items.value(1).toString();
        rows.append(row);
    }

    for (const Row &row : rows) {
        QJsonObject payload = QJsonDocument::fromJson(row.payload.toUtf8()).object();
        const QString reading = payload.value(QStringLiteral("reading")).toString();
        const QString audio = kanaClip(reading);
        if (audio.isEmpty())
            continue;
        if (payload.value(QStringLiteral("audio")).toString() != audio) {
            payload.insert(QStringLiteral("audio"), audio);
            QSqlQuery update(m_db);
            update.prepare(QStringLiteral("UPDATE items SET payload = ? WHERE id = ?"));
            update.addBindValue(jsonText(payload));
            update.addBindValue(row.id);
            if (!update.exec()) {
                m_error = update.lastError().text();
                return false;
            }
        }
        const QString glyph = payload.value(QStringLiteral("glyph")).toString();
        const QString glyphAlt = payload.value(QStringLiteral("glyphAlt")).toString();
        if (!upsertFace(row.id, QStringLiteral("listen"),
                        promptAudio(audio), answerText(glyph, {glyph, glyphAlt})))
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

bool StudyStore::insertItem(const QString &id, const QString &lang, const QString &setId, const QVariantMap &payload, const QString &kind)
{
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO items (id, lang, kind, set_id, payload, links) VALUES (?, ?, ?, ?, ?, '[]')"));
    query.addBindValue(id);
    query.addBindValue(lang);
    query.addBindValue(kind);
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

struct KanaSlot {
    char16_t hira0;
    char16_t hira1;
    char16_t kata0;
    char16_t kata1;
    const char *reading;
};

struct StudyStore::KanaChartRow {
    char16_t head0;
    char16_t head1;
    const char *group;
    const KanaSlot *kana;
    int count;
};

bool StudyStore::layoutReady(const QString &layoutId) const
{
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral("SELECT 1 FROM layouts WHERE id = ?"));
    query.addBindValue(layoutId);
    return query.exec() && query.next();
}

bool StudyStore::koreanChartCurrent() const
{
    QSqlQuery layout(m_db);
    layout.prepare(QStringLiteral("SELECT rows_json FROM layouts WHERE id = 'ko-syllable'"));
    if (!layout.exec() || !layout.next())
        return false;
    if (!layout.value(0).toString().contains(QStringLiteral("\"sections\"")))
        return false;
    QSqlQuery count(m_db);
    if (!count.exec(QStringLiteral("SELECT COUNT(*) FROM items WHERE set_id = 'ko-syllable'")) || !count.next())
        return false;
    return count.value(0).toInt() == kKsx1001Count;
}

bool StudyStore::clearSet(const QString &setId)
{
    const QStringList statements = {
        QStringLiteral("DELETE FROM review_events WHERE item_id IN (SELECT id FROM items WHERE set_id = ?)"),
        QStringLiteral("DELETE FROM memory WHERE item_id IN (SELECT id FROM items WHERE set_id = ?)"),
        QStringLiteral("DELETE FROM faces WHERE item_id IN (SELECT id FROM items WHERE set_id = ?)"),
        QStringLiteral("DELETE FROM items WHERE set_id = ?"),
        QStringLiteral("DELETE FROM layouts WHERE set_id = ?"),
    };
    for (const QString &sql : statements) {
        QSqlQuery query(m_db);
        query.prepare(sql);
        query.addBindValue(setId);
        if (query.exec())
            continue;
        m_error = query.lastError().text();
        return false;
    }
    return true;
}

bool StudyStore::removeSyllable(const QString &id)
{
    const QStringList statements = {
        QStringLiteral("DELETE FROM review_events WHERE item_id = ?"),
        QStringLiteral("DELETE FROM memory WHERE item_id = ?"),
        QStringLiteral("DELETE FROM faces WHERE item_id = ?"),
        QStringLiteral("DELETE FROM items WHERE id = ?"),
    };
    for (const QString &sql : statements) {
        QSqlQuery query(m_db);
        query.prepare(sql);
        query.addBindValue(id);
        if (query.exec())
            continue;
        m_error = query.lastError().text();
        return false;
    }
    return true;
}

bool StudyStore::saveSyllable(const QString &id, const QString &lang, const QString &setId, const QJsonObject &payload,
                              const QString &glyph, const QString &reading, bool existed)
{
    if (existed) {
        QSqlQuery update(m_db);
        update.prepare(QStringLiteral("UPDATE items SET lang = ?, kind = 'syllable', set_id = ?, payload = ? WHERE id = ?"));
        update.addBindValue(lang);
        update.addBindValue(setId);
        update.addBindValue(jsonText(payload));
        update.addBindValue(id);
        if (!update.exec()) {
            m_error = update.lastError().text();
            return false;
        }
    } else if (!insertItem(id, lang, setId, payload.toVariantMap())) {
        return false;
    }
    return upsertFace(id, QStringLiteral("glyph-to-reading"), promptText(glyph), answerText(reading, {reading}))
        && upsertFace(id, QStringLiteral("reading-to-glyph"), promptText(reading), answerText(glyph, {glyph}));
}

bool StudyStore::seedKanaChart(const QString &layoutId, const QString &setId, const QString &title,
                               const QStringList &columns, const QStringList &columnLabels,
                               const KanaChartRow *rows, int rowCount)
{
    if (!clearSet(setId))
        return false;

    const QString lang = QStringLiteral("ja");
    const QString pairLeftLabel = QString::fromUtf16(u"\u5e73\u5047\u540d");
    const QString pairRightLabel = QString::fromUtf16(u"\u7247\u5047\u540d");
    const QString rowSuffix = QString::fromUtf16(u"\u884c");

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

    for (int rowIndex = 0; rowIndex < rowCount; ++rowIndex) {
        const KanaChartRow &row = rows[rowIndex];
        const QString head = kanaText(row.head0, row.head1);
        QJsonArray cells;
        for (int column = 0; column < row.count; ++column) {
            const KanaSlot &slot = row.kana[column];
            if (slot.reading == nullptr || slot.reading[0] == '\0') {
                cells.append(QString());
                continue;
            }
            ++position;
            Pending item;
            item.glyph = kanaText(slot.hira0, slot.hira1);
            item.glyphAlt = kanaText(slot.kata0, slot.kata1);
            item.reading = QString::fromLatin1(slot.reading);
            item.audio = kanaClip(item.reading);
            item.id = itemId(lang, item.reading);
            item.payload = QJsonObject{
                {QStringLiteral("glyph"), item.glyph},
                {QStringLiteral("glyphAlt"), item.glyphAlt},
                {QStringLiteral("reading"), item.reading},
                {QStringLiteral("audio"), item.audio},
                {QStringLiteral("pairLeftLabel"), pairLeftLabel},
                {QStringLiteral("pairLeft"), item.glyph},
                {QStringLiteral("pairRightLabel"), pairRightLabel},
                {QStringLiteral("pairRight"), item.glyphAlt},
                {QStringLiteral("rowLabel"), head + rowSuffix},
                {QStringLiteral("columnLabel"), column < columnLabels.size() ? columnLabels.at(column) : QString()},
                {QStringLiteral("column"), column},
                {QStringLiteral("position"), position},
                {QStringLiteral("mnemonic"), QString()},
                {QStringLiteral("lookalikes"), QJsonArray()},
            };
            cells.append(item.id);
            pending.append(std::move(item));
        }
        layoutRows.append(QJsonObject{
            {QStringLiteral("short"), head},
            {QStringLiteral("group"), QString::fromLatin1(row.group)},
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

    QJsonArray columnJson;
    for (const QString &column : columns)
        columnJson.append(column);

    QSqlQuery layout(m_db);
    layout.prepare(QStringLiteral(
        "INSERT INTO layouts (id, lang, set_id, eyebrow, title, column_serif, columns_json, rows_json) "
        "VALUES (?, ?, ?, ?, ?, 0, ?, ?)"));
    layout.addBindValue(layoutId);
    layout.addBindValue(lang);
    layout.addBindValue(setId);
    layout.addBindValue(QStringLiteral("-"));
    layout.addBindValue(title);
    layout.addBindValue(QString::fromUtf8(QJsonDocument(columnJson).toJson(QJsonDocument::Compact)));
    layout.addBindValue(QString::fromUtf8(QJsonDocument(layoutRows).toJson(QJsonDocument::Compact)));
    if (layout.exec())
        return true;
    m_error = layout.lastError().text();
    return false;
}

QStringList danLabels(const char16_t *kana, int count)
{
    QStringList labels;
    const QString suffix = QString::fromUtf16(u"\u6bb5");
    for (int i = 0; i < count; ++i)
        labels.append(QString(QChar(kana[i])) + suffix);
    return labels;
}

bool StudyStore::seedDakuon()
{
    static const KanaSlot ga[] = {
        {0x304C, 0, 0x30AC, 0, "ga"}, {0x304E, 0, 0x30AE, 0, "gi"}, {0x3050, 0, 0x30B0, 0, "gu"},
        {0x3052, 0, 0x30B2, 0, "ge"}, {0x3054, 0, 0x30B4, 0, "go"},
    };
    static const KanaSlot za[] = {
        {0x3056, 0, 0x30B6, 0, "za"}, {0x3058, 0, 0x30B8, 0, "ji"}, {0x305A, 0, 0x30BA, 0, "zu"},
        {0x305C, 0, 0x30BC, 0, "ze"}, {0x305E, 0, 0x30BE, 0, "zo"},
    };
    static const KanaSlot da[] = {
        {0x3060, 0, 0x30C0, 0, "da"}, {0x3062, 0, 0x30C2, 0, "di"}, {0x3065, 0, 0x30C5, 0, "du"},
        {0x3067, 0, 0x30C7, 0, "de"}, {0x3069, 0, 0x30C9, 0, "do"},
    };
    static const KanaSlot ba[] = {
        {0x3070, 0, 0x30D0, 0, "ba"}, {0x3073, 0, 0x30D3, 0, "bi"}, {0x3076, 0, 0x30D6, 0, "bu"},
        {0x3079, 0, 0x30D9, 0, "be"}, {0x307C, 0, 0x30DC, 0, "bo"},
    };
    static const KanaChartRow rows[] = {
        {0x304C, 0, "ga", ga, 5},
        {0x3056, 0, "za", za, 5},
        {0x3060, 0, "da", da, 5},
        {0x3070, 0, "ba", ba, 5},
    };
    const char16_t dans[] = {0x3042, 0x3044, 0x3046, 0x3048, 0x304A};
    return seedKanaChart(QStringLiteral("ja-gojuon-dakuon"), QStringLiteral("ja-dakuon"),
                         QString::fromUtf16(u"\u6fc1\u97f3"),
                         {QStringLiteral("A"), QStringLiteral("I"), QStringLiteral("U"), QStringLiteral("E"), QStringLiteral("O")},
                         danLabels(dans, 5), rows, 4);
}

bool StudyStore::seedHandakuon()
{
    static const KanaSlot pa[] = {
        {0x3071, 0, 0x30D1, 0, "pa"}, {0x3074, 0, 0x30D4, 0, "pi"}, {0x3077, 0, 0x30D7, 0, "pu"},
        {0x307A, 0, 0x30DA, 0, "pe"}, {0x307D, 0, 0x30DD, 0, "po"},
    };
    static const KanaChartRow rows[] = {
        {0x3071, 0, "pa", pa, 5},
    };
    const char16_t dans[] = {0x3042, 0x3044, 0x3046, 0x3048, 0x304A};
    return seedKanaChart(QStringLiteral("ja-gojuon-handakuon"), QStringLiteral("ja-handakuon"),
                         QString::fromUtf16(u"\u534a\u6fc1\u97f3"),
                         {QStringLiteral("A"), QStringLiteral("I"), QStringLiteral("U"), QStringLiteral("E"), QStringLiteral("O")},
                         danLabels(dans, 5), rows, 1);
}

bool StudyStore::seedYouon()
{
    static const KanaSlot kya[] = {
        {0x304D, 0x3083, 0x30AD, 0x30E3, "kya"}, {0x304D, 0x3085, 0x30AD, 0x30E5, "kyu"}, {0x304D, 0x3087, 0x30AD, 0x30E7, "kyo"},
    };
    static const KanaSlot sha[] = {
        {0x3057, 0x3083, 0x30B7, 0x30E3, "sha"}, {0x3057, 0x3085, 0x30B7, 0x30E5, "shu"}, {0x3057, 0x3087, 0x30B7, 0x30E7, "sho"},
    };
    static const KanaSlot cha[] = {
        {0x3061, 0x3083, 0x30C1, 0x30E3, "cha"}, {0x3061, 0x3085, 0x30C1, 0x30E5, "chu"}, {0x3061, 0x3087, 0x30C1, 0x30E7, "cho"},
    };
    static const KanaSlot nya[] = {
        {0x306B, 0x3083, 0x30CB, 0x30E3, "nya"}, {0x306B, 0x3085, 0x30CB, 0x30E5, "nyu"}, {0x306B, 0x3087, 0x30CB, 0x30E7, "nyo"},
    };
    static const KanaSlot hya[] = {
        {0x3072, 0x3083, 0x30D2, 0x30E3, "hya"}, {0x3072, 0x3085, 0x30D2, 0x30E5, "hyu"}, {0x3072, 0x3087, 0x30D2, 0x30E7, "hyo"},
    };
    static const KanaSlot mya[] = {
        {0x307F, 0x3083, 0x30DF, 0x30E3, "mya"}, {0x307F, 0x3085, 0x30DF, 0x30E5, "myu"}, {0x307F, 0x3087, 0x30DF, 0x30E7, "myo"},
    };
    static const KanaSlot rya[] = {
        {0x308A, 0x3083, 0x30EA, 0x30E3, "rya"}, {0x308A, 0x3085, 0x30EA, 0x30E5, "ryu"}, {0x308A, 0x3087, 0x30EA, 0x30E7, "ryo"},
    };
    static const KanaSlot gya[] = {
        {0x304E, 0x3083, 0x30AE, 0x30E3, "gya"}, {0x304E, 0x3085, 0x30AE, 0x30E5, "gyu"}, {0x304E, 0x3087, 0x30AE, 0x30E7, "gyo"},
    };
    static const KanaSlot ja[] = {
        {0x3058, 0x3083, 0x30B8, 0x30E3, "ja"}, {0x3058, 0x3085, 0x30B8, 0x30E5, "ju"}, {0x3058, 0x3087, 0x30B8, 0x30E7, "jo"},
    };
    static const KanaSlot dya[] = {
        {0x3062, 0x3083, 0x30C2, 0x30E3, "dya"}, {0x3062, 0x3085, 0x30C2, 0x30E5, "dyu"}, {0x3062, 0x3087, 0x30C2, 0x30E7, "dyo"},
    };
    static const KanaSlot bya[] = {
        {0x3073, 0x3083, 0x30D3, 0x30E3, "bya"}, {0x3073, 0x3085, 0x30D3, 0x30E5, "byu"}, {0x3073, 0x3087, 0x30D3, 0x30E7, "byo"},
    };
    static const KanaSlot pya[] = {
        {0x3074, 0x3083, 0x30D4, 0x30E3, "pya"}, {0x3074, 0x3085, 0x30D4, 0x30E5, "pyu"}, {0x3074, 0x3087, 0x30D4, 0x30E7, "pyo"},
    };
    static const KanaChartRow rows[] = {
        {0x304D, 0x3083, "kya", kya, 3},
        {0x3057, 0x3083, "sha", sha, 3},
        {0x3061, 0x3083, "cha", cha, 3},
        {0x306B, 0x3083, "nya", nya, 3},
        {0x3072, 0x3083, "hya", hya, 3},
        {0x307F, 0x3083, "mya", mya, 3},
        {0x308A, 0x3083, "rya", rya, 3},
        {0x304E, 0x3083, "gya", gya, 3},
        {0x3058, 0x3083, "ja", ja, 3},
        {0x3062, 0x3083, "dya", dya, 3},
        {0x3073, 0x3083, "bya", bya, 3},
        {0x3074, 0x3083, "pya", pya, 3},
    };
    const char16_t dans[] = {0x3084, 0x3086, 0x3088};
    return seedKanaChart(QStringLiteral("ja-gojuon-youon"), QStringLiteral("ja-youon"),
                         QString::fromUtf16(u"\u62d7\u97f3"),
                         {QStringLiteral("YA"), QStringLiteral("YU"), QStringLiteral("YO")},
                         danLabels(dans, 3), rows, 12);
}

bool StudyStore::ensureCharts()
{
    const bool koreanReady = koreanChartCurrent();
    const bool dakuonReady = layoutReady(QStringLiteral("ja-gojuon-dakuon"));
    const bool handakuonReady = layoutReady(QStringLiteral("ja-gojuon-handakuon"));
    const bool youonReady = layoutReady(QStringLiteral("ja-gojuon-youon"));
    if (koreanReady && dakuonReady && handakuonReady && youonReady)
        return true;

    if (!m_db.transaction())
        return false;
    bool ok = true;
    if (!dakuonReady)
        ok = seedDakuon();
    if (ok && !handakuonReady)
        ok = seedHandakuon();
    if (ok && !youonReady)
        ok = seedYouon();
    if (ok && !koreanReady)
        ok = seedKorean();
    if (!ok || !m_db.commit()) {
        m_db.rollback();
        if (m_error.isEmpty())
            m_error = QStringLiteral("音节表没有写入");
        return false;
    }
    return true;
}

bool StudyStore::seedKorean()
{
    const QString lang = QStringLiteral("ko");
    const QString setId = QStringLiteral("ko-syllable");
    const QString pairLeftLabel = QString::fromUtf16(u"\u8f85\u97f3");
    const QString pairRightLabel = QString::fromUtf16(u"\u5143\u97f3");
    const QString pairCodaLabel = QString::fromUtf16(u"\u6536\u97f3");
    const QString rowSuffix = QString::fromUtf16(u"\u884c");

    QHash<QString, QString> keptMnemonic;
    QSet<QString> existing;
    QSqlQuery prior(m_db);
    prior.prepare(QStringLiteral("SELECT id, payload FROM items WHERE set_id = ?"));
    prior.addBindValue(setId);
    if (!prior.exec()) {
        m_error = prior.lastError().text();
        return false;
    }
    while (prior.next()) {
        const QString id = prior.value(0).toString();
        existing.insert(id);
        const QJsonObject old = QJsonDocument::fromJson(prior.value(1).toString().toUtf8()).object();
        const QString mnemonic = old.value(QStringLiteral("mnemonic")).toString();
        if (!mnemonic.isEmpty())
            keptMnemonic.insert(id, mnemonic);
    }

    struct Pending {
        QString id;
        QJsonObject payload;
        QString glyph;
        QString reading;
        bool existed = false;
    };
    QVector<Pending> pending;
    QJsonArray layoutRows;
    QJsonArray columns;
    QSet<QString> keep;
    int position = 0;

    for (int vowel = 0; vowel < 21; ++vowel)
        columns.append(QString(QChar(static_cast<char16_t>(0x314F + vowel))));

    int cursor = 0;
    for (int initial = 0; initial < 19; ++initial) {
        const QString jamo(QChar(kInitialJamo[initial]));
        QString group = QString::fromLatin1(kInitialReading[initial]);
        if (group.isEmpty())
            group = QStringLiteral("ng");
        QJsonArray sections;
        QJsonArray flat;
        while (cursor < kKsx1001Count && kKsx1001Offset[cursor] / (21 * 28) == initial) {
            const int medial = (kKsx1001Offset[cursor] / 28) % 21;
            const QString vowel(QChar(static_cast<char16_t>(0x314F + medial)));
            QJsonArray cells;
            while (cursor < kKsx1001Count) {
                const int offset = kKsx1001Offset[cursor];
                const int lead = offset / (21 * 28);
                const int vowelIndex = (offset / 28) % 21;
                if (lead != initial || vowelIndex != medial)
                    break;
                const int finale = offset % 28;
                ++position;
                const QString reading = QString::fromLatin1(kInitialReading[lead])
                    + QString::fromLatin1(kVowelReading[vowelIndex])
                    + QString::fromLatin1(kFinalReading[finale]);
                Pending item;
                item.id = itemId(lang, reading);
                item.glyph = QString(QChar(0xAC00 + offset));
                item.reading = reading;
                item.existed = existing.contains(item.id);
                const QString coda = finale == 0 ? QString() : QString(QChar(kFinalJamo[finale]));
                item.payload = QJsonObject{
                    {QStringLiteral("glyph"), item.glyph},
                    {QStringLiteral("glyphAlt"), QString()},
                    {QStringLiteral("reading"), item.reading},
                    {QStringLiteral("audio"), QString()},
                    {QStringLiteral("pairLeftLabel"), pairLeftLabel},
                    {QStringLiteral("pairLeft"), jamo},
                    {QStringLiteral("pairRightLabel"), pairRightLabel},
                    {QStringLiteral("pairRight"), vowel},
                    {QStringLiteral("pairCodaLabel"), pairCodaLabel},
                    {QStringLiteral("pairCoda"), coda},
                    {QStringLiteral("rowLabel"), jamo + rowSuffix},
                    {QStringLiteral("columnLabel"), vowel},
                    {QStringLiteral("column"), vowelIndex},
                    {QStringLiteral("position"), position},
                    {QStringLiteral("mnemonic"), keptMnemonic.value(item.id)},
                    {QStringLiteral("lookalikes"), QJsonArray()},
                };
                cells.append(item.id);
                flat.append(item.id);
                keep.insert(item.id);
                pending.append(std::move(item));
                ++cursor;
            }
            sections.append(QJsonObject{
                {QStringLiteral("label"), vowel},
                {QStringLiteral("cells"), cells},
            });
        }
        if (sections.isEmpty())
            continue;
        layoutRows.append(QJsonObject{
            {QStringLiteral("short"), jamo},
            {QStringLiteral("group"), group},
            {QStringLiteral("cells"), flat},
            {QStringLiteral("sections"), sections},
        });
    }

    if (pending.size() != kKsx1001Count) {
        m_error = QStringLiteral("常用韩文音节没有排全");
        return false;
    }

    for (Pending &item : pending) {
        item.payload.insert(QStringLiteral("total"), pending.size());
        if (!saveSyllable(item.id, lang, setId, item.payload, item.glyph, item.reading, item.existed))
            return false;
    }
    for (const QString &id : existing) {
        if (!keep.contains(id) && !removeSyllable(id))
            return false;
    }

    QSqlQuery drop(m_db);
    drop.prepare(QStringLiteral("DELETE FROM layouts WHERE id = ?"));
    drop.addBindValue(setId);
    if (!drop.exec()) {
        m_error = drop.lastError().text();
        return false;
    }

    QSqlQuery layout(m_db);
    layout.prepare(QStringLiteral(
        "INSERT INTO layouts (id, lang, set_id, eyebrow, title, column_serif, columns_json, rows_json) "
        "VALUES (?, ?, ?, ?, ?, 1, ?, ?)"));
    layout.addBindValue(setId);
    layout.addBindValue(lang);
    layout.addBindValue(setId);
    layout.addBindValue(QStringLiteral("-"));
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
        QVariantMap rowMap{
            {QStringLiteral("short"), row.value(QStringLiteral("short")).toString()},
            {QStringLiteral("group"), row.value(QStringLiteral("group")).toString()},
            {QStringLiteral("cells"), cells},
        };
        const QJsonArray storedSections = row.value(QStringLiteral("sections")).toArray();
        if (!storedSections.isEmpty()) {
            QVariantList sections;
            for (const QJsonValue &sectionValue : storedSections) {
                const QJsonObject section = sectionValue.toObject();
                QVariantList sectionCells;
                for (const QJsonValue &sectionCell : section.value(QStringLiteral("cells")).toArray()) {
                    const QString sectionId = sectionCell.toString();
                    if (sectionId.isEmpty() || !cards.contains(sectionId))
                        sectionCells.append(QVariantMap{{QStringLiteral("id"), QString()}});
                    else
                        sectionCells.append(cards.value(sectionId));
                }
                sections.append(QVariantMap{
                    {QStringLiteral("label"), section.value(QStringLiteral("label")).toString()},
                    {QStringLiteral("cells"), sectionCells},
                });
            }
            rowMap.insert(QStringLiteral("sections"), sections);
        }
        rows.append(rowMap);
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
            {QStringLiteral("gloss"), likePayload.value(QStringLiteral("gloss")).toString()},
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
    result.insert(QStringLiteral("pairCodaLabel"), payload.value(QStringLiteral("pairCodaLabel")).toString());
    result.insert(QStringLiteral("pairCoda"), payload.value(QStringLiteral("pairCoda")).toString());
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

    result.insert(QStringLiteral("group"), payload.value(QStringLiteral("group")).toString());
    result.insert(QStringLiteral("pos"), payload.value(QStringLiteral("pos")).toString());
    result.insert(QStringLiteral("gloss"), payload.value(QStringLiteral("gloss")).toString());
    result.insert(QStringLiteral("example"), payload.value(QStringLiteral("example")).toString());
    result.insert(QStringLiteral("exampleGloss"), payload.value(QStringLiteral("exampleGloss")).toString());
    result.insert(QStringLiteral("note"), payload.value(QStringLiteral("note")).toString());
    result.insert(QStringLiteral("mnemonic"), payload.value(QStringLiteral("mnemonic")).toString());
    result.insert(QStringLiteral("lookalikes"), lookalikes);
    result.insert(QStringLiteral("status"), query.value(4).toString().isEmpty() ? QStringLiteral("unlearned") : query.value(4).toString());
    result.insert(QStringLiteral("streak"), query.value(5).toInt());
    result.insert(QStringLiteral("lastResult"), lastResult);
    return result;
}

QVariantList StudyStore::items(const QString &setId) const
{
    QVariantList result;
    if (!m_db.isOpen() || setId.isEmpty())
        return result;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT i.id, i.payload, m.status FROM items i "
        "LEFT JOIN memory m ON m.item_id = i.id WHERE i.set_id = ?"));
    query.addBindValue(setId);
    if (!query.exec())
        return result;

    struct Row {
        int position;
        QVariantMap item;
    };
    QVector<Row> rows;
    while (query.next()) {
        const QJsonObject payload = QJsonDocument::fromJson(query.value(1).toString().toUtf8()).object();
        const QString status = query.value(2).toString();
        rows.append({payload.value(QStringLiteral("position")).toInt(), QVariantMap{
            {QStringLiteral("id"), query.value(0).toString()},
            {QStringLiteral("glyph"), payload.value(QStringLiteral("glyph")).toString()},
            {QStringLiteral("gloss"), payload.value(QStringLiteral("gloss")).toString()},
            {QStringLiteral("pos"), payload.value(QStringLiteral("pos")).toString()},
            {QStringLiteral("status"), status.isEmpty() ? QStringLiteral("unlearned") : status},
        }});
    }
    std::sort(rows.begin(), rows.end(), [](const Row &left, const Row &right) {
        return left.position < right.position;
    });
    for (const Row &row : rows)
        result.append(row.item);
    return result;
}

void StudyStore::setMnemonic(const QString &itemId, const QString &text)
{
    QVariantMap fields;
    fields.insert(QStringLiteral("mnemonic"), text);
    setFields(itemId, fields);
}

void StudyStore::setFields(const QString &itemId, const QVariantMap &fields)
{
    if (!m_db.isOpen() || itemId.isEmpty() || fields.isEmpty())
        return;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral("SELECT payload FROM items WHERE id = ?"));
    query.addBindValue(itemId);
    if (!query.exec() || !query.next())
        return;

    QJsonObject payload = QJsonDocument::fromJson(query.value(0).toString().toUtf8()).object();
    bool edited = false;
    for (auto it = fields.cbegin(); it != fields.cend(); ++it) {
        if (!kEditableFields.contains(it.key()))
            continue;
        const QString text = it.value().toString();
        if (payload.value(it.key()).toString() == text)
            continue;
        payload.insert(it.key(), text);
        edited = true;
    }
    if (!edited)
        return;

    QSqlQuery update(m_db);
    update.prepare(QStringLiteral("UPDATE items SET payload = ? WHERE id = ?"));
    update.addBindValue(jsonText(payload));
    update.addBindValue(itemId);
    if (!update.exec())
        return;
    ++m_revision;
    emit changed();
}

bool StudyStore::upsertFace(const QString &itemId, const QString &promptKind, const QVariantMap &prompt, const QVariantMap &answer)
{
    QSqlQuery existing(m_db);
    existing.prepare(QStringLiteral("SELECT id FROM faces WHERE item_id = ? AND prompt_kind = ?"));
    existing.addBindValue(itemId);
    existing.addBindValue(promptKind);
    if (!existing.exec()) {
        m_error = existing.lastError().text();
        return false;
    }
    if (!existing.next())
        return insertFace(itemId, promptKind, prompt, answer);

    QSqlQuery update(m_db);
    update.prepare(QStringLiteral("UPDATE faces SET prompt = ?, answer = ? WHERE id = ?"));
    update.addBindValue(jsonText(objectFrom(prompt)));
    update.addBindValue(jsonText(objectFrom(answer)));
    update.addBindValue(existing.value(0).toString());
    if (update.exec())
        return true;
    m_error = update.lastError().text();
    return false;
}

bool StudyStore::syncVocabFaces(const QString &itemId, const QString &glyph, const QString &gloss)
{
    return upsertFace(itemId, QStringLiteral("word-to-gloss"), promptText(glyph), answerText(gloss, {gloss}))
        && upsertFace(itemId, QStringLiteral("gloss-to-word"), promptText(gloss), answerText(glyph, {glyph}));
}

bool StudyStore::vocabKind(const QString &itemId, QJsonObject *payload) const
{
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral("SELECT kind, payload FROM items WHERE id = ?"));
    query.addBindValue(itemId);
    if (!query.exec() || !query.next())
        return false;
    if (query.value(0).toString() != QStringLiteral("vocab"))
        return false;
    if (payload)
        *payload = QJsonDocument::fromJson(query.value(1).toString().toUtf8()).object();
    return true;
}

QString StudyStore::scriptIssue(const QString &lang, const QString &word) const
{
    bool hangul = false;
    bool kana = false;
    bool han = false;
    for (const QChar &ch : word) {
        switch (ch.script()) {
        case QChar::Script_Hangul:
            hangul = true;
            break;
        case QChar::Script_Hiragana:
        case QChar::Script_Katakana:
            kana = true;
            break;
        case QChar::Script_Han:
            han = true;
            break;
        default:
            break;
        }
    }

    if (lang == QLatin1String("ko")) {
        if (!hangul || kana)
            return QStringLiteral("这个词不是韩文");
        return {};
    }
    if (lang == QLatin1String("ja")) {
        if (hangul || !(kana || han))
            return QStringLiteral("这个词不是日文");
        return {};
    }
    return QStringLiteral("这个词库不能添加");
}

QString StudyStore::addVocab(const QString &setId, const QString &lang, const QVariantMap &fields)
{
    if (!m_db.isOpen())
        return {};
    const bool japanese = setId == QLatin1String("ja-vocab") && lang == QLatin1String("ja");
    const bool korean = setId == QLatin1String("ko-vocab") && lang == QLatin1String("ko");
    if (!japanese && !korean) {
        m_error = QStringLiteral("这个词库不能添加");
        return {};
    }

    const QString glyph = fieldText(fields, "glyph");
    if (glyph.isEmpty()) {
        m_error = QStringLiteral("单词不能是空的");
        return {};
    }
    if (fieldText(fields, "gloss").isEmpty()) {
        m_error = QStringLiteral("中文意思不能是空的");
        return {};
    }
    const QString issue = scriptIssue(lang, glyph);
    if (!issue.isEmpty()) {
        m_error = issue;
        return {};
    }

    int position = 1;
    QSqlQuery scan(m_db);
    scan.prepare(QStringLiteral("SELECT payload FROM items WHERE set_id = ?"));
    scan.addBindValue(setId);
    if (!scan.exec()) {
        m_error = scan.lastError().text();
        return {};
    }
    while (scan.next()) {
        const QJsonObject row = QJsonDocument::fromJson(scan.value(0).toString().toUtf8()).object();
        position = qMax(position, row.value(QStringLiteral("position")).toInt() + 1);
    }

    QJsonObject payload{
        {QStringLiteral("glyphAlt"), QString()},
        {QStringLiteral("audio"), QString()},
        {QStringLiteral("position"), position},
        {QStringLiteral("total"), position},
    };
    writeVocabText(payload, glyph, fields);

    const QString id = lang + QStringLiteral(":vocab:") + QUuid::createUuid().toString(QUuid::WithoutBraces);
    const QString gloss = payload.value(QStringLiteral("gloss")).toString();
    if (!m_db.transaction())
        return {};
    if (!insertItem(id, lang, setId, payload.toVariantMap(), QStringLiteral("vocab"))
        || !syncVocabFaces(id, glyph, gloss)
        || !m_db.commit()) {
        m_db.rollback();
        if (m_error.isEmpty())
            m_error = QStringLiteral("词汇没有写入");
        return {};
    }
    ++m_revision;
    emit changed();
    return id;
}

bool StudyStore::updateVocab(const QString &itemId, const QVariantMap &fields)
{
    if (!m_db.isOpen() || itemId.isEmpty())
        return false;

    const QString glyph = fieldText(fields, "glyph");
    if (glyph.isEmpty()) {
        m_error = QStringLiteral("单词不能是空的");
        return false;
    }
    if (fieldText(fields, "gloss").isEmpty()) {
        m_error = QStringLiteral("中文意思不能是空的");
        return false;
    }

    QSqlQuery langQuery(m_db);
    langQuery.prepare(QStringLiteral("SELECT lang FROM items WHERE id = ?"));
    langQuery.addBindValue(itemId);
    if (!langQuery.exec() || !langQuery.next()) {
        m_error = langQuery.lastError().text();
        if (m_error.isEmpty())
            m_error = QStringLiteral("只能修改词汇");
        return false;
    }
    const QString issue = scriptIssue(langQuery.value(0).toString(), glyph);
    if (!issue.isEmpty()) {
        m_error = issue;
        return false;
    }

    QJsonObject payload;
    if (!vocabKind(itemId, &payload)) {
        m_error = QStringLiteral("只能修改词汇");
        return false;
    }
    writeVocabText(payload, glyph, fields);
    const QString gloss = payload.value(QStringLiteral("gloss")).toString();

    if (!m_db.transaction())
        return false;
    QSqlQuery update(m_db);
    update.prepare(QStringLiteral("UPDATE items SET payload = ? WHERE id = ? AND kind = 'vocab'"));
    update.addBindValue(jsonText(payload));
    update.addBindValue(itemId);
    if (!update.exec() || !syncVocabFaces(itemId, glyph, gloss) || !m_db.commit()) {
        m_db.rollback();
        if (m_error.isEmpty())
            m_error = QStringLiteral("词汇没有保存");
        return false;
    }
    ++m_revision;
    emit changed();
    return true;
}

bool StudyStore::removeVocab(const QString &itemId)
{
    if (!m_db.isOpen() || itemId.isEmpty())
        return false;
    if (!vocabKind(itemId)) {
        m_error = QStringLiteral("只能删除词汇");
        return false;
    }
    if (!m_db.transaction())
        return false;

    const QStringList statements = {
        QStringLiteral("DELETE FROM review_events WHERE item_id = ?"),
        QStringLiteral("DELETE FROM memory WHERE item_id = ?"),
        QStringLiteral("DELETE FROM faces WHERE item_id = ?"),
        QStringLiteral("DELETE FROM items WHERE id = ? AND kind = 'vocab'"),
    };
    for (const QString &sql : statements) {
        QSqlQuery query(m_db);
        query.prepare(sql);
        query.addBindValue(itemId);
        if (!query.exec()) {
            m_error = query.lastError().text();
            m_db.rollback();
            return false;
        }
        if (sql.startsWith(QStringLiteral("DELETE FROM items")) && query.numRowsAffected() != 1) {
            m_error = QStringLiteral("词汇没有删掉");
            m_db.rollback();
            return false;
        }
    }
    if (!m_db.commit()) {
        m_db.rollback();
        if (m_error.isEmpty())
            m_error = QStringLiteral("词汇没有删掉");
        return false;
    }
    ++m_revision;
    emit changed();
    return true;
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

QVariantMap StudyStore::progress(const QString &lang) const
{
    struct SetSpec {
        QString id;
        QString label;
    };
    QVector<SetSpec> specs;
    if (lang == QLatin1String("ko")) {
        specs.append({QStringLiteral("ko-syllable"), QString::fromUtf16(u"\u8c1a\u6587")});
        specs.append({QStringLiteral("ko-vocab"), QString::fromUtf16(u"\u8bcd\u6c47")});
    } else {
        specs.append({QStringLiteral("ja-seion"), QString::fromUtf16(u"\u6e05\u97f3")});
        specs.append({QStringLiteral("ja-dakuon"), QString::fromUtf16(u"\u6fc1\u97f3")});
        specs.append({QStringLiteral("ja-handakuon"), QString::fromUtf16(u"\u534a\u6fc1\u97f3")});
        specs.append({QStringLiteral("ja-youon"), QString::fromUtf16(u"\u62d7\u97f3")});
        specs.append({QStringLiteral("ja-vocab"), QString::fromUtf16(u"\u8bcd\u6c47")});
    }

    QHash<QString, QVariantMap> bySet;
    for (const SetSpec &spec : specs) {
        bySet.insert(spec.id, QVariantMap{
            {QStringLiteral("id"), spec.id},
            {QStringLiteral("label"), spec.label},
            {QStringLiteral("total"), 0},
            {QStringLiteral("mastered"), 0},
            {QStringLiteral("fuzzy"), 0},
            {QStringLiteral("unlearned"), 0},
        });
    }

    if (m_db.isOpen()) {
        QSqlQuery counts(m_db);
        counts.prepare(QStringLiteral(
            "SELECT i.set_id, IFNULL(m.status, 'unlearned'), COUNT(*) "
            "FROM items i LEFT JOIN memory m ON m.item_id = i.id "
            "WHERE i.lang = ? GROUP BY i.set_id, IFNULL(m.status, 'unlearned')"));
        counts.addBindValue(lang);
        if (counts.exec()) {
            while (counts.next()) {
                const QString setId = counts.value(0).toString();
                if (!bySet.contains(setId))
                    continue;
                QVariantMap row = bySet.value(setId);
                const QString status = counts.value(1).toString();
                const int count = counts.value(2).toInt();
                row.insert(QStringLiteral("total"), row.value(QStringLiteral("total")).toInt() + count);
                if (status == QLatin1String("mastered"))
                    row.insert(QStringLiteral("mastered"), count);
                else if (status == QLatin1String("fuzzy"))
                    row.insert(QStringLiteral("fuzzy"), count);
                else
                    row.insert(QStringLiteral("unlearned"), row.value(QStringLiteral("unlearned")).toInt() + count);
                bySet.insert(setId, row);
            }
        }
    }

    QVariantList sets;
    for (const SetSpec &spec : specs)
        sets.append(bySet.value(spec.id));

    struct Event {
        QString itemId;
        QDate day;
        bool right = false;
    };
    QVector<Event> events;
    if (m_db.isOpen()) {
        QSqlQuery query(m_db);
        query.prepare(QStringLiteral(
            "SELECT e.item_id, e.at, e.result FROM review_events e "
            "JOIN items i ON i.id = e.item_id WHERE i.lang = ? ORDER BY e.id ASC"));
        query.addBindValue(lang);
        if (query.exec()) {
            while (query.next()) {
                const QDateTime at = QDateTime::fromString(query.value(1).toString(), Qt::ISODateWithMs);
                if (!at.isValid())
                    continue;
                Event event;
                event.itemId = query.value(0).toString();
                event.day = at.toLocalTime().date();
                event.right = query.value(2).toString() == QLatin1String("right");
                events.append(event);
            }
        }
    }

    const QDate today = QDate::currentDate();
    QHash<QDate, QPair<int, int>> byDay;
    QSet<QDate> activeDays;
    QHash<QString, bool> latestRight;
    int reviews = 0;
    int right = 0;
    for (const Event &event : events) {
        ++reviews;
        if (event.right)
            ++right;
        QPair<int, int> dayCount = byDay.value(event.day);
        dayCount.first += 1;
        if (event.right)
            dayCount.second += 1;
        byDay.insert(event.day, dayCount);
        activeDays.insert(event.day);
        latestRight.insert(event.itemId, event.right);
    }

    int held = 0;
    for (auto it = latestRight.cbegin(); it != latestRight.cend(); ++it) {
        if (it.value())
            ++held;
    }

    int streak = 0;
    QDate cursor = today;
    if (!activeDays.contains(cursor))
        cursor = cursor.addDays(-1);
    while (activeDays.contains(cursor)) {
        ++streak;
        cursor = cursor.addDays(-1);
    }

    QVariantList curve;
    for (int offset = 13; offset >= 0; --offset) {
        const QDate day = today.addDays(-offset);
        const QPair<int, int> dayCount = byDay.value(day);
        curve.append(QVariantMap{
            {QStringLiteral("label"), QString::number(day.month()) + QLatin1Char('/') + QString::number(day.day())},
            {QStringLiteral("reviews"), dayCount.first},
            {QStringLiteral("right"), dayCount.second},
        });
    }

    QStringList missIds;
    QSet<QString> seenMiss;
    for (int index = events.size() - 1; index >= 0 && missIds.size() < 8; --index) {
        const Event &event = events.at(index);
        if (seenMiss.contains(event.itemId))
            continue;
        seenMiss.insert(event.itemId);
        if (!event.right)
            missIds.append(event.itemId);
    }

    QHash<QString, QString> setLabels;
    for (const SetSpec &spec : specs)
        setLabels.insert(spec.id, spec.label);

    QVariantList misses;
    for (const QString &id : missIds) {
        QSqlQuery item(m_db);
        item.prepare(QStringLiteral("SELECT set_id, payload FROM items WHERE id = ?"));
        item.addBindValue(id);
        if (!item.exec() || !item.next())
            continue;
        const QJsonObject payload = QJsonDocument::fromJson(item.value(1).toString().toUtf8()).object();
        const QString setId = item.value(0).toString();
        misses.append(QVariantMap{
            {QStringLiteral("id"), id},
            {QStringLiteral("glyph"), payload.value(QStringLiteral("glyph")).toString()},
            {QStringLiteral("reading"), payload.value(QStringLiteral("reading")).toString()},
            {QStringLiteral("gloss"), payload.value(QStringLiteral("gloss")).toString()},
            {QStringLiteral("setLabel"), setLabels.value(setId)},
        });
    }

    const QPair<int, int> todayCount = byDay.value(today);
    return QVariantMap{
        {QStringLiteral("sets"), sets},
        {QStringLiteral("reviews"), reviews},
        {QStringLiteral("right"), right},
        {QStringLiteral("today"), todayCount.first},
        {QStringLiteral("todayRight"), todayCount.second},
        {QStringLiteral("reviewed"), latestRight.size()},
        {QStringLiteral("held"), held},
        {QStringLiteral("streak"), streak},
        {QStringLiteral("curve"), curve},
        {QStringLiteral("misses"), misses},
    };
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

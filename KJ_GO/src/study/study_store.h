#pragma once

#include <QJsonObject>
#include <QObject>
#include <QSqlDatabase>
#include <QVariantList>
#include <QVariantMap>

class StudyStore : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int revision READ revision NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
public:
    explicit StudyStore(QObject *parent = nullptr);

    int revision() const;
    QString error() const;
    QString language() const;
    void setLanguage(const QString &language);

    Q_INVOKABLE QVariantMap layout(const QString &layoutId) const;
    Q_INVOKABLE QVariantMap item(const QString &itemId) const;
    Q_INVOKABLE QVariantList items(const QString &setId) const;
    Q_INVOKABLE QVariantMap counts(const QString &setId) const;
    Q_INVOKABLE QVariantMap progress(const QString &lang) const;
    Q_INVOKABLE QStringList weakIds(const QString &setId) const;
    Q_INVOKABLE QStringList itemIds(const QString &setId) const;
    Q_INVOKABLE QStringList reviewQueue(const QString &setId, int limit) const;
    Q_INVOKABLE void rate(const QString &itemId, bool correct, const QString &activity, const QString &prompt);
    Q_INVOKABLE void setMnemonic(const QString &itemId, const QString &text);
    Q_INVOKABLE void setFields(const QString &itemId, const QVariantMap &fields);
    Q_INVOKABLE QString scriptIssue(const QString &lang, const QString &word) const;
    Q_INVOKABLE QString addVocab(const QString &setId, const QString &lang, const QVariantMap &fields);
    Q_INVOKABLE bool updateVocab(const QString &itemId, const QVariantMap &fields);
    Q_INVOKABLE bool removeVocab(const QString &itemId);
    Q_INVOKABLE QString lastError() const;

signals:
    void changed();
    void errorChanged();
    void languageChanged();

private:
    void setError(const QString &message);
    bool openDatabase();
    bool migrate();
    struct KanaChartRow;

    bool seedIfEmpty();
    bool ensureCharts();
    bool seedJapanese();
    bool seedKorean();
    bool seedDakuon();
    bool seedHandakuon();
    bool seedYouon();
    bool seedKanaChart(const QString &layoutId, const QString &setId, const QString &title,
                       const QStringList &columns, const QStringList &columnLabels,
                       const KanaChartRow *rows, int rowCount);
    bool koreanChartCurrent() const;
    bool layoutReady(const QString &layoutId) const;
    bool clearSet(const QString &setId);
    bool saveSyllable(const QString &id, const QString &lang, const QString &setId, const QJsonObject &payload,
                      const QString &glyph, const QString &reading, bool existed);
    bool removeSyllable(const QString &id);
    bool exec(const QString &sql);
    bool upgradeMemory();
    bool attachKanaAudio();
    bool recomputeStatuses();
    QString statusFor(const QString &itemId) const;
    bool insertItem(const QString &id, const QString &lang, const QString &setId, const QVariantMap &payload, const QString &kind = QStringLiteral("syllable"));
    bool insertFace(const QString &itemId, const QString &promptKind, const QVariantMap &prompt, const QVariantMap &answer);
    bool upsertFace(const QString &itemId, const QString &promptKind, const QVariantMap &prompt, const QVariantMap &answer);
    bool syncVocabFaces(const QString &itemId, const QString &glyph, const QString &gloss);
    bool vocabKind(const QString &itemId, QJsonObject *payload = nullptr) const;

    QSqlDatabase m_db;
    QString m_error;
    QString m_language = QStringLiteral("ja");
    int m_revision = 0;
};

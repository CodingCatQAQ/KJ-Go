#pragma once

#include <QObject>
#include <QSqlDatabase>
#include <QVariantList>
#include <QVariantMap>

class StudyStore : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int revision READ revision NOTIFY changed)
    Q_PROPERTY(QString error READ error CONSTANT)
public:
    explicit StudyStore(QObject *parent = nullptr);

    int revision() const;
    QString error() const;

    Q_INVOKABLE QVariantMap layout(const QString &layoutId) const;
    Q_INVOKABLE QVariantMap item(const QString &itemId) const;
    Q_INVOKABLE QVariantList items(const QString &setId) const;
    Q_INVOKABLE QVariantMap counts(const QString &setId) const;
    Q_INVOKABLE QStringList weakIds(const QString &setId) const;
    Q_INVOKABLE QStringList itemIds(const QString &setId) const;
    Q_INVOKABLE QStringList reviewQueue(const QString &setId, int limit) const;
    Q_INVOKABLE void rate(const QString &itemId, bool correct, const QString &activity, const QString &prompt);
    Q_INVOKABLE void setMnemonic(const QString &itemId, const QString &text);
    Q_INVOKABLE void setFields(const QString &itemId, const QVariantMap &fields);

signals:
    void changed();

private:
    bool openDatabase();
    bool migrate();
    bool seedIfEmpty();
    bool seedJapanese();
    bool seedKorean();
    bool ensureKoreanVocab();
    bool seedKoreanVocab();
    bool exec(const QString &sql);
    bool upgradeMemory();
    bool recomputeStatuses();
    QString statusFor(const QString &itemId) const;
    bool insertItem(const QString &id, const QString &lang, const QString &setId, const QVariantMap &payload, const QString &kind = QStringLiteral("syllable"));
    bool insertFace(const QString &itemId, const QString &promptKind, const QVariantMap &prompt, const QVariantMap &answer);

    QSqlDatabase m_db;
    QString m_error;
    int m_revision = 0;
};

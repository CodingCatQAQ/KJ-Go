#pragma once

#include "game/application/vocab_catalog.h"
#include "game/application/vocab_dealer.h"
#include "game/domain/board_tier.h"
#include "game/domain/memory_board.h"
#include "game/presentation/memory_card_model.h"

#include <QElapsedTimer>
#include <QObject>
#include <QRandomGenerator>
#include <QTimer>
#include <QVariantList>

namespace game {

class MemoryMatchGame : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString setId READ setId WRITE setSetId NOTIFY setIdChanged)
    Q_PROPERTY(QString phase READ phase NOTIFY changed)
    Q_PROPERTY(int side READ side NOTIFY changed)
    Q_PROPERTY(int pairsLeft READ pairsLeft NOTIFY changed)
    Q_PROPERTY(int pairsTotal READ pairsTotal NOTIFY changed)
    Q_PROPERTY(int moves READ moves NOTIFY changed)
    Q_PROPERTY(int misses READ misses NOTIFY changed)
    Q_PROPERTY(int seconds READ seconds NOTIFY changed)
    Q_PROPERTY(bool resolving READ resolving NOTIFY changed)
    Q_PROPERTY(bool resolveMatched READ resolveMatched NOTIFY changed)
    Q_PROPERTY(bool perfect READ perfect NOTIFY changed)
    Q_PROPERTY(int usableCount READ usableCount NOTIFY changed)
    Q_PROPERTY(MemoryCardModel *cards READ cards CONSTANT)
    Q_PROPERTY(QVariantList recap READ recap NOTIFY changed)
public:
    explicit MemoryMatchGame(VocabCatalog &catalog, QObject *parent = nullptr);

    QString setId() const;
    void setSetId(const QString &setId);
    QString phase() const;
    int side() const;
    int pairsLeft() const;
    int pairsTotal() const;
    int moves() const;
    int misses() const;
    int seconds() const;
    bool resolving() const;
    bool resolveMatched() const;
    bool perfect() const;
    int usableCount() const;
    MemoryCardModel *cards() const;
    QVariantList recap() const;

    Q_INVOKABLE bool canStart(int side) const;
    Q_INVOKABLE int shortfall(int side) const;
    Q_INVOKABLE bool start(int side);
    Q_INVOKABLE void flip(int index);
    Q_INVOKABLE void again();
    Q_INVOKABLE void replay();
    Q_INVOKABLE void endRound();

public slots:
    void reloadPool();

signals:
    void changed();
    void setIdChanged();

private slots:
    void settle();
    void tick();

private:
    void resetRound();
    void beginRound(int side, const DealtRound &round);

    VocabCatalog &m_catalog;
    MemoryCardModel *m_cards;
    QVector<VocabWord> m_usableWords;
    QVector<VocabWord> m_dealt;
    QVariantList m_recap;
    BoardTier m_tier;
    MemoryBoard m_board;
    QString m_setId;
    QString m_phase = QStringLiteral("setup");
    bool m_resolving = false;
    bool m_resolveMatched = false;
    int m_seconds = 0;
    QTimer m_settleTimer;
    QTimer m_tickTimer;
    QElapsedTimer m_clock;
    QRandomGenerator m_random;
};

}

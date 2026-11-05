#pragma once

#include "game/domain/memory_card.h"

#include <QVector>

namespace game {

enum class FlipOutcome { Ignored, First, Match, Miss };

class MemoryBoard {
public:
    void deal(QVector<MemoryCard> cards);
    void clear();
    FlipOutcome flip(int index);
    void settle();

    bool awaitingSettle() const;
    int pairsLeft() const;
    int pairsTotal() const;
    int moves() const;
    int misses() const;
    const QVector<MemoryCard> &cards() const;

private:
    QVector<MemoryCard> m_cards;
    int m_first = -1;
    int m_second = -1;
    int m_moves = 0;
    int m_misses = 0;
    int m_pairsLeft = 0;
    int m_pairsTotal = 0;
    bool m_awaiting = false;
};

}

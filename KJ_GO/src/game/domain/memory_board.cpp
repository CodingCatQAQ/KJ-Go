#include "game/domain/memory_board.h"

#include <utility>

namespace game {

void MemoryBoard::deal(QVector<MemoryCard> cards)
{
    clear();
    m_cards = std::move(cards);
    m_pairsTotal = m_cards.size() / 2;
    m_pairsLeft = m_pairsTotal;
}

void MemoryBoard::clear()
{
    m_cards.clear();
    m_first = -1;
    m_second = -1;
    m_moves = 0;
    m_misses = 0;
    m_pairsLeft = 0;
    m_pairsTotal = 0;
    m_awaiting = false;
}

FlipOutcome MemoryBoard::flip(int index)
{
    if (m_awaiting || index < 0 || index >= m_cards.size())
        return FlipOutcome::Ignored;
    MemoryCard &card = m_cards[index];
    if (card.visibility != CardVisibility::Down)
        return FlipOutcome::Ignored;

    card.visibility = CardVisibility::Up;
    if (m_first < 0) {
        m_first = index;
        return FlipOutcome::First;
    }

    m_second = index;
    m_moves += 1;
    m_awaiting = true;
    if (m_cards.at(m_first).pairId == card.pairId)
        return FlipOutcome::Match;
    m_misses += 1;
    return FlipOutcome::Miss;
}

void MemoryBoard::settle()
{
    if (!m_awaiting || m_first < 0 || m_second < 0)
        return;

    MemoryCard &first = m_cards[m_first];
    MemoryCard &second = m_cards[m_second];
    if (first.pairId == second.pairId) {
        first.visibility = CardVisibility::Cleared;
        second.visibility = CardVisibility::Cleared;
        if (m_pairsLeft > 0)
            m_pairsLeft -= 1;
    } else {
        first.visibility = CardVisibility::Down;
        second.visibility = CardVisibility::Down;
    }
    m_first = -1;
    m_second = -1;
    m_awaiting = false;
}

bool MemoryBoard::awaitingSettle() const
{
    return m_awaiting;
}

int MemoryBoard::pairsLeft() const
{
    return m_pairsLeft;
}

int MemoryBoard::pairsTotal() const
{
    return m_pairsTotal;
}

int MemoryBoard::moves() const
{
    return m_moves;
}

int MemoryBoard::misses() const
{
    return m_misses;
}

const QVector<MemoryCard> &MemoryBoard::cards() const
{
    return m_cards;
}

}

#include "game/presentation/memory_match_game.h"

#include <QVariantMap>

namespace game {
namespace {
constexpr int kMatchHoldMs = 280;
constexpr int kMissHoldMs = 800;
}

MemoryMatchGame::MemoryMatchGame(VocabCatalog &catalog, QObject *parent)
    : QObject(parent)
    , m_catalog(catalog)
    , m_cards(new MemoryCardModel(this))
    , m_random(QRandomGenerator::securelySeeded())
{
    m_settleTimer.setSingleShot(true);
    connect(&m_settleTimer, &QTimer::timeout, this, &MemoryMatchGame::settle);
    m_tickTimer.setInterval(200);
    connect(&m_tickTimer, &QTimer::timeout, this, &MemoryMatchGame::tick);
}

QString MemoryMatchGame::setId() const
{
    return m_setId;
}

void MemoryMatchGame::setSetId(const QString &setId)
{
    if (m_setId == setId)
        return;
    m_setId = setId;
    resetRound();
    emit setIdChanged();
    reloadPool();
}

QString MemoryMatchGame::phase() const
{
    return m_phase;
}

int MemoryMatchGame::side() const
{
    return m_tier.side;
}

int MemoryMatchGame::pairsLeft() const
{
    return m_board.pairsLeft();
}

int MemoryMatchGame::pairsTotal() const
{
    return m_board.pairsTotal();
}

int MemoryMatchGame::moves() const
{
    return m_board.moves();
}

int MemoryMatchGame::misses() const
{
    return m_board.misses();
}

int MemoryMatchGame::seconds() const
{
    return m_seconds;
}

bool MemoryMatchGame::resolving() const
{
    return m_resolving;
}

bool MemoryMatchGame::resolveMatched() const
{
    return m_resolveMatched;
}

bool MemoryMatchGame::perfect() const
{
    return m_phase == QLatin1String("finished") && m_board.pairsTotal() > 0 && m_board.misses() == 0;
}

int MemoryMatchGame::usableCount() const
{
    return m_usableWords.size();
}

MemoryCardModel *MemoryMatchGame::cards() const
{
    return m_cards;
}

QVariantList MemoryMatchGame::recap() const
{
    return m_recap;
}

bool MemoryMatchGame::canStart(int side) const
{
    const BoardTier tier = BoardTier::fromSide(side);
    return tier.valid() && m_usableWords.size() >= tier.pairs();
}

int MemoryMatchGame::shortfall(int side) const
{
    const BoardTier tier = BoardTier::fromSide(side);
    if (!tier.valid())
        return 0;
    const int lack = tier.pairs() - m_usableWords.size();
    return lack > 0 ? lack : 0;
}

bool MemoryMatchGame::start(int side)
{
    const BoardTier tier = BoardTier::fromSide(side);
    if (!tier.valid() || m_usableWords.size() < tier.pairs())
        return false;
    const DealtRound round = VocabDealer::deal(m_usableWords, tier.pairs(), m_random);
    if (round.cards.size() != tier.cards())
        return false;
    beginRound(side, round);
    return true;
}

void MemoryMatchGame::flip(int index)
{
    if (m_phase != QLatin1String("playing"))
        return;
    const FlipOutcome outcome = m_board.flip(index);
    if (outcome == FlipOutcome::Ignored)
        return;
    m_cards->sync(m_board.cards());
    if (outcome == FlipOutcome::First) {
        emit changed();
        return;
    }
    m_resolving = true;
    m_resolveMatched = outcome == FlipOutcome::Match;
    emit changed();
    m_settleTimer.start(m_resolveMatched ? kMatchHoldMs : kMissHoldMs);
}

void MemoryMatchGame::again()
{
    if (!m_tier.valid() || !start(m_tier.side))
        endRound();
}

void MemoryMatchGame::replay()
{
    if (m_dealt.isEmpty() || !m_tier.valid())
        return;
    DealtRound round;
    round.words = m_dealt;
    round.cards = VocabDealer::layout(m_dealt, m_random);
    beginRound(m_tier.side, round);
}

void MemoryMatchGame::endRound()
{
    resetRound();
    emit changed();
}

void MemoryMatchGame::reloadPool()
{
    m_usableWords = VocabDealer::usable(m_catalog.load(m_setId));
    emit changed();
}

void MemoryMatchGame::settle()
{
    if (!m_board.awaitingSettle())
        return;
    m_board.settle();
    m_resolving = false;
    m_resolveMatched = false;
    m_cards->sync(m_board.cards());
    if (m_board.pairsLeft() == 0) {
        m_phase = QStringLiteral("finished");
        m_tickTimer.stop();
        m_seconds = int(m_clock.elapsed() / 1000);
    }
    emit changed();
}

void MemoryMatchGame::tick()
{
    if (m_phase != QLatin1String("playing"))
        return;
    const int seconds = int(m_clock.elapsed() / 1000);
    if (seconds == m_seconds)
        return;
    m_seconds = seconds;
    emit changed();
}

void MemoryMatchGame::resetRound()
{
    m_settleTimer.stop();
    m_tickTimer.stop();
    m_board.clear();
    m_dealt.clear();
    m_recap.clear();
    m_tier = {};
    m_resolving = false;
    m_resolveMatched = false;
    m_seconds = 0;
    m_phase = QStringLiteral("setup");
    m_cards->replace({});
}

void MemoryMatchGame::beginRound(int side, const DealtRound &round)
{
    m_settleTimer.stop();
    m_tier = BoardTier::fromSide(side);
    m_board.deal(round.cards);
    m_dealt = round.words;
    m_recap.clear();
    for (const VocabWord &word : m_dealt) {
        m_recap.append(QVariantMap{
            {QStringLiteral("glyph"), word.glyph},
            {QStringLiteral("gloss"), word.gloss},
        });
    }
    m_resolving = false;
    m_resolveMatched = false;
    m_seconds = 0;
    m_phase = QStringLiteral("playing");
    m_cards->replace(m_board.cards());
    m_clock.start();
    if (!m_tickTimer.isActive())
        m_tickTimer.start();
    emit changed();
}

}

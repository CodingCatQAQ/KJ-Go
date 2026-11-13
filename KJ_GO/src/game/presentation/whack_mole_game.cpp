#include "game/presentation/whack_mole_game.h"

#include "game/application/vocab_dealer.h"

#include <QVariantMap>

namespace game {
namespace {
constexpr int kTickMs = 50;
constexpr int kLeadMs = 450;
constexpr int kSpawnGapMs = 180;
constexpr int kBetweenMs = 380;
}

WhackMoleGame::WhackMoleGame(VocabCatalog &catalog, StudyStore &store, QObject *parent)
    : QObject(parent)
    , m_catalog(catalog)
    , m_store(store)
    , m_holes(new MoleHoleModel(this))
    , m_random(QRandomGenerator::securelySeeded())
{
    m_hideAt.fill(-1);
    m_timer.setInterval(kTickMs);
    connect(&m_timer, &QTimer::timeout, this, &WhackMoleGame::tick);
}

QString WhackMoleGame::setId() const
{
    return m_setId;
}

void WhackMoleGame::setSetId(const QString &setId)
{
    if (m_setId == setId)
        return;
    m_setId = setId;
    resetRound();
    emit setIdChanged();
    reloadPool();
}

QString WhackMoleGame::phase() const
{
    return m_phase;
}

const MolePrompt *WhackMoleGame::currentPrompt() const
{
    if (m_promptIndex < 0 || m_promptIndex >= m_prompts.size())
        return nullptr;
    return &m_prompts.at(m_promptIndex);
}

QString WhackMoleGame::promptText() const
{
    if (m_phase != QLatin1String("playing"))
        return {};
    const MolePrompt *prompt = currentPrompt();
    return prompt ? prompt->prompt : QString();
}

int WhackMoleGame::promptNumber() const
{
    if (m_phase != QLatin1String("playing") || !currentPrompt())
        return 0;
    return m_promptIndex + 1;
}

int WhackMoleGame::promptTotal() const
{
    return m_prompts.size();
}

int WhackMoleGame::hits() const
{
    return m_hits;
}

int WhackMoleGame::wrongTaps() const
{
    return m_wrongTaps;
}

int WhackMoleGame::escapes() const
{
    return m_escapes;
}

int WhackMoleGame::seconds() const
{
    return m_seconds;
}

int WhackMoleGame::usableCount() const
{
    return m_usableWords.size();
}

QString WhackMoleGame::moleFace() const
{
    return m_face == PromptFace::Gloss ? QStringLiteral("word") : QStringLiteral("gloss");
}

bool WhackMoleGame::perfect() const
{
    return m_phase == QLatin1String("finished") && m_escapes == 0 && !m_prompts.isEmpty();
}

MoleHoleModel *WhackMoleGame::holes() const
{
    return m_holes;
}

QVariantList WhackMoleGame::recap() const
{
    return m_recap;
}

bool WhackMoleGame::canStart(const QString &tierId) const
{
    const WhackTier tier = WhackTier::fromId(tierId);
    return tier.valid() && m_usableWords.size() >= WhackTier::kMinimumWords;
}

int WhackMoleGame::shortfall(const QString &tierId) const
{
    if (!WhackTier::fromId(tierId).valid())
        return 0;
    const int lack = WhackTier::kMinimumWords - m_usableWords.size();
    return lack > 0 ? lack : 0;
}

bool WhackMoleGame::start(const QString &tierId, const QString &direction)
{
    const WhackTier tier = WhackTier::fromId(tierId);
    if (!tier.valid() || m_usableWords.size() < WhackTier::kMinimumWords)
        return false;
    const PromptFace face = promptFaceFromId(direction);
    const WhackRound round = MoleDealer::deal(m_usableWords, face, tier, m_random);
    if (round.prompts.size() != tier.prompts)
        return false;
    m_pool = m_usableWords;
    beginRound(tier, face, round);
    return true;
}

void WhackMoleGame::whack(int hole)
{
    if (m_phase != QLatin1String("playing") || m_between || m_resolved || m_paused)
        return;
    const WhackOutcome outcome = m_field.whack(hole);
    if (outcome == WhackOutcome::Empty)
        return;
    if (hole >= 0 && hole < MoleField::kHoleCount)
        m_hideAt[hole] = -1;
    if (outcome == WhackOutcome::Wrong) {
        m_wrongTaps += 1;
        const qint64 clock = now();
        if (m_nextSpawnAt < clock + kSpawnGapMs)
            m_nextSpawnAt = clock + kSpawnGapMs;
        m_holes->sync(m_field);
        emit changed();
        return;
    }
    finishPrompt(true);
}

void WhackMoleGame::again()
{
    if (!m_tier.valid() || !start(m_tier.id, promptFaceId(m_face)))
        endRound();
}

void WhackMoleGame::replay()
{
    if (m_prompts.isEmpty() || !m_tier.valid())
        return;
    QVector<VocabWord> targets;
    targets.reserve(m_prompts.size());
    for (const MolePrompt &prompt : m_prompts) {
        VocabWord word;
        word.id = prompt.wordId;
        word.glyph = prompt.glyph;
        word.gloss = prompt.gloss;
        targets.append(word);
    }
    WhackRound round;
    round.prompts = MoleDealer::build(targets, m_pool, m_face, m_tier.wave, m_random);
    if (round.prompts.size() != targets.size())
        return;
    beginRound(m_tier, m_face, round);
}

void WhackMoleGame::endRound()
{
    resetRound();
    emit changed();
}

void WhackMoleGame::setRunning(bool running)
{
    if (m_running == running)
        return;
    m_running = running;
    if (!running) {
        if (m_phase == QLatin1String("playing") && !m_paused) {
            m_pausedAt = m_clock.elapsed();
            m_paused = true;
            m_timer.stop();
        }
        return;
    }
    if (!m_paused)
        return;
    m_held += m_clock.elapsed() - m_pausedAt;
    m_paused = false;
    if (m_phase == QLatin1String("playing"))
        m_timer.start();
}

void WhackMoleGame::reloadPool()
{
    m_usableWords = VocabDealer::usable(m_catalog.load(m_setId));
    emit changed();
}

void WhackMoleGame::tick()
{
    if (m_phase != QLatin1String("playing") || m_paused)
        return;

    const qint64 clock = now();
    const int seconds = int(clock / 1000);
    if (m_between) {
        if (clock < m_resumeAt) {
            if (seconds != m_seconds) {
                m_seconds = seconds;
                emit changed();
            }
            return;
        }
        m_promptIndex += 1;
        if (m_promptIndex >= m_prompts.size()) {
            m_phase = QStringLiteral("finished");
            m_between = false;
            m_timer.stop();
            m_seconds = int(now() / 1000);
            clearField();
            emit changed();
            return;
        }
        openPrompt();
        emit changed();
        return;
    }

    bool fieldDirty = false;
    for (int hole = 0; hole < MoleField::kHoleCount; ++hole) {
        if (!m_field.occupied(hole) || m_hideAt[hole] < 0 || clock < m_hideAt[hole])
            continue;
        const bool escaped = m_field.sink(hole);
        m_hideAt[hole] = -1;
        fieldDirty = true;
        if (escaped) {
            finishPrompt(false);
            return;
        }
        if (m_nextSpawnAt < clock + kSpawnGapMs)
            m_nextSpawnAt = clock + kSpawnGapMs;
    }

    const MolePrompt *prompt = currentPrompt();
    if (!m_resolved && prompt && m_field.occupiedCount() < m_tier.concurrent && m_waveIndex < prompt->wave.size()
        && clock >= m_nextSpawnAt) {
        const int hole = freeHole();
        if (hole >= 0) {
            const MoleAppearance &item = prompt->wave.at(m_waveIndex);
            m_waveIndex += 1;
            if (m_field.pop(hole, item.wordId, item.label, item.target)) {
                m_hideAt[hole] = clock + m_tier.dwellMs;
                m_nextSpawnAt = clock + kSpawnGapMs;
                fieldDirty = true;
            }
        }
    }

    if (!m_resolved && prompt && m_waveIndex >= prompt->wave.size() && m_field.occupiedCount() == 0) {
        finishPrompt(false);
        return;
    }

    if (fieldDirty)
        m_holes->sync(m_field);
    if (fieldDirty || seconds != m_seconds) {
        m_seconds = seconds;
        emit changed();
    }
}

void WhackMoleGame::resetRound()
{
    m_timer.stop();
    m_prompts.clear();
    m_pool.clear();
    m_recap.clear();
    m_tier = {};
    m_promptIndex = 0;
    m_waveIndex = 0;
    m_hits = 0;
    m_wrongTaps = 0;
    m_escapes = 0;
    m_seconds = 0;
    m_between = false;
    m_resolved = false;
    m_paused = false;
    m_held = 0;
    m_pausedAt = 0;
    m_nextSpawnAt = 0;
    m_resumeAt = 0;
    m_phase = QStringLiteral("setup");
    clearField();
}

void WhackMoleGame::beginRound(const WhackTier &tier, PromptFace face, const WhackRound &round)
{
    m_timer.stop();
    m_tier = tier;
    m_face = face;
    m_prompts = round.prompts;
    m_recap.clear();
    m_promptIndex = 0;
    m_hits = 0;
    m_wrongTaps = 0;
    m_escapes = 0;
    m_seconds = 0;
    m_paused = false;
    m_held = 0;
    m_phase = QStringLiteral("playing");
    m_clock.start();
    openPrompt();
    if (m_running)
        m_timer.start();
    else {
        m_paused = true;
        m_pausedAt = m_clock.elapsed();
    }
    emit changed();
}

void WhackMoleGame::openPrompt()
{
    clearField();
    m_waveIndex = 0;
    m_resolved = false;
    m_between = false;
    m_nextSpawnAt = now() + kLeadMs;
}

void WhackMoleGame::finishPrompt(bool correct)
{
    if (m_resolved)
        return;
    const MolePrompt *prompt = currentPrompt();
    if (!prompt)
        return;

    const QString wordId = prompt->wordId;
    const QString glyph = prompt->glyph;
    const QString gloss = prompt->gloss;
    m_resolved = true;
    m_waveIndex = prompt->wave.size();
    clearField();
    if (correct) {
        m_hits += 1;
    } else {
        m_escapes += 1;
        m_recap.append(QVariantMap{
            {QStringLiteral("glyph"), glyph},
            {QStringLiteral("gloss"), gloss},
        });
    }
    m_between = true;
    m_resumeAt = now() + kBetweenMs;
    m_store.rate(wordId, correct, QStringLiteral("whack"), promptFaceId(m_face));
    emit changed();
}

void WhackMoleGame::clearField()
{
    m_field.reset();
    m_hideAt.fill(-1);
    m_holes->sync(m_field);
}

int WhackMoleGame::freeHole()
{
    QVector<int> open;
    open.reserve(MoleField::kHoleCount);
    for (int hole = 0; hole < MoleField::kHoleCount; ++hole) {
        if (!m_field.occupied(hole))
            open.append(hole);
    }
    if (open.isEmpty())
        return -1;
    return open.at(m_random.bounded(int(open.size())));
}

qint64 WhackMoleGame::now() const
{
    return m_clock.elapsed() - m_held;
}

}

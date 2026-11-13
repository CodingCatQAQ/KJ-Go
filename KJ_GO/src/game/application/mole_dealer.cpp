#include "game/application/mole_dealer.h"

#include <QSet>

#include <algorithm>

namespace game {
namespace {

QString promptText(const VocabWord &word, PromptFace face)
{
    return face == PromptFace::Gloss ? word.gloss : word.glyph;
}

QString moleLabel(const VocabWord &word, PromptFace face)
{
    return face == PromptFace::Gloss ? word.glyph : word.gloss;
}

QVector<VocabWord> pickTargets(const QVector<VocabWord> &usable, int count, QRandomGenerator &random)
{
    QVector<VocabWord> fresh;
    QVector<VocabWord> known;
    fresh.reserve(usable.size());
    known.reserve(usable.size());
    for (const VocabWord &word : usable) {
        if (word.mastered)
            known.append(word);
        else
            fresh.append(word);
    }
    std::shuffle(fresh.begin(), fresh.end(), random);
    std::shuffle(known.begin(), known.end(), random);

    QVector<VocabWord> ordered;
    ordered.reserve(usable.size());
    ordered += fresh;
    ordered += known;
    if (ordered.isEmpty() || count <= 0)
        return {};

    QVector<VocabWord> targets;
    targets.reserve(count);
    const int pool = int(ordered.size());
    const int firstPass = qMin(count, pool);
    for (int i = 0; i < firstPass; ++i)
        targets.append(ordered.at(i));
    while (targets.size() < count) {
        std::shuffle(ordered.begin(), ordered.end(), random);
        const int take = qMin(count - int(targets.size()), pool);
        for (int i = 0; i < take; ++i)
            targets.append(ordered.at(i));
    }
    return targets;
}

}

QString promptFaceId(PromptFace face)
{
    return face == PromptFace::Glyph ? QStringLiteral("glyph") : QStringLiteral("gloss");
}

PromptFace promptFaceFromId(const QString &id)
{
    return id == QLatin1String("glyph") ? PromptFace::Glyph : PromptFace::Gloss;
}

WhackRound MoleDealer::deal(const QVector<VocabWord> &usable, PromptFace face, const WhackTier &tier,
                             QRandomGenerator &random)
{
    WhackRound round;
    if (!tier.valid())
        return round;
    const QVector<VocabWord> targets = pickTargets(usable, tier.prompts, random);
    round.prompts = build(targets, usable, face, tier.wave, random);
    return round;
}

QVector<MolePrompt> MoleDealer::build(const QVector<VocabWord> &targets, const QVector<VocabWord> &pool,
                                      PromptFace face, int waveLength, QRandomGenerator &random)
{
    QVector<MolePrompt> prompts;
    prompts.reserve(targets.size());
    const int distractorSlots = qMax(0, waveLength - 1);

    for (const VocabWord &target : targets) {
        const QString prompt = promptText(target, face).trimmed();
        const QString answer = moleLabel(target, face).trimmed();
        if (target.id.isEmpty() || prompt.isEmpty() || answer.isEmpty())
            continue;

        QVector<VocabWord> distractors;
        QSet<QString> seen;
        seen.insert(answer);
        for (const VocabWord &word : pool) {
            if (word.id == target.id)
                continue;
            const QString label = moleLabel(word, face).trimmed();
            if (label.isEmpty() || label == prompt || seen.contains(label))
                continue;
            seen.insert(label);
            distractors.append(word);
        }
        std::shuffle(distractors.begin(), distractors.end(), random);

        QVector<MoleAppearance> wave;
        const int take = qMin(distractorSlots, int(distractors.size()));
        wave.reserve(take + 1);
        for (int i = 0; i < take; ++i)
            wave.append(MoleAppearance{distractors.at(i).id, moleLabel(distractors.at(i), face).trimmed(), false});

        const int slot = random.bounded(int(wave.size()) + 1);
        wave.insert(slot, MoleAppearance{target.id, answer, true});

        prompts.append(MolePrompt{target.id, prompt, target.glyph.trimmed(), target.gloss.trimmed(), wave});
    }
    return prompts;
}

}

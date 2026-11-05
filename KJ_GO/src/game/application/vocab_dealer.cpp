#include "game/application/vocab_dealer.h"

#include <QHash>

#include <algorithm>

namespace game {

QVector<VocabWord> VocabDealer::usable(const QVector<VocabWord> &words)
{
    QVector<VocabWord> kept;
    QHash<QString, int> glossAt;
    for (const VocabWord &word : words) {
        const QString glyph = word.glyph.trimmed();
        const QString gloss = word.gloss.trimmed();
        if (word.id.isEmpty() || glyph.isEmpty() || gloss.isEmpty())
            continue;
        const int existing = glossAt.value(gloss, -1);
        if (existing < 0) {
            glossAt.insert(gloss, kept.size());
            kept.append(VocabWord{word.id, glyph, gloss, word.mastered});
            continue;
        }
        if (kept[existing].mastered && !word.mastered)
            kept[existing] = VocabWord{word.id, glyph, gloss, false};
    }
    return kept;
}

QVector<MemoryCard> VocabDealer::layout(const QVector<VocabWord> &words, QRandomGenerator &random)
{
    QVector<MemoryCard> cards;
    cards.reserve(words.size() * 2);
    for (const VocabWord &word : words) {
        cards.append(MemoryCard{word.id, CardFace::Word, word.glyph, CardVisibility::Down});
        cards.append(MemoryCard{word.id, CardFace::Gloss, word.gloss, CardVisibility::Down});
    }
    std::shuffle(cards.begin(), cards.end(), random);
    return cards;
}

DealtRound VocabDealer::deal(const QVector<VocabWord> &usableWords, int pairs, QRandomGenerator &random)
{
    DealtRound round;
    if (pairs <= 0 || usableWords.size() < pairs)
        return round;

    QVector<VocabWord> fresh;
    QVector<VocabWord> known;
    for (const VocabWord &word : usableWords) {
        if (word.mastered)
            known.append(word);
        else
            fresh.append(word);
    }
    std::shuffle(fresh.begin(), fresh.end(), random);
    std::shuffle(known.begin(), known.end(), random);

    QVector<VocabWord> ordered;
    ordered.reserve(usableWords.size());
    ordered += fresh;
    ordered += known;
    round.words = ordered.mid(0, pairs);
    round.cards = layout(round.words, random);
    return round;
}

}

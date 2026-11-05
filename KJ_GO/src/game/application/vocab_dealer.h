#pragma once

#include "game/application/vocab_word.h"
#include "game/domain/memory_card.h"

#include <QRandomGenerator>
#include <QVector>

namespace game {

struct DealtRound {
    QVector<MemoryCard> cards;
    QVector<VocabWord> words;
};

class VocabDealer {
public:
    static QVector<VocabWord> usable(const QVector<VocabWord> &words);
    static DealtRound deal(const QVector<VocabWord> &usableWords, int pairs, QRandomGenerator &random);
    static QVector<MemoryCard> layout(const QVector<VocabWord> &words, QRandomGenerator &random);
};

}

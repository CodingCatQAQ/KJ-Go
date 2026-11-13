#pragma once

#include "game/application/vocab_word.h"
#include "game/domain/whack_tier.h"

#include <QRandomGenerator>
#include <QString>
#include <QVector>

namespace game {

enum class PromptFace { Gloss, Glyph };

struct MoleAppearance {
    QString wordId;
    QString label;
    bool target = false;
};

struct MolePrompt {
    QString wordId;
    QString prompt;
    QString glyph;
    QString gloss;
    QVector<MoleAppearance> wave;
};

struct WhackRound {
    QVector<MolePrompt> prompts;
};

class MoleDealer {
public:
    static WhackRound deal(const QVector<VocabWord> &usable, PromptFace face, const WhackTier &tier,
                            QRandomGenerator &random);
    static QVector<MolePrompt> build(const QVector<VocabWord> &targets, const QVector<VocabWord> &pool,
                                     PromptFace face, int waveLength, QRandomGenerator &random);
};

QString promptFaceId(PromptFace face);
PromptFace promptFaceFromId(const QString &id);

}

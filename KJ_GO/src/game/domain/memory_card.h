#pragma once

#include <QString>

namespace game {

enum class CardFace { Word, Gloss };
enum class CardVisibility { Down, Up, Cleared };

struct MemoryCard {
    QString pairId;
    CardFace face = CardFace::Word;
    QString text;
    CardVisibility visibility = CardVisibility::Down;
};

}

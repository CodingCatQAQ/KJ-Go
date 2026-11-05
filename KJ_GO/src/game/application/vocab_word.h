#pragma once

#include <QString>

namespace game {

struct VocabWord {
    QString id;
    QString glyph;
    QString gloss;
    bool mastered = false;
};

}

#pragma once

#include "game/application/vocab_word.h"

#include <QString>
#include <QVector>

namespace game {

class VocabCatalog {
public:
    virtual ~VocabCatalog() = default;
    virtual QVector<VocabWord> load(const QString &setId) const = 0;
};

}

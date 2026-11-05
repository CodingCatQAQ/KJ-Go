#pragma once

#include "game/application/vocab_catalog.h"

class StudyStore;

namespace game {

class StudyVocabCatalog : public VocabCatalog {
public:
    explicit StudyVocabCatalog(StudyStore &store);
    QVector<VocabWord> load(const QString &setId) const override;

private:
    StudyStore &m_store;
};

}

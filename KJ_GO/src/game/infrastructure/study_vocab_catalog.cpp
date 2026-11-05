#include "game/infrastructure/study_vocab_catalog.h"

#include "study/study_store.h"

namespace game {

StudyVocabCatalog::StudyVocabCatalog(StudyStore &store)
    : m_store(store)
{
}

QVector<VocabWord> StudyVocabCatalog::load(const QString &setId) const
{
    QVector<VocabWord> words;
    const QVariantList rows = m_store.items(setId);
    words.reserve(rows.size());
    for (const QVariant &rowValue : rows) {
        const QVariantMap row = rowValue.toMap();
        VocabWord word;
        word.id = row.value(QStringLiteral("id")).toString();
        word.glyph = row.value(QStringLiteral("glyph")).toString();
        word.gloss = row.value(QStringLiteral("gloss")).toString();
        word.mastered = row.value(QStringLiteral("status")).toString() == QLatin1String("mastered");
        words.append(word);
    }
    return words;
}

}

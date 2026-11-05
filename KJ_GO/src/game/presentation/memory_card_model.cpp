#include "game/presentation/memory_card_model.h"

namespace game {

MemoryCardModel::MemoryCardModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int MemoryCardModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_cards.size();
}

QVariant MemoryCardModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_cards.size())
        return {};
    const MemoryCard &card = m_cards.at(index.row());
    switch (role) {
    case PairIdRole:
        return card.pairId;
    case FaceRole:
        return card.face == CardFace::Word ? QStringLiteral("word") : QStringLiteral("gloss");
    case TextRole:
        return card.text;
    case VisibilityRole:
        switch (card.visibility) {
        case CardVisibility::Up:
            return QStringLiteral("up");
        case CardVisibility::Cleared:
            return QStringLiteral("cleared");
        case CardVisibility::Down:
            return QStringLiteral("down");
        }
        break;
    default:
        break;
    }
    return {};
}

QHash<int, QByteArray> MemoryCardModel::roleNames() const
{
    return {
        {PairIdRole, "pairId"},
        {FaceRole, "face"},
        {TextRole, "text"},
        {VisibilityRole, "visibility"},
    };
}

void MemoryCardModel::replace(const QVector<MemoryCard> &cards)
{
    beginResetModel();
    m_cards = cards;
    endResetModel();
}

void MemoryCardModel::sync(const QVector<MemoryCard> &cards)
{
    if (cards.size() != m_cards.size()) {
        replace(cards);
        return;
    }
    m_cards = cards;
    if (m_cards.isEmpty())
        return;
    emit dataChanged(index(0, 0), index(m_cards.size() - 1, 0));
}

}

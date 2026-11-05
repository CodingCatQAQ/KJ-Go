#pragma once

#include "game/domain/memory_card.h"

#include <QAbstractListModel>
#include <QVector>

namespace game {

class MemoryCardModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles {
        PairIdRole = Qt::UserRole + 1,
        FaceRole,
        TextRole,
        VisibilityRole
    };

    explicit MemoryCardModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void replace(const QVector<MemoryCard> &cards);
    void sync(const QVector<MemoryCard> &cards);

private:
    QVector<MemoryCard> m_cards;
};

}

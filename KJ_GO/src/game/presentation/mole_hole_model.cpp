#include "game/presentation/mole_hole_model.h"

namespace game {

MoleHoleModel::MoleHoleModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_holes.resize(MoleField::kHoleCount);
}

int MoleHoleModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_holes.size();
}

QVariant MoleHoleModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_holes.size())
        return {};
    const Hole &hole = m_holes.at(index.row());
    switch (role) {
    case LabelRole:
        return hole.label;
    case UpRole:
        return hole.up;
    default:
        break;
    }
    return {};
}

QHash<int, QByteArray> MoleHoleModel::roleNames() const
{
    return {
        {LabelRole, "label"},
        {UpRole, "up"},
    };
}

void MoleHoleModel::sync(const MoleField &field)
{
    if (m_holes.size() != MoleField::kHoleCount) {
        beginResetModel();
        m_holes.resize(MoleField::kHoleCount);
        endResetModel();
    }
    for (int i = 0; i < MoleField::kHoleCount; ++i) {
        const bool up = field.occupied(i);
        m_holes[i].up = up;
        if (up) {
            const QString label = field.label(i);
            if (!label.isEmpty())
                m_holes[i].label = label;
        }
    }
    if (!m_holes.isEmpty())
        emit dataChanged(index(0, 0), index(m_holes.size() - 1, 0));
}

}

#pragma once

#include "game/domain/mole_field.h"

#include <QAbstractListModel>
#include <QVector>

namespace game {

class MoleHoleModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum Roles {
        LabelRole = Qt::UserRole + 1,
        UpRole
    };

    explicit MoleHoleModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void sync(const MoleField &field);

private:
    struct Hole {
        QString label;
        bool up = false;
    };

    QVector<Hole> m_holes;
};

}

#include "IVZonesModel.h"

IVZonesModel::IVZonesModel(QObject* parent)
    : QAbstractListModel(parent)
{}

IVSet* IVZonesModel::set() const
{
    return _set;
}

void IVZonesModel::setSet(IVSet* newSet)
{
    if (newSet == _set) {
        return;
    }

    if (_set) {
        disconnect(_set);
    }

    beginResetModel();
    _set = newSet;
    endResetModel();

    if (_set) {
        connect(_set, &IVSet::beginInsertZones, this, [this](int first, int last){
            beginInsertRows({}, first, last);
        });
        connect(_set, &IVSet::endInsertZones, this, [this](){
            endInsertRows();
        });

        connect(_set, &IVSet::beginRemoveZones, this, [this](int first, int last){
            beginRemoveRows({}, first, last);
        });
        connect(_set, &IVSet::endRemoveZones, this, [this](){
            endRemoveRows();
        });

        connect(_set, &IVSet::beginResetZones, this, [this](){
            beginResetModel();
        });
        connect(_set, &IVSet::endResetZones, this, [this](){
            endResetModel();
        });
    }

    emit setChanged();
}

QVariant IVZonesModel::data(const QModelIndex& index, int role) const
{
    if (!_set || !index.isValid() || index.row() >= rowCount()) {
        return {};
    }
    return QVariant::fromValue(_set->getZone(index.row()));
}

int IVZonesModel::rowCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent)
    return _set ? _set->zonesCount() : 0;
}

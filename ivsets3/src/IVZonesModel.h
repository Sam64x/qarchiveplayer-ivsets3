#pragma once

#include <QAbstractListModel>

#include "IVSet.h"

class IVZonesModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(IVSet* set READ set WRITE setSet NOTIFY setChanged)

public:
    explicit IVZonesModel(QObject *parent = nullptr);

    IVSet* set() const;
    void setSet(IVSet* newSet);

    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;

signals:
    void setChanged();

private:
    IVSet* _set {nullptr};
};

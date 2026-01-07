#ifndef TREEMODEL_H
#define TREEMODEL_H

#include <QtQml>
#include <QObject>
#include "treeitem.h"

class TreeModel : public QObject
{
    Q_OBJECT

public:
    Q_PROPERTY(QList<QObject*> tree READ treeAsQObjects NOTIFY treeChanged)
    Q_PROPERTY(int state READ state WRITE setState NOTIFY stateChanged)
    Q_INVOKABLE void search(QString searchText);

    explicit TreeModel(QObject *parent = nullptr);

public:
    void addChidItem(TreeItem* item);
    const QList<TreeItem*> &tree() const;
    const QList<QObject*> treeAsQObjects() const;
    const int &state() const;

signals:
    void treeChanged();
    void stateChanged();

public slots:
    void setState(int);
    void calcState();
    void calcVisible(){};
private:
    int m_state;
    QList<TreeItem*> m_tree;
};

#endif // TREEMODEL_H

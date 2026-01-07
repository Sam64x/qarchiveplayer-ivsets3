#ifndef TREEMODEL_H
#define TREEMODEL_H

#include <QtQml>
#include <QObject>
#include "treeitem.h"
#include "iv_stable.h"

class TreeModel : public QObject
{
    Q_OBJECT

public:
    Q_PROPERTY(QList<QObject*> tree READ treeAsQObjects NOTIFY treeChanged)
    Q_PROPERTY(int state READ state WRITE setState NOTIFY stateChanged)
    Q_PROPERTY(int visCount READ visCount NOTIFY visCountChanged)
    Q_INVOKABLE void search(QString searchText, bool byProp);
    Q_INVOKABLE void apply();

    explicit TreeModel(QObject *parent = nullptr);
    Q_INVOKABLE void init(QString type);
    Q_INVOKABLE void clear();

    Q_INVOKABLE int getCount();
    Q_INVOKABLE int getCheckedCount();
    Q_INVOKABLE TreeItem* get(int);

public:
    void addChildItem(TreeItem* item);
    void removeAt(int index);
    const QList<TreeItem*> &tree() const;
    const QList<QObject*> treeAsQObjects() const;
    const int &state() const;
    const int &visCount() const;

signals:
    void visCountChanged();
    void treeChanged();
    void stateChanged();
    void ready(bool include, QStringList events);

public slots:
    void setState(int);
    void calcState();
    void calcVisible(){};
    void getVisCount();

private:
    int m_state;
    int m_count;
    QList<TreeItem*> m_tree;
};

#endif // TREEMODEL_H

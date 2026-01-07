#ifndef SOURCETREE_H
#define SOURCETREE_H

#include <QtQml>
#include <QObject>
#include <QDebug>
#include <iv_threads.h>
#include "iv_threads_pool.h"
#include <iv_stable.h>
#include <QAbstractItemModel>

class SourceTree :   public QObject
{
    Q_OBJECT
    QString m_view;
    QList<SourceTree *> m_children;





public:
    explicit SourceTree(QObject *parent = nullptr);
    ~SourceTree();


    Q_PROPERTY(QList<QObject*> children READ childrenAsQObject NOTIFY childrenChanged)
    // общие свойства, такие как имя, тип, тип отображения, видимость в списке
    Q_PROPERTY(QString view READ view WRITE setView NOTIFY viewChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString type READ type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(QString view_type READ view_type WRITE setView_type NOTIFY view_typeChanged)
    Q_PROPERTY(bool opened READ opened WRITE setOpened NOTIFY openedChanged)
    Q_PROPERTY(bool visible READ visible WRITE setVisible NOTIFY visibleChanged)

    //специфические свойства, такие как id набора, id группы, локальный ли набор
    Q_PROPERTY(QString setId_ READ setId_ WRITE setSetId_ NOTIFY setId_Changed)
    Q_PROPERTY(QString groupId_ READ groupId_ WRITE setGroupId_ NOTIFY groupId_Changed)
    Q_PROPERTY(bool isLocal_ READ isLocal_ WRITE setIsLocal_ NOTIFY isLocal_Changed)

    Q_INVOKABLE void search(QString searchText);
    Q_INVOKABLE void search2(QString searchText);
    Q_INVOKABLE void search3(QString searchText);
    Q_INVOKABLE void setProp(const QString&, QVariant);
    Q_INVOKABLE QVariant getProp(const QString &);
    Q_INVOKABLE void init(const QString&);
    Q_INVOKABLE int getCount(QString = "", int = -1);
    Q_INVOKABLE int getCurrentCount();
    Q_INVOKABLE void addGroupFromQml(SourceTree* parent,QString name);
    Q_INVOKABLE SourceTree *get(QVariantList);
    Q_INVOKABLE void remove(QVariantList);
    Q_INVOKABLE void remove(int = -1);
    Q_INVOKABLE QVariantList getRows();

public:
    QQueue<SourceTree*> getAll(SourceTree* item);
    bool searchBrunch(SourceTree* item, QString searchText);
    void setRecProperty(SourceTree* item,QString propertyName, bool value);
    QString view();
    QList<SourceTree*> children();
    const QList<QObject*> childrenAsQObject() const;
    const bool hasChild() const;

    void addRec(QJsonArray array,SourceTree* item);
    SourceTree* findRec(SourceTree* item, QString name);
    QString _searchText;

    void setName(QString name);
    QString name();

    void setOpened(bool opened);
    bool opened();

    void setVisible(bool visible);
    bool visible();

    void setType(QString type);
    QString type();

    void setView_type(QString view_type);
    QString view_type();

    void setSetId_(QString setId);
    QString setId_();

    void setGroupId_(QString groupId);
    QString groupId_();

    void setIsLocal_(bool isLocal);
    bool isLocal_();

private:
    QString _name;
    QString _type;
    QString _view_type;
    QString _setId_;
    QString _groupId_;
    bool _visible;
    bool _opened;
    bool _isLocal_;

public slots:
    void setView(QString&);
    void addChildItem(SourceTree*);


signals:
    void childrenChanged();
    void viewChanged();
    void hasChildChanged();
    void nameChanged();
    void typeChanged();
    void view_typeChanged();
    void openedChanged();
    void visibleChanged();
    void setId_Changed();
    void groupId_Changed();
    void isLocal_Changed();




};

#endif // SOURCETREE_H

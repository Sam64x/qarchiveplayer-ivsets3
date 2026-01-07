#ifndef TREEITEM_H
#define TREEITEM_H

#include <QtQml>
#include <QObject>
#include <QDebug>
#include <iv_stable.h>

class TreeItem : public QObject
{
    Q_OBJECT

    bool m_vis;
    QString m_id;
    QString m_name;
    QString m_icon;
    bool m_isOpen;
    int m_state;
    QList<TreeItem *> m_childItems;

public:
    explicit TreeItem(QObject *parent = nullptr);
    ~TreeItem();

    Q_PROPERTY(bool visible READ visible WRITE setVisible NOTIFY visibleChanged)
    Q_PROPERTY(QString id READ id WRITE setId NOTIFY idChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString icon READ icon WRITE setIcon NOTIFY iconChanged)
    Q_PROPERTY(int state READ state WRITE setState NOTIFY stateChanged)
    Q_PROPERTY(bool hasChild READ hasChild NOTIFY hasChildChanged)
    Q_PROPERTY(bool isOpen READ isOpen WRITE setIsOpen NOTIFY isOpenChanged)
    Q_PROPERTY(QList<QObject*> childItems READ childItemsAsQObject NOTIFY childItemsChanged)

    Q_INVOKABLE void setProp(const QString &name, QVariant value) {
        setProperty(name.toStdString().c_str(), value);
    }
    Q_INVOKABLE QVariant getProp(const QString &name) {
        return property(name.toUtf8());
    }

public:
    const bool visible() const;
    const QString id() const;
    const QString name() const;
    const QString icon() const;
    QList<TreeItem*> childItems();
    const QList<QObject*> childItemsAsQObject() const;
    const int state() const;
    const bool isOpen() const;
    const bool hasChild() const;

public slots:
    void calcVisible();
    void calcState();
    void addChildItem(TreeItem *childItem);

    void setVisible(bool val);
    void setId(QString val);
    void setName(QString val);
    void setIcon(QString val);
    void setState(int val);
    void setIsOpen(bool val);

signals:
    void nameChanged();
    void stateChanged();
    void childItemsChanged();
    void isOpenChanged();
    void hasChildChanged();
    void iconChanged();
    void idChanged();
    void visibleChanged();
};

#endif // TREEITEM_H

#include "treeitem.h"

TreeItem::TreeItem(QObject *parent) : QObject(parent)
{
    m_name = "";
    m_icon = "";
    m_isOpen = false;
    m_state = 0;
    m_vis = true;
    m_childItems = QList<TreeItem*>();
    if (parent) {
        connect(this, SIGNAL(stateChanged()), parent, SLOT(calcState()));
        connect(this, SIGNAL(visibleChanged()), parent, SLOT(calcVisible()));
    }
}

const QString TreeItem::id() const {return m_id;}
const bool TreeItem::visible() const {return m_vis;}
const QString TreeItem::name() const {return m_name;}
const QString TreeItem::icon() const {return m_icon;}
const int TreeItem::state() const {return m_state;}
const bool TreeItem::isOpen() const {return m_isOpen;}
const bool TreeItem::hasChild() const {return !m_childItems.isEmpty();}
const QList<TreeItem*> TreeItem::childItems() const {return m_childItems;}

void TreeItem::addChildItem(TreeItem *childItem){
    m_childItems.append(childItem);
    emit childItemsChanged();
    if (m_childItems.count() == 1)
        emit hasChildChanged();
}

void TreeItem::setState(int val) {
    if (val != m_state) {
        m_state = val;
        for (auto i : m_childItems) i->setState(val);
        emit stateChanged();
    }
}
void TreeItem::setVisible(bool val) {
    if (val != m_vis) {
        m_vis = val;
        emit visibleChanged();
    }
}
void TreeItem::setId(QString val) {
    if (val != m_id) {
        m_id = val;
        emit idChanged();
    }
}
void TreeItem::setName(QString val) {
    if (val != m_name) {
        m_name = val;
        emit nameChanged();
    }
}
void TreeItem::setIcon(QString val) {
    if (val != m_icon) {
        m_icon = val;
        emit iconChanged();
    }
}
void TreeItem::setIsOpen(bool val){
    if(val != m_isOpen){
        m_isOpen = val;
        emit isOpenChanged();
    }
}

const QList<QObject *> TreeItem::childItemsAsQObject() const{
    QList<QObject *> res;
    res.reserve(m_childItems.count());
    for(auto i : m_childItems)
        res.append(i);
    return res;
}

void TreeItem::calcState()
{
    int stSum = 0;
    for (auto i : m_childItems) stSum += i->state();
    m_state = stSum > 0 ? (stSum < m_childItems.count()*2 ? 1 : 2) : 0;
    emit stateChanged();
}

void TreeItem::calcVisible()
{
    int visSum = 0;
    for (auto i : m_childItems) visSum += (i->visible() ? 1 : 0);
    m_vis = visSum > 0;
    emit visibleChanged();
}






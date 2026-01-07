#include "treeitem.h"

TreeItem::TreeItem(QObject *parent) : QObject(parent)
{
    St2_FUNCT_St2(100);
    m_name = "";
    m_icon = "";
    m_isOpen = false;
    m_state = 0;
    m_vis = true;
    m_childItems = QList<TreeItem*>();
    if (parent) {
        connect(this, SIGNAL(stateChanged()), parent, SLOT(calcState()));
        connect(this, SIGNAL(visibleChanged()), parent, SLOT(calcVisible()));
        if (parent->metaObject()->className() == "TreeModel") {
            connect(this, SIGNAL(childItemsChanged()), parent, SLOT(getVisCount()));
            connect(this, SIGNAL(childItemsChanged()), parent, SIGNAL(treeChanged()));
        }
        else {
            connect(this, SIGNAL(childItemsChanged()), parent, SIGNAL(childItemsChanged()));
        }
    }
}

TreeItem::~TreeItem()
{
    St2_FUNCT_St2(200);
    qDebug() << "~TreeItem" << this << getProp("name_");
    //for (auto i : m_childItems) delete i;
    m_childItems.clear();
    emit childItemsChanged();
}

const QString TreeItem::id() const {return m_id;}
const bool TreeItem::visible() const {return m_vis;}
const QString TreeItem::name() const {return m_name;}
const QString TreeItem::icon() const {return m_icon;}
const int TreeItem::state() const {return m_state;}
const bool TreeItem::isOpen() const {return m_isOpen;}
const bool TreeItem::hasChild() const {return !m_childItems.isEmpty();}
QList<TreeItem*> TreeItem::childItems() {return m_childItems;}

void TreeItem::addChildItem(TreeItem *childItem){
    St2_FUNCT_St2(300);
    m_childItems.append(childItem);
    emit childItemsChanged();
    if (m_childItems.count() == 1)
        emit hasChildChanged();
}

void TreeItem::setState(int val) {
    St2_FUNCT_St2(400);
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
    St2_FUNCT_St2(500);
    QList<QObject *> res;
    res.reserve(m_childItems.count());
    for(auto i : m_childItems)
        res.append(i);
    return res;
}

void TreeItem::calcState()
{
    St2_FUNCT_St2(600);
    int stSum = 0;
    for (auto i : m_childItems) stSum += i->state();
    m_state = stSum > 0 ? (stSum < m_childItems.count()*2 ? 1 : 2) : 0;
    emit stateChanged();
}

void TreeItem::calcVisible()
{
    St2_FUNCT_St2(700);
    int visSum = 0;
    for (auto i : m_childItems) visSum += (i->visible() ? 1 : 0);
    m_vis = visSum > 0;
    emit visibleChanged();
}






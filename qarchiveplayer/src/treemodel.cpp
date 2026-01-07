#include "treemodel.h"

void TreeModel::search(QString searchText)
{
    QQueue<TreeItem*> q;
    for (auto i : m_tree){
        q.push_back(i);
    }
    while (!q.isEmpty()) {
        TreeItem* item = q.last();
        q.pop_back();
        for (auto i : item->childItems()) q.push_back(i);

        if (item->id().length() > 0) {
            bool findName = item->name().contains(searchText, Qt::CaseInsensitive);
            bool findId = item->id().contains(searchText, Qt::CaseInsensitive);
            item->setVisible(findName || findId);
        }
    }
}

TreeModel::TreeModel(QObject *parent) : QObject(parent), m_tree(QList<TreeItem*>())
{
    // Открываем json
    QJsonArray mainArr;
    {
        QDir dir;
        if (!dir.exists("qtplugins")) dir.cdUp();
        dir.cd("qtplugins");
        dir.cd("iv");
        dir.cd("events");
        dir.cd("events");
        QString filepath = dir.absolutePath() + QDir::separator() + "eventTypes.json";
        QFile file(filepath);
        file.open(QFile::ReadOnly);
        QJsonDocument res = QJsonDocument::fromJson(file.readAll());
        mainArr = res.array();
        file.close();
    }
    // и парсим его
    for (auto i : mainArr)
    {
        QJsonObject categoryObject = i.toObject();
        TreeItem* categoryItem = new TreeItem(this);
        categoryItem->setName(categoryObject.value("name").toString());
        addChidItem(categoryItem);

        QJsonArray groupsArr = categoryObject.value("groups").toArray();
        for (auto j : groupsArr)
        {
            QJsonObject groupObject = j.toObject();

            TreeItem* groupItem = new TreeItem(categoryItem);
            groupItem->setName(groupObject.value("name").toString());
            groupItem->setIcon(groupObject.value("icon").toString());

            categoryItem->addChildItem(groupItem);

            QJsonArray eventsArr = groupObject.value("events").toArray();
            for (auto k : eventsArr)
            {
                QJsonObject eventObject = k.toObject();

                TreeItem* eventItem = new TreeItem(groupItem);
                eventItem->setName(eventObject.value("name").toString());
                eventItem->setId(eventObject.value("id").toString());

                groupItem->addChildItem(eventItem);
            }
        }
    }
    m_state = 0;
}

void TreeModel::addChidItem(TreeItem *item)
{
    m_tree.append(item);
    emit treeChanged();
}
const QList<TreeItem *> &TreeModel::tree() const {return m_tree;}
const int &TreeModel::state() const {return m_state;}
void TreeModel::setState(int val)
{
    if (val != m_state) {
        m_state = val;
        for (auto i : m_tree) i->setState(val);
        emit stateChanged();
    }
}
void TreeModel::calcState()
{
    int stSum = 0;
    for (auto i : m_tree) stSum += i->state();
    m_state = stSum > 0 ? (stSum < m_tree.count()*2 ? 1 : 2) : 0;
    emit stateChanged();
}
const QList<QObject *> TreeModel::treeAsQObjects() const{
    QList<QObject *> res;
    res.reserve(m_tree.count());
    for (auto i : m_tree) res.append(i);
    return res;
}

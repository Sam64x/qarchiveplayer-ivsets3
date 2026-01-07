#include "treemodel.h"

void TreeModel::search(QString searchText, bool byProp = false)
{
    St2_FUNCT_St2(100);
    QQueue<TreeItem*> q;
    for (auto i : m_tree){
        q.push_back(i);
    }
    while (!q.isEmpty()) {
        TreeItem* item = q.last();
        q.pop_back();
        for (auto i : item->childItems()) q.push_back(i);

        if (byProp) {
            bool findRes = false;
            for (auto d : item->dynamicPropertyNames())
            {
                QString val = item->property(d).toString();
                if (val.contains(searchText, Qt::CaseInsensitive)) {
                    findRes = true;
                    break;
                }
            }
            item->setVisible(findRes);
        }
        else {
            if (item->id().length() > 0) {
                bool findName = item->name().contains(searchText, Qt::CaseInsensitive);
                bool findId = item->id().contains(searchText, Qt::CaseInsensitive);
                item->setVisible(findName || findId);
            }
        }
    }
}

void TreeModel::apply()
{
    St2_FUNCT_St2(200);
    QStringList onEv, offEv;

    QQueue<TreeItem*> q;
    for (auto i : m_tree) q.push_back(i);
    while (!q.isEmpty())
    {
        TreeItem* item = q.last();
        q.pop_back();
        for (auto i : item->childItems()) q.push_back(i);

        if (item->id().length() > 0) {
            if (item->state() > 0) onEv.push_back(item->id());
            else offEv.push_back(item->id());
        }
    }
    if (onEv.count() <= offEv.count())
        emit ready(true, onEv);
    else
        emit ready(false, offEv);
}

void TreeModel::init(QString type)
{
    St2_FUNCT_St2(300);
    if (type == "sources") {
        QDir newSetsDir;
        if (!newSetsDir.exists("databases")) newSetsDir.cdUp();
        newSetsDir.cd("databases");
        newSetsDir.cd("new_sets");

        QDir camsDir(newSetsDir.absolutePath());
        camsDir.cd("cameras");

        QDir setsDir(newSetsDir.absolutePath());
        setsDir.cd("local_sets");

        QDir remSetsDir(newSetsDir.absolutePath());
        remSetsDir.cd("remote_sets");

        QFile file(QString(camsDir.absolutePath() + QDir::separator() + "cameras"));
        file.open(QFile::ReadOnly);
        //qDebug()<< "Open file:"<< file.fileName();
        QJsonArray camsArr = QJsonDocument::fromJson(file.readAll()).array();
        file.close();

        file.setFileName(QString(setsDir.absolutePath() + QDir::separator() + "local_sets"));
        file.open(QFile::ReadOnly);
        //qDebug()<< "Open file:"<< file.fileName();
        QJsonArray setsArr = QJsonDocument::fromJson(file.readAll()).array();
        file.close();

        file.setFileName(QString(remSetsDir.absolutePath() + QDir::separator() + "remote_sets"));
        file.open(QFile::ReadOnly);
        //qDebug()<< "Open file:"<< file.fileName();
        QJsonArray remSetsArr = QJsonDocument::fromJson(file.readAll()).array();
        file.close();


        TreeItem* setsGroup = new TreeItem(this);
        setsGroup->setProperty("name_", "Наборы");
        setsGroup->setProperty("type", "sets");
        for (auto i : setsArr)
        {
            TreeItem* item = new TreeItem(setsGroup);
            QJsonObject obj = i.toObject();
            item->setProperty("name_", obj.value("setName").toString());
            item->setProperty("type", "set");
            item->setProperty("isLocal", true);
            QString cams;
            QJsonArray zones = obj.value("zones").toArray();
            QString zonesStr(QJsonDocument(zones).toJson(QJsonDocument::Compact));
            for (auto i : zones) {
                QJsonArray arr = i.toObject().value("key2").toObject().value("value").toArray();
                cams.append(arr[0].toString());
                QString viewerPath = i.toObject().value("qml_path").toString();
            }
            item->setProperty("cams", cams);
            item->setProperty("zones", zonesStr);
            setsGroup->addChildItem(item);
        }
        for (auto i : remSetsArr)
        {
            TreeItem* item = new TreeItem(setsGroup);
            QJsonObject obj = i.toObject();
            item->setProperty("name_", obj.value("setName").toString());
            item->setProperty("type", "set");
            item->setProperty("isLocal", false);
            QString cams;
            QJsonArray zones = obj.value("zones").toArray();
            QString zonesStr(QJsonDocument(zones).toJson(QJsonDocument::Compact));
            for (auto i : zones) {
                QJsonArray arr = i.toObject().value("key2").toObject().value("value").toArray();
                cams.append(arr[0].toString());
                QString viewerPath = i.toObject().value("qml_path").toString();
            }
            item->setProperty("cams", cams);
            item->setProperty("zones", zonesStr);
            setsGroup->addChildItem(item);
        }
        TreeItem* camsGroup = new TreeItem(this);
        camsGroup->setProperty("name_", "Камеры");
        camsGroup->setProperty("type", "cameras");
        for (auto i : camsArr)
        {
            TreeItem* item = new TreeItem(camsGroup);
            QJsonObject obj = i.toObject();
            item->setProperty("name_", obj.value("key2").toString());
            item->setProperty("server", obj.value("key1").toString());
            item->setProperty("type", "camera");
            camsGroup->addChildItem(item);
        }
        qDebug() <<"devices.init sets count:" << setsGroup->childItems().count()
                << "cams count:" << camsGroup->childItems().count();

        addChildItem(setsGroup);
        addChildItem(camsGroup);
    }
    else {
        QJsonArray mainArr;
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
        for (auto i : mainArr)
        {
            QJsonObject categoryObject = i.toObject();
            TreeItem* categoryItem = new TreeItem(this);
            categoryItem->setName(categoryObject.value("name").toString());
            addChildItem(categoryItem);

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
    }
}

int TreeModel::getCheckedCount()
{
    St2_FUNCT_St2(400);
    int count = 0;
    QQueue<TreeItem*> q;
    for (auto i : m_tree) q.push_back(i);
    while (!q.isEmpty())
    {
        TreeItem* item = q.last();
        q.pop_back();
        if (!item->hasChild()){
            if (item->state() > 0) count++;
        }
        else {
            for (auto i : item->childItems()) {
                q.push_back(i);
            }
        }
    }
    return count;
}

TreeItem* TreeModel::get(int ind = -1) {
    St2_FUNCT_St2(500);
    QList<TreeItem*> devicesList;
    TreeItem* item = nullptr;
    if (ind < 0) return item;
    int count = 0;
    QQueue<TreeItem*> q;
    for (auto i : m_tree) q.push_back(i);
    while (!q.isEmpty())
    {
        item = q.last();
        q.pop_back();
        if (!item->hasChild()) {
            devicesList.append(item);
        }
        else {
            for (auto i : item->childItems()) {
                q.push_back(i);
            }
        }
    }
    if (ind < devicesList.count()){
        item = devicesList[ind];
    }
    return item;
}

void TreeModel::removeAt(int index)
{
    St2_FUNCT_St2(600);
    TreeItem* removeItem = get(index);
    delete removeItem;
    emit treeChanged();
}

int TreeModel::getCount()
{
    St2_FUNCT_St2(700);
    int count = 0;
    QQueue<TreeItem*> q;
    for (auto i : m_tree) q.push_back(i);
    while (!q.isEmpty())
    {
        TreeItem* item = q.last();
        q.pop_back();
        if (!item->hasChild()) count++;
        else {
            for (auto i : item->childItems()) {
                q.push_back(i);
            }
        }
    }
    return count;
}

void TreeModel::getVisCount()
{
    St2_FUNCT_St2(800);
    int count = 0;
    QQueue<TreeItem*> q;
    for (auto i : m_tree) q.push_back(i);
    while (!q.isEmpty())
    {
        TreeItem* item = q.last();
        q.pop_back();
        if (!item->hasChild()) {
            if (item->visible()) count++;
        }
        else {
            for (auto i : item->childItems()) {
                q.push_back(i);
            }
        }
    }
    if (count != m_count){
        m_count = count;
        emit visCountChanged();
    }
}

void TreeModel::clear()
{
    St2_FUNCT_St2(900);
    qDebug() << "Clear treeModel";
    for (int i = 0; i < m_tree.count(); i++)
    {
        for (int j = 0; j < m_tree[i]->childItems().count(); j++)
        {
            qDebug() << "m_tree[i]->childItems().count()" << m_tree[i]->childItems().count();
            delete m_tree[i]->childItems().at(j);
        }
        m_tree[i]->childItems().clear();
    }
    m_tree.clear();
    emit treeChanged();
}

TreeModel::TreeModel(QObject *parent) : QObject(parent), m_tree(QList<TreeItem*>())
{
    St2_FUNCT_St2(1000);
    m_state = 0;
    connect(this, SIGNAL(treeChanged()), this, SLOT(getVisCount()));
}
void TreeModel::addChildItem(TreeItem *item)
{
    St2_FUNCT_St2(1100);
    m_tree.append(item);
    emit treeChanged();
}

const QList<TreeItem *> &TreeModel::tree() const {return m_tree;}
const int &TreeModel::state() const {return m_state;}
const int &TreeModel::visCount() const {return m_count;}
void TreeModel::setState(int val)
{
    St2_FUNCT_St2(1200);
    if (val != m_state) {
        m_state = val;
        for (auto i : m_tree) i->setState(val);
        emit stateChanged();
    }
}
void TreeModel::calcState()
{
    St2_FUNCT_St2(1300);
    int stSum = 0;
    for (auto i : m_tree) stSum += i->state();
    m_state = stSum > 0 ? (stSum < m_tree.count()*2 ? 1 : 2) : 0;
    apply();
    emit stateChanged();
}

const QList<QObject *> TreeModel::treeAsQObjects() const{
    St2_FUNCT_St2(1400);
    QList<QObject *> res;
    res.reserve(m_tree.count());
    for (auto i : m_tree) res.append(i);
    return res;
}

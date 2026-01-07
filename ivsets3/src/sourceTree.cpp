#include "sourceTree.h"

SourceTree::SourceTree(QObject *parent) : QObject(parent)
{
    St2_FUNCT_St2(100);
    //qDebug()<< "SourceTree::SourceTree(" << this->parent() << ")" << "=" << this;
    setProp("checkState", 0);
    setProp("visible", true);
    setProp("opened", false);
    _opened = false;
    if (this->parent() != nullptr) {
        connect(this, SIGNAL(childrenChanged()), parent, SIGNAL(childrenChanged()));
        //qDebug()<< "SourceTree signals connected to parent";
    }
}

SourceTree::~SourceTree()
{
    St2_FUNCT_St2(200);
    //qDebug() << "Destructor of" << this << getProp("name_");
    for (auto i : m_children) delete i;
    m_children.clear();
}

void SourceTree::setName(QString name)
{
    if(_name != name)
    {
        _name = name;
        emit nameChanged();
    }

}
QString SourceTree::name()
{
    return _name;
}

void SourceTree::setOpened(bool opened)
{
   // qDebug()<< "setOpened = "<< _opened << opened;
    if(_opened != opened)
    {
        _opened = opened;
        emit openedChanged();
    }

}
bool SourceTree::opened()
{
    return _opened;
}

void SourceTree::setVisible(bool visible)
{
    if(_visible != visible)
    {
        _visible = visible;
        emit visibleChanged();
    }
}
bool SourceTree::visible()
{
    return _visible;
}

void SourceTree::setType(QString type)
{
    if(_type != type)
    {
        _type = type;
        emit typeChanged();
    }
}
QString SourceTree::type()
{
    return _type;
}

void SourceTree::setView_type(QString view_type)
{
    if(_view_type != view_type)
    {
        _view_type = view_type;
        emit view_typeChanged();
    }
}
QString SourceTree::view_type()
{
    return _view_type;
}

void SourceTree::setSetId_(QString setId)
{
    if(_setId_ != setId)
    {
        _setId_ = setId;
        emit setId_Changed();
    }
}
QString SourceTree::setId_()
{
    return _setId_;
}

void SourceTree::setGroupId_(QString groupId)
{
    if(_groupId_ != groupId)
    {
        _groupId_ = groupId;
        emit groupId_Changed();
    }
}
QString SourceTree::groupId_()
{
    return _groupId_;
}

void SourceTree::setIsLocal_(bool isLocal)
{
    if(_isLocal_ != isLocal)
    {
        _isLocal_ = isLocal;
        emit isLocal_Changed();
    }
}
bool SourceTree::isLocal_()
{
    return _isLocal_;
}


void SourceTree::search(QString searchText)
{
    St2_FUNCT_St2(300);
    QQueue<SourceTree*> q;
    for (auto i : m_children)
    {
        q.push_back(i);
    }
    while (!q.isEmpty())
    {
        SourceTree* item = q.last();
        q.pop_back();
        for (auto i : item->children()) q.push_back(i);
        bool findRes = false;
//        for (auto d : item->dynamicPropertyNames())
//        {
            QString val = item->getProp("name_").toString();
            if (val.contains(searchText, Qt::CaseInsensitive)) {
                findRes = true;
                qDebug()<< "FOUNDED NAME = " << val;
               // break;
            }
       // }
        QString _name = item->getProp("type").toString();
        if(_name != "maps" && _name != "cameras" && _name != "sets")
        {
            item->setProp("visible", findRes);
        }
    }
    emit childrenChanged();
}
QQueue<SourceTree*> SourceTree::getAll(SourceTree* item)
{
    QQueue<SourceTree*> q;
    for (auto i : item->m_children)
    {
       // QString _name = i->getProp("type").toString();
        //if(_name != "maps" && _name != "cameras" && _name != "sets")
        //{
            q.push_back(i);
        //}
        if(i->hasChild())
        {
            QQueue<SourceTree*> q2 = getAll(i);
            q.append(q2);
        }


    }
    return q;
}

void SourceTree::search2(QString searchText)
{
    St2_FUNCT_St2(300);
    QQueue<SourceTree*> q;
    q = getAll(this);
    qDebug()<< "COUNT OF ALL = " << q.size();
    while (!q.isEmpty())
    {
        SourceTree* item = q.last();
        q.pop_back();
        QString val = item->getProp("name_").toString();
        qDebug()<< "NAME = " << val << q.size();
        if (val.contains(searchText, Qt::CaseInsensitive))
        {
            QString _type = item->getProp("type").toString();
            if(_type != "maps" && _type != "cameras" && _type != "sets" && _type != "cluster" && _type != "repeater" && _type != "server" && _type != "custom")
            {
                item->setProp("visible", true);
            }
        }
        else
        {
            QString _name = item->getProp("type").toString();
            if(_name != "maps" && _name != "cameras" && _name != "sets" && _name != "cluster" && _name != "repeater" && _name != "server" && _name != "custom")
            {
                item->setProp("visible", false);
            }
        }
    }
    emit childrenChanged();
}


void SourceTree::setRecProperty(SourceTree* item,QString propertyName, bool value)
{
    St2_FUNCT_St2(23456)
    if(item)
    {
        item->setVisible(true);
        QString _type_ = item->getProp("type").toString();
        if(_type_ != "set")
        {
            item->setOpened(value);
            for (auto i : item->m_children)
            {
                QString _name = i->getProp("name_").toString();
                QString _type = i->getProp("type").toString();
                //qDebug()<< "setRecProperty" << _name << _type << propertyName << value;
                bool hasChild = i->hasChild();
                if(hasChild )
                {
                    setRecProperty(i,propertyName,value);
                }
            }
        }
        else
        {
            item->setOpened(false);
        }
    }
}

bool SourceTree::searchBrunch(SourceTree* item, QString searchText)
{
     St2_FUNCT_St2(541);
    QQueue<SourceTree*> q;
    bool isCompareFound = false;
    for (auto i : item->m_children)
    {
        if(i)
        {
            QString _name = i->getProp("name_").toString();
            QString _type = i->getProp("type").toString();
            bool hasChild = i->hasChild();
            //qDebug()<< "NAME COMPARE " << _name << searchText << _type;
            if (_name.contains(searchText, Qt::CaseInsensitive))
            {
                //qDebug()<< "NAME COMPARE FOUND =" << _name << searchText << _type;
                i->setVisible(true);
                isCompareFound = true;
                if(hasChild)
                {
                    setRecProperty(i,"opened",true);
                }
                //continue;
            }
            else
            {
               // qDebug()<< "NAME COMPARE NOT FOUND" << _name << searchText << _type;
                bool currentFound = false;
                if(hasChild)
                {
                   // qDebug()<< "NAME COMPARE NOT FOUND HAS CHILD" << _name << searchText << _type;
                    currentFound = searchBrunch(i,searchText);
                    if(currentFound)
                    {
                        isCompareFound = true;
                        i->setOpened(true);
                    }
                }
                i->setVisible(currentFound);
            }
        }
    }
    return isCompareFound;
}
void search_updater(void *thread, void *udata)
{
    St2_FUNCT_St2(556);
//    QString cmd__ = "{\"cmd\":\"camera:list\",\"params\":{\"info\": true,\"profiles\": true,\"positions\":false,\"page\":1,\"page_size\":4000}}";
//    QString cmd2__ = "{\"cmd\":\"cams_read\",\"value\":true}}";
//    int timeout = 10;
//    int is_local = 0;
//    QByteArray b = cmd__.toUtf8();
//    char* _cmd = b.data();
//    QByteArray b2 = cmd2__.toUtf8();
//    char* _cmd2 = b.data();
//    //qDebug()<<"camera cmd = "<< _cmd;
//    param_t p2[] =
//    {
//        {PARAM_PCHAR, "cmd", _cmd},
//        {PARAM_PINT32,"timeout", &timeout},
//        {PARAM_PVOID, "owner", myOwner},
//        {PARAM_PVOID, "owner_data", "customset_cams"},
//        {PARAM_PINT32,"is_local",&is_local},
//        {0, 0, 0}
//    };
//    iv::core::profile_data(_onDataPr,p2);
    SourceTree* _this = (SourceTree*)udata;
    if(!_this)
    {
        qDebug()<<"SEARCH ERROR!!!!!!!!!!!!!!";
        return;
    }
    if(_this->_searchText.isEmpty())
    {
        QQueue<SourceTree*> q;
        q = _this->getAll(_this);
        while (!q.isEmpty())
        {
            SourceTree* item = q.last();
            q.pop_back();
            item->setVisible(true);//setProp("visible",true);
        }
    }
    else
    {
        bool isFound = _this->searchBrunch(_this,_this->_searchText);
    }
    //emit _this->childrenChanged();
}
void SourceTree::search3(QString searchText)
{
    St2_FUNCT_St2(540);
    _searchText = searchText;
    iv::threads::pool::execute("custom_cams",search_updater,this);


}

void SourceTree::remove(QVariantList path)
{
    St2_FUNCT_St2(400);
    if (path.length() > 0) {
        //qDebug() << "SourceTree::remove by path" << path;
        get(path.mid(0, path.size() - 1))->remove(path.last().toInt());
    }
    else qDebug() << "SourceTree::remove by path error - path is empty";
}
void SourceTree::remove(int index)
{
    St2_FUNCT_St2(500);
    //qDebug() << "SourceTree::remove item";
    if (index < 0) {
        for (auto i : m_children) delete i;
        m_children.clear();
    }
    else {
        delete m_children.at(index);
        m_children.removeAt(index);
    }
    emit childrenChanged();
}

void SourceTree::setProp(const QString &name, QVariant value) {
    St2_FUNCT_St2(600);
    setProperty(name.toStdString().c_str(), value);
    if (name == "checkState")
    {
        if (value.toInt() == 2 || value.toInt() == 0)
        {
            for (auto i : m_children)
            {
                if (i->getProp("visible").toBool()) {
                    i->setProp("checkState", value);
                }
            }
        }
    }
    //qDebug()<< getProp("name_").toString() << "prop:" << name << "=" << getProp(name);
    emit childrenChanged();
}

QVariant SourceTree::getProp(const QString &name) {
    return property(name.toUtf8());
}

void SourceTree::init(const QString &type)
{
    St2_FUNCT_St2(700);
    setProp("name_", "Root object");
    if(type == "cameras")
    {
        QDir newSetsDir;
        if (!newSetsDir.exists("databases")) newSetsDir.cdUp();
        newSetsDir.cd("databases");
        newSetsDir.cd("new_sets");



        QDir camsDir(newSetsDir.absolutePath());
        camsDir.cd("cameras");

        QFile file(QString(camsDir.absolutePath() + QDir::separator() + "cameras"));
        file.open(QFile::ReadOnly);
       // qDebug()<< "Open file:"<< file.fileName();
        QJsonArray camsArr = QJsonDocument::fromJson(file.readAll()).array();
        file.close();

        QDir mapsDir(newSetsDir.absolutePath());
        mapsDir.cd("maps");

        file.setFileName(QString(mapsDir.absolutePath() + QDir::separator() + "maps"));
        file.open(QFile::ReadOnly);
       // qDebug()<< "Open file:"<< file.fileName();
        QJsonArray mapsArray = QJsonDocument::fromJson(file.readAll()).array();
        file.close();



        SourceTree* camsGroup = new SourceTree(this);
        camsGroup->setProp("name_", "Камеры");
        camsGroup->setProp("type", "cameras");
        camsGroup->setProp("view_type", "group");
        camsGroup->setProp("visible", true);

        SourceTree* mapsGroup = new SourceTree(this);
        mapsGroup->setProp("name_", "Карты");
        mapsGroup->setProp("type", "maps");
        mapsGroup->setProp("view_type", "group");
        mapsGroup->setProp("visible", true);

         int isNotAval = 0;
        for (auto i : camsArr)
        {
            SourceTree* item = new SourceTree(camsGroup);
            QJsonObject obj = i.toObject();
            bool isAval =obj.value("is_available").toBool();
            item->setProp("name_", obj.value("key2").toString());
            item->setProp("server", obj.value("key1").toString());
            item->setProp("is_ptz", obj.value("is_ptz").toBool());
            item->setProp("is_available", isAval);
            item->setProp("type", "camera");
            item->setProp("view_type", "item");
            item->setProp("visible", true);
            if(!isAval)
            {
                isNotAval++;
            }
            camsGroup->addChildItem(item);

        }
        if(mapsArray.size()>0) // дописать код для разных ответов ws тттттттттттттттттттттттттттттттттттттттттттттттттттттттттт
        {
            qDebug()<< "MAPS ARRAY 0 SIZE = ";

            auto t = mapsArray[0].toArray();
            if(t.size()>0)
            {
              //  qDebug()<< "MAPS ARRAY 0 SIZE = " << t.size();
                for (auto i : t)
                {
                    SourceTree* item = new SourceTree(mapsGroup);
                    QString __key2 = i.toString();
                   // qDebug()<<__key2;
                    QStringList files = __key2.split( "/" );
                    QString neededWord = files.value( files.length()-1 );
                    if(neededWord.contains(".json"))
                    {
                        item->setProp("name_",neededWord);
                        item->setProp("type", "map");
                        item->setProp("view_type", "item");
                        item->setProp("visible", true);
                        mapsGroup->addChildItem(item);
                    }
                }
            }
            else
            {
                for (auto i : mapsArray)
                {
                    SourceTree* item = new SourceTree(mapsGroup);
                    QString __key2 = i.toString();
                   // qDebug()<<__key2;
                    QStringList files = __key2.split( "/" );
                    QString neededWord = files.value( files.length()-1 );
                    if(neededWord.contains(".json"))
                    {
                        item->setProp("name_",neededWord);
                        item->setProp("type", "map");
                        item->setProp("view_type", "item");
                        item->setProp("visible", true);
                        mapsGroup->addChildItem(item);
                    }
                }
            }
        }
        camsGroup->setProp("isNotAval",5);

        addChildItem(camsGroup);
        addChildItem(mapsGroup);
    }
    if (type == "sources")
    {
        QDir newSetsDir;
        if (!newSetsDir.exists("databases")) newSetsDir.cdUp();
        newSetsDir.cd("databases");
        newSetsDir.cd("new_sets");

        QDir camsDir(newSetsDir.absolutePath());
        camsDir.cd("cameras");

        QDir setsDir(newSetsDir.absolutePath());
        setsDir.cd("sets");

//        QDir remSetsDir(newSetsDir.absolutePath());
//        remSetsDir.cd("remote_sets");

        QDir mapsDir(newSetsDir.absolutePath());
        mapsDir.cd("maps");



        //file:///C:/Users/INTEGRA/OneDrive/Desktop/ffmpeg_test/2024_03_23-win-x64/2024_03_23/databases/mapData

        QFile file(QString(camsDir.absolutePath() + QDir::separator() + "cameras"));
        file.open(QFile::ReadOnly);
       // qDebug()<< "Open file:"<< file.fileName();
        QJsonArray camsArr = QJsonDocument::fromJson(file.readAll()).array();
        file.close();

        file.setFileName(QString(setsDir.absolutePath() + QDir::separator() + "sets"));
        file.open(QFile::ReadOnly);
        //qDebug()<< "Open file:"<< file.fileName();
        QJsonArray setsArr = QJsonDocument::fromJson(file.readAll()).array();
        file.close();

//        file.setFileName(QString(remSetsDir.absolutePath() + QDir::separator() + "remote_sets"));
//        file.open(QFile::ReadOnly);
//        //qDebug()<< "Open file:"<< file.fileName();
//        QJsonArray remSetsArr = QJsonDocument::fromJson(file.readAll()).array();
//        file.close();

        file.setFileName(QString(mapsDir.absolutePath() + QDir::separator() + "maps"));
        file.open(QFile::ReadOnly);
       // qDebug()<< "Open file:"<< file.fileName();
        QJsonArray mapsArray = QJsonDocument::fromJson(file.readAll()).array();
        file.close();

       // qDebug()<< "MAPS ARRAY ========" << mapsArray.size();



        SourceTree* setsGroup = new SourceTree(this);
        setsGroup->setProp("name_", "Наборы");
        setsGroup->setProp("type", "sets");
        setsGroup->setProp("view_type", "group");
        setsGroup->setProp("visible", true);




        SourceTree* camsGroup = new SourceTree(this);
        camsGroup->setProp("name_", "Камеры");
        camsGroup->setProp("type", "cameras");
        camsGroup->setProp("view_type", "group");
        camsGroup->setProp("visible", true);

        SourceTree* mapsGroup = new SourceTree(this);
        mapsGroup->setProp("name_", "Карты");
        mapsGroup->setProp("type", "maps");
        mapsGroup->setProp("view_type", "group");
        mapsGroup->setProp("visible", true);

        int isNotAval = 0;
        for (auto i : setsArr)
        {
            SourceTree* item = new SourceTree(setsGroup);
            QJsonObject obj = i.toObject();
            int isUser =  obj.value("isuser").toInt(-1);
            item->setProp("name_", obj.value("setName").toString());
            item->setProp("id_", obj.value("setId").toString());
            item->setProp("type", "set");
            item->setProp("view_type", "group");
            item->setProp("isLocal",isUser==0?false:true);
            item->setProp("visible", true);
            QString cams;
            QJsonArray zones = obj.value("zones").toArray();
            QString zonesStr(QJsonDocument(zones).toJson(QJsonDocument::Compact));
            for (auto i : zones)
            {
                QJsonArray arr = i.toObject().value("params").toObject().value("key2").toObject().value("value").toArray();
                if(arr.size()==0)
                {
                    continue;
                }
                QString __key2 = arr[0].toString();
                if(__key2 != "null")
                {
                    SourceTree* item2 = new SourceTree(item);
                   // qDebug()<< "KEY 2 in set = " <<  __key2;
                    item2->setProp("name_",__key2);
                    item2->setProp("is_ptz", false);
                    item2->setProp("is_available",true);
                    item2->setProp("type", "camera");
                    item2->setProp("view_type", "item");
                    item2->setProp("visible", true);
                    item->addChildItem(item2);
                }

            }
            setsGroup->addChildItem(item);
        }

        for (auto i : camsArr)
        {
            SourceTree* item = new SourceTree(camsGroup);
            QJsonObject obj = i.toObject();
            bool isAval =obj.value("is_available").toBool();
            item->setProp("name_", obj.value("key2").toString());
            item->setProp("server", obj.value("key1").toString());
            item->setProp("is_ptz", obj.value("is_ptz").toBool());
            item->setProp("is_available", isAval);
            item->setProp("type", "camera");
            item->setProp("view_type", "item");
            item->setProp("visible", true);
            if(!isAval)
            {
                isNotAval++;
            }
            camsGroup->addChildItem(item);
        }
        if(mapsArray.size()>0) // дописать код для разных ответов ws тттттттттттттттттттттттттттттттттттттттттттттттттттттттттт
        {
            qDebug()<< "MAPS ARRAY 0 SIZE = ";

            auto t = mapsArray[0].toArray();
            if(t.size()>0)
            {
              //  qDebug()<< "MAPS ARRAY 0 SIZE = " << t.size();
                for (auto i : t)
                {
                    SourceTree* item = new SourceTree(mapsGroup);
                    QString __key2 = i.toString();
                   // qDebug()<<__key2;
                    QStringList files = __key2.split( "/" );
                    QString neededWord = files.value( files.length()-1 );
                    if(neededWord.contains(".json"))
                    {
                        item->setProp("name_",neededWord);
                        item->setProp("type", "map");
                        item->setProp("view_type", "item");
                        item->setProp("visible", true);
                        mapsGroup->addChildItem(item);
                    }
                }
            }
            else
            {
                for (auto i : mapsArray)
                {
                    SourceTree* item = new SourceTree(mapsGroup);
                    QString __key2 = i.toString();
                   // qDebug()<<__key2;
                    QStringList files = __key2.split( "/" );
                    QString neededWord = files.value( files.length()-1 );
                    if(neededWord.contains(".json"))
                    {
                        item->setProp("name_",neededWord);
                        item->setProp("type", "map");
                        item->setProp("view_type", "item");
                        item->setProp("visible", true);
                        mapsGroup->addChildItem(item);
                    }
                }
            }
        }
        addChildItem(setsGroup);
        addChildItem(camsGroup);
        addChildItem(mapsGroup);
    }
    else if(type == "fact")
    {
        QDir newSetsDir;
        if (!newSetsDir.exists("databases")) newSetsDir.cdUp();
        newSetsDir.cd("databases");
        newSetsDir.cd("new_sets");

        QDir camsDir(newSetsDir.absolutePath());
        camsDir.cd("other");
        QFile file(QString(camsDir.absolutePath() + QDir::separator() + "fact_list"));
        file.open(QFile::ReadOnly);
       // qDebug()<< "Open file:"<< file.fileName();
        QJsonArray factArray = QJsonDocument::fromJson(file.readAll()).array();
        file.close();
        int isNotAvalGlob = 0;
        for (auto i : factArray)
        {
            QJsonObject obj1 = i.toObject().value("data").toObject().value("string").toObject();
            SourceTree* item = new SourceTree(this);
           // qDebug()<<"comm server name = " <<  obj1.value("server_name").toString();
            item->setProp("name_", obj1.value("server_name").toString());
            item->setProp("direct_access", obj1.value("direct_access").toInt());
            item->setProp("visible", true);
            QJsonArray arrayDown = obj1.value("down_servers").toArray();
            addRec(arrayDown,item);
            QJsonArray arrayCams = obj1.value("cams").toArray();
            for(auto cam : arrayCams)
            {
                SourceTree* itemCam = new SourceTree(item);
                QJsonObject objCam = cam.toObject();
                bool islocAval = objCam.value("Status").toBool();
                itemCam->setProp("name_", objCam.value("key2").toString());
                itemCam->setProp("server", obj1.value("server_name").toString());
                itemCam->setProp("is_ptz", objCam.value("ptzStat").toBool());
                itemCam->setProp("is_available", islocAval);
                itemCam->setProp("type", "camera");
                itemCam->setProp("view_type", "item");
                itemCam->setProp("visible", true);
                item->addChildItem(itemCam);
                if(!islocAval)
                {
                    isNotAvalGlob++;
                }
            }
            if(arrayDown.size() >0 && arrayCams.size()>0)
            {
                item->setProp("type", "cluster");
            }
            else if(arrayDown.size() ==0&& arrayCams.size()>=0 )
            {
                item->setProp("type", "server");
            }
            else if(arrayDown.size() >0 && arrayCams.size()==0)
            {
                item->setProp("type", "repeater");
                qDebug()<< "REPEATER FOUND";
            }
            item->setProp("visible", true);
            item->setProp("view_type", "group");
            QVariant tSize = item->getProp("isNotAval");
            item->setProp("isNotAval",5);
            addChildItem(item);
        }
    }
    else if(type == "custom")
    {
        //return;
        QDir newSetsDir;
        if (!newSetsDir.exists("databases")) newSetsDir.cdUp();
        newSetsDir.cd("databases");
        newSetsDir.cd("new_sets");

        QDir camsDir(newSetsDir.absolutePath());
        camsDir.cd("other");
        QDir remSetsDir(newSetsDir.absolutePath());
        remSetsDir.cd("sets");



        QFile file(QString(camsDir.absolutePath() + QDir::separator() + "groups_list"));
        file.open(QFile::ReadOnly);
       // qDebug()<< "Open file:"<< file.fileName();
        QJsonArray groupsArr = QJsonDocument::fromJson(file.readAll()).array();
        file.close();

        file.setFileName(QString(camsDir.absolutePath() + QDir::separator() + "groups_list_sets"));
        file.open(QFile::ReadOnly);
       // qDebug()<< "Open file:"<< file.fileName();
        QJsonArray groupsSetsArr = QJsonDocument::fromJson(file.readAll()).array();
        file.close();

        file.setFileName(QString(remSetsDir.absolutePath() + QDir::separator() + "sets"));
        file.open(QFile::ReadOnly);
      //  qDebug()<< "Open file:"<< file.fileName();
        QJsonArray remSetsArr = QJsonDocument::fromJson(file.readAll()).array();
        file.close();
         qDebug()<< "remSetsArr.size()"<< remSetsArr.size();

       QQueue<QJsonObject> _notFoundList;
        for (auto i : groupsArr)
        {
            QJsonObject obj = i.toObject();
            QString _pId = obj.value("groupParentId").toString();
            QString _grname =obj.value("groupName").toString();
            QString _gId =obj.value("groupId").toString();
            if(_pId == "null")
            {
                qDebug()<< "_grname = " << _grname << " _pId = " << _pId;
                SourceTree* item = new SourceTree(this);
                item->setProp("name_", obj.value("groupName").toString());
                item->setProp("groupId", obj.value("groupId").toString());
                item->setProp("type", "custom");
                item->setProp("view_type", "group");
                item->setProp("visible", true);
                for (auto i1 : groupsSetsArr)
                {
                    QJsonObject obj2 = i1.toObject();
                    QString _sId = obj2.value("sgssetid").toString();
                    QString _gId2 =obj2.value("groupId").toString();
                    if(_gId2 == _gId)
                    {
                        for (auto i2 : remSetsArr)
                        {
                            QJsonObject obj3 = i2.toObject();
                            QString _sId2 = obj3.value("setId").toString();
                            if(_sId2 ==_sId)
                            {
                                SourceTree* item2 = new SourceTree(item);
                                item2->setProp("name_", obj3.value("setName").toString());
                                item2->setProp("id_", obj3.value("setId").toString());
                                item2->setProp("type", "set");
                                item2->setProp("view_type", "group");
                                item2->setProp("isLocal", false);
                                item2->setProp("visible", true);
                                QJsonArray zones = obj3.value("zones").toArray();
                                QString zonesStr(QJsonDocument(zones).toJson(QJsonDocument::Compact));
                                for (auto ir : zones)
                                {
                                    QJsonArray arr = ir.toObject().value("params").toObject().value("key2").toObject().value("value").toArray();
                                    if(arr.size()==0)
                                    {
                                        continue;
                                    }
                                    QString __key2 = arr[0].toString();
                                    if(__key2 != "null")
                                    {
                                        //qDebug()<< "KEY2 = " << __key2;
                                        SourceTree* itemr = new SourceTree(item2);
                                        itemr->setProp("name_",__key2);
                                        itemr->setProp("is_ptz", false);
                                        itemr->setProp("is_available",true);
                                        itemr->setProp("type", "camera");
                                        itemr->setProp("view_type", "item");
                                        itemr->setProp("visible", true);
                                        item2->addChildItem(itemr);
                                    }
                                }
                                item->addChildItem(item2);
                            }
                        }
                    }
                }
                addChildItem(item);
            }
            else
            {
                qDebug()<< "else _grname = " << _grname << " _pId = " << _pId;
                SourceTree* _f = findRec(this,_pId);
                if(_f)
                {
                    qDebug()<< "GR FOUND _grname = " << _grname << " _pId = " << _pId;
                    SourceTree* item = new SourceTree(_f);
                    item->setProp("name_", obj.value("groupName").toString());
                    item->setProp("groupId", obj.value("groupId").toString());
                    item->setProp("type", "custom");
                    item->setProp("view_type", "group");
                    item->setProp("visible", true);
                    for (auto i1 : groupsSetsArr)
                    {
                        QJsonObject obj2 = i1.toObject();
                        QString _sId = obj2.value("sgssetid").toString();
                        QString _gId2 =obj2.value("groupId").toString();
                        if(_gId2 == _gId)
                        {
                            for (auto i2 : remSetsArr)
                            {
                                QJsonObject obj3 = i2.toObject();
                                QString _sId2 = obj3.value("setId").toString();
                                if(_sId2 ==_sId)
                                {
                                    SourceTree* item2 = new SourceTree(item);
                                    item2->setProp("name_", obj3.value("setName").toString());
                                    item2->setProp("id_", obj3.value("setId").toString());
                                    item2->setProp("type", "set");
                                    item2->setProp("view_type", "group");
                                    item2->setProp("isLocal", false);
                                    item2->setProp("visible", true);
                                    QJsonArray zones = obj3.value("zones").toArray();
                                    QString zonesStr(QJsonDocument(zones).toJson(QJsonDocument::Compact));
                                    for (auto ir : zones)
                                    {
                                        QJsonArray arr = ir.toObject().value("params").toObject().value("key2").toObject().value("value").toArray();
                                        if(arr.size()==0)
                                        {
                                            continue;
                                        }
                                        QString __key2 = arr[0].toString();
                                        if(__key2 != "null")
                                        {
                                            //qDebug()<< "KEY2 = " << __key2;
                                            SourceTree* itemr = new SourceTree(item2);
                                            itemr->setProp("name_",__key2);
                                            itemr->setProp("is_ptz", false);
                                            itemr->setProp("is_available",true);
                                            itemr->setProp("type", "camera");
                                            itemr->setProp("view_type", "item");
                                            itemr->setProp("visible", true);
                                            item2->addChildItem(itemr);
                                        }
                                    }
                                    item->addChildItem(item2);
                                }
                            }
                        }
                    }
                    _f->addChildItem(item);
                }
                else
                {
                    _notFoundList.append(obj);
                }
            }
        }
        if(_notFoundList.size()>0)
        {

            while(!_notFoundList.empty())
            {
                QJsonObject obj = _notFoundList.last();
                _notFoundList.pop_back();
                QString _pId = obj.value("groupParentId").toString();
                QString _gId = obj.value("groupId").toString();
                SourceTree* _f = findRec(this,_pId);
                if(_f)
                {
                    //qDebug()<< "GR FOUND _grname = " << _grname << " _pId = " << _pId;
                    SourceTree* item = new SourceTree(_f);
                    item->setProp("name_", obj.value("groupName").toString());
                    item->setProp("groupId", obj.value("groupId").toString());
                    item->setProp("type", "custom");
                    item->setProp("view_type", "group");
                    item->setProp("visible", true);
                    for (auto i1 : groupsSetsArr)
                    {
                        QJsonObject obj2 = i1.toObject();
                        QString _sId = obj2.value("sgssetid").toString();
                        QString _gId2 =obj2.value("groupId").toString();
                        if(_gId2 == _gId)
                        {
                            for (auto i2 : remSetsArr)
                            {
                                QJsonObject obj3 = i2.toObject();
                                QString _sId2 = obj3.value("setId").toString();
                                if(_sId2 ==_sId)
                                {
                                    SourceTree* item2 = new SourceTree(item);
                                    item2->setProp("name_", obj3.value("setName").toString());
                                    item2->setProp("id_", obj3.value("setId").toString());
                                    item2->setProp("type", "set");
                                    item2->setProp("view_type", "group");
                                    item2->setProp("isLocal", false);
                                    item2->setProp("visible", true);
                                    QJsonArray zones = obj3.value("zones").toArray();
                                    QString zonesStr(QJsonDocument(zones).toJson(QJsonDocument::Compact));
                                    for (auto ir : zones)
                                    {
                                        QJsonArray arr = ir.toObject().value("params").toObject().value("key2").toObject().value("value").toArray();
                                        if(arr.size()==0)
                                        {
                                            continue;
                                        }
                                        QString __key2 = arr[0].toString();
                                        if(__key2 != "null")
                                        {
                                            SourceTree* itemr = new SourceTree(item2);
                                            itemr->setProp("name_",__key2);
                                            itemr->setProp("is_ptz", false);
                                            itemr->setProp("is_available",true);
                                            itemr->setProp("type", "camera");
                                            itemr->setProp("view_type", "item");
                                            itemr->setProp("visible", true);
                                            item2->addChildItem(itemr);
                                        }
                                    }
                                    item->addChildItem(item2);
                                }
                            }
                        }
                    }
                    _f->addChildItem(item);
                }
                else
                {
                    _notFoundList.insert(0,obj);
                }
            }
        }
    }
    else
    {
        //empty
    }
}
void SourceTree::addRec(QJsonArray array,SourceTree* item)
{
    St2_FUNCT_St2(820);
    for (auto i : array)
    {
        QJsonObject obj1 = i.toObject();

        for(auto obj:obj1)
        {
            qDebug()<< obj.isObject() << obj.isArray();
            if(obj.isObject())
            {
                SourceTree* item2 = new SourceTree(item);
                QJsonObject obj2 = obj.toObject();
                int isNotAval = 0;
                item2->setProp("name_", obj2.value("server_name").toString());
                //item2->setProp("type", "group");
                item2->setProp("isLocal", false);
                item2->setProp("direct_access", obj2.value("direct_access").toInt());
                QJsonArray arrayDown = obj2.value("down_servers").toArray();
                addRec(arrayDown,item2);
                QJsonArray arrayCams = obj2.value("cams").toArray();
                //qDebug()<< "SERVER NAME ======= " << obj2.value("server_name").toString();
                for(auto cam : arrayCams)
                {
                    SourceTree* itemCam = new SourceTree(item2);
                    QJsonObject objCam = cam.toObject();
                    bool isAval = objCam.value("Status").toBool();
                    itemCam->setProp("name_", objCam.value("key2").toString());
                    // qDebug()<< "CAM NAME ======= " << objCam.value("key2").toString();
                    itemCam->setProp("server", obj1.value("server_name").toString());
                    itemCam->setProp("is_ptz", objCam.value("ptzStat").toBool());
                    itemCam->setProp("is_available",isAval );
                    itemCam->setProp("type", "camera");
                    itemCam->setProp("view_type", "item");
                    if(!isAval)
                    {
                        isNotAval++;
                    }
                    item2->addChildItem(itemCam);
                }
                if(arrayDown.size() >1 && arrayCams.size()>0)
                {
                    item2->setProp("type", "cluster");
                }
                else if(arrayDown.size() ==0 )
                {
                    item2->setProp("type", "server");
                }
                else if(arrayDown.size() >1 && arrayCams.size()==0)
                {
                    item2->setProp("type", "repeater");
                }
                item2->setProp("view_type", "group");
                QVariant tSize = item2->getProp("isNotAval");
                item->setProp("isNotAval",5);
                item->addChildItem(item2);
            }
        }
    }
}

SourceTree *SourceTree::findRec(SourceTree *item, QString name)
{
    St2_FUNCT_St2(991);
    SourceTree* el = item;
    SourceTree* res = 0;
    if(el)
    {
        QString id_ = el->getProp("groupId").toString();
        QString name_ = el->getProp("name_").toString();
        //qDebug()<< "findRec el = " << name_ << id_;
        if(id_==name)
        {
            res = el;
            return res;
        }
    }
    for (auto i : el->children())
    {
        QString id_ = i->getProp("groupId").toString();
        QString name_ = i->getProp("name_").toString();
       // qDebug()<< "findRec el children = " << name_ << id_ << name;
        if(id_==name)
        {
            res = i;
            break;
        }
        if(i->children().size()>0)
        {
            res = findRec(i,name);
            if(res)
                break;
        }
        else
        {
            if(id_==name)
            {
                res = i;
                break;
            }
        }
    }
    return res;

}
int SourceTree::getCount(QString viewStr, int checkState)
{
    St2_FUNCT_St2(800);
    int count = 0;
    QQueue<SourceTree*> q;
    for (auto i : children()) q.push_back(i);
    while (!q.isEmpty())
    {
        SourceTree* item = q.last();
        q.pop_back();
        if (item->hasChild()) {
            for (auto i : item->children()) q.push_back(i);
            continue;
        }
//        bool itemInView = true;
//        if (viewStr.length() > 0) {
//            itemInView = (item->getProp("type").toString()+"s") == view() || viewStr == "all";
//        }
//        if (itemInView) {
            if (checkState > -1) {
                if (item->getProp("checkState").toInt() == checkState) {
                    count++;
                    continue;
                }
            }
            else count++;
        //}
    }
    return count;
}

int SourceTree::getCurrentCount()
{
    St2_FUNCT_St2(321);
    SourceTree* el = this;
    int count = 0;
    if(el)
    {
        count = el->children().size();
    }
    return count;
}

void SourceTree::addGroupFromQml(SourceTree *parent2, QString name)
{
    St2_FUNCT_St2(1900);
    if(!parent2)
    {
        SourceTree* elem = new SourceTree(this);
        elem->setProp("name_", name);
        elem->setProp("type", "custom");
        elem->setProp("view_type", "group");
        addChildItem(elem);
    }
    else
    {
        SourceTree* elem = new SourceTree(parent2);
        elem->setProp("name_", name);
        elem->setProp("type", "custom");
        elem->setProp("view_type", "group");
        parent2->addChildItem(elem);
    }
}

SourceTree *SourceTree::get(QVariantList rows = {})
{
    St2_FUNCT_St2(900);
    SourceTree* el = this;
    for (auto i : rows)
    {
        el = el->children().at(i.toInt());
    }
    //qDebug() << "SourceTree::get" << el << "name:" << el->getProp("name_");
    return el;
}

QVariantList SourceTree::getRows()
{
    St2_FUNCT_St2(1000);
    QVariantList res;
    //qDebug() << "SourceTree::getRows to" << getProp("name_").toString();
    SourceTree* el = this;
    SourceTree* p = (SourceTree*)el->parent();
    const char* myClassName = SourceTree::metaObject()->className();
    while (p && p->metaObject()->className() == myClassName)
    {
        int index = p->children().indexOf(el);
        if (index < 0) {
            qDebug() << "SourceTree::getRows" << el->getProp("name_").toString()
                     << "not founded in" << p->getProp("name_").toString();
            return {};
        }
        res.append(index);
        el = (SourceTree*)el->parent();
        p = (SourceTree*)el->parent();
    }
    std::reverse(res.begin(), res.end());
    //qDebug() << "SourceTree::getRows result:" << res;
    return res;
}

QString SourceTree::view()
{
    St2_FUNCT_St2(1100);
    return m_view;
}

QList<SourceTree *> SourceTree::children()
{
    St2_FUNCT_St2(1200);
    return m_children;
}

const QList<QObject*> SourceTree::childrenAsQObject() const
{
    St2_FUNCT_St2(1300);
    QList<QObject*> res;
    res.reserve(m_children.count());
    for (auto i : m_children) res.append(i);
    return res;
}

const bool SourceTree::hasChild() const
{
    St2_FUNCT_St2(1400);
    return m_children.count() > 0;
}

void SourceTree::setView(QString &view)
{
    St2_FUNCT_St2(1500);
    if (m_view != view){
        m_view = view;
        emit viewChanged();
    }
}

void SourceTree::addChildItem(SourceTree *item)
{
    St2_FUNCT_St2(1600);
    m_children.append(item);
    emit childrenChanged();
}

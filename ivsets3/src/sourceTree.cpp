#include "sourceTree.h"

#include <QDebug>
#include <QStack>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QFile>
#include <QDir>

#include <iv_stable.h>

SourceTree::SourceTree(QObject *parent) : QObject(parent)
{}

QString SourceTree::name() const
{
    return _name;
}
void SourceTree::setName(const QString& name)
{
    if (_name != name) {
        _name = name;
        emit nameChanged();
    }
}

QString SourceTree::type() const
{
    return _type;
}
void SourceTree::setType(const QString& type)
{
    if (_type != type) {
        _type = type;
        emit typeChanged();
    }
}

QString SourceTree::viewType() const
{
    return _viewType;
}
void SourceTree::setViewType(const QString& value)
{
    if (_viewType != value) {
        _viewType = value;
        emit viewTypeChanged();
    }
}

bool SourceTree::visible() const
{
    return _visible;
}
void SourceTree::setVisible(bool visible)
{
    if (_visible != visible) {
        _visible = visible;
        emit visibleChanged();
    }
}

QList<QObject*> SourceTree::childrenAsQObject() const
{
    St2_FUNCT_St2(1300);
    QList<QObject*> result;
    result.reserve(_children.size());
    for (SourceTree* child : _children) {
        result.push_back(child);
    }
    return result;
}

bool SourceTree::opened() const
{
    return _opened;
}
void SourceTree::setOpened(bool opened)
{
    if (_opened != opened) {
        _opened = opened;
        emit openedChanged();
    }
}

int SourceTree::count() const
{
    return _count;
}
void SourceTree::setCount(int value)
{
    if (_count != value) {
        _count = value;
        emit countChanged();
    }
}

int SourceTree::unavailableCount() const
{
    return _unavailableCount;
}
void SourceTree::setUnavailableCount(int value)
{
    if (_unavailableCount != value) {
        _unavailableCount = value;
        emit unavailableCountChanged();
    }
}

QString SourceTree::groupColor() const
{
    return _groupColor;
}
void SourceTree::setGroupColor(const QString& value)
{
    if (_groupColor != value) {
        _groupColor = value;
        emit groupColorChanged();
    }
}

bool SourceTree::selected() const
{
    return _selected;
}
void SourceTree::setSelected(bool value)
{
    if (_selected != value) {
        _selected = value;
        emit selectedChanged();
    }
}

bool SourceTree::available() const
{
    return _available;
}
void SourceTree::setAvailable(bool value)
{
    if (_available != value) {
        _available = value;
        emit availableChanged();
    }
}

QString SourceTree::setId() const
{
    return _setId;
}
void SourceTree::setSetId(const QString& value)
{
    if (_setId != value) {
        _setId = value;
        emit setIdChanged();
    }
}

bool SourceTree::isLocal() const
{
    return _isLocal;
}
void SourceTree::setIsLocal(bool isLocal)
{
    if (_isLocal != isLocal) {
        _isLocal = isLocal;
        emit isLocalChanged();
    }
}

int SourceTree::sourcesCount() const
{
    return _camerasSources.count() + _mapsSources.count();
}

int SourceTree::calculateSelectedCamerasCount() const
{
    return std::count_if(_camerasSources.cbegin(), _camerasSources.cend(), [](ItemConfig itemConfig){
        return itemConfig.selected;
    });
}

int SourceTree::calculateSelectedMapsCount() const
{
    return std::count_if(_mapsSources.cbegin(), _mapsSources.cend(), [](ItemConfig itemConfig){
        return itemConfig.selected;
    });
}

void SourceTree::updateSelectedCameras(const QString& name, bool value)
{
    if (_viewType == "item") {
        if (_type == "camera" && _name == name) {
            setSelected(value);
        }
        return;
    }
    for (auto& item: _children) {
        item->updateSelectedCameras(name, value);
    }
}

void SourceTree::updateSelectedMaps(const QString& name, bool value)
{
    if (_viewType == "item") {
        if (_type == "map" && _name == name) {
            setSelected(value);
        }
        return;
    }
    for (auto& item: _children) {
        item->updateSelectedMaps(name, value);
    }
}

void SourceTree::clearSelection()
{
    if (_viewType == "item") {
        setSelected(false);
        return;
    }
    for (auto& item: _children) {
        item->clearSelection();
    }
}

void SourceTree::changeCameraSelected(const QString& name, bool value)
{
    if (_camerasSources.constFind(name) != _camerasSources.constEnd()) {
        _camerasSources[name].selected = value;
        emit selectedCamerasCountChanged();
    }
}

void SourceTree::changeMapSelected(const QString& name, bool value)
{
    if (_mapsSources.constFind(name) != _mapsSources.constEnd()) {
        _mapsSources[name].selected = value;
        emit selectedMapsCountChanged();
    }
}

void SourceTree::clearSourcesSelection()
{
    for (auto& item: _camerasSources) {
        item.selected = false;
    }
    emit selectedCamerasCountChanged();
    for (auto& item: _mapsSources) {
        item.selected = false;
    }
    emit selectedMapsCountChanged();
}

QStringList SourceTree::getSelectedCameras() const
{
    QStringList selectedCameras;
    for (auto it = _camerasSources.constBegin(); it != _camerasSources.constEnd(); ++it) {
        if (it->selected) {
            selectedCameras.append(it.key());
        }
    }
    return selectedCameras;
}

void SourceTree::switchExpandAll(bool value)
{
    setOpened(value);

    for (auto& item: _children) {
        if (item->viewType() == "item" || value && (item->type() == "set" || item->type() == "server")) {
            continue;
        }
        item->switchExpandAll(value);
    }
}

void SourceTree::addChildItem(SourceTree *item)
{
    St2_FUNCT_St2(1600);
    _children.append(item);
    emit childrenChanged();
}

void SourceTree::clearChildren()
{
    St2_FUNCT_St2(500);
    for (auto& child : _children) {
        child->deleteLater();
    }
    _children.clear();
    emit childrenChanged();
}

void SourceTree::search(QString searchText)
{
    St2_FUNCT_St2(540);
    if (searchText.isEmpty()) {
        showAll(this);
    }
    else {
        for (auto child: std::as_const(_children)) {
            filterNodeRecursively(child, searchText);
        }
    }
}

void SourceTree::showAll(SourceTree* root, bool openGroups)
{
    QStack<SourceTree*> stack;
    stack.push(root);
    while (!stack.isEmpty()) {
        SourceTree* item = stack.pop();

        item->setVisible(true);
        if (openGroups && item->viewType() == "group" && item->type() != "set") {
            item->setOpened(true);
        }

        for (auto child: std::as_const(item->_children)) {
            stack.push(child);
        }
    }
}

void SourceTree::filterNodeRecursively(SourceTree* item, QString searchText)
{
    if (item->name().contains(searchText, Qt::CaseInsensitive)) {
        showAll(item, true);
        return;
    }
    for (auto child: std::as_const(item->_children)) {
        filterNodeRecursively(child, searchText);
    }
    const auto childHasMatch = std::any_of(item->_children.cbegin(), item->_children.cend(), [](SourceTree* item){
        return item->visible();
    });

    item->setVisible(childHasMatch);
    if (item->viewType() == "group" && item->type() != "set") {
        item->setOpened(childHasMatch);
    }
}

static QJsonArray readJsonArrayFromFile(const QString &filePath) {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Cannot open JSON file:" << filePath;
        return QJsonArray();
    }
    return QJsonDocument::fromJson(file.readAll()).array();
}

void SourceTree::initSources()
{
    _camerasSources.clear();
    _mapsSources.clear();

    QDir baseDir;
    if (!baseDir.exists("databases")) {
        baseDir.cdUp();
    }
    baseDir.cd("databases/new_sets");

    const auto camsArr = readJsonArrayFromFile(baseDir.absoluteFilePath("cameras/cameras"));
    const auto mapsArray = readJsonArrayFromFile(baseDir.absoluteFilePath("maps/maps"));

    for (const auto& i : camsArr) {
        QJsonObject obj = i.toObject();
        const auto name = obj.value("key2").toString();
        const auto available = obj.value("is_available").toBool();

        _camerasSources.insert(name, { false, available});
    }

    for (const auto& i : mapsArray) {
        const auto mapFileName = i.toString().split( "/" ).last();
        if (mapFileName.contains(".json")) {
            _mapsSources.insert(mapFileName, { false, true});
        }
    }

    emit sourcesCountChanged();
}

void SourceTree::initFlat()
{
    clearChildren();

    QDir baseDir;
    if (!baseDir.exists("databases")) {
        baseDir.cdUp();
    }
    baseDir.cd("databases/new_sets");

    const auto setsArr = readJsonArrayFromFile(baseDir.absoluteFilePath("sets/sets"));
    const auto camsArr = readJsonArrayFromFile(baseDir.absoluteFilePath("cameras/cameras"));
    const auto mapsArray = readJsonArrayFromFile(baseDir.absoluteFilePath("maps/maps"));

    SourceTree* setsGroup = new SourceTree(this);
    setsGroup->setName("Наборы");
    setsGroup->setType("sets");
    setsGroup->setViewType("group");

    SourceTree* camsGroup = new SourceTree(this);
    camsGroup->setName("Камеры");
    camsGroup->setType("cameras");
    camsGroup->setViewType("group");

    SourceTree* mapsGroup = new SourceTree(this);
    mapsGroup->setName("Карты");
    mapsGroup->setType("maps");
    mapsGroup->setViewType("group");

    for (const auto& setValue : setsArr) {
        createSetItem(setsGroup, setValue.toObject());
    }
    setsGroup->setCount(setsGroup->_children.size());

    int unavailableCount_ = 0;
    for (const auto& i : camsArr) {
        QJsonObject obj = i.toObject();
        SourceTree* item = createCameraItem(camsGroup, obj.value("key2").toString());
        if (item && !item->available()) {
            unavailableCount_++;
        }
    }
    camsGroup->setCount(camsGroup->_children.size());
    camsGroup->setUnavailableCount(unavailableCount_);

    for (const auto& i : mapsArray) {
        const auto mapFileName = i.toString().split( "/" ).last();
        createMapItem(mapsGroup, mapFileName);
    }
    mapsGroup->setCount(mapsGroup->_children.size());

    addChildItem(setsGroup);
    addChildItem(camsGroup);
    addChildItem(mapsGroup);
}

void SourceTree::initFact()
{
    clearChildren();

    QDir baseDir;
    if (!baseDir.exists("databases")) {
        baseDir.cdUp();
    }
    baseDir.cd("databases/new_sets");

    const auto factArray = readJsonArrayFromFile(baseDir.absoluteFilePath("other/fact_list"));

    for (const auto& i : factArray) {
        QJsonObject obj1 = i.toObject().value("data").toObject().value("string").toObject();
        createServerObject(obj1, this);
    }
}

SourceTree* SourceTree::createServerObject(QJsonObject serverObject, SourceTree* parent)
{
    St2_FUNCT_St2(820);
    SourceTree* server = new SourceTree(parent);

    server->setName(serverObject.value("server_name").toString());
    server->setViewType("group");

    const auto downServers = serverObject.value("down_servers").toArray();
    const auto cams = serverObject.value("cams").toArray();
    const auto downServersExist = !downServers.isEmpty();
    const auto camsExist = !cams.isEmpty();

    if (downServersExist && camsExist) {
        server->setType("cluster");
    }
    else if (downServersExist && !camsExist) {
        server->setType("repeater");
    }
    else if (!downServersExist) {
        server->setType("server");
    }

    auto count = 0;
    auto unavailableCount = 0;

    for (const auto& downServer : downServers) {
        const auto serverObject = downServer.toObject();
        for (const auto& serverObjectValue : serverObject) {
            if (serverObjectValue.isObject()) {
                const auto createdDownServer = createServerObject(serverObjectValue.toObject(), server);
                count += createdDownServer->count();
                unavailableCount += createdDownServer->unavailableCount();
            }
        }
    }

    for (const auto& cam : cams) {
        QJsonObject cameraObject = cam.toObject();
        SourceTree* item = createCameraItem(server, cameraObject.value("key2").toString());
        if (item) {
            if (!item->available()) {
                unavailableCount++;
            }
            count++;
        }
    }

    server->setCount(count);
    server->setUnavailableCount(unavailableCount);

    parent->addChildItem(server);
    return server;
}

void SourceTree::initCustom()
{
    clearChildren();

    QDir baseDir;
    if (!baseDir.exists("databases")) {
        baseDir.cdUp();
    }
    baseDir.cd("databases/new_sets");

    const auto setsArray = readJsonArrayFromFile(baseDir.absoluteFilePath("sets/sets"));
    const auto customGroupsArray = readJsonArrayFromFile(baseDir.absoluteFilePath("other/groups_list"));
    const auto groupsSetsArray = readJsonArrayFromFile(baseDir.absoluteFilePath("other/groups_list_sets"));

    QList<CustomGroupConfig> rootGroupsHash;
    QList<CustomGroupConfig> itemGroupsHash;
    for (const auto& customGroup: customGroupsArray) {
        const auto customGroupObject = customGroup.toObject();
        const auto groupId = customGroupObject.value("groupId").toString();
        const auto groupName = customGroupObject.value("groupName").toString();
        const auto groupParentId = customGroupObject.value("groupParentId").toString();
        const auto groupColor = customGroupObject.value("groupColor").toString();
        const CustomGroupConfig config = { groupId, groupName, groupParentId, groupColor };
        if (groupParentId == "null") {
            rootGroupsHash << config;
        }
        else {
            itemGroupsHash << config;
        }
    }

    QHash<QString, QList<QString>> groupsSetsHash;
    for (const auto& item: groupsSetsArray) {
        const auto customGroupObject = item.toObject();
        const auto groupId = customGroupObject.value("groupId").toString();
        const auto setId = customGroupObject.value("sgssetid").toString();
        groupsSetsHash[groupId] << setId;
    }

    QHash<QString, QJsonObject> setsHash;
    for (const auto& set: setsArray) {
        const auto setObject = set.toObject();
        const auto setId = setObject.value("setId").toString();
        setsHash.insert(setId, setObject);
    }

    for (const auto& rootGroupConfig: std::as_const(rootGroupsHash)) {
        const auto rootGroup = new SourceTree(this);
        rootGroup->setName(rootGroupConfig.name);
        rootGroup->setViewType("group");
        rootGroup->setType("custom");
        rootGroup->setGroupColor(rootGroupConfig.color == "null" ? "" : rootGroupConfig.color);

        createCustomGroupRecursed(rootGroup, rootGroupConfig.id, itemGroupsHash, groupsSetsHash, setsHash);

        addChildItem(rootGroup);
    }
}

void SourceTree::createCustomGroupRecursed(SourceTree* parent,
                                           const QString& parentId,
                                           QList<CustomGroupConfig>& itemGroupsHash,
                                           QHash<QString, QList<QString>>& groupsSetsHash,
                                           QHash<QString, QJsonObject>& setsHash)
{

    QList<CustomGroupConfig> childs;

    for (auto it = itemGroupsHash.begin(); it != itemGroupsHash.end(); ) {
        const auto itemConfig = *it;
        if (itemConfig.parentId == parentId) {
            childs.append(std::move(itemConfig));
            it = itemGroupsHash.erase(it);
        } else {
            ++it;
        }
    }

    for (const auto& child: childs) {
        const auto group = new SourceTree(parent);
        group->setName(child.name);
        group->setViewType("group");
        group->setType("custom");
        group->setGroupColor(child.color == "null" ? parent->groupColor() : child.color);

        createCustomGroupRecursed(group, child.id, itemGroupsHash, groupsSetsHash, setsHash);

        parent->addChildItem(group);
    }

    const auto groupSetsIt = groupsSetsHash.constFind(parentId);
    if (groupSetsIt == groupsSetsHash.cend()) {
        return;
    }

    for (const auto& setId: *groupSetsIt) {
        const auto setObjectIt = setsHash.constFind(setId);
        if (setObjectIt == setsHash.cend()) {
            continue;
        }
        auto setItem = createSetItem(parent, *setObjectIt);
        setItem->setGroupColor(parent->groupColor());
    }

    parent->setCount(parent->_children.size());
}

SourceTree* SourceTree::createCameraItem(SourceTree* group, const QString& name) const
{
    const auto source = _camerasSources.find(name);
    if (source == _camerasSources.cend()) {
        return nullptr;
    }

    SourceTree* item = new SourceTree(group);
    item->setName(name);
    item->setType("camera");
    item->setViewType("item");
    item->setAvailable(source->available);
    item->setSelected(source->selected);
    group->addChildItem(item);
    return item;
}

SourceTree* SourceTree::createMapItem(SourceTree* group, const QString& name) const
{
    const auto source = _mapsSources.find(name);
    if (source == _mapsSources.cend()) {
        return nullptr;
    }

    SourceTree* item = new SourceTree(group);
    item->setName(name);
    item->setType("map");
    item->setViewType("item");
    item->setAvailable(true);
    item->setSelected(source->selected);
    group->addChildItem(item);
    return item;
}

SourceTree* SourceTree::createSetItem(SourceTree* parent, const QJsonObject& setObject) const
{
    int isUser = setObject.value("isuser").toInt(-1);

    SourceTree* setGroup = new SourceTree(parent);
    setGroup->setName(setObject.value("setName").toString());
    setGroup->setSetId(setObject.value("setId").toString());
    setGroup->setType("set");
    setGroup->setViewType("group");
    setGroup->setIsLocal(isUser != 0);

    int unavailableCount_ = 0;
    const auto zones = setObject.value("zones").toArray();
    for (const auto& i : zones) {
        const auto zoneObject = i.toObject();
        const auto zoneType = zoneObject.value("type").toString();

        if (zoneType == "camera") {
            QJsonArray arr = i.toObject().value("params").toObject()
            .value("key2").toObject().value("value").toArray();
            if (arr.isEmpty()) {
                continue;
            }
            const auto key2 = arr.first().toString();
            auto item = createCameraItem(setGroup, key2);
            if (item && !item->available()) {
                unavailableCount_++;
            }
        }
        else if (zoneType == "map") {
            QJsonArray arr = i.toObject().value("params").toObject()
            .value("jsonDataFileName").toObject().value("value").toArray();
            if (arr.isEmpty()) {
                continue;
            }
            QString mapFileName = arr.first().toString();
            createMapItem(setGroup, mapFileName);
        }
    }
    setGroup->setCount(setGroup->_children.size());
    setGroup->setUnavailableCount(unavailableCount_);
    parent->addChildItem(setGroup);
    return setGroup;
}

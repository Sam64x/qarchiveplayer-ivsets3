#include "IVSet.h"

#include <qdebug.h>

constexpr auto MaxZonesCount = 64;

IVSet::IVSet(QObject* parent, QString id, bool isUser, IVSetConfig config, QList<IVZone::IVZoneConfig> zonesConfigs)
    : QObject(parent)
    , _id {id}
    , _isUser {isUser}
    , _initConfig {config}
    , _config {config}
    , _initZonesConfigs {zonesConfigs}
{
    connect(this, &IVSet::nameChanged, this, [this]() {
        setIsModified(_config.name != _initConfig.name);
    });
    connect(this, &IVSet::gridTypeChanged, this, [this]() {
        setIsModified(_config.gridType != _initConfig.gridType);
    });
    connect(this, &IVSet::slotCountChanged, this, [this]() {
        setIsModified(_config.slotCount != _initConfig.slotCount);
    });
    connect(this, &IVSet::horizonalSlotCountChanged, this, [this]() {
        setIsModified(_config.horizonalSlotCount != _initConfig.horizonalSlotCount);
    });
    connect(this, &IVSet::verticalSlotCountChanged, this, [this]() {
        setIsModified(_config.verticalSlotCount != _initConfig.verticalSlotCount);
    });
    connect(this, &IVSet::customSlotCountChanged, this, [this]() {
        setIsModified(_config.customSlotCount != _initConfig.customSlotCount);
    });
    connect(this, &IVSet::horizontalCellCountChanged, this, [this]() {
        setIsModified(_config.horizontalCellCount != _initConfig.horizontalCellCount);
    });
    connect(this, &IVSet::verticalCellCountChanged, this, [this]() {
        setIsModified(_config.verticalCellCount != _initConfig.verticalCellCount);
    });
    connect(this, &IVSet::xRatioChanged, this, [this]() {
        setIsModified(_config.xRatio != _initConfig.xRatio);
    });
    connect(this, &IVSet::yRatioChanged, this, [this]() {
        setIsModified(_config.yRatio != _initConfig.yRatio);
    });
    connect(this, &IVSet::zonesCountChanged, this, [this]() {
        setIsModified(_zones.size() != _initZonesConfigs.size());
    });

    connect(this, &IVSet::zonesCountChanged, this, &IVSet::updateEmptyZonesCount);
    connect(this, &IVSet::zoneContentChanged, this, &IVSet::updateEmptyZonesCount);

    fillZonesFromInitConfig();
}

QString IVSet::id() const { return _id; }
void IVSet::setId(const QString &id)
{
    if (_id != id) {
        _id = id;
        emit idChanged();
    }
}

QString IVSet::name() const { return _config.name; }
void IVSet::setName(const QString &name)
{
    if (_config.name != name) {
        _config.name = name;
        emit nameChanged();
    }
}

bool IVSet::isUser() const { return _isUser; }
void IVSet::setIsUser(bool isUser)
{
    if (_isUser != isUser) {
        _isUser = isUser;
        emit isUserChanged();
    }
}

IVSet::GridType IVSet::gridType() const { return _config.gridType; }
void IVSet::setGridType(GridType gridType)
{
    if (_config.gridType != gridType) {
        _config.gridType = gridType;
        emit gridTypeChanged();

        const auto prevSlotCount = _config.slotCount;
        switch (_config.gridType) {
            case GridType::Quad:
                setSlotCount(2);
                if (_config.slotCount == prevSlotCount) {
                    updateZones();
                }
                break;
            case GridType::TwoHeaderFocus:
                setSlotCount(4);
                if (_config.slotCount == prevSlotCount) {
                    updateZones();
                }
                break;
            case GridType::ThreeCornersPlusQuad:
                updateZones();
                break;
            case GridType::TopLeftFocus:
                setSlotCount(3);
                if (_config.slotCount == prevSlotCount) {
                    updateZones();
                }
                break;
            case GridType::CenterFocus:
                setSlotCount(4);
                if (_config.slotCount == prevSlotCount) {
                    updateZones();
                }
                break;
            case GridType::QuadCenterFocus:
                setSlotCount(5);
                if (_config.slotCount == prevSlotCount) {
                    updateZones();
                }
                break;
            case GridType::Custom:
                break;
        }
    }
}

int IVSet::slotCount() const { return _config.slotCount; }
void IVSet::setSlotCount(int slotCount)
{
    if (_config.slotCount != slotCount) {
        _config.slotCount = slotCount;

        _isSlotCountUpdating = true;
        setHorizonalSlotCount(_config.slotCount);
        setVerticalSlotCount(_config.slotCount);
        _isSlotCountUpdating = false;

        updateZones();

        emit slotCountChanged();
    }
}

int IVSet::horizonalSlotCount() const { return _config.horizonalSlotCount; }
void IVSet::setHorizonalSlotCount(int horizonalSlotCount)
{
    if (_config.horizonalSlotCount != horizonalSlotCount) {
        _config.horizonalSlotCount = horizonalSlotCount;

        setHorizontalCellCount(_config.horizonalSlotCount == 7 ? 56 : _config.horizonalSlotCount == 8 ? 64 : 60);

        if (!_isSlotCountUpdating && _config.gridType == GridType::Quad) {
            updateZones();
        }

        emit horizonalSlotCountChanged();
    }
}

int IVSet::verticalSlotCount() const { return _config.verticalSlotCount; }
void IVSet::setVerticalSlotCount(int verticalSlotCount)
{
    if (_config.verticalSlotCount != verticalSlotCount) {
        _config.verticalSlotCount = verticalSlotCount;

        setVerticalCellCount(_config.verticalSlotCount == 7 ? 56 : _config.verticalSlotCount == 8 ? 64 : 60);

        if (!_isSlotCountUpdating && _config.gridType == GridType::Quad) {
            updateZones();
        }

        emit verticalSlotCountChanged();
    }
}

int IVSet::customSlotCount() const { return _config.customSlotCount; }
void IVSet::setCustomSlotCount(int customSlotCount)
{
    if (_config.customSlotCount != customSlotCount) {
        _config.customSlotCount = customSlotCount;

        updateZones();

        emit customSlotCountChanged();
    }
}

int IVSet::horizontalCellCount() const { return _config.horizontalCellCount; }
void IVSet::setHorizontalCellCount(int horizontalCellCount)
{
    if (_config.horizontalCellCount != horizontalCellCount) {
        _config.horizontalCellCount = horizontalCellCount;
        emit horizontalCellCountChanged();
    }
}

int IVSet::verticalCellCount() const { return _config.verticalCellCount; }
void IVSet::setVerticalCellCount(int verticalCellCount)
{
    if (_config.verticalCellCount != verticalCellCount) {
        _config.verticalCellCount = verticalCellCount;
        emit verticalCellCountChanged();
    }
}

int IVSet::xRatio() const { return _config.xRatio; }
void IVSet::setXRatio(int xRatio)
{
    if (_config.xRatio != xRatio) {
        _config.xRatio = xRatio;
        emit xRatioChanged();
    }
}

int IVSet::yRatio() const { return _config.yRatio; }
void IVSet::setYRatio(int yRatio)
{
    if (_config.yRatio != yRatio) {
        _config.yRatio = yRatio;
        emit yRatioChanged();
    }
}

bool IVSet::isModified() const { return _isModified; }
void IVSet::setIsModified(bool isModified)
{
    if (_isModified != isModified) {
        _isModified = isModified;
        emit isModifiedChanged();
    }
}

QList<IVZone*> IVSet::zones() const { return _zones; }

int IVSet::zonesCount() const
{
    return _zones.size();
}

int IVSet::emptyZonesCount() const
{
    return _emptyZonesCount;
}

IVZone* IVSet::getZone(int index) const
{
    return _zones.at(index);
}

void IVSet::removeZone(int zoneIndex) // 124
{
    if (zoneIndex < 0 || zoneIndex >= _zones.size()) {
        return;
    }

    emit beginRemoveZones(zoneIndex, zoneIndex);

    auto* zoneToRemove = _zones.takeAt(zoneIndex);
    updateZonesIndexes();

    emit endRemoveZones();

    zoneToRemove->deleteLater();

    emit zonesCountChanged();
}

void IVSet::addZone(const QString& key2, bool running)
{
    if (_zones.size() >= MaxZonesCount) {
        return;
    }

    emit beginInsertZones(_zones.size(), _zones.size());

    IVZone::IVZoneConfig zoneConfig;
    zoneConfig.setIndex = _zones.size();
    zoneConfig.type = "camera";
    zoneConfig.key2 = key2;
    zoneConfig.running = running;
    zoneConfig.startXCell = 24;
    zoneConfig.startYCell = 24;
    zoneConfig.capturedHorizontalCellCount = 12;
    zoneConfig.capturedVerticalCellCount = 12;

    auto* zone = new IVZone(this, zoneConfig);
    _zones.append(zone);

    emit endInsertZones();
    emit zonesCountChanged();
}

void IVSet::addZoneContentToFirstEmptyZone(const QString& key2, bool running)
{
    for (auto& zone: _zones) {
        if (zone->type() == "empty") {
            zone->setType("camera");
            zone->setKey2(key2);
            zone->setRunning(running);
            emit zoneContentChanged(_zones.indexOf(zone));
            return;
        }
    }
}

void IVSet::addZoneContent(int zoneIndex, const QString& key2, bool running)
{
    auto zone = _zones.at(zoneIndex);
    if (zone->type() != "empty") {
        return;
    }
    zone->setType("camera");
    zone->setKey2(key2);
    zone->setRunning(running);

    emit zoneContentChanged(zoneIndex);
}

void IVSet::replaceZoneContent(int zoneIndex, const QString& key2, bool running)
{
    auto zone = _zones.at(zoneIndex);
    if (!zone) {
        return;
    }
    zone->setType("camera");
    zone->setKey2(key2);
    zone->setRunning(running);

    emit zoneContentChanged(zoneIndex);
}

void IVSet::removeZoneContent(int zoneIndex)
{
    const auto zoneToRemove = _zones.at(zoneIndex);
    if (!zoneToRemove) {
        qDebug() << "Index for zone to remove content not found:" << zoneIndex;
        return;
    }

    zoneToRemove->setType("empty");
    zoneToRemove->setKey2("");

    emit zoneContentChanged(zoneIndex);
}

void IVSet::swapZoneContent(int zoneIndexFrom, int zoneIndexTo)
{
    auto zone1 = _zones.at(zoneIndexFrom);
    auto zone2 = _zones.at(zoneIndexTo);
    if (!zone1 || !zone2) {
        return;
    }

    const auto zone1Type = zone1->type();
    const auto zone1Key2 = zone1->key2();
    const auto zone1Running = zone1->running();

    zone1->setType(zone2->type());
    zone1->setKey2(zone2->key2());
    zone1->setRunning(zone2->running());
    emit zoneContentChanged(zoneIndexFrom);

    zone2->setType(zone1Type);
    zone2->setKey2(zone1Key2);
    zone2->setRunning(zone1Running);
    emit zoneContentChanged(zoneIndexTo);
}

void IVSet::resetConfig()
{
    if (_config.gridType != _initConfig.gridType) {
        _config.gridType = _initConfig.gridType;
        emit gridTypeChanged();
    }
    if (_config.slotCount != _initConfig.slotCount) {
        _config.slotCount = _initConfig.slotCount;
        emit slotCountChanged();
    }
    if (_config.horizonalSlotCount != _initConfig.horizonalSlotCount) {
        _config.horizonalSlotCount = _initConfig.horizonalSlotCount;
        emit horizonalSlotCountChanged();
    }
    if (_config.verticalSlotCount != _initConfig.verticalSlotCount) {
        _config.verticalSlotCount = _initConfig.verticalSlotCount;
        emit verticalSlotCountChanged();
    }
    if (_config.customSlotCount != _initConfig.customSlotCount) {
        _config.customSlotCount = _initConfig.customSlotCount;
        emit customSlotCountChanged();
    }
    setHorizontalCellCount(_initConfig.horizontalCellCount);
    setVerticalCellCount(_initConfig.verticalCellCount);
    setXRatio(_initConfig.xRatio);
    setYRatio(_initConfig.yRatio);
    setName(_initConfig.name);

    auto oldZones = _zones;

    fillZonesFromInitConfig();

    for (auto& zone: oldZones) {
        zone->deleteLater();
    }

    setIsModified(false);
}

void IVSet::saveConfigAsDefault()
{
    _initConfig = _config;

    _initZonesConfigs.clear();
    for (auto& zone: _zones) {
        _initZonesConfigs.push_back(zone->config());
    }

    setIsModified(false);
}

void IVSet::fillZonesFromInitConfig()
{
    for (const auto& connection : std::as_const(_zonesConnections)) {
        QObject::disconnect(connection);
    }
    _zonesConnections.clear();

    emit beginResetZones();

    _zones.clear();
    for (auto& zoneConfig: _initZonesConfigs) {
        auto* zone = new IVZone(this, zoneConfig);
        _zones.append(zone);

        createZoneConnections(zone);
    }

    emit zonesCountChanged();
    emit endResetZones();
}

void IVSet::createZoneConnections(IVZone* zone)
{
    auto getZoneConfig = [this, zone]() {
        const auto zoneIndex = _zones.indexOf(zone);
        return _initZonesConfigs.at(zoneIndex);
    };
    _zonesConnections << connect(zone, &IVZone::setIndexChanged, this, [this, zone, getZoneConfig]() {
        auto zoneConfig = getZoneConfig();
        setIsModified(zone->setIndex() != zoneConfig.setIndex);
    });
    _zonesConnections << connect(zone, &IVZone::typeChanged, this, [this, zone, getZoneConfig]() {
        auto zoneConfig = getZoneConfig();
        setIsModified(zone->type() != zoneConfig.type);
    });
    _zonesConnections << connect(zone, &IVZone::key2Changed, this, [this, zone, getZoneConfig]() {
        auto zoneConfig = getZoneConfig();
        setIsModified(zone->key2() != zoneConfig.key2);
    });
    _zonesConnections << connect(zone, &IVZone::runningChanged, this, [this, zone, getZoneConfig]() {
        auto zoneConfig = getZoneConfig();
        setIsModified(zone->running() != zoneConfig.running);
    });
    _zonesConnections << connect(zone, &IVZone::startXCellChanged, this, [this, zone, getZoneConfig]() {
        auto zoneConfig = getZoneConfig();
        setIsModified(zone->startXCell() != zoneConfig.startXCell);
    });
    _zonesConnections << connect(zone, &IVZone::startYCellChanged, this, [this, zone, getZoneConfig]() {
        auto zoneConfig = getZoneConfig();
        setIsModified(zone->startYCell() != zoneConfig.startYCell);
    });
    _zonesConnections << connect(zone, &IVZone::capturedHorizontalCellCountChanged, this, [this, zone, getZoneConfig]() {
        auto zoneConfig = getZoneConfig();
        setIsModified(zone->capturedHorizontalCellCount() != zoneConfig.capturedHorizontalCellCount);
    });
    _zonesConnections << connect(zone, &IVZone::capturedVerticalCellCountChanged, this, [this, zone, getZoneConfig]() {
        auto zoneConfig = getZoneConfig();
        setIsModified(zone->capturedVerticalCellCount() != zoneConfig.capturedVerticalCellCount);
    });
}

void IVSet::updateZonesIndexes()
{
    for (auto& zone: _zones) {
        zone->setSetIndex(_zones.indexOf(zone));
    }
}

void IVSet::updateEmptyZonesCount()
{
    const auto emptyZonesCount = std::count_if(_zones.cbegin(), _zones.cend(), [](IVZone* zone) {
        return zone->type() == "empty";
    });
    if (_emptyZonesCount != emptyZonesCount) {
        _emptyZonesCount = emptyZonesCount;
        emit emptyZonesCountChanged();
    }
}

void IVSet::updateZones()
{
    int newZonesSize = 0;
    switch (_config.gridType) {
        case GridType::Quad:
            newZonesSize = _config.horizonalSlotCount * _config.verticalSlotCount;
            break;
        case GridType::TwoHeaderFocus:
            newZonesSize = _config.slotCount * 2 + 2;
            break;
        case GridType::ThreeCornersPlusQuad:
            newZonesSize = 7;
            break;
        case GridType::TopLeftFocus:
            newZonesSize = _config.slotCount * 2;
            if (_config.slotCount < 3) {
                return;
            }
            break;
        case GridType::CenterFocus:
            newZonesSize = _config.slotCount * 4 - 3;
            if (_config.slotCount < 4) {
                return;
            }
            break;
        case GridType::QuadCenterFocus:
            newZonesSize = _config.slotCount * 4;
            if (_config.slotCount < 5) {
                return;
            }
            break;
        case GridType::Custom:
            newZonesSize = _config.customSlotCount;
            break;
    }

    if (_zones.size() > newZonesSize) {
        emit beginRemoveZones(newZonesSize, _zones.size() - 1);

        QList<IVZone*> zonesToRemove;
        while (_zones.size() > newZonesSize) {
            zonesToRemove << _zones.takeLast();
        }

        emit endRemoveZones();

        for (auto& zone: zonesToRemove) {
            zone->deleteLater();
        }
    }

    QList<IVZone::IVZoneConfig> zonesConfigs;
    switch (_config.gridType) {
        case GridType::Quad:
            zonesConfigs = calculateQuadGrid(newZonesSize);
            break;
        case GridType::TwoHeaderFocus:
            zonesConfigs = calculateTwoHeaderFocusGrid(newZonesSize);
            break;
        case GridType::ThreeCornersPlusQuad:
            zonesConfigs = calculateThreeCornersPlusQuadGrid();
            break;
        case GridType::TopLeftFocus:
            zonesConfigs = calculateTopLeftFocusGrid(newZonesSize);
            break;
        case GridType::CenterFocus:
            zonesConfigs = calculateCenterFocusGrid(newZonesSize);
            break;
        case GridType::QuadCenterFocus:
            zonesConfigs = calculateQuadCenterFocusGrid(newZonesSize);
            break;
        case GridType::Custom:
            break;
    }

    for (int i = 0; i < _zones.size(); i++) {
        auto* zone = _zones.at(i);
        const auto zoneConfig = zonesConfigs.at(i);
        zone->setStartXCell(zoneConfig.startXCell);
        zone->setStartYCell(zoneConfig.startYCell);
        zone->setCapturedHorizontalCellCount(zoneConfig.capturedHorizontalCellCount);
        zone->setCapturedVerticalCellCount(zoneConfig.capturedVerticalCellCount);
    }

    if (_zones.size() < zonesConfigs.size()) {
        emit beginInsertZones(_zones.size(), zonesConfigs.size() - 1);

        for (int i = _zones.size(); i < zonesConfigs.size(); i++) {
            const auto zoneConfig = zonesConfigs.at(i);
            auto* zone = new IVZone(this, zoneConfig);
            _zones.append(zone);
        }

        emit endInsertZones();
    }

    emit zonesCountChanged();
}

QList<IVZone::IVZoneConfig> IVSet::calculateQuadGrid(int zoneCount) const
{
    QList<IVZone::IVZoneConfig> zonesConfigs;
    zonesConfigs.reserve(zoneCount);

    const auto capturedHorizontalCellCount = _config.horizontalCellCount / _config.horizonalSlotCount;
    const auto capturedVerticalCellCount = _config.verticalCellCount / _config.verticalSlotCount;

    for (int i = 0; i < zoneCount; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = i;
        zoneConfig.startXCell = i % _config.horizonalSlotCount * capturedHorizontalCellCount;
        zoneConfig.startYCell = (i / _config.horizonalSlotCount) * capturedVerticalCellCount;
        zoneConfig.capturedHorizontalCellCount = capturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = capturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
    }

    return zonesConfigs;
}

QList<IVZone::IVZoneConfig> IVSet::calculateTwoHeaderFocusGrid(int zoneCount) const
{
    QList<IVZone::IVZoneConfig> zonesConfigs;
    zonesConfigs.reserve(zoneCount);

    const auto headerHorizontalSlotCount = 2;
    const auto largeCapturedHorizontalCellCount = _config.horizontalCellCount / headerHorizontalSlotCount;
    const auto largeCapturedVerticalCellCount = _config.verticalCellCount / headerHorizontalSlotCount;
    const auto smallCapturedHorizontalCellCount = _config.horizontalCellCount / _config.horizonalSlotCount;
    const auto smallCapturedVerticalCellCount = _config.verticalCellCount / 4;

    for (int i = 0; i < headerHorizontalSlotCount; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = i;
        zoneConfig.startXCell = i % headerHorizontalSlotCount * largeCapturedHorizontalCellCount;
        zoneConfig.startYCell = 0;
        zoneConfig.capturedHorizontalCellCount = largeCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = largeCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
    }

    for (int i = headerHorizontalSlotCount; i < zoneCount; i++) {
        IVZone::IVZoneConfig zoneConfig;
        const auto internalIndex = i - headerHorizontalSlotCount;
        zoneConfig.setIndex = i;
        zoneConfig.startXCell = internalIndex % _config.horizonalSlotCount * smallCapturedHorizontalCellCount;
        zoneConfig.startYCell = largeCapturedVerticalCellCount
                                + (internalIndex / _config.horizonalSlotCount) * smallCapturedVerticalCellCount;
        zoneConfig.capturedHorizontalCellCount = smallCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = smallCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
    }

    return zonesConfigs;
}

QList<IVZone::IVZoneConfig> IVSet::calculateThreeCornersPlusQuadGrid() const
{
    QList<IVZone::IVZoneConfig> zonesConfigs;
    zonesConfigs.reserve(7);

    const auto largeCapturedHorizontalCellCount = _config.horizontalCellCount / 2;
    const auto largeCapturedVerticalCellCount = _config.verticalCellCount / 2;
    const auto smallCapturedHorizontalCellCount = _config.horizontalCellCount / 4;
    const auto smallCapturedVerticalCellCount = _config.verticalCellCount / 4;

    for (int i = 0; i < 3; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = i;
        zoneConfig.startXCell = i % 2 * largeCapturedHorizontalCellCount;
        zoneConfig.startYCell = (i / 2) * largeCapturedVerticalCellCount;
        zoneConfig.capturedHorizontalCellCount = largeCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = largeCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
    }

    for (int i = 3; i < 7; i++) {
        IVZone::IVZoneConfig zoneConfig;
        const auto internalIndex = i - 3;
        zoneConfig.setIndex = i;
        zoneConfig.startXCell = largeCapturedHorizontalCellCount + internalIndex % 2 * smallCapturedHorizontalCellCount;
        zoneConfig.startYCell = largeCapturedVerticalCellCount + (internalIndex / 2) * smallCapturedVerticalCellCount;
        zoneConfig.capturedHorizontalCellCount = smallCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = smallCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
    }

    return zonesConfigs;
}


QList<IVZone::IVZoneConfig> IVSet::calculateTopLeftFocusGrid(int zoneCount) const
{
    QList<IVZone::IVZoneConfig> zonesConfigs;
    zonesConfigs.reserve(zoneCount);

    const auto smallCapturedHorizontalCellCount = _config.horizontalCellCount / _config.slotCount;
    const auto smallCapturedVerticalCellCount = _config.verticalCellCount / _config.slotCount;
    const auto largeCapturedHorizontalCellCount = _config.horizontalCellCount - smallCapturedHorizontalCellCount;
    const auto largeCapturedVerticalCellCount = _config.verticalCellCount - smallCapturedVerticalCellCount;

    auto zoneInContainerIndex = 0;

    IVZone::IVZoneConfig zoneConfig;
    zoneConfig.setIndex = zoneInContainerIndex;
    zoneConfig.startXCell = 0;
    zoneConfig.startYCell = 0;
    zoneConfig.capturedHorizontalCellCount = largeCapturedHorizontalCellCount;
    zoneConfig.capturedVerticalCellCount = largeCapturedVerticalCellCount;
    zonesConfigs.append(zoneConfig);
    zoneInContainerIndex++;

    for (int i = 0; i < _config.slotCount; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = zoneInContainerIndex;
        zoneConfig.startXCell = i * smallCapturedHorizontalCellCount;
        zoneConfig.startYCell = largeCapturedVerticalCellCount;
        zoneConfig.capturedHorizontalCellCount = smallCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = smallCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
        zoneInContainerIndex++;
    }

    for (int i = 0; i < _config.slotCount - 1; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = zoneInContainerIndex;
        zoneConfig.startXCell = largeCapturedHorizontalCellCount;
        zoneConfig.startYCell = i * smallCapturedVerticalCellCount;
        zoneConfig.capturedHorizontalCellCount = smallCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = smallCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
        zoneInContainerIndex++;
    }

    return zonesConfigs;
}

QList<IVZone::IVZoneConfig> IVSet::calculateCenterFocusGrid(int zoneCount) const
{
    QList<IVZone::IVZoneConfig> zonesConfigs;
    zonesConfigs.reserve(zoneCount);

    const auto smallCapturedHorizontalCellCount = _config.horizontalCellCount / _config.slotCount;
    const auto smallCapturedVerticalCellCount = _config.verticalCellCount / _config.slotCount;
    const auto largeCapturedHorizontalCellCount = _config.horizontalCellCount - 2 * smallCapturedHorizontalCellCount;
    const auto largeCapturedVerticalCellCount = _config.verticalCellCount - 2* smallCapturedVerticalCellCount;

    auto zoneInContainerIndex = 0;

    IVZone::IVZoneConfig zoneConfig;
    zoneConfig.setIndex = zoneInContainerIndex;
    zoneConfig.startXCell = smallCapturedHorizontalCellCount;
    zoneConfig.startYCell = smallCapturedVerticalCellCount;
    zoneConfig.capturedHorizontalCellCount = largeCapturedHorizontalCellCount;
    zoneConfig.capturedVerticalCellCount = largeCapturedVerticalCellCount;
    zonesConfigs.append(zoneConfig);
    zoneInContainerIndex++;

    //top zones
    for (int i = 0; i < _config.slotCount; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = zoneInContainerIndex;
        zoneConfig.startXCell = i * smallCapturedHorizontalCellCount;
        zoneConfig.startYCell = 0;
        zoneConfig.capturedHorizontalCellCount = smallCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = smallCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
        zoneInContainerIndex++;
    }
    //bottom zones
    for (int i = 0; i < _config.slotCount; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = zoneInContainerIndex;
        zoneConfig.startXCell = i * smallCapturedHorizontalCellCount;
        zoneConfig.startYCell = smallCapturedVerticalCellCount + largeCapturedVerticalCellCount;
        zoneConfig.capturedHorizontalCellCount = smallCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = smallCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
        zoneInContainerIndex++;
    }
    //left zones
    for (int i = 0; i < _config.slotCount - 2; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = zoneInContainerIndex;
        zoneConfig.startXCell = 0;
        zoneConfig.startYCell = smallCapturedVerticalCellCount + i * smallCapturedVerticalCellCount;
        zoneConfig.capturedHorizontalCellCount = smallCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = smallCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
        zoneInContainerIndex++;
    }
    //right zones
    for (int i = 0; i < _config.slotCount - 2; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = zoneInContainerIndex;
        zoneConfig.startXCell = smallCapturedHorizontalCellCount + largeCapturedHorizontalCellCount;
        zoneConfig.startYCell = smallCapturedVerticalCellCount + i * smallCapturedVerticalCellCount;
        zoneConfig.capturedHorizontalCellCount = smallCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = smallCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
        zoneInContainerIndex++;
    }

    return zonesConfigs;
}

QList<IVZone::IVZoneConfig> IVSet::calculateQuadCenterFocusGrid(int zoneCount) const
{
    QList<IVZone::IVZoneConfig> zonesConfigs;
    zonesConfigs.reserve(zoneCount);

    const auto smallCapturedHorizontalCellCount = _config.horizontalCellCount / _config.slotCount;
    const auto smallCapturedVerticalCellCount = _config.verticalCellCount / _config.slotCount;
    const auto largeCapturedHorizontalCellCount = (_config.horizontalCellCount - 2 * smallCapturedHorizontalCellCount) / 2;
    const auto largeCapturedVerticalCellCount = (_config.verticalCellCount - 2* smallCapturedVerticalCellCount) / 2;


    //center zones
    for (int i = 0; i < 4; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = i;
        zoneConfig.startXCell = smallCapturedHorizontalCellCount + (i % 2) * largeCapturedHorizontalCellCount;
        zoneConfig.startYCell = smallCapturedVerticalCellCount + (i / 2) * largeCapturedVerticalCellCount;
        zoneConfig.capturedHorizontalCellCount = largeCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = largeCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
    }

    auto zoneInContainerIndex = 4;

    //top zones
    for (int i = 0; i < _config.slotCount; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = zoneInContainerIndex;
        zoneConfig.startXCell = i * smallCapturedHorizontalCellCount;
        zoneConfig.startYCell = 0;
        zoneConfig.capturedHorizontalCellCount = smallCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = smallCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
        zoneInContainerIndex++;
    }
    //bottom zones
    for (int i = 0; i < _config.slotCount; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = zoneInContainerIndex;
        zoneConfig.startXCell = i * smallCapturedHorizontalCellCount;
        zoneConfig.startYCell = smallCapturedVerticalCellCount + 2 * largeCapturedVerticalCellCount;
        zoneConfig.capturedHorizontalCellCount = smallCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = smallCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
        zoneInContainerIndex++;
    }
    //left zones
    for (int i = 0; i < _config.slotCount - 2; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = zoneInContainerIndex;
        zoneConfig.startXCell = 0;
        zoneConfig.startYCell = smallCapturedVerticalCellCount + i * smallCapturedVerticalCellCount;
        zoneConfig.capturedHorizontalCellCount = smallCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = smallCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
        zoneInContainerIndex++;
    }
    //right zones
    for (int i = 0; i < _config.slotCount - 2; i++) {
        IVZone::IVZoneConfig zoneConfig;
        zoneConfig.setIndex = zoneInContainerIndex;
        zoneConfig.startXCell = smallCapturedHorizontalCellCount + 2 * largeCapturedHorizontalCellCount;
        zoneConfig.startYCell = smallCapturedVerticalCellCount + i * smallCapturedVerticalCellCount;
        zoneConfig.capturedHorizontalCellCount = smallCapturedHorizontalCellCount;
        zoneConfig.capturedVerticalCellCount = smallCapturedVerticalCellCount;
        zonesConfigs.append(zoneConfig);
        zoneInContainerIndex++;
    }

    return zonesConfigs;
}

void IVSet::print() const
{
    qDebug() << "<<<<<<<<<<<<<<<<<<<<<<<<< PRINT IVSET >>>>>>>>>>>>>>>>>>>>>>>>";
    const int columnWidth = 20;

    qDebug().noquote() << QString("%1%2%3%4%5%6%7%8%9%10%11")
                              .arg("name", -columnWidth)
                              .arg("isUser", -columnWidth)
                              .arg("gridType", -columnWidth)
                              .arg("slotCount", -columnWidth)
                              .arg("horizonalSlotCount", -columnWidth)
                              .arg("verticalSlotCount", -columnWidth)
                              .arg("horizontalCellCount", -columnWidth)
                              .arg("verticalCellCount", -columnWidth)
                              .arg("isModified", -columnWidth)
                              .arg("id", -40)
                              .arg("__IVZONEs size", -columnWidth);

    qDebug().noquote() << QString("%1%2%3%4%5%6%7%8%9%10%11")
                              .arg(_config.name, -columnWidth)
                              .arg(_isUser, -columnWidth)
                              .arg(int(_config.gridType), -columnWidth)
                              .arg(_config.slotCount, -columnWidth)
                              .arg(_config.horizonalSlotCount, -columnWidth)
                              .arg(_config.verticalSlotCount, -columnWidth)
                              .arg(_config.horizontalCellCount, -columnWidth)
                              .arg(_config.verticalCellCount, -columnWidth)
                              .arg(_isModified, -columnWidth)
                              .arg(_id, -40)
                              .arg(_zones.size(), -columnWidth);

    for (auto* zone: _zones) {
        zone->print();
    }

    qDebug() << ">>>>>>>>>>>>>>>>>>>>>>>> END PRINT IVSET <<<<<<<<<<<<<<<<<<<<<<<<<";
}

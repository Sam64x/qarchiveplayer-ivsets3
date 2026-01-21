#include "IVSetsManager.h"

#include <QVariant>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJSValue>
#include <QUuid>
#include <QDebug>

static QHash<int, IVSet::GridType> ServerClientGridTypeMap {
    {0, IVSet::GridType::TopLeftFocus},
    {1, IVSet::GridType::TwoHeaderFocus},
    {2, IVSet::GridType::ThreeCornersPlusQuad},
    {3, IVSet::GridType::CenterFocus},
    {4, IVSet::GridType::QuadCenterFocus},
    {5, IVSet::GridType::Quad}
};

IVSetsManager* IVSetsManager::instance()
{
    static IVSetsManager inst;
    return &inst;
}

IVSetsManager::IVSetsManager(QObject *parent)
    : QObject(parent)
{}

bool IVSetsManager::freeEditEnabled() const
{
    return _freeEditEnabled;
}

void IVSetsManager::setFreeEditEnabled(bool enabled)
{
    if (_freeEditEnabled != enabled) {
        _freeEditEnabled = enabled;
        emit freeEditEnabledChanged();
    }
}

int IVSetsManager::setsCount() const
{
    return _sets.size();
}

IVSet* IVSetsManager::activeSet() const
{
    return _activeSet;
}

void IVSetsManager::setActiveSet(IVSet* set)
{
    if (set != _activeSet) {
        _activeSet = set;
        emit activeSetChanged();
    }
}

IVSet* IVSetsManager::createNewSet(const QString& setName)
{
    IVSet::IVSetConfig setConfig;

    setConfig.name = setName;
    setConfig.gridType = IVSet::GridType::Quad;
    setConfig.slotCount = 2;
    setConfig.horizonalSlotCount = 2;
    setConfig.verticalSlotCount = 2;
    setConfig.customSlotCount = 2;
    setConfig.horizontalCellCount = 60;
    setConfig.verticalCellCount = 60;
    setConfig.xRatio = 16;
    setConfig.yRatio = 9;

    auto* newSet = new IVSet(this, "new_tab", true, setConfig, {});
    newSet->updateZones();

    _sets.push_back(newSet);
    emit setsCountChanged();

    return newSet;
}

IVSet* IVSetsManager::getSet(const QString& setId) const
{
    for (auto* set: _sets) {
        if (set->id() == setId) {
            return set;
        }
    }
    return nullptr;
}

IVSet* IVSetsManager::createSet(const QVariant &input)
{
    QVariant convertedVariant;

    if (input.canConvert<QJSValue>()) {
        QJSValue jsValue = input.value<QJSValue>();
        convertedVariant = jsValue.toVariant();
    } else {
        convertedVariant = input;
    }
    QJsonDocument doc = QJsonDocument::fromVariant(convertedVariant);
    if (!doc.isObject()) {
        qWarning() << "Invalid JSON object" << convertedVariant;
        return nullptr;
    }
    QJsonObject root = doc.object();

    QString setName = root["setName"].toString();
    QString setId = root["setId"].toString();

    for (auto& set: _sets) {
        if (set->id() == setId && set->name() == setName) {
            return set;
        }
    }

    IVSet::IVSetConfig setConfig;

    setConfig.name = setName;
    setConfig.gridType = ServerClientGridTypeMap.value(root["grid"].toInt(), IVSet::GridType::Custom);
    setConfig.horizontalCellCount = root["cols"].toInt();
    setConfig.verticalCellCount = root["rows"].toInt();
    setConfig.xRatio = root["ratioX"].toInt();
    setConfig.yRatio = root["ratioY"].toInt();
    auto isUser = root["isuser"].toInt();

    QJsonArray zones = root["zones"].toArray();

    setConfig.slotCount = 2;
    setConfig.horizonalSlotCount = 2;
    setConfig.verticalSlotCount = 2;
    setConfig.customSlotCount = zones.size();

    if (setConfig.gridType == IVSet::GridType::Quad) {
        static int miximalSlotsCount = 8;
        QSet<QPair<int, int>> slotPairs;
        for (int i = 1; i <= miximalSlotsCount; i++) {
            for (int j = 1; j <= miximalSlotsCount; j++) {
                if ((i * j == zones.size())
                    && (zones.size() % i == 0)
                    && (zones.size() % j == 0)) {
                    slotPairs.insert({i, j});
                }
            }
        }
        QPair<int, int> minimumSlotDifPair {8,1};

        for (auto slotPair: slotPairs) {
            if (abs(slotPair.second - slotPair.first) < abs(minimumSlotDifPair.second - minimumSlotDifPair.first) ) {
                minimumSlotDifPair = slotPair;
            }
        }

        setConfig.slotCount = minimumSlotDifPair.first;
        setConfig.horizonalSlotCount = minimumSlotDifPair.first;
        setConfig.verticalSlotCount = minimumSlotDifPair.second;
    }
    else if (setConfig.gridType == IVSet::GridType::TwoHeaderFocus) {
        setConfig.slotCount = (zones.size() - 2) / 2;
    }
    else if (setConfig.gridType == IVSet::GridType::TopLeftFocus) {
        setConfig.slotCount = zones.size() / 2;
    }
    else if (setConfig.gridType == IVSet::GridType::CenterFocus) {
        setConfig.slotCount = (zones.size() - 1) / 4 + 1;
    }
    else if (setConfig.gridType == IVSet::GridType::QuadCenterFocus) {
        setConfig.slotCount = (zones.size() - 4) / 4 + 1;
    }

    QList<IVZone::IVZoneConfig> zonesConfigs;
    for (int i = 0; i < zones.size(); i++) {
        const auto zoneVal = zones.at(i);
        if (zoneVal.isObject()) {
            QJsonObject zone = zoneVal.toObject();

            IVZone::IVZoneConfig zoneConfig;

            zoneConfig.setIndex = i;
            zoneConfig.startXCell = zone["x"].toInt() - 1;
            zoneConfig.startYCell = zone["y"].toInt() - 1;
            zoneConfig.capturedHorizontalCellCount = zone["dx"].toInt();
            zoneConfig.capturedVerticalCellCount = zone["dy"].toInt();
            zoneConfig.type = zone["type"].toString();

            QJsonObject params = zone["params"].toObject();
            if (params.contains("key2")) {
                QJsonObject key2Obj = params["key2"].toObject();
                if (key2Obj["type"].toString() == "var") {
                    QJsonArray values = key2Obj["value"].toArray();
                    if (!values.isEmpty()) {
                        zoneConfig.key2 = values[0].toString();
                    }
                }
            }
            if (params.contains("running")) {
                QJsonObject runningObj = params["running"].toObject();
                if (runningObj["type"].toString() == "var") {
                    QJsonArray values = runningObj["value"].toArray();
                    if (!values.isEmpty()) {
                        zoneConfig.running = values[0].toBool();
                    }
                }
            }
            zonesConfigs.append(zoneConfig);
        }
    }
    auto* newSet = new IVSet(this, setId, isUser, setConfig, zonesConfigs);

    _sets.push_back(newSet);
    emit setsCountChanged();

    return newSet;
}

void IVSetsManager::clearSets()
{
    while (_sets.size() != 0) {
        const auto set = _sets.takeLast();
        set->deleteLater();
    }
    setActiveSet(nullptr);
    emit setsCountChanged();
}

QString IVSetsManager::getSetConfigToSave(IVSet* set) const
{
    if (!set) {
        return "";
    }

    QJsonObject root;

    root["cols"] = set->horizontalCellCount();
    root["rows"] = set->verticalCellCount();
    root["grid"] = ServerClientGridTypeMap.key(set->gridType());
    root["ratioX"] = set->xRatio();
    root["ratioY"] = set->yRatio();
    root["isuser"] = int(set->isUser());
    root["setId"] = !set->isUser() || set->id() == "new_set"
                        ? QUuid::createUuid().toString()
                        : set->id();
    root["setName"] = set->name();

    QJsonArray zonesArray;
    const auto zones = set->zones();
    for (const auto& zone: zones) {
        QJsonObject zoneObj;
        zoneObj["x"] = zone->startXCell() + 1;
        zoneObj["y"] = zone->startYCell() + 1;
        zoneObj["dx"] = zone->capturedHorizontalCellCount();
        zoneObj["dy"] = zone->capturedVerticalCellCount();
        zoneObj["type"] = zone->type();

        QJsonObject params;
        if (zone->type() != "empty") {
            params["key2"] = QJsonObject{{"type", "var"}, {"value", QJsonArray{zone->key2()}}};
            params["running"] = QJsonObject{{"type", "var"}, {"value", QJsonArray{zone->running()}}};
            zoneObj["params"] = params;
        }
        else {
            zoneObj["params"] = QJsonObject{};
        }

        zonesArray.append(zoneObj);
    }

    root["zones"] = zonesArray;

    QJsonDocument doc(root);
    return QString::fromUtf8(doc.toJson(QJsonDocument::Compact));
}

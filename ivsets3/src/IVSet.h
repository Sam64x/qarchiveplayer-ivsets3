#pragma once

#include <QObject>
#include <QString>
#include <QList>

#include "IVZone.h"

class IVSet : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString id READ id WRITE setId NOTIFY idChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(bool isUser READ isUser WRITE setIsUser NOTIFY isUserChanged)
    Q_PROPERTY(GridType gridType READ gridType WRITE setGridType NOTIFY gridTypeChanged)
    Q_PROPERTY(int xRatio READ xRatio WRITE setXRatio NOTIFY xRatioChanged)
    Q_PROPERTY(int yRatio READ yRatio WRITE setYRatio NOTIFY yRatioChanged)

    Q_PROPERTY(int slotCount READ slotCount WRITE setSlotCount NOTIFY slotCountChanged)
    Q_PROPERTY(int horizonalSlotCount READ horizonalSlotCount WRITE setHorizonalSlotCount NOTIFY horizonalSlotCountChanged)
    Q_PROPERTY(int verticalSlotCount READ verticalSlotCount WRITE setVerticalSlotCount NOTIFY verticalSlotCountChanged)
    Q_PROPERTY(int customSlotCount READ customSlotCount WRITE setCustomSlotCount NOTIFY customSlotCountChanged)

    Q_PROPERTY(int horizontalCellCount READ horizontalCellCount WRITE setHorizontalCellCount NOTIFY horizontalCellCountChanged)
    Q_PROPERTY(int verticalCellCount READ verticalCellCount WRITE setVerticalCellCount NOTIFY verticalCellCountChanged)

    Q_PROPERTY(int zonesCount READ zonesCount NOTIFY zonesCountChanged)
    Q_PROPERTY(bool anyZoneEmpty READ anyZoneEmpty NOTIFY anyZoneEmptyChanged)

    Q_PROPERTY(bool isModified READ isModified WRITE setIsModified NOTIFY isModifiedChanged)

    friend class IVSetsManager;

public:
    enum class GridType {
        Quad = 0,
        TwoHeaderFocus,
        ThreeCornersPlusQuad,
        TopLeftFocus,
        CenterFocus,
        QuadCenterFocus,
        Custom
    };
    Q_ENUM(GridType)

    struct IVSetConfig {
        QString name;
        GridType gridType;
        int slotCount;
        int horizonalSlotCount;
        int verticalSlotCount;
        int customSlotCount;
        int horizontalCellCount;
        int verticalCellCount;
        int xRatio;
        int yRatio;
    };

    IVSet(QObject* parent, QString id, bool isUser, IVSetConfig config, QList<IVZone::IVZoneConfig> zonesConfigs);

    QString id() const;
    void setId(const QString &id);

    Q_INVOKABLE QString initName() const;
    QString name() const;
    void setName(const QString &name);

    bool isUser() const;
    void setIsUser(bool isUser);

    GridType gridType() const;
    void setGridType(GridType gridType);

    int slotCount() const;
    void setSlotCount(int slotCount);

    int horizonalSlotCount() const;
    void setHorizonalSlotCount(int horizonalSlotCount);

    int verticalSlotCount() const;
    void setVerticalSlotCount(int verticalSlotCount);

    int customSlotCount() const;
    void setCustomSlotCount(int customSlotCount);

    int horizontalCellCount() const;
    void setHorizontalCellCount(int horizontalCellCount);

    int verticalCellCount() const;
    void setVerticalCellCount(int verticalCellCount);

    int xRatio() const;
    void setXRatio(int xRatio);

    int yRatio() const;
    void setYRatio(int yRatio);

    bool isModified() const;
    void setIsModified(bool isModified);

    QList<IVZone*> zones() const;
    void initZones(const QList<IVZone*> &zones);
    int zonesCount() const;

    bool anyZoneEmpty() const;

    Q_INVOKABLE IVZone* getZone(int index) const;
    Q_INVOKABLE void removeZone(int zoneIndex);
    Q_INVOKABLE void addZone(const QString& key2, bool running);
    Q_INVOKABLE void addZoneContentToFirstEmptyZone(const QString& key2, bool running);
    Q_INVOKABLE void addZoneContent(int zoneIndex, const QString& key2, bool running);
    Q_INVOKABLE void removeZoneContent(int zoneIndex);
    Q_INVOKABLE void swapZoneContent(int zoneIndexFrom, int zoneIndexTo);

    Q_INVOKABLE void resetConfig();
    Q_INVOKABLE void saveConfigAsDefault();

    Q_INVOKABLE void print() const;

signals:
    void idChanged();
    void nameChanged();
    void isUserChanged();
    void gridTypeChanged();
    void slotCountChanged();
    void horizonalSlotCountChanged();
    void verticalSlotCountChanged();
    void customSlotCountChanged();
    void horizontalCellCountChanged();
    void verticalCellCountChanged();
    void xRatioChanged();
    void yRatioChanged();

    void zonesCountChanged();
    void zoneContentChanged(int zoneIndex);

    void anyZoneEmptyChanged();

    void beginInsertZones(int first, int last);
    void endInsertZones();
    void beginRemoveZones(int first, int last);
    void endRemoveZones();
    void beginResetZones();
    void endResetZones();

    void isModifiedChanged();

private:
    void fillZonesFromInitConfig();
    void createZoneConnections(IVZone* zone);

    void updateZonesIndexes();
    void updateAnyZoneEmptyFlag();

    void updateZones();

    QList<IVZone::IVZoneConfig> calculateQuadGrid(int zoneCount) const;
    QList<IVZone::IVZoneConfig> calculateTwoHeaderFocusGrid(int zoneCount) const;
    QList<IVZone::IVZoneConfig> calculateThreeCornersPlusQuadGrid() const;
    QList<IVZone::IVZoneConfig> calculateTopLeftFocusGrid(int zoneCount) const;
    QList<IVZone::IVZoneConfig> calculateCenterFocusGrid(int zoneCount) const;
    QList<IVZone::IVZoneConfig> calculateQuadCenterFocusGrid(int zoneCount) const;

    QString _id;
    bool _isUser = false;

    IVSetConfig _initConfig;
    IVSetConfig _config;

    QList<IVZone*> _zones;
    QList<IVZone::IVZoneConfig> _initZonesConfigs;

    QList<QMetaObject::Connection> _zonesConnections;

    bool _isModified = false;

    bool _isSlotCountUpdating = false;
    bool _isAnyZoneEmpty = false;
};

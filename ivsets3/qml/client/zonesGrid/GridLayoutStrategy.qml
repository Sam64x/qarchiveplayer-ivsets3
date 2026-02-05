import QtQuick 2.9
import QtQml.Models 2.1

import iv.sets.sets3 1.0

Item {
    id: root

    property real cellWidth: 1
    property real cellHeight: 1

    property alias slotsRepeater: slotsRepeater

    Repeater {
        id: slotsRepeater

        model: IVZonesModel {
            set: IVSetsManager.activeSet
        }

        delegate: Slot {
            readonly property var zone: model.display

            cellWidth: root.cellWidth
            cellHeight: root.cellHeight
            horizontalCellCount: IVSetsManager.activeSet.horizontalCellCount
            verticalCellCount: IVSetsManager.activeSet.verticalCellCount
            editEnabled: IVSetsManager.freeEditEnabled

            startXCell: zone.startXCell
            startYCell: zone.startYCell
            capturedHorizontalCellCount: zone.capturedHorizontalCellCount
            capturedVerticalCellCount: zone.capturedVerticalCellCount

            onStartXCellChanged: {
                zone.startXCell = startXCell;
            }
            onStartYCellChanged: {
                zone.startYCell = startYCell;
            }
            onCapturedHorizontalCellCountChanged: {
                zone.capturedHorizontalCellCount = capturedHorizontalCellCount;
            }
            onCapturedVerticalCellCountChanged: {
                zone.capturedVerticalCellCount = capturedVerticalCellCount;
            }

            Connections {
                target: zone

                onStartXCellChanged: {
                    startXCell = zone.startXCell;
                }
                onStartYCellChanged: {
                    startYCell = zone.startYCell;
                }
                onCapturedHorizontalCellCountChanged: {
                    capturedHorizontalCellCount = zone.capturedHorizontalCellCount;
                }
                onCapturedVerticalCellCountChanged: {
                    capturedVerticalCellCount = zone.capturedVerticalCellCount;
                }
            }

            onRemoveSlot: {
                IVSetsManager.activeSet.removeZone(model.index);
            }

            onDrop: function (dragData) {
                const zoneIndexFrom = dragData.indexInSavedSet;
                const zoneIndexTo = model.index;

                if (zoneIndexFrom === undefined) {
                    return;
                }

                if (zoneIndexFrom !== null) {
                    IVSetsManager.activeSet.swapZoneContent(zoneIndexFrom, zoneIndexTo)
                }
                else if (dragData.key2 !== undefined && dragData.running !== undefined) {
                    const key2 = dragData.key2;
                    const running = dragData.running;
                    if (!key2 || !running) {
                        return;
                    }
                    if (dragData.replaceContent) {
                        IVSetsManager.activeSet.replaceZoneContent(zoneIndexTo, key2, running)
                    }
                    else {
                        IVSetsManager.activeSet.addZoneContent(zoneIndexTo, key2, running)
                    }
                }
            }
        }
    }
}

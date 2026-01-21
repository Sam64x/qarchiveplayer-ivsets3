import QtQuick 2.9

import iv.sets.sets3 1.0

Item {
    id: root

    property alias slotsRepeater: slotGridPositioner.slotsRepeater

    implicitWidth: 100
    implicitHeight: 100

    Item {
        id: grid

        readonly property real scale: Math.min(root.width / IVSetsManager.activeSet.xRatio,
                                               root.height / IVSetsManager.activeSet.yRatio)

        anchors.centerIn: parent
        width: IVSetsManager.activeSet.xRatio * scale
        height: IVSetsManager.activeSet.yRatio * scale

        GridLayoutStrategy {
            id: slotGridPositioner

            anchors.fill: parent

            cellWidth: privates.cellWidth
            cellHeight: privates.cellHeight
        }

        CellGrid {
            anchors.fill: parent

            visible: IVSetsManager.freeEditEnabled
            horizontalCellCount: IVSetsManager.activeSet.horizontalCellCount
            verticalCellCount: IVSetsManager.activeSet.verticalCellCount
        }
    }

    QtObject {
        id: privates

        readonly property real cellWidth: grid.width / IVSetsManager.activeSet.horizontalCellCount
        readonly property real cellHeight: grid.height / IVSetsManager.activeSet.verticalCellCount
    }
}

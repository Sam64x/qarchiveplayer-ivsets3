import QtQuick 2.9

Item {
    id: root

    property int horizontalCellCount: 1
    property int verticalCellCount: 1

    Repeater {
        id: xAxisRepeater
        model: verticalCellCount + 1
        delegate: Rectangle {
            x: 0
            y: model.index * parent.height / root.verticalCellCount

            width: parent.width
            height: 1

            color: "#66FFFFFF"
        }
    }

    Repeater {
        id: yAxisRepeater
        model: horizontalCellCount + 1
        delegate: Rectangle {
            x: model.index * parent.width / root.horizontalCellCount
            y: 0

            width: 1
            height: parent.height

            color: "#22FFFFFF"
        }
    }
}

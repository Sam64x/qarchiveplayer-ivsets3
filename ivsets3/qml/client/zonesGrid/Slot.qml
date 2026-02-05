import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import iv.controls 1.0

Rectangle {
    id: root

    property real cellWidth
    property real cellHeight

    property int startXCell: 0
    property int startYCell: 0
    property int capturedHorizontalCellCount: 0
    property int capturedVerticalCellCount: 0

    property int horizontalCellCount: 1
    property int verticalCellCount: 1

    property bool editEnabled: false

    readonly property alias content: content

    signal removeSlot();
    signal drop(var dragData);

    x: startXCell * cellWidth
    y: startYCell * cellHeight
    width: capturedHorizontalCellCount * cellWidth
    height: capturedVerticalCellCount * cellHeight

    color: "#d5d2d2"
    border {
        width: 1
        color: '#000000'
    }

    Drag.active: dragArea.drag.active
    Drag.hotSpot.x: 0
    Drag.hotSpot.y: 0

    DropArea {
        id: dropArea

        property var dragSource: null

        anchors.fill: parent

        enabled: !editEnabled

        onDropped: function(dropEvent) {
            const dragData = dropEvent.source.dragData;
            if (!dragData) {
                return;
            }
            root.drop(dragData);

            dragSource.aboveSlot = false;
            dragSource = null;
        }
        onEntered: function(drag) {
            drag.source.aboveSlot = true;
            drag.source.slotEmpty = !Boolean(content.visibleChildren.length);
            dragSource = drag.source;
        }
        onExited: {
            dragSource.aboveSlot = false;
            dragSource = null;
        }
    }

    Rectangle {
        id: dropBorder

        z: 1
        anchors.fill: parent

        visible: dropArea.containsDrag
        color: "transparent"
        border {
            width: 1
            color: 'blue'
        }
    }

    Label {
        width: parent.width
        anchors.centerIn: parent

        font.pixelSize: 14
        text: "Свободное поле"
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
    }

    Item {
        id: content
        anchors.fill: parent
    }

    MouseArea {
        id: dragArea

        anchors.fill: parent

        visible: root.editEnabled
        enabled: visible
        drag.target: parent
        drag.minimumX: 1
        drag.maximumX: root.parent.width - root.width + 1
        drag.minimumY: 1
        drag.maximumY: root.parent.height - root.height + 1

        onPressed: {
            root.Drag.start();
            root.z = 1;
        }
        onReleased: {
            root.Drag.drop();
            root.z = 0;

            root.startXCell = Math.round(root.x / root.cellWidth);
            root.startYCell = Math.round(root.y / root.cellHeight);
            // биндинги нужны, т.к. если startXCell или startYCell не изменится, то слот не притянется к ячейке
            root.x = Qt.binding(function() { return root.startXCell * root.cellWidth; });
            root.y = Qt.binding(function() { return root.startYCell * root.cellHeight; });
        }
    }

    IVButton {
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        visible: root.editEnabled
        type: IVButton.Type.Helper
        source: "white/delete"

        onClicked: {
            root.removeSlot();
        }
    }

    enum Side {
        Top,
        Left,
        Right,
        Bottom
    }

    MouseArea {
        id: topResizeHandle

        height: 4
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        visible: root.editEnabled
        enabled: visible
        cursorShape: Qt.SizeVerCursor

        onPressed: {
            resizeHelper.pressedHandler(Slot.Side.Top, mouse);
        }

        onPositionChanged: {
            if (pressed) {
                resizeHelper.positionChangedHandler(Slot.Side.Top, mouse);
            }
        }

        onReleased: {
            resizeHelper.releasedHandler(Slot.Side.Top);
        }
    }

    MouseArea {
        id: bottomResizeHandle

        height: 4
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        visible: root.editEnabled
        enabled: visible
        cursorShape: Qt.SizeVerCursor

        onPressed: {
            resizeHelper.pressedHandler(Slot.Side.Bottom, mouse);
        }

        onPositionChanged: {
            if (pressed) {
                resizeHelper.positionChangedHandler(Slot.Side.Bottom, mouse);
            }
        }

        onReleased: {
            resizeHelper.releasedHandler(Slot.Side.Bottom);
        }
    }

    MouseArea {
        id: leftResizeHandle

        width: 4
        anchors {
            top: parent.top
            left: parent.left
            bottom: parent.bottom
        }

        visible: root.editEnabled
        enabled: visible
        cursorShape: Qt.SizeHorCursor

        onPressed: {
            resizeHelper.pressedHandler(Slot.Side.Left, mouse);
        }

        onPositionChanged: {
            if (pressed) {
                resizeHelper.positionChangedHandler(Slot.Side.Left, mouse);
            }
        }

        onReleased: {
            resizeHelper.releasedHandler(Slot.Side.Left);
        }
    }

    MouseArea {
        id: rightResizeHandle

        width: 4
        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }

        visible: root.editEnabled
        enabled: visible
        cursorShape: Qt.SizeHorCursor

        onPressed: {
            resizeHelper.pressedHandler(Slot.Side.Right, mouse);
        }

        onPositionChanged: {
            if (pressed) {
                resizeHelper.positionChangedHandler(Slot.Side.Right, mouse);
            }
        }

        onReleased: {
            resizeHelper.releasedHandler(Slot.Side.Right);
        }
    }

    QtObject {
        id: resizeHelper

        property real startX: 0
        property real startY: 0
        property real startWidth: 0
        property real startHeight: 0

        property point startPoint: Qt.point(0, 0)

        function pressedHandler(type, mouse) {
            startPoint = root.parent.mapFromItem(root, mouse.x, mouse.y);
            startX = mouse.x;
            startY = mouse.y;
            startWidth = root.width;
            startHeight = root.height;
            root.z = 1;
        }

        function positionChangedHandler(type, mouse) {
            const point = root.parent.mapFromItem(root, mouse.x, mouse.y);

            switch(type) {
                case Slot.Side.Top:
                    root.y = clamp(point.y, 0, startPoint.y + startHeight - root.cellHeight)

                    root.height = clamp(startHeight - (point.y - startPoint.y),
                                        root.cellHeight,
                                        startPoint.y + startHeight);
                    break;
                case Slot.Side.Bottom:
                    root.height = clamp(root.height + mouse.y - startY, root.cellHeight, root.parent.height - root.y);
                    break;
                case Slot.Side.Left:
                    root.x = clamp(point.x, 0, startPoint.x + startWidth - root.cellWidth)

                    root.width = clamp(startWidth - (point.x - startPoint.x),
                                        root.cellWidth,
                                        startPoint.x + startWidth);
                    break;
                case Slot.Side.Right:
                    root.width = clamp(root.width + mouse.x - startX, root.cellWidth, root.parent.width - root.x);
                    break;
            }
        }

        function releasedHandler(type) {
            alignSizeToGrid(type);
            root.z = 0;
        }

        function alignSizeToGrid(type) {
            switch(type) {
                case Slot.Side.Top:
                    alignY();
                    alignHeight();
                    break;
                case Slot.Side.Bottom:
                    alignHeight();
                    break;
                case Slot.Side.Left:
                    alignX();
                    alignWidth();
                    break;
                case Slot.Side.Right:
                    alignWidth();
                    break;
            }
        }

        function alignX() {
            root.startXCell = Math.round(root.x / root.cellWidth);
            root.x = Qt.binding(function() { return root.startXCell * root.cellWidth; });
        }
        function alignY() {
            root.startYCell = Math.round(root.y / root.cellHeight);
            root.y = Qt.binding(function() { return root.startYCell * root.cellHeight; });
        }
        function alignWidth() {
            root.capturedHorizontalCellCount = Math.round(root.width / root.cellWidth)
            root.width = Qt.binding(function() {
                return root.parent.width * root.capturedHorizontalCellCount / root.horizontalCellCount
            });
        }
        function alignHeight() {
            root.capturedVerticalCellCount = Math.round(root.height / root.cellHeight)
            root.height = Qt.binding(function() {
                return root.parent.height * root.capturedVerticalCellCount / root.verticalCellCount
            });
        }

        function clamp(value, min, max) {
            return Math.min(Math.max(min, value), max);
        }
    }
}

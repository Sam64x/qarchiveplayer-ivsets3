import QtQuick.Controls 2.4
import QtQuick 2.7
import QtQml 2.3

import iv.colors 1.0
import iv.controls 1.0 as C
import iv.singletonLang 1.0

Rectangle {
    id: root
    width: background.width
    height: 24

    color: "transparent"
    border.width: 1
    border.color: normalColor

    property color normalColor: "#C71329"
    property color currentColor: normalColor

    property bool showText: true
    property bool pendingHide: false

    signal clicked()

    Canvas {
        id: background

        readonly property int leftPadding: 4
        readonly property int rightPadding: 4
        readonly property int contentWidth: background.leftPadding + archiveIcon.implicitWidth + textLabel.implicitWidth + background.rightPadding

        width: showText ? background.contentWidth : 24
        height: 24

        anchors.top: parent.top
        anchors.right: parent.right

        clip: true

        Behavior on width {
            NumberAnimation { duration: 260; easing.type: Easing.InOutQuad }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            const w = width
            const h = height
            const r = 8

            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(width, 0)

            ctx.lineTo(w, h - r)
            ctx.arcTo(w, h, w - r, h, r)

            ctx.lineTo(r, h)
            ctx.arcTo(0, h, 0, h - r, r)

            ctx.closePath()
            ctx.fillStyle = root.currentColor
            ctx.fill()
        }

        C.IVImage {
            id: archiveIcon
            name: "new_images/Archive mode play"
            width: 16
            height: 16
            sourceSize: Qt.size(16, 16)
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: 4
            }
        }

        Label {
            id: textLabel
            text: Language.getTranslate("Exit the archive", "Выйти из архива")

            anchors {
                verticalCenter: parent.verticalCenter
                left: archiveIcon.right
            }

            leftPadding: 4
            rightPadding: 4

            elide: Text.ElideRight
            opacity: showText ? 1 : 0
            font: IVColors.getFont("Label")
            color: IVColors.get("Colors/Text new/TxPrimaryThemed")

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            }
        }

        Timer {
            id: initialHideTimer
            interval: 5000
            running: true
            repeat: false
            onTriggered: {
                if (!hoverArea.containsMouse) {
                    showText = false
                } else {
                    pendingHide = true
                }
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                showText = true
                pendingHide = false

                root.currentColor = Qt.lighter(root.normalColor, 1.3)
                background.requestPaint()
            }
            onExited: {
                showText = false
                pendingHide = false

                root.currentColor = root.normalColor
                background.requestPaint()
            }
            onPressed: {
                root.currentColor = Qt.darker(root.normalColor, 1.3)
                background.requestPaint()
            }
            onReleased: {
                root.currentColor = containsMouse
                                   ? Qt.lighter(root.normalColor, 1.3)
                                   : root.normalColor
                background.requestPaint()
            }
            onClicked: root.clicked()
        }
    }
}

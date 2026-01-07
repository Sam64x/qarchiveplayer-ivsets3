import QtQml 2.1
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.0
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

import iv.colors 1.0
import iv.singletonLang 1.0
import iv.controls 1.0 as C

Item {
    id: root

    property real strokeWidth: 2
    property int rotationDuration: 500
    property int progress: 0
    property int stepInterval: timer.interval
    property int remainingSeconds: Math.ceil((100 - progress) * stepInterval / 1000)

    implicitWidth: 466
    implicitHeight: 32

    onProgressChanged: canvas.requestPaint()

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (progress >= 100) {
                progress = 0
            }
            timer.start()
        }
    }

    Rectangle {
        radius: 8
        anchors.fill: parent
        color: IVColors.get("Colors/Background new/BgFormOverVideo")

        RowLayout {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.leftMargin: 16
            anchors.bottomMargin: 4
            anchors.rightMargin: 8
            spacing: 4

            Canvas {
                id: canvas

                Layout.preferredHeight: 24
                Layout.preferredWidth: 24

                onPaint: {
                    var ctx = getContext("2d");
                    var cx = width/2, cy = height/2, r  = Math.min(cx, cy) - root.strokeWidth/2;
                    ctx.reset();
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, Math.PI*2);
                    ctx.lineWidth = root.strokeWidth;
                    ctx.strokeStyle = IVColors.get("Colors/Text new/TxTertiaryContrast");
                    ctx.stroke();


                    var start = -Math.PI/2;
                    var end = start + (root.progress/100)*Math.PI*2;
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, start, end);
                    ctx.lineWidth   = root.strokeWidth;
                    ctx.strokeStyle = IVColors.get("Colors/Text new/TxContrast");
                    ctx.stroke();
                }
                NumberAnimation on rotation {
                    from: 0; to: 360
                    duration: root.rotationDuration
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                    running: root.progress < 100
                }
            }

            Text {
                text: Language.getTranslate("Synchronization...", "Синхронизация...")
                font: IVColors.getFont("Label accent")
                color: IVColors.get("Colors/Text new/TxContrast")
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Language.getTranslate("About %1 sec. left.", "Осталось примерно: %1 сек.").arg(remainingSeconds)
                font: IVColors.getFont("Subtext")
                color: IVColors.get("Colors/Text new/TxSecondaryContrast")
                visible: root.progress < 100
            }

            C.IVButtonControl {
                implicitWidth: 24
                implicitHeight: 24
                source: "new_images/x-close"
                type: C.IVButtonControl.Type.Flat
                size: C.IVButtonControl.Size.Small
            }
        }
    }

    Timer {
        id: timer
        interval: 80
        repeat: true
        onTriggered: {
            if (progress < 100) {
                progress += 1
            } else {
                timer.stop()
            }
        }
    }
}

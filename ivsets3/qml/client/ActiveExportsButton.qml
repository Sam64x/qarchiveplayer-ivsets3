import QtQml 2.3
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import ArchiveComponents 1.0
import iv.singletonLang 1.0
import iv.controls 1.0 as Controls
import iv.colors 1.0

Controls.IVButtonControl {
    id: control

    horizontalPadding: 8

    text: ExportManager.activeExportsModel.count
    size: Controls.IVButtonControl.Size.Big
    type: Controls.IVButtonControl.Type.Tertiary
    checkable: true
    checked: artiveExportMenu.opened

    toolTipText: Language.getTranslate("Open exports", "Открыть выгрузки")
    toolTipVisible: !artiveExportMenu.opened && toolTipText.length > 0 && hovered

    source: {
        switch (ExportManager.activeExportsModel.generalStatus) {
        case 0:
        case 2:
            return "new_images/archive";
        case 3:
        case 4:
            return "new_images/alert-triangle";
        }
        return "";
    }

    onClicked: {
        if (artiveExportMenu.opened)
            artiveExportMenu.close()
        else
            artiveExportMenu.open()
    }

    contentItem: RowLayout {
        spacing: 4

        Loader {
            id: progressCircleLoader
            visible: active

            function updateActiveBinding() {
                active = Qt.binding(function() { return ExportManager.activeExportsModel.generalStatus === 1; })
            }

            Component.onCompleted: {
                updateActiveBinding();
            }

            sourceComponent: Item {
                implicitWidth: 24
                implicitHeight: 24

                Canvas {
                    readonly property int progress: ExportManager ? ExportManager.activeExportsModel.generalProgress : 0
                    readonly property var strokeStyle: IVColors.get("Colors/Text new/TxContrast")
                    readonly property var fillStyle: IVColors.get("Colors/Text new/TxContrast")

                    implicitWidth: 20
                    implicitHeight: 20
                    anchors.centerIn: parent

                    antialiasing: true

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        if (width <= 0 || height <= 0) {
                            return;
                        }

                        const centerX = width / 2;
                        const centerY = height / 2;
                        const radius = Math.min(width, height) / 2 - 2;

                        ctx.beginPath();
                        ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI, false);
                        ctx.strokeStyle = strokeStyle;
                        ctx.lineWidth = 2;
                        ctx.stroke();

                        if (progress > 0 && progress < 100) {
                            const startAngle = -Math.PI / 2;
                            const endAngle = startAngle + (2 * Math.PI * progress / 100);

                            ctx.beginPath();
                            ctx.moveTo(centerX, centerY);
                            ctx.arc(centerX, centerY, radius - 2, startAngle, endAngle, false);
                            ctx.lineTo(centerX, centerY);
                            ctx.closePath();
                            ctx.fillStyle = fillStyle;
                            ctx.fill();
                        }
                    }

                    onProgressChanged: {
                        requestPaint();
                    }
                }
            }
        }

        Loader {
            active: !progressCircleLoader.active
            visible: active

            sourceComponent: Controls.IVImage {
                asynchronous: true
                name: control.source

                Layout.preferredWidth: imageSize
                Layout.preferredHeight: imageSize
                sourceSize: Qt.size(imageSize, imageSize)
                fillMode : Image.PreserveAspectFit
                color: {
                    switch (ExportManager.activeExportsModel.generalStatus) {
                    case 3:
                    case 4:
                        return IVColors.get("Colors/Text new/TxCritical");
                    }
                    return control.contentColor;
                }
                Layout.alignment: layoutAlignment
            }
        }

        Text {
            text: control.text
            color: control.textColor
            font: textFont
        }

        Controls.IVImage {
            asynchronous: true
            name: control.chevroneSource
            Layout.preferredWidth: imageSize
            Layout.preferredHeight: imageSize
            Layout.alignment: Qt.AlignRight
            sourceSize: Qt.size(imageSize, imageSize)
            rotation: control.checked ? 180 : 0
            fillMode: Image.PreserveAspectFit
            color: control.contentColor
        }
    }

    Timer {
        id: uploadAndErrorSwitcher
        interval: 1000
        repeat: true
        running: ExportManager.activeExportsModel.generalStatus === 4
        onTriggered: {
            progressCircleLoader.active ^= true;
        }
        onRunningChanged: {
            if (!running) {
                progressCircleLoader.updateActiveBinding();
            }
        }
    }

    IVExportHistory {
        id: artiveExportMenu

        x: (parent.width - width) / 2
        y: parent.height + 6
    }
}

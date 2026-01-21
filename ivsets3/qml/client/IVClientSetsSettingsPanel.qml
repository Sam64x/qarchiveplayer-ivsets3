import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Dialogs 1.1
import QtQuick.Window 2.3

import iv.plugins.loader 1.0
import iv.sets.sets3 1.0
import iv.components.windows 1.0
import iv.colors 1.0
import iv.controls 1.0

Rectangle {
    id: root

    property var globalSignalsObject: null

    implicitWidth: 364
    implicitHeight: contentLayout.implicitHeight

    color: IVColors.get("Colors/Background new/BgContextMenuThemed")

    Flickable {
        anchors.fill: parent

        contentWidth: width
        contentHeight: contentLayout.implicitHeight + 2 * contentLayout.anchors.margins

        interactive: true
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
            visible: parent.contentHeight > parent.height
        }

        ColumnLayout {
            id: contentLayout

            anchors.fill: parent
            anchors.margins: 16

            spacing: 8

            RowLayout {
                spacing: 0

                Label {
                    Layout.fillWidth: true
                    Layout.maximumWidth: Math.floor(implicitWidth)

                    text: "Редактирование"
                    font: IVColors.getFont("Subtitle accent")
                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                }

                Item {
                    Layout.fillWidth: true
                }

                IVButton {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32

                    source: "new_images/x-close"
                    toolTipText: "Закрыть редактирование"
                    type: IVButton.Type.Helper

                    onClicked: {
                        editPanelOpened.value = "false";
                    }

                    IvVcliSetting {
                        id: editPanelOpened
                        name: "editPanel.opened"
                    }
                }
            }

            IVInputField {
                id: setNameField

                Layout.fillWidth: true

                onTextChanged: {
                    if (IVSetsManager.activeSet) {
                        IVSetsManager.activeSet.name = text;
                    }
                }

                Connections {
                    target: IVSetsManager
                    onActiveSetChanged: {
                        setNameField.text = IVSetsManager.activeSet.name;
                    }
                }

                Connections {
                    target: IVSetsManager.activeSet
                    onNameChanged: {
                        setNameField.text = IVSetsManager.activeSet.name;
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40

                radius: 8
                color: IVColors.get("Colors/Background new/BgFormTertiaryThemed")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Label {
                        Layout.fillWidth: true
                        Layout.maximumWidth: Math.floor(implicitWidth)

                        font.pixelSize: 14
                        text: "Свободное редактирование"
                        color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                    }

                    IVToggle {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 16
                        Layout.alignment: Qt.AlignRight

                        type: IVToggle.Type.Default
                        checkState: IVSetsManager.freeEditEnabled ? IVToggle.State.Checked : IVToggle.State.Unchecked

                        onClicked: {
                            IVSetsManager.freeEditEnabled = !IVSetsManager.freeEditEnabled;
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                spacing: 4

                Label {
                    text: "Сетка"
                    font.pixelSize: 14
                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40

                    radius: 8
                    color: IVColors.get("Colors/Background new/BgFormTertiaryThemed")

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Repeater {
                            model: ListModel {
                                ListElement {
                                    name: "Grid 1"
                                    value: IVSet.GridType.Quad
                                }
                                ListElement {
                                    name: "Grid 2"
                                    value: IVSet.GridType.TwoHeaderFocus
                                }
                                ListElement {
                                    name: "Grid 3"
                                    value: IVSet.GridType.ThreeCornersPlusQuad
                                }
                                ListElement {
                                    name: "Grid 4"
                                    value: IVSet.GridType.TopLeftFocus
                                }
                                ListElement {
                                    name: "Grid 5"
                                    value: IVSet.GridType.CenterFocus
                                }
                                ListElement {
                                    name: "Grid 6"
                                    value: IVSet.GridType.QuadCenterFocus
                                }
                                ListElement {
                                    name: "Grid Custom"
                                    value: IVSet.GridType.Custom
                                }
                            }

                            delegate: IVButton {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                enabled: model.value !== IVSet.GridType.Custom
                                source: "new_images/grids/" + model.name
                                type: IVSetsManager.activeSet && (model.value === IVSetsManager.activeSet.gridType)
                                      ? IVButton.Type.Primary
                                      : IVButton.Type.Tertiary

                                onClicked: {
                                    if (IVSetsManager.activeSet) {
                                        IVSetsManager.activeSet.gridType = model.value;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8

                active: IVSetsManager.activeSet
                        && (IVSetsManager.activeSet.gridType !== IVSet.GridType.ThreeCornersPlusQuad)
                visible: active

                sourceComponent: ColumnLayout {
                    spacing: 8

                    Loader {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32

                        active: IVSetsManager.activeSet.gridType !== IVSet.GridType.Custom
                        visible: active

                        sourceComponent: IVSlider {
                            id: slotSlider

                            anchors.fill: parent

                            type: IVButton.Type.Segmented
                            text: "Размер сетки"
                            minValue: privates.minSlotCount
                            maxValue: privates.maxSlotCount
                            value: IVSetsManager.activeSet.slotCount

                            onValueChanged: {
                                IVSetsManager.activeSet.slotCount = value;
                            }

                            Connections {
                                target: IVSetsManager.activeSet
                                onSlotCountChanged: {
                                    slotSlider.value = IVSetsManager.activeSet.slotCount;
                                }
                            }

                            Connections {
                                target: IVSetsManager
                                onActiveSetChanged: {
                                    slotSlider.value = IVSetsManager.activeSet.slotCount;
                                }
                            }
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32

                        active: IVSetsManager.activeSet.gridType === IVSet.GridType.Quad
                        visible: active

                        sourceComponent: IVSlider {
                            id: hSlotSlider

                            anchors.fill: parent

                            type: IVButton.Type.Segmented
                            text: "Столбцы"
                            minValue: privates.minSlotCount
                            maxValue: privates.maxSlotCount
                            value: IVSetsManager.activeSet.horizonalSlotCount

                            onValueChanged: {
                                IVSetsManager.activeSet.horizonalSlotCount = value;
                            }

                            Connections {
                                target: IVSetsManager.activeSet
                                onSlotCountChanged: {
                                    hSlotSlider.value = IVSetsManager.activeSet.horizonalSlotCount;
                                }
                            }

                            Connections {
                                target: IVSetsManager
                                onActiveSetChanged: {
                                    hSlotSlider.value = IVSetsManager.activeSet.horizonalSlotCount;
                                }
                            }
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32

                        active: IVSetsManager.activeSet.gridType === IVSet.GridType.Quad
                        visible: active

                        sourceComponent: IVSlider {
                            id: vSlotSlider

                            anchors.fill: parent

                            type: IVButton.Type.Segmented
                            text: "Строки"
                            minValue: privates.minSlotCount
                            maxValue: privates.maxSlotCount
                            value: IVSetsManager.activeSet.verticalSlotCount

                            onValueChanged: {
                                IVSetsManager.activeSet.verticalSlotCount = value;
                            }

                            Connections {
                                target: IVSetsManager.activeSet
                                onSlotCountChanged: {
                                    vSlotSlider.value = IVSetsManager.activeSet.verticalSlotCount;
                                }
                            }

                            Connections {
                                target: IVSetsManager
                                onActiveSetChanged: {
                                    vSlotSlider.value = IVSetsManager.activeSet.verticalSlotCount;
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Пропорции набора"
                        font.pixelSize: 14
                        color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                    }

                    RatioCombobox {
                        // Layout.fillWidth: true
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 40
                    }
                }

                // IVButtonControl {
                //     Layout.preferredWidth: 32
                //     Layout.preferredHeight: 40
                //     Layout.alignment: Qt.AlignBottom

                //     property bool active: true

                //     enabled: false
                //     type: active ? IVButton.Type.Tertiary : IVButton.Type.Helper
                //     source: active ? "new_images/Lock2" : "new_images/lock_open"

                //     onClicked: {
                //         active = !active;
                //     }
                // }

                // ColumnLayout {
                //     Layout.fillWidth: true

                //     Label {
                //         text: "Пропорции камер"
                //         font.pixelSize: 14
                //         color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                //     }

                //     RatioCombobox {
                //         Layout.fillWidth: true
                //         Layout.preferredHeight: 40

                //         enabled: false
                //     }
                // }
            }

            // RowLayout {
            //     Layout.fillWidth: true
            //     spacing: 0

            //     IVCheckBoxControl {
            //         enabled: false
            //     }

            //     Label {
            //         Layout.fillWidth: true
            //         Layout.maximumWidth: Math.floor(implicitWidth)

            //         font.pixelSize: 14
            //         text: "Превью с монитором"
            //         color: IVColors.get("Colors/Text new/TxPrimaryThemed")
            //     }

            //     Item {
            //         Layout.fillWidth: true
            //     }
            // }

            IVButton {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 40

                visible: IVSetsManager.activeSet && IVSetsManager.activeSet.isUser
                type: IVButton.Type.Tertiary
                source: "white/delete"
                toolTipText: "Удалить Набор"

                onClicked: {
                    removeSetDialog.open();
                }

                MessageDialog {
                    id: removeSetDialog

                    title: "Удаление набора"
                    text: "Вы уверены, что хотите удалить набор \"%1\" ?"
                        .arg(IVSetsManager.activeSet ? IVSetsManager.activeSet.name : "")
                    standardButtons: StandardButton.Apply | StandardButton.Cancel

                    onApply: {
                        customSets.deleteSet2(IVSetsManager.activeSet.name, IVSetsManager.activeSet.id);
                        root.globalSignalsObject.tabRemoved2(IVSetsManager.activeSet.name);
                        root.globalSignalsObject.setRemoved(IVSetsManager.activeSet.id, IVSetsManager.activeSet.name);
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                spacing: 8

                IVButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28

                    type: IVButton.Type.Secondary
                    source: "new_images/Undo"
                    text: "Вернуть"
                    enabled: IVSetsManager.activeSet && IVSetsManager.activeSet.isModified

                    onClicked: {
                        IVSetsManager.activeSet.resetConfig();
                    }
                }

                IVButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28

                    enabled: IVSetsManager.activeSet && IVSetsManager.activeSet.isModified
                    type: IVButton.Type.Primary
                    text: "Сохранить"

                    onClicked: {
                        const setType = IVSetsManager.activeSet.isUser ? "текущий" : "новый";
                        messageDialogSave.text = "Сохранить как %1 набор?".arg(setType);
                        messageDialogSave.open();
                    }

                    MessageDialog {
                        id: messageDialogSave

                        title: "Сохранение набора"
                        standardButtons: StandardButton.Apply | StandardButton.Cancel

                        onApply: {
                            saveSet(IVSetsManager.activeSet);
                        }

                        function saveSet(set) {
                            const config = IVSetsManager.getSetConfigToSave(set);
                            const configJson = JSON.parse(config);
                            customSets.saveSet2(set.initName(),
                                                configJson.setId,
                                                set.name,
                                                config);
                            set.saveConfigAsDefault();
                            if (!set.isUser) {
                                const prevId = set.id;
                                set.id = configJson.setId;
                                set.isUser = true;
                                root.globalSignalsObject.serverSetSaved(prevId, set.id, set.name);
                            }
                            else {
                                root.globalSignalsObject.setSaved(set.id, set.name);
                            }
                        }
                    }
                }
            }
        }
    }

    QtObject {
        id: privates

        readonly property int minSlotCount: IVSetsManager.activeSet
                                   ? gridTypeSlotBoundary[IVSetsManager.activeSet.gridType].minSlotCount
                                   : 1
        readonly property int maxSlotCount: IVSetsManager.activeSet
                                   ? gridTypeSlotBoundary[IVSetsManager.activeSet.gridType].maxSlotCount
                                   : 8
        readonly property var gridTypeSlotBoundary: (function() {
            const map = {};
            map[IVSet.GridType.Quad]                 = { minSlotCount: 1, maxSlotCount: 8 };
            map[IVSet.GridType.TwoHeaderFocus]       = { minSlotCount: 1, maxSlotCount: 8 };
            map[IVSet.GridType.ThreeCornersPlusQuad] = { minSlotCount: 1, maxSlotCount: 8 };
            map[IVSet.GridType.TopLeftFocus]         = { minSlotCount: 3, maxSlotCount: 8 };
            map[IVSet.GridType.CenterFocus]          = { minSlotCount: 4, maxSlotCount: 8 };
            map[IVSet.GridType.QuadCenterFocus]      = { minSlotCount: 5, maxSlotCount: 8 };
            map[IVSet.GridType.Custom]               = { minSlotCount: 1, maxSlotCount: 8 };
            return map;
        })()
    }

    IVCustomSets {
        id: customSets

        Component.onCompleted: {
            initWs();
        }
    }
}

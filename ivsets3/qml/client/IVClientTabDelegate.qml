import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import QtQuick.Dialogs 1.1
import QtQml 2.3
import QtGraphicalEffects 1.0

import iv.sets.sets3 1.0
import iv.plugins.loader 1.0
import iv.colors 1.0
import iv.controls 1.0

Rectangle {
    id: root

    property string viewType: ""
    property string name: ""
    property int innerIndex: -2
    property string type: ""
    property string tabId: ""
    property int currentIndex: -1
    property var globalSignalsObject: null
    property int modelSize: 0

    signal removeTab()
    signal tabRemoveLeft()
    signal tabRemoveRight()

    implicitWidth: 160 * privates.isize
    implicitHeight: 32 * privates.isize

    radius: 8 * privates.isize

    state: root.currentIndex === root.innerIndex ? "selected" : "normal"
    states:[
        State {
            name: "normal"
            PropertyChanges {
                target: root
                color: privates.defaultBackgroundColor
            }
            PropertyChanges {
                target: tabNameLabel
                color: privates.defaultContentColor
            }
            PropertyChanges {
                target: typeImage
                color: privates.defaultIconColor
            }
        },
        State {
            name: "selected"
            PropertyChanges {
                target: root
                color: privates.selectedBackgroundColor
            }
            PropertyChanges {
                target: tabNameLabel
                color: privates.selectedContentColor
            }
            PropertyChanges {
                target: typeImage
                color: privates.selectedIconColor
            }
        }
    ]

    IVToolTip {
        visible: tabNameLabel.truncated && tabMouseArea.containsMouse
        text: tabNameLabel.text
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        IVImage {
            id: typeImage

            Layout.preferredWidth: 20 * privates.isize
            Layout.preferredHeight: 20 * privates.isize

            name: privates.typeImagePath
        }

        Label {
            id: tabNameLabel

            Layout.fillWidth: true

            elide: Text.ElideRight
            text: root.type === "set"
                  ? privates.set && privates.set.name
                  : root.name
            font: IVColors.getFont("Subtext accent")
        }
    }

    IVContextMenuControl {
        id: moreMenu

        x: -20
        y: root.height

        bgColor : IVColors.get("Colors/Background new/BgContextMenuThemed")
        closePolicy: Popup.CloseOnPressOutside

        contentItem: Item {
            implicitWidth: 364 * privates.isize
            implicitHeight: moreMenuContentLayout.implicitHeight

            ColumnLayout {
                id: moreMenuContentLayout
                anchors.fill: parent
                spacing: 8

                IVInputField {
                    id: setNameField

                    Layout.fillWidth: true
                    Layout.preferredHeight: 48 * privates.isize

                    visible: privates.type2 === IVClientTabDelegate.Type.Set
                    text: privates.set && privates.set.name

                    onTextChanged: {
                        if (privates.set) {
                            privates.set.name = text;
                        }
                    }

                    Connections {
                        enabled: privates.set
                        target: privates.set
                        onNameChanged: {
                            setNameField.text = privates.set.name;
                        }
                    }
                }

                IVButton {
                    id: saveSetButton

                    Layout.fillWidth: true
                    Layout.preferredHeight: 32 * privates.isize

                    visible: privates.type2 === IVClientTabDelegate.Type.Set
                    enabled: privates.set && privates.set.isModified
                    type: IVButton.Type.Primary
                    text: "Сохранить"

                    onClicked: {
                        const setType = privates.set.isUser ? "текущий" : "новый";
                        messageDialogSave.text = "Сохранить как %1 набор?".arg(setType);
                        messageDialogSave.open();
                    }

                    MessageDialog {
                        id: messageDialogSave

                        title: "Сохранение набора"
                        standardButtons: StandardButton.Apply | StandardButton.Cancel

                        onApply: {
                            saveSet(privates.set);
                        }

                        function saveSet(set) {
                            const config = IVSetsManager.getSetConfigToSave(set);
                            const configJson = JSON.parse(config);
                            IVCustomSets.saveSet2(config);
                        }
                    }
                }

                function refreshMenu() {
                    menuListModel.clear();
                    if (privates.type2 === IVClientTabDelegate.Type.Set) {
                        const text = !privates.isArchive ? "Перейти в архив" : "Перейти в реалтайм";
                        menuListModel.append({
                            text: text,
                            icon: "new_images/toArchiveBtn",
                            action: "switch_viewType"
                        })
                    }
                    if (root.innerIndex > 0) {
                        menuListModel.append({
                            text: "Закрыть все вкладки слева",
                            icon: "new_images/chevron-left-big",
                            action: "close_left"
                        })
                    }
                    if (root.innerIndex !== root.modelSize - 1) {
                        menuListModel.append({
                            text: "Закрыть все вкладки справа",
                            icon: "new_images/chevron-right-big",
                            action: "close_right"
                        })
                    }
                    menuListModel.append({
                        text: "Закрыть",
                        icon: "new_images/x-close",
                        action: "close"
                    })
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: contentHeight

                    model: ListModel {
                        id: menuListModel
                    }

                    delegate: IVContextMenuItem {
                        width: parent.width

                        source: model.icon
                        text: model.text

                        onClicked: {
                            if (action === "switch_viewType") {
                                const viewType = !privates.isArchive ? "archive" : "realtime";
                                root.globalSignalsObject.tabAdded5(root.name, root.type, root.tabId, viewType);
                            }
                            else if (action === "close_left") {
                                root.tabRemoveLeft();
                            }
                            else if (action === "close_right") {
                                root.tabRemoveRight();
                            }
                            else if (action === "close") {
                                root.removeTab();
                            }
                            moreMenu.close();
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: tabMouseArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: {
            if (mouse.button & Qt.RightButton) {
                moreMenuContentLayout.refreshMenu();
                moreMenu.open();
            }
            else {
                const viewType = archive_fix2.value === "true" ? "archive" : root.viewType;
                root.globalSignalsObject.tabSelected5(root.name, root.type, root.tabId, viewType);
            }
            root.globalSignalsObject.tabUniqId = root.toString();
        }
    }

    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }

    IvVcliSetting {
        id: archive_fix2
        name: 'archive.fixVisible'
    }

    enum Type {
        Set,
        Camera,
        Map,
        Undefined
    }

    QtObject {
        id: privates

        readonly property var set: IVSetsManager.setsCount ? IVSetsManager.getSet(tabId) : null

        readonly property int type2: {
            switch (type) {
            case "set": return IVClientTabDelegate.Type.Set;
            case "camera": return IVClientTabDelegate.Type.Camera;
            case "map": return IVClientTabDelegate.Type.Map;
            default: return IVClientTabDelegate.Type.Undefined;
            }
        }

        readonly property string typeImagePath:
            type2 === IVClientTabDelegate.Type.Set && set && set.isModified ? "new_images/gridEdited" :
            type2 === IVClientTabDelegate.Type.Set ? "new_images/layout-grid-02" :
            type2 === IVClientTabDelegate.Type.Camera ? "new_images/cctv" :
            type2 === IVClientTabDelegate.Type.Map ? "new_images/Earth" :
            "new_images/help-circle.svg"

        readonly property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1
        readonly property bool isArchive: root.viewType === "archive"

        readonly property string defaultBackgroundColor: IVColors.get("Colors/Background new/BgFormTertiaryThemed")
        readonly property string defaultContentColor: IVColors.get("Colors/Text new/TxAccentThemed")
        readonly property string defaultIconColor: isArchive
                                                   ? IVColors.get("Colors/Text new/TxCritical")
                                                   : IVColors.get("Colors/Text new/TxAccentThemed")

        readonly property string selectedBackgroundColor: IVColors.get("Colors/Background new/BgBtnContrast")
        readonly property string selectedContentColor: IVColors.get("Colors/Text new/TxAccent")
        readonly property string selectedIconColor: isArchive
                                                    ? IVColors.get("Colors/Text new/TxCritical")
                                                    : IVColors.get("Colors/Text new/TxAccent")
    }
}

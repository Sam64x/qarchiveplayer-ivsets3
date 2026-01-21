import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4
import QtQml 2.3

import iv.plugins.loader 1.0
import iv.sets.sets3 1.0
import iv.colors 1.0
import iv.controls 1.0

Item {
    id: root

    property var customSets: null
    property var devices: null
    property var globSignalsObject: null
    property bool isSameOpened: false
    property bool isAllOpen: false

    readonly property bool setNeedCamsVisible: newSetsHideCames.value === "false" || newSetsHideCames.value === ""
    readonly property bool isFixArchive: archive_fix.value === "true"
    readonly property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1

    signal expandChanged()
    signal setRemoved()

    function switchExpandFlag() {
        isSameOpened ^= true;
        isAllOpen = isSameOpened;
        expandChanged();
    }

    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }

    IvVcliSetting {
        id: newSetsHideCames
        name: 'settings.new_sets_hide_cams'
    }

    IvVcliSetting {
        id: archive_fix
        name: 'archive.fixVisible'
    }

    ListView {
        id: contentListView

        anchors.fill: parent
        rightMargin: 10
        spacing: 1

        model: root.devices ? root.devices.children : []
        boundsBehavior: ListView.StopAtBounds
        cacheBuffer: 3000
        clip: true

        ScrollBar.vertical: ScrollBar {
            width: 8

            policy: ScrollBar.AlwaysOn
            visible: parent.contentHeight > parent.height
            contentItem: Rectangle {
                implicitWidth: parent.width
                implicitHeight: parent.height / contentListView.contentHeight
                radius: width / 2
                color: parent.pressed
                       ? IVColors.get("Colors/Text new/TxPrimaryThemed")
                       : IVColors.get("Colors/Background new/BgFormSecondaryThemed")
            }
        }

        delegate: componentChooser
    }

    Component {
        id: componentChooser
        Loader {
            id: itemLoader

            readonly property var view_type: modelData.getProp("view_type")
            readonly property var type: modelData.getProp("type")

            width: ListView.view.width - ListView.view.rightMargin

            sourceComponent: switch(view_type) {
                             case "group": return groupComponent;
                             case "item": return itemComponent;
                             default: return null;
                            }

            Binding {
                target: itemLoader.item
                property: "model"
                value: modelData
                when: itemLoader.item !== null
            }
        }
    }

    Component {
        id: groupComponent

        Item {
            id: groupRoot

            property var model: null

            readonly property string name: model && model.getProp("name_")
            readonly property string type: model && model.getProp("type")
            readonly property string view_type: model && model.getProp("view_type")
            readonly property var tabId: model && model.getProp("id_")
            readonly property bool opened: model && model.opened

            readonly property bool isSetGroup: type === "set"
            readonly property bool isLocal: model && Boolean(model.getProp("isLocal"))
            // property var isNotAvalCount: model && model.getProp("isNotAval")

            implicitHeight: groupContentLayout.implicitHeight

            visible: model && model.visible

            function open() {
                model.opened = true;
                root.isSameOpened = true;
            }

            function close() {
                model.opened = false;
            }

            Connections {
                target: root
                onExpandChanged: {
                    const notExpandableGroup = isSetGroup || groupRoot.type === "server";
                    if (notExpandableGroup) {
                        return;
                    }
                    groupRoot.model.opened = root.isAllOpen;
                }
            }

            ColumnLayout {
                id: groupContentLayout
                anchors.fill: parent
                spacing: 1

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40 * root.isize

                    radius: 8
                    color: groupMouseArea.pressed
                           ? IVColors.get("Colors/Background new/BgBtnTertiaryThemed-click")
                           : groupMouseArea.containsMouse
                             ? IVColors.get("Colors/Background new/BgBtnPrimary")
                             : IVColors.get("Colors/Background new/BgBtnSecondaryThemed")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 4

                        Loader {
                            Layout.preferredWidth: 20 * root.isize
                            Layout.preferredHeight: 20 * root.isize

                            active: groupRoot.type !== "custom"
                            visible: active

                            sourceComponent: IVImage {
                                readonly property var source: privates.groupTypeImage[groupRoot.type]

                                name: source ? source : "new_images/view_small"
                                color: IVColors.get("Colors/Text new/TxAccentThemed")
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        Loader {
                            Layout.preferredWidth: 24 * root.isize
                            Layout.preferredHeight: 24 * root.isize

                            active: !groupRoot.isSetGroup || root.setNeedCamsVisible
                            visible: active

                            sourceComponent: IVImage {
                                name: groupRoot.opened ? "new_images/chevron-down" : "new_images/chevron-right"
                                color: IVColors.get("Colors/Text new/TxAccentThemed")
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        Text {
                            id: nameLabel

                            Layout.fillWidth: true

                            text: groupRoot.name
                            elide: Text.ElideRight
                            font: IVColors.getFont("Text body accent")
                            color: IVColors.get("Colors/Text new/TxAccentThemed")
                        }

                        Loader {
                            Layout.preferredWidth: 20 * root.isize
                            Layout.preferredHeight: 20 * root.isize

                            active: groupRoot.isSetGroup && !groupRoot.isLocal
                            visible: active

                            sourceComponent: IVImage {
                                name: "new_images/Lock2"
                                color: IVColors.get("Colors/Text new/TxAccentThemed")
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: camsCountText.width + 8
                            Layout.preferredHeight: 24 * root.isize

                            radius: 8 * root.isize
                            color: IVColors.get("Colors/Background new/BgSegmentUnselected")

                            Text {
                                id: camsCountText

                                anchors.centerIn: parent

                                text: groupRoot.model ? groupRoot.model.getCurrentCount() : ""
                                clip: true
                                elide: Text.ElideRight
                                font: IVColors.getFont("Text body accent")
                                color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                            }

                            Rectangle {
                                width: errorCamsCountText.width + 8
                                height: errorCamsCountText.height
                                anchors.horizontalCenter: parent.right
                                anchors.verticalCenter: parent.top

                                visible: false//(groupRoot.isNotAvalCount!== undefined && groupRoot.isNotAvalCount>0)?true:false
                                radius: 8 * root.isize
                                color: IVColors.get("Colors/Statuse new/Defective")

                                Text {
                                    id: errorCamsCountText

                                    anchors.centerIn: parent

                                    text: "10"//groupRoot.isNotAvalCount
                                    font: IVColors.getFont("Subtext accent")
                                    color: IVColors.get("Colors/Text new/TxContrast")
                                }
                            }
                        }
                    }

                    IVToolTip {
                        text: groupRoot.name
                        visible: nameLabel.truncated && groupMouseArea.containsMouse
                    }

                    MouseArea {
                        id: groupMouseArea

                        z: -1
                        anchors.fill: parent

                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onClicked: {
                            if (mouse.button & Qt.RightButton) {
                                if (groupRoot.isSetGroup) {
                                    const point = groupRoot.mapToItem(root, mouseX, mouseY);
                                    groupContextMenu.x = point.x;
                                    groupContextMenu.y = point.y;
                                    groupContextMenu.name = groupRoot.name;
                                    groupContextMenu.type = groupRoot.type;
                                    groupContextMenu.tabId = groupRoot.tabId;
                                    groupContextMenu.isLocal = groupRoot.isLocal;
                                    groupContextMenu.open();
                                }
                            }
                            else if (groupRoot.view_type === "group") {
                                if(groupRoot.opened) {
                                    groupRoot.close();
                                }
                                else {
                                    groupRoot.open();
                                }
                            }
                        }

                        onDoubleClicked: {
                            if (groupRoot.isSetGroup) {
                                const viewType = root.isFixArchive ? "archive" : "realtime";
                                root.globSignalsObject.tabAdded5(groupRoot.name, groupRoot.type, groupRoot.tabId, viewType);
                            }
                        }
                    }
                }

                ListView {
                    id: componentListView

                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? componentListView.contentHeight : 0
                    Layout.leftMargin: 16
                    spacing: 1

                    visible: groupRoot.opened && (!groupRoot.isSetGroup || root.setNeedCamsVisible)
                    model: groupRoot.model && groupRoot.model.children
                    boundsBehavior: ListView.StopAtBounds
                    cacheBuffer: 3000
                    clip: true
                    delegate: componentChooser
                }
            }
        }
    }

    Component {
        id: itemComponent

        Rectangle {
            id: itemItem

            property var model: null
            property bool checkable: true
            property bool selected: false

            readonly property var itemName: model && model.getProp("name_")
            readonly property var type: model && model.getProp("type")
            readonly property var view_type: model && model.getProp("view_type")
            readonly property bool isAvailable: model && Boolean(model.getProp("is_available"))

            implicitHeight: 32 * root.isize

            visible: itemItem.model && itemItem.model.visible
            color: itemMouseArea.pressed
                   ? IVColors.get("Colors/Background new/BgBtnTertiaryThemed-click")
                   : itemMouseArea.containsMouse
                     ? IVColors.get("Colors/Background new/BgBtnTertiaryThemed-hover")
                     : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 4
                spacing: 4

                Loader {
                    Layout.preferredWidth: 16 * root.isize
                    Layout.preferredHeight: 16 * root.isize

                    active: itemItem.checkable
                    visible: active

                    sourceComponent: IVButtonControl {
                        enabled: false
                        source: "new_images/" + (itemItem.selected ? "check-fill" : "uncheck")
                        size: IVButtonControl.Size.Small
                        contentColor: IVColors.get("Colors/Text new/TxTertiaryThemed")
                    }
                }

                Text {
                    id: nameLabel

                    Layout.fillWidth: true

                    text: itemItem.itemName
                    elide: Text.ElideRight
                    font: IVColors.getFont("Label accent")
                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                }

                Loader {
                    Layout.preferredWidth: 24 * root.isize
                    Layout.preferredHeight: 24 * root.isize
                    Layout.rightMargin: 4

                    active: !itemItem.isAvailable
                    visible: active

                    sourceComponent: Rectangle {
                        radius: 16 * root.isize
                        color: IVColors.get("Colors/Statuse new/Defective")

                        IVImage {
                            anchors.centerIn: parent
                            width: 16 * root.isize
                            height: 16 * root.isize

                            name: "new_images/camera_warning"
                            color: IVColors.get("Colors/Text new/TxContrast")
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                }

                IVButtonControl {
                    Layout.preferredWidth: 24 * root.isize
                    Layout.preferredHeight: 24 * root.isize

                    enabled: privates.addToSetEnabled
                    backgroundColor: "transparent"
                    source: "new_images/plus_circle"
                    toolTipText: "Добавить в набор"
                    type: IVButtonControl.Type.Helper

                    onClicked: {
                        const obj = root.customSets.getTypePreset(itemItem.type, "key2", "string", itemItem.itemName);
                        const key2 = obj.params.key2.value[0];
                        const running = obj.params.running.value[0];
                        if (IVSetsManager.freeEditEnabled) {
                            IVSetsManager.activeSet.addZone(key2, running)
                        }
                        else {
                            IVSetsManager.activeSet.addZoneContentToFirstEmptyZone(key2, running)
                        }
                    }
                }
            }

            IVToolTip {
                text: itemItem.itemName
                visible: nameLabel.truncated && itemMouseArea.containsMouse
            }

            IVImage {
                id: dragItem

                property var dragData: ({})

                width: 36
                height: 24

                visible: Drag.active
                name: "black/dash"

                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2
            }

            MouseArea {
                id: itemMouseArea

                z: -1
                anchors.fill: parent

                hoverEnabled: true
                propagateComposedEvents: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                drag.target: dragItem
                drag.axis: Drag.XAndYAxis
                drag.threshold: 5

                onPressed: {
                    const obj = root.customSets.getTypePreset(itemItem.type, "key2", "string", itemItem.itemName);
                    if (!obj.params || !obj.params.key2 || !obj.params.running) {
                        return;
                    }

                    dragItem.dragData = {
                        key2: obj.params.key2.value[0],
                        running: obj.params.running.value[0],
                        indexInSavedSet: null
                    }

                    dragItem.x = mouseX - dragItem.width / 2;
                    dragItem.y = mouseY - dragItem.height / 2;
                    dragItem.Drag.start();
                }

                onReleased: {
                    dragItem.Drag.drop();
                }

                onClicked: {
                    if (mouse.button & Qt.RightButton) {
                        const point = mapToItem(root, mouseX, mouseY);
                        itemContextMenu.x = point.x;
                        itemContextMenu.y = point.y;
                        itemContextMenu.name = itemItem.itemName;
                        itemContextMenu.type = itemItem.type;
                        itemContextMenu.open();
                    }
                }

                onDoubleClicked: {
                    if (mouse.button & Qt.LeftButton) {
                        const viewType = root.isFixArchive ? "archive" : "realtime";
                        root.globSignalsObject.tabAdded5(itemItem.itemName, itemItem.type, "", viewType);
                    }
                }
            }
        }
    }

    IVContextMenuControl {
        id: itemContextMenu

        property string name
        property string type

        readonly property alias addToSetEnabled: privates.addToSetEnabled

        implicitWidth: 254 * root.isize

        closePolicy: Popup.CloseOnPressOutside

        onAddToSetEnabledChanged: {
            if (addToSetEnabled) {
                itemMenuModel.append({
                    text: "Добавить в набор",
                    icon: "new_images/Add-to-sets2",
                    action: "add_to_set"
                })
            }
            else {
                itemMenuModel.remove(1);
            }
        }

        contentItem: ListView {
            implicitHeight: contentHeight

            model: ListModel {
                id: itemMenuModel

                ListElement {
                    text: "Открыть"
                    icon: "new_images/expand"
                    action: "open"
                }
            }
            delegate: IVContextMenuItem {
                width: parent.width

                text: model.text
                source: model.icon

                onClicked: {
                    if (action === "open") {
                        root.globSignalsObject.tabAdded5(itemContextMenu.name, itemContextMenu.type, "", "realtime");
                    }
                    else if(action === "add_to_set")
                    {
                        const item = root.customSets.getTypePreset(itemContextMenu.type, "key2", "string", itemContextMenu.name);
                        const key2 = item.params.key2.value[0];
                        const running = item.params.running.value[0];
                        IVSetsManager.activeSet.addZoneContentToFirstEmptyZone(key2, running);
                    }
                    itemContextMenu.close();
                }
            }
        }
    }

    IVContextMenuControl {
        id: groupContextMenu

        property string name
        property string type
        property string tabId
        property bool isLocal

        implicitWidth: 254 * root.isize

        closePolicy: Popup.CloseOnPressOutside

        onIsLocalChanged: {
            if (isLocal) {
                groupContextMenuModel.append({
                    text: "Удалить",
                    icon: "new_images/del",
                    status: IVContextMenuItem.Type.Critical,
                    action: "remove"
                });
            }
            else {
                groupContextMenuModel.remove(2)
            }
        }

        contentItem: ListView {
            implicitHeight: contentHeight

            model: ListModel {
                id: groupContextMenuModel

                ListElement {
                    text: "Открыть"
                    status: IVContextMenuItem.Type.Default
                    icon: "new_images/expand"
                    action: "open"
                }
                ListElement {
                    text: "Открыть в архиве"
                    status: IVContextMenuItem.Type.Default
                    icon: "new_images/expand"
                    action: "open_archive"
                }
            }

            delegate: IVContextMenuItem {
                width: parent.width

                type: model.status
                source: model.icon
                text: model.text

                onClicked: {
                    if (action === "open") {
                        root.globSignalsObject.tabAdded5(groupContextMenu.name, groupContextMenu.type, groupContextMenu.tabId, "realtime");
                    }
                    else if (action === "open_archive") {
                        root.globSignalsObject.tabAdded5(groupContextMenu.name, groupContextMenu.type, groupContextMenu.tabId, "archive");
                    }
                    else if (action === "remove") {
                        root.customSets.deleteSet2(groupContextMenu.name, groupContextMenu.tabId);
                        root.setRemoved();
                    }
                    groupContextMenu.close();
                }
            }
        }
    }

    QtObject {
        id: privates

        readonly property bool addToSetEnabled: globSignalsObject.tabType === "set" && IVSetsManager.activeSet
                                                && (IVSetsManager.freeEditEnabled ? IVSetsManager.activeSet.zonesCount < 64
                                                                                  : IVSetsManager.activeSet.anyZoneEmpty)

        readonly property var groupTypeImage: (function() {
            const map = {};
            map["cameras"]  = "new_images/cctv"
            map["sets"]     = "new_images/set"
            map["set"]      = "new_images/set"
            map["repeater"] = "new_images/repeater"
            map["cluster"]  = "new_images/cluster"
            map["server"]   = "new_images/server_2"
            map["maps"]     = "new_images/Earth"
            return map;
        })()

    }
}

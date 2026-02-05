import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4
import QtQml 2.3
import QtQuick.Window 2.3

import iv.plugins.loader 1.0
import iv.sets.sets3 1.0
import iv.colors 1.0
import iv.controls 1.0
import iv.viewers.archiveplayer 1.0 as ArchivePlayerModule

Item {
    id: root

    property string listType
    property string searchText
    property var globSignalsObject: null
    property bool isSomeOpened: false

    readonly property bool setNeedCamsVisible: newSetsHideCames.value === "false" || newSetsHideCames.value === ""
    readonly property bool isFixArchive: archive_fix.value === "true"
    readonly property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1

    Flickable {
        id: flickableWrapper

        anchors.fill: parent

        contentWidth: width
        contentHeight: contentLayout.implicitHeight + contentLayout.anchors.bottomMargin
        bottomMargin: selectionFooter.actualHeight

        clip: true
        interactive: ScrollBar.vertical.visible
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            width: 8
            bottomPadding: selectionFooter.actualHeight

            policy: ScrollBar.AlwaysOn
            visible: parent.contentHeight > parent.height
            contentItem: Rectangle {
                implicitWidth: parent.width
                implicitHeight: parent.height / flickableWrapper.contentHeight
                radius: width / 2
                color: parent.pressed
                       ? IVColors.get("Colors/Text new/TxPrimaryThemed")
                       : IVColors.get("Colors/Background new/BgFormSecondaryThemed")
            }
        }

        ColumnLayout {
            id: contentLayout

            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 4
            spacing: 1

            Repeater {
                model: IVCustomSets.currentUser === "guest" ? [] : sourcesModel.children
                delegate: componentChooser
            }
        }
    }

    Loader {
        id: selectionFooter

        readonly property real actualHeight: active ? height + anchors.bottomMargin : 0
        readonly property int selectedSourcesCount: sourcesModel.selectedCamerasCount
                                                    + sourcesModel.selectedMapsCount

        width: parent.width
        height: 40 * root.isize
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4

        active: selectedSourcesCount
        visible: active

        sourceComponent: Rectangle {
            color: IVColors.get("Colors/Background new/BgFormAccent")
            radius: 12 * root.isize

            MouseArea {
                id: removingListElementHover
                anchors.fill: parent
                hoverEnabled: true
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                RowLayout {
                    spacing: 4

                    IVCheckBoxControl {
                        text: selectedSourcesCount
                        type: IVCheckBoxControl.Type.Contrast
                        checked: true

                        onCheckedChanged: {
                            root.clearSelection();
                        }
                    }

                    Text {
                        id: selectedText
                        text: "из %2".arg(sourcesModel.sourcesCount)
                        font: IVColors.getFont("Label")
                        color: IVColors.get("Colors/Text new/TxSecondaryContrast")
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                IVButtonControl {
                    enabled: sourcesModel.selectedMapsCount === 0
                             && (IVSetsManager.activeSet.emptyZonesCount >= selectionFooter.selectedSourcesCount)
                    horizontalPadding: 8
                    type: IVButtonControl.Type.Secondary
                    size: IVButtonControl.Size.Small
                    text: "Добавить"

                    onClicked: {
                        const selectedCamerasNames = sourcesModel.getSelectedCameras();
                        for (var i = 0; i < selectedCamerasNames.length; i++) {
                            IVSetsManager.activeSet.addZoneContentToFirstEmptyZone(selectedCamerasNames[i], true);
                        }
                        root.clearSelection();
                    }
                }

                Loader {
                    active: root.globSignalsObject.tabType === "set"
                            && root.globSignalsObject.tabViewType === "archive"
                            && ArchivePlayerModule.ExportManager.commonTimeline
                            && ArchivePlayerModule.ExportManager.commonTimeline.exportMode
                    visible: active

                    sourceComponent: ArchivePlayerModule.ExportSettingsButton {
                        width: undefined
                        height: undefined
                        horizontalPadding: 8
                        enabled: sourcesModel.selectedMapsCount === 0
                        type: IVButtonControl.Type.Secondary
                        size: IVButtonControl.Size.Small
                        text: "Выгрузить"
                        source: ""
                        toolTipVisible: false

                        archiveId: ArchivePlayerModule.ExportManager.archiveId
                        rootRef: root.globSignalsObject.clientRect
                        externalFromTime: ArchivePlayerModule.ExportManager.commonTimeline.exportBounds.left
                        externalToTime: ArchivePlayerModule.ExportManager.commonTimeline.exportBounds.right
                        useExternalBounds: true
                        applyBounds: function(fromTime, toTime) {
                            ArchivePlayerModule.ExportManager.commonTimeline.setExportBounds(fromTime, toTime)
                        }

                        onClicked: {
                            exportCameraIds = sourcesModel.getSelectedCameras();
                        }
                    }
                }
            }
        }
    }

    Component {
        id: componentChooser

        Loader {
            readonly property var viewType: modelData.viewType

            Layout.fillWidth: true

            active: modelData.visible
            visible: active

            sourceComponent: switch(viewType) {
                case "group": return groupComponent;
                case "item": return itemComponent;
                default: return null;
            }

            onStatusChanged: {
                if (status === Loader.Ready) {
                    item.model = modelData
                }
            }
        }
    }

    Component {
        id: groupComponent

        Item {
            id: groupRoot

            property var model: null

            readonly property string name: model && model.name
            readonly property string type: model && model.type
            readonly property string viewType: model && model.viewType
            readonly property var tabId: model && model.setId
            readonly property bool opened: model && model.opened
            readonly property bool isSetGroup: type === "set"
            readonly property bool isLocal: model && model.isLocal
            readonly property var unavailableCount: model && model.unavailableCount
            readonly property var count: model && model.count
            readonly property var groupColor: model && model.groupColor

            implicitHeight: visible ?  groupContentLayout.implicitHeight : 0

            visible: model && model.visible

            function open() {
                model.opened = true;
                root.isSomeOpened = true;
            }

            function close() {
                model.opened = false;
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
                                color: groupRoot.groupColor || IVColors.get("Colors/Text new/TxAccentThemed")
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

                        Loader {
                            Layout.preferredWidth: 24 * root.isize
                            Layout.preferredHeight: 24 * root.isize

                            active: groupRoot.type === "custom" && groupRoot.groupColor
                            visible: active

                            sourceComponent: Rectangle {
                                radius: width / 2
                                color: groupRoot.groupColor
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

                            visible: groupRoot.count
                            radius: 8 * root.isize
                            color: IVColors.get("Colors/Background new/BgSegmentUnselected")

                            Text {
                                id: camsCountText

                                anchors.centerIn: parent

                                text: groupRoot.count
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

                                visible: Boolean(groupRoot.unavailableCount)
                                radius: 8 * root.isize
                                color: IVColors.get("Colors/Statuse new/Defective")

                                Text {
                                    id: errorCamsCountText

                                    anchors.centerIn: parent

                                    text: String(groupRoot.unavailableCount)
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

                        hoverEnabled: groupRoot.visible
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
                            else if (groupRoot.viewType === "group") {
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

                Loader {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16

                    active: groupRoot.opened && (!groupRoot.isSetGroup || root.setNeedCamsVisible)
                            && groupRoot.model && groupRoot.model.children.length
                    visible: active

                    sourceComponent: ColumnLayout {
                        spacing: 1

                        Repeater {
                            model: groupRoot.model && groupRoot.model.children
                            delegate: componentChooser
                        }
                    }
                }
            }
        }
    }

    Component {
        id: itemComponent

        Rectangle {
            id: itemItem

            property var model: null

            readonly property var itemName: model && model.name
            readonly property var type: model && model.type
            readonly property var selected: model && model.selected
            readonly property bool isAvailable: model && model.available

            implicitHeight: visible ? 32 * root.isize : 0

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

                IVCheckBoxControl {
                    enabled: itemItem.type === "camera"
                    checked: itemItem.selected
                    size: IVCheckBoxControl.Size.Small

                    onClicked: {
                        root.selectItem(itemItem.type, itemItem.itemName, !itemItem.selected);
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

                    active: itemItem.type === "camera" && !itemItem.isAvailable
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

                    enabled: itemItem.type === "camera" && privates.singleAddToSetEnabled
                    backgroundColor: "transparent"
                    source: "new_images/plus_circle"
                    toolTipText: "Добавить в набор"
                    type: IVButtonControl.Type.Helper

                    onClicked: {
                        if (IVSetsManager.freeEditEnabled) {
                            IVSetsManager.activeSet.addZone(itemItem.itemName, true)
                        }
                        else {
                            IVSetsManager.activeSet.addZoneContentToFirstEmptyZone(itemItem.itemName, true)
                        }
                    }
                }
            }

            IVToolTip {
                text: itemItem.itemName
                visible: nameLabel.truncated && itemMouseArea.containsMouse
            }

            MouseArea {
                id: itemMouseArea

                readonly property bool isDragEnabled: itemItem.type === "camera" && !IVSetsManager.freeEditEnabled
                                                      && privates.dragEnabled

                z: -1
                anchors.fill: parent

                hoverEnabled: true
                propagateComposedEvents: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: isDragEnabled ? Qt.OpenHandCursor : Qt.ArrowCursor

                drag.target: dragItem
                drag.axis: Drag.XAndYAxis
                drag.threshold: 5

                onPressed: {
                    if (!isDragEnabled) {
                        return;
                    }

                    dragItem.dragData = {
                        key2: itemItem.itemName,
                        running: true,
                        indexInSavedSet: null,
                        replaceContent: Boolean(mouse.modifiers & Qt.ControlModifier)
                    }

                    const globalPosition = mapToItem(Window.contentItem, mouse.x, mouse.y);
                    dragItem.x = globalPosition.x - dragItem.width / 2;
                    dragItem.y = globalPosition.y - dragItem.height / 2;
                    dragItem.Drag.start();
                }

                onReleased: {
                    dragItem.Drag.drop();
                }

                onClicked: {
                    if (itemItem.type !== "camera") {
                        return;
                    }

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

    IVImage {
        id: dragItem

        property var dragData: ({})
        property bool aboveSlot: false
        property bool slotEmpty: false
        property var cursorShape: aboveSlot && !slotEmpty && !dragData.replaceContent
                                  ? Qt.ForbiddenCursor
                                  : Qt.ClosedHandCursor

        width: 36
        height: 24

        parent: Overlay.overlay
        visible: Drag.active
        name: "black/dash"

        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        MouseArea {
            anchors.fill: parent
            cursorShape: dragItem.cursorShape
        }
    }

    IVContextMenuControl {
        id: itemContextMenu

        property string name
        property string type

        readonly property alias singleAddToSetEnabled: privates.singleAddToSetEnabled

        implicitWidth: 254 * root.isize

        closePolicy: Popup.CloseOnPressOutside

        onSingleAddToSetEnabledChanged: {
            if (singleAddToSetEnabled) {
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
                    else if(action === "add_to_set") {
                        IVSetsManager.activeSet.addZoneContentToFirstEmptyZone(itemContextMenu.name, true);
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
                        IVCustomSets.deleteSet2(groupContextMenu.tabId);
                    }
                    groupContextMenu.close();
                }
            }
        }
    }

    function clearSelection() {
        sourcesModel.clearSourcesSelection();
        sourcesModel.clearSelection();
    }

    function selectItem(type, name, value) {
        if (type === "camera") {
            sourcesModel.changeCameraSelected(name, value);
            sourcesModel.updateSelectedCameras(name, value);
        }
        else if (type === "map") {
            sourcesModel.changeMapSelected(name, value);
            sourcesModel.updateSelectedMaps(name, value);
        }
    }

    function switchExpandFlag() {
        isSomeOpened ^= true;
        sourcesModel.switchExpandAll(isSomeOpened);
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

    Connections {
        target: IVCustomSets

        onSourcesReadyChanged: {
            if (IVCustomSets.sourcesReady) {
                sourcesModel.updateSources();
            }
        }

        onSetsUpdated: {
            if (root.listType === "flat" || root.listType === "custom") {
                sourcesModel.changeGroup();
            }
        }
    }

    onListTypeChanged: {
        sourcesModel.changeGroup();
        if (searchText) {
            filterDelay.restart();
        }
    }

    Component.onCompleted: {
        sourcesModel.updateSources();
    }

    onSearchTextChanged: {
        filterDelay.restart();
    }

    Timer {
        id: filterDelay
        interval: 300
        onTriggered: {
            sourcesModel.search(root.searchText);
        }
    }

    SourceTree {
        id: sourcesModel

        function updateSources() {
            initSources();
            changeGroup();
        }

        function changeGroup() {
            switch(root.listType) {
            case "flat":
                initFlat();
                break;
            case "fact":
                initFact();
                break;
            case "custom":
                initCustom();
                break;
            }
        }
    }

    QtObject {
        id: privates

        readonly property bool isSetTabActive: globSignalsObject.tabType === "set" && IVSetsManager.activeSet
        readonly property bool singleAddToSetEnabled: isSetTabActive && (IVSetsManager.freeEditEnabled
                                                                         ? IVSetsManager.activeSet.zonesCount < 64
                                                                         : IVSetsManager.activeSet.emptyZonesCount > 0)

        readonly property bool dragEnabled: isSetTabActive && (root.globSignalsObject.ctrlPressed
                                            || IVSetsManager.activeSet.emptyZonesCount > 0)

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

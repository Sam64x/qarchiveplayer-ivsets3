import QtQuick 2.11
import QtQml 2.3
import QtQml.Models 2.1
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtQuick.Window 2.3

import iv.controls 1.0
import iv.sets.sets3 1.0
import iv.plugins.loader 1.0

import iv.viewers.archiveplayer 1.0 as ArchivePlayerModule
import iv.viewers.viewer 1.0 as ViewerModule

Item {
    id: root

    property var globalSignalsObject: null
    property var commonArchiveManager: null

    property string initSetName
    property string initSetId

    property bool isRealtime: true
    property bool isFullscreen: false

    implicitWidth: contentLayout.implicitWidth
    implicitHeight: contentLayout.implicitHeight

    Component.onCompleted: {
        root.tryCreateAndActivateSet(initSetName, initSetId)
    }

    Component.onDestruction: {
        privates.removeCreatedZones();
    }

    function tryCreateAndActivateSet(tabName, setId) {
        if (tabName && setId) {
            if (setId === "new_set") {
                const createdNewSet = IVSetsManager.createNewSet(tabName);
                IVSetsManager.setActiveSet(createdNewSet);
            }
            else {
                var set = IVSetsManager.getSet(setId);
                if (!set) {
                    const setJson = IVCustomSets.getZonesCommon(setId);
                    set = IVSetsManager.createSet(JSON.parse(setJson));
                }

                if (set) {
                    IVSetsManager.setActiveSet(set);
                }
            }
        }
    }

    property var zoneObjectInFullscreen: null
    Connections {
        target: globalSignalsObject

        onTabSelected5: function (tabName, type, setId, viewType) {
            if (type !== "set") {
                return;
            }

            isFullscreen = false;
            if (zoneObjectInFullscreen) {
                zoneObjectInFullscreen.destroy();
                privates.createdZones.clear()
            }


            root.isRealtime = viewType === 'realtime';

            root.tryCreateAndActivateSet(tabName, setId)

            if (root.isRealtime) {
                root.globalSignalsObject.setToRealtime();
            }
            else {
                root.globalSignalsObject.setToArchive();
            }
        }

        onRemoveZoneContent: function(indexInSet) {
            if (IVSetsManager.activeSet) {
                IVSetsManager.activeSet.removeZoneContent(indexInSet);
            }
        }

        onCommand1: function(command, sender, params) {
            if (command === "viewers:fullscreen") {
                root.isFullscreen = !root.isFullscreen;

                var zoneObject = null;
                for (var i = 0; i < privates.createdZones.count; i++) {
                    const iZoneObject = privates.createdZones.get(i);
                    if (iZoneObject && (iZoneObject.viewer === sender)) {
                        zoneObject = iZoneObject;
                        break;
                    }
                }
                if (!zoneObject) {
                    return;
                }

                if (root.isFullscreen) {
                    zoneObject.parent = root;
                    zoneObject.anchors.fill = root;
                    zoneObjectInFullscreen = zoneObject;
                }
                else {
                    const slot = privates.slotsRepeater.itemAt(zoneObject.indexInSavedSet);
                    if (!slot) {
                        console.log("Slot when disabling fullscreen not found");
                    }
                    zoneObject.parent = slot.content;
                    zoneObject.anchors.fill = slot.content;
                    zoneObjectInFullscreen = null;
                }
            }
        }
    }

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent

        Loader {
            id: slotGridLoader

            Layout.fillWidth: true
            Layout.fillHeight: true

            active: IVSetsManager.activeSet
            visible: active

            sourceComponent: SlotGrid {}

            onActiveChanged: {
                if (!active) {
                    privates.removeCreatedZones();
                }
            }
        }

        ArchivePlayerModule.IVCommonArchiveStrip {
            id: commonArchiveStrip

            readonly property bool isArchiveLineVisible: !root.isRealtime
                                                         && !root.isFullscreen
                                                         && !commonArchiveStrip.hasFullscreenPlayer

            Layout.fillWidth: true
            Layout.preferredHeight: height

            visible: isArchiveLineVisible && IVSetsManager.activeSet
            players: root.commonArchiveManager.commonArchivePlayers
            rootRef: root
            Component.onCompleted: {
                root.commonArchiveManager.commonArchiveStrip = commonArchiveStrip;
            }

            Component.onDestruction: {
                if (root.commonArchiveManager.commonArchiveStrip === commonArchiveStrip)
                    root.commonArchiveManager.commonArchiveStrip = null;
            }
        }
    }

    Component {
        id: zoneComponent

        Item {
            id: dragWrapper

            property bool isRealtime
            property string key2
            property bool running
            property int indexInSavedSet

            readonly property var viewer: viewerLoader.item

            Loader {
                id: viewerLoader
                anchors.fill: parent
                sourceComponent: root.isRealtime
                                 ? viewerComponent
                                 : new_arc_strip.value === "true"
                                   ? archivePlayerMinComponent
                                   : archivePlayerMinComponent
            }

            MouseArea {
                id: dragMouseArea

                anchors.fill: parent

                visible: !IVSetsManager.freeEditEnabled
                enabled: visible
                cursorShape: root.globalSignalsObject.ctrlPressed ? Qt.OpenHandCursor : Qt.ArrowCursor

                drag.target: dragItem
                drag.axis: Drag.XAndYAxis
                drag.threshold: 5

                onPressed: {
                    const shouldDrag = (mouse.button === Qt.LeftButton) && (mouse.modifiers & Qt.ControlModifier)
                    if (!shouldDrag) {
                      mouse.accepted = false;
                      return;
                    }
                    const globalPosition = mapToItem(Window.contentItem, mouse.x, mouse.y);
                    dragItem.x = globalPosition.x - dragItem.width / 2;
                    dragItem.y = globalPosition.y - dragItem.height / 2;

                    dragItem.dragData = {
                        indexInSavedSet: dragWrapper.indexInSavedSet,
                        key2: dragWrapper.key2
                    }

                    dragItem.Drag.start();
                }

                onReleased: {
                    dragItem.Drag.drop();
                }
            }

            Component {
                id: viewerComponent
                ViewerModule.IVViewer {
                    key2: dragWrapper.key2
                    running: dragWrapper.running
                    indexInSavedSet: dragWrapper.indexInSavedSet
                    globSignalsObject: root.globalSignalsObject
                    isRealtime: root.isRealtime
                    globalComponent: root.commonArchiveManager
                }
            }

            Component {
                id: archivePlayerMinComponent
                ArchivePlayerModule.IVArchivePlayerMin {
                    key2: dragWrapper.key2
                    running: dragWrapper.running
                    indexInSavedSet: dragWrapper.indexInSavedSet
                    viewer_command_obj: viewerCommandProxy
                    globalComponent: root.commonArchiveManager
                }
            }

            // Component {
            //     id: archivePlayerComponent
            //     ArchivePlayerModule.IVArchivePlayer {
            //         key2: dragWrapper.key2
            //         running: dragWrapper.running
            //         viewer_command_obj: viewerCommandProxy
            //     }
            // }

            QtObject {
                id: viewerCommandProxy
                function command_to_viewer(command) {
                    archiveHelper.handleViewerCommand(command,
                                             dragWrapper.viewer,
                                             {
                                                 indexInSavedSet: dragWrapper.indexInSavedSet
                                             });
                }
            }
        }
    }

    IVImage {
        id: dragItem

        property var dragData: ({})
        property bool aboveSlot: false
        property bool slotEmpty: false

        width: 36
        height: 24

        parent: Overlay.overlay
        visible: Drag.active
        name: "black/dash"

        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.ClosedHandCursor
        }
    }

    Connections {
        enabled: IVSetsManager.activeSet
        target: privates.slotsRepeater

        onItemAdded: function (index, slot) {
            privates.createZone(slot);
        }

        onItemRemoved: function (index, slot) {
            privates.removeZone(slot);
        }
    }

    Connections {
        target: IVSetsManager.activeSet

        onZoneContentChanged: function(zoneIndex) {
            const slot = privates.slotsRepeater.itemAt(zoneIndex);
            if (!slot) {
                return;
            }

            var isSlotHasZone = false;

            for (var i = 0; i < privates.createdZones.count; i++) {
                const zoneObject = privates.createdZones.get(i);
                if (zoneObject.parent === slot.content) {
                    isSlotHasZone = true;
                    break;
                }
            }

            const isZoneContentEmpty = slot.zone.type === "empty";
            const isZoneContentAdded = !isZoneContentEmpty && !isSlotHasZone;
            const isZoneContentRemoved = isZoneContentEmpty && isSlotHasZone;
            if (isZoneContentAdded) {
                privates.createZone(slot);
            }
            else if (isZoneContentRemoved) {
                privates.removeZone(slot);
            }
        }
    }

    QtObject {
        id: privates

        readonly property var createdZones: ObjectModel {}
        readonly property var slotsRepeater: slotGridLoader.item && slotGridLoader.item.slotsRepeater

        onSlotsRepeaterChanged: {
            if (slotsRepeater) {
                for (var i = 0; i < slotsRepeater.count; i++) {
                    const slot = slotsRepeater.itemAt(i);
                    createZone(slot);
                }
            }
        }

        function createZone(slot) {
            const zone = slot.zone;
            if (!zone || zone.type === "empty") {
                return;
            }

            const zoneObject = zoneComponent.createObject(slot.content, {
                isRealtime: root.isRealtime,
                key2: Qt.binding(function() { return zone.key2; }),
                running: Qt.binding(function() { return zone.running; }),
                indexInSavedSet: Qt.binding(function() { return zone.setIndex; })
            });

            if (zoneObject) {
                zoneObject.anchors.fill = zoneObject.parent;
                privates.createdZones.append(zoneObject);
            }
        }

        function removeZone(slot) {
            for (var i = 0; i < createdZones.count; i++) {
                const zoneObject = createdZones.get(i);
                if (zoneObject.parent === slot.content) {
                    createdZones.remove(i);
                    zoneObject.destroy();
                    return;
                }
            }
        }

        function removeCreatedZones() {
            while (createdZones.count !== 0) {
                const zoneLoaderToRemove = createdZones.get(0);
                createdZones.remove(0);
                zoneLoaderToRemove.destroy();
            }
        }
    }

    IvVcliSetting {
        id: new_arc_strip
        name: 'archive.new_strip'
    }

    QtObject {
        id: archiveHelper

        function handleViewerCommand(command, sender, params) {
            if (command === "viewers:fullscreen") {
                root.globalSignalsObject.command1(command, sender, {});
            }
            else if (command === "viewers:switch") {
                const tab = {
                    tabName: IVSetsManager.activeSet.name,
                    type: "set",
                    setId: IVSetsManager.activeSet.id,
                    viewType: root.isRealtime ? "archive" : "realtime"
                }
                root.globalSignalsObject.tabAdded5(tab.tabName, tab.type, tab.setId, tab.viewType)
            }
            else if (command === "sets:area:removecamera2") {
                root.globalSignalsObject.removeZoneContent(params.indexInSavedSet);
            }
        }
    }
}

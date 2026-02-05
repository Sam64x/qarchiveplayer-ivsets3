import QtQuick 2.11
import QtQml 2.3
import QtQuick.Layouts 1.3

import iv.sets.sets3 1.0

import iv.viewers.viewer 1.0 as ViewerModule
import iv.mapviewer 1.0 as MapViewerModule
import iv.comcomp 1.0 as ComCompModule

Item {
    id: root

    property var globalSignalsObject: null

    implicitWidth: 500
    implicitHeight: 500

    ColumnLayout {
        anchors.fill: parent

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true

            active: privates.tabType === 'client_settings'
            visible: active

            sourceComponent: ComCompModule.IVSettingsTab {}
        }

        Loader {
            id: mapLoader

            property string jsonDataFileName

            Layout.fillWidth: true
            Layout.fillHeight: true

            active: privates.tabType === 'map'
            visible: active

            sourceComponent: MapViewerModule.QMapViewer {
                jsonDataFileName: mapLoader.jsonDataFileName
                globalComponentObject: root.globalSignalsObject
            }
        }

        Loader {
            id: cameraLoader

            property string key2
            property bool running
            property bool isRealtime

            Layout.fillWidth: true
            Layout.fillHeight: true

            active: privates.tabType === 'camera'
            visible: active

            sourceComponent: ViewerModule.IVViewer {
                key2: cameraLoader.key2
                running: cameraLoader.running
                isRealtime: cameraLoader.isRealtime
                globSignalsObject: root.globalSignalsObject
                globalComponent: _commonArchiveManager
            }
        }

        Loader {
            id: setsZoneLoader

            property string initSetName
            property string initSetId
            property bool isRealtime

            Layout.fillWidth: true
            Layout.fillHeight: true

            active: privates.tabType === 'set'
            visible: active

            sourceComponent: IVClientSetsZone {
                globalSignalsObject: root.globalSignalsObject
                commonArchiveManager: _commonArchiveManager
                initSetName: setsZoneLoader.initSetName
                initSetId: setsZoneLoader.initSetId
                isRealtime: setsZoneLoader.isRealtime
            }
        }
    }

    Connections {
        target: globalSignalsObject

        onTabSelected5: function (tabName, type, setId, viewType) {
            if (type === "camera") {
                cameraLoader.key2 = tabName;
                cameraLoader.running = true;
                cameraLoader.isRealtime = viewType === 'realtime';
            }

            if (type === "map") {
                mapLoader.jsonDataFileName = tabName;
            }

            if (type === "set") {
                setsZoneLoader.initSetName = tabName;
                setsZoneLoader.initSetId = setId;
                setsZoneLoader.isRealtime = viewType === 'realtime';
            }

            privates.tabType = type;
        }
    }

    QtObject {
        id: _commonArchiveManager

        property var commonArchivePlayers: []
        property var commonArchiveStrip: null

        function notifyCommonArchiveStrip() {
            if (commonArchiveStrip) {
                commonArchiveStrip.players = commonArchivePlayers;
            }
        }

        function registerArchivePlayerMin(player) {
            if (player === null || player === undefined)
                return;

            if (commonArchivePlayers.indexOf(player) !== -1)
                return;

            var updated = commonArchivePlayers.concat([player]);
            commonArchivePlayers = updated;
            notifyCommonArchiveStrip();
        }

        function unregisterArchivePlayerMin(player) {
            if (player === null || player === undefined)
                return;

            var index = commonArchivePlayers.indexOf(player);
            if (index === -1)
                return;

            var updated = commonArchivePlayers.slice();
            updated.splice(index, 1);
            commonArchivePlayers = updated;
            notifyCommonArchiveStrip();
        }
    }

    QtObject {
        id: privates

        property string tabType: "set"
    }
}

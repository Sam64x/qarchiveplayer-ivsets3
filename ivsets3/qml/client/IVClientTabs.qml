import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import QtGraphicalEffects 1.0

import iv.singletonLang 1.0
import iv.sets.sets3 1.0
import iv.components.windows 1.0
import iv.plugins.loader 1.0
import iv.colors 1.0
import iv.controls 1.0 as Controls

Item {
    id: root

    property var globalSignalsObject: null

    implicitWidth: contentLayout.implicitWidth
    implicitHeight: 32

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: 4

        Loader {
            Layout.preferredWidth: 48 * privates.isize
            Layout.fillHeight: true

            active: eventsMaps.value === "true"
            visible: active

            sourceComponent: Controls.IVButton {
                source: "new_images/" + (privates.isMapInit ? "pause" : "play")
                toolTipText: "Автооткрытие карт"

                onClicked: {
                    if(privates.isMapInit) {
                        privates.isMapInit = false;
                        IVCustomSets.deinitMap();
                    }
                    else {
                        privates.isMapInit = true;
                        IVCustomSets.initMap();
                    }
                }
            }
        }

        Loader {
            Layout.preferredWidth: 48 * privates.isize
            Layout.fillHeight: true

            active: autoScroll.value === "true"
            visible: active

            sourceComponent: Controls.IVButton {
                source: "new_images/" + (tabsPagingTimer.running ? "pause" : "play")
                toolTipText: "Листание вкладок"

                Canvas {
                    id: canvas
                    property int percentage: 0
                    property var mainColor: IVColors.get("Colors/Text new/TxPrimaryThemed")
                    width: height
                    height: parent.height
                    anchors.centerIn: parent
                    rotation: -90
                    visible: opacity > 0
                    opacity: tabsPagingTimer.running ? 1 : 0
                    Timer {
                        id: canvasTimer

                        property int addPart: 100*interval/(tabsPagingTimer.interval-interval)

                        interval: 500
                        repeat: true
                        onTriggered: canvas.percentage += addPart
                    }

                    Connections {
                        target: tabsPagingTimer
                        onRunningChanged: {
                            if (tabsPagingTimer.running) canvasTimer.start()
                            else canvasTimer.stop()
                            canvas.percentage = 0
                        }
                        onTriggered: canvas.percentage = 0
                    }
                    Behavior on percentage {
                        NumberAnimation {duration:  canvasTimer.interval}
                    }
                    Behavior on opacity {
                        NumberAnimation {duration: 600; easing.type: Easing.InOutQuad}
                    }
                    onMainColorChanged: canvas.requestPaint()
                    onPercentageChanged: canvas.requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var centerX = width / 2;
                        var centerY = height / 2;
                        var radius = width/2 - 2;
                        var angle = (percentage / 100) * 2 * Math.PI;
                        ctx.beginPath();
                        ctx.arc(centerX, centerY, radius, 0, angle, false);
                        ctx.lineWidth = 3 * privates.isize;
                        ctx.strokeStyle = mainColor;
                        ctx.stroke();
                    }
                }
                onClicked: {
                    if (tabsPagingTimer.running) tabsPagingTimer.stop();
                    else tabsPagingTimer.start();
                }
            }
        }

        Timer {
            id: tabsPagingTimer

            triggeredOnStart: false
            interval:5000
            repeat: true
            onTriggered: {
                tabsListView.currentIndex = (tabsListView.currentIndex + 1) % openedTabsModel.count
                const currentTab = openedTabsModel.get(tabsListView.currentIndex);
                root.globalSignalsObject.tabSelected5(currentTab.name, currentTab.type, currentTab.id, currentTab.view);
            }
        }

        Item {
            id: tabsPlace

            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                id: slideLeftLoader

                width: 28 * privates.isize
                height: parent.height
                anchors.right: tabsLayout.left
                anchors.rightMargin: 4

                active: tabsListView.width === tabsLayout.maximumTabsWidth
                visible: active
                sourceComponent: Controls.IVButton {
                    source: "new_images/chevron-left-big"
                    toolTipText: "Влево"

                    onClicked: {
                        if (!tabsListView.atXBeginning) {
                            tabsListView.flick(1000,0);
                        }
                    }
                }
            }

            RowLayout {
                id: tabsLayout

                readonly property int maximumTabsWidth: tabsPlace.width - newTabButton.width - spacing
                                                        - slideLeftLoader.width - slideLeftLoader.anchors.rightMargin
                                                        - slideRightLoader.width - slideRightLoader.anchors.leftMargin

                height: parent.height
                anchors.centerIn: parent

                ListView {
                    id: tabsListView

                    Layout.preferredWidth: Math.min(contentWidth, tabsLayout.maximumTabsWidth)
                    Layout.fillHeight: true

                    spacing: 5

                    model: openedTabsModel
                    currentIndex: -1
                    clip: true
                    snapMode: ListView.SnapToItem
                    orientation: ListView.Horizontal
                    boundsBehavior: ListView.StopAtBounds

                    function flickToLeft() {
                        if (!tabsListView.atXBeginning) {
                            tabsListView.flick(1000,0);
                        }
                    }
                    function flickToRight() {
                        if (!tabsListView.atXEnd) {
                            tabsListView.flick(-1000,0);
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: true
                        onWheel: function(wheel) {
                            if (wheel.angleDelta.y > 0) {
                                tabsListView.flickToLeft();
                            }
                            else {
                                tabsListView.flickToRight();
                            }
                        }
                    }

                    delegate: IVClientTabDelegate {
                        viewType: model.view
                        name: model.name
                        innerIndex: model.index
                        type: model.type
                        tabId: model.tabId
                        currentIndex: tabsListView.currentIndex
                        globalSignalsObject: root.globalSignalsObject
                        modelSize: tabsListView.count

                        onRemoveTab: {
                            root.globalSignalsObject.tabRemoved2(name, type);
                        }

                        onTabRemoveLeft: {
                            const modelIndex = findItemIndex();
                            openedTabsModel.remove(0, modelIndex);
                            privates.saveModelToFile();
                        }

                        onTabRemoveRight: {
                            const modelIndex = findItemIndex();
                            const count = openedTabsModel.count - modelIndex - 1;
                            openedTabsModel.remove(modelIndex + 1, count);
                            privates.saveModelToFile();
                        }

                        function findItemIndex() {
                            const compareProperty = type === "set" ? "tabId" : "name";
                            for (var i = 0; i < openedTabsModel.count; i++) {
                                if (openedTabsModel.get(i)[compareProperty] === this[compareProperty]) {
                                    return i;
                                }
                            }
                        }
                    }
                }

                Controls.IVButton {
                    id: newTabButton

                    implicitWidth: 48 * privates.isize
                    Layout.fillHeight: true

                    type: Controls.IVButton.Type.Secondary
                    source: "new_images/plus"
                    toolTipText: "Создать новый набор"
                    onClicked: {
                        root.globalSignalsObject.tabAdded5("Новый набор", "set", "new_set", "realtime");
                    }
                }
            }

            Loader {
                id: slideRightLoader

                width: 28 * privates.isize
                height: parent.height
                anchors.left: tabsLayout.right
                anchors.leftMargin: 4

                active: tabsListView.width === tabsLayout.maximumTabsWidth
                visible: active
                sourceComponent: Controls.IVButton {
                    source: "new_images/chevron-right-big"
                    toolTipText: "Вправо"

                    onClicked: {
                        tabsListView.flickToRight();
                    }
                }
            }
        }
    }

    ListModel {
        id: openedTabsModel
    }

    readonly property string currentUserToken: appInfo.ip + "#" + IVCustomSets.currentUser + "#" + root.Window.window.unique

    IvVcliSetting {
        id: activeTabSettings
        name: root.Window.window.unique ? currentUserToken + "#tabs#activeTab" : ""
    }

    IvVcliSetting {
        id: openedTabsSettings

        readonly property bool isResetAvailable: IVCustomSets.sourcesReady

        name: root.Window.window.unique ? currentUserToken + "#tabs#openedTabs" : ""

        onIsResetAvailableChanged: {
            if (isResetAvailable) {
                resetModel();
            }
        }

        onValueChanged: {
            resetModel();
        }

        function resetModel() {
            if (!isResetAvailable) {
                return;
            }

            openedTabsModel.clear();
            IVSetsManager.clearSets();
            if (IVCustomSets.currentUser === "guest") {
                return;
            }

            try {
                const tabsArray = JSON.parse(openedTabsSettings.value);
                if (tabsArray.length > 0) {
                    addValidTabs(tabsArray);

                    trimTabsModel();

                    createSets();

                    const tabSelected = selectActiveTab();
                    if (tabSelected) {
                        return;
                    }

                    selectFirstTabIfExist();
                }
            }
            catch(exception) {}
        }


        function addValidTabs(tabsArray) {
            for (var i = 0; i < tabsArray.length; i++) {
                const tabItem = tabsArray[i];
                if (tabItem.type === "set" && tabItem.tabId !== "new_set") {
                    const setJsonString = IVCustomSets.getZonesCommon(tabItem.tabId);
                    if (setJsonString === "{}") {
                        continue;
                    }
                }
                const view = archive_fix2.value === "true" ? "archive" : tabItem.view;
                openedTabsModel.append({type: tabItem.type, name: tabItem.name, tabId: tabItem.tabId, view: view})
            }
        }

        function trimTabsModel() {
            const trimResult = privates.trimTabsToLimit();
            if(trimResult.trimmed) {
                privates.saveModelToFile();
            }
        }

        function createSets() {
            for (var i = 0; i < openedTabsModel.count; i++) {
                const tabItem = openedTabsModel.get(i);
                if (tabItem.type === "set") {
                    const setJsonString = IVCustomSets.getZonesCommon(tabItem.tabId);
                    if (setJsonString !== "{}") {
                        const data = JSON.parse(setJsonString);
                        openedTabsModel.setProperty(i, "tabId", data.setId);
                        IVSetsManager.createSet(data);
                    }
                }
            }
            privates.saveModelToFile();
        }

        function selectActiveTab() {
            const activeTabName = activeTabSettings.value;
            for (var i = 0; i < openedTabsModel.count; i++) {
                const tabItem = openedTabsModel.get(i);
                if (tabItem.name === activeTabName) {
                    tabsListView.currentIndex = i;
                    root.globalSignalsObject.tabSelected5(tabItem.name,tabItem.type,tabItem.tabId,tabItem.view);
                    return true;
                }
            }
            return false;
        }

        function selectFirstTabIfExist() {
            if (openedTabsModel.count > 0) {
                tabsListView.currentIndex = 0;//trimResult.index >= 0 ? trimResult.index : 0;
                const tabItem = openedTabsModel.get(tabsListView.currentIndex);
                activeTabSettings.value = tabItem.name;
                root.globalSignalsObject.tabSelected5(tabItem.name,tabItem.type,tabItem.tabId,tabItem.view);
            }
        }
    }

    Connections {
        target: IVCustomSets
        onEventMapChanged: {
            root.globalSignalsObject.tabAdded4(mapName,"map","",key2);
        }
    }

    Connections {
        target: root.globalSignalsObject

        onTabRemoved2: function(tabname, tabType) {
            const count = openedTabsModel.count
            var i1;
            for (i1 = 0; i1 < count; i1++) {
                const tabItem = openedTabsModel.get(i1);
                if(tabItem.type === tabType && tabItem.name === tabname) {
                    openedTabsModel.remove(i1,1);
                    break;
                }
            }

            if (i1 >= 0 && openedTabsModel.count > 0) {
                if(i1 < openedTabsModel.count) {
                    tabsListView.currentIndex = i1;
                }
                else {
                    tabsListView.currentIndex = Math.max(i1 - 1, 0);
                }

                const currItem = openedTabsModel.get(tabsListView.currentIndex);
                root.globalSignalsObject.tabSelected5(currItem.name, currItem.type, currItem.tabId, currItem.view);
                activeTabSettings.value = currItem.name;
            }

            if (openedTabsModel.count === 0) {
                root.globalSignalsObject.tabSelected5("", "", "", "");
            }

            privates.saveModelToFile();
        }
        onTabAdded4: {
            var isFound = false;
            for(var i =0 ; i < openedTabsModel.count; i++) {
                var tabName_ =  openedTabsModel.get(i).name;
                var tabid_ =  openedTabsModel.get(i).tabId;
                if(tabName_ === tabname && tabid_ === id)
                {
                    tabsListView.currentIndex = i;
                    root.globalSignalsObject.tabSelected4(tabName_,type,id,key2);
                    return;
                }
            }

            openedTabsModel.append({type: type,name:tabname,tabId:id});
            var trimResult4 = privates.trimTabsToLimit(openedTabsModel.count-1);
            tabsListView.currentIndex = trimResult4.index;
            root.globalSignalsObject.tabSelected4(tabname,type,id,key2);
            privates.saveModelToFile();
        }
        onTabAdded5: function (tabName, type, setId, viewType) {
            var isFound = false;
            for(var i =0;i<openedTabsModel.count;i++ )
            {
                var tabName_ =  openedTabsModel.get(i).name;
                var tabid_ =  openedTabsModel.get(i).tabId;
                var _view =  openedTabsModel.get(i).view;
                if(tabName_ === tabName && tabid_ === setId)
                {
                    tabsListView.currentIndex = i;
                    openedTabsModel.setProperty(i,"view",viewType);

                    root.globalSignalsObject.tabSelected5(tabName_,type,setId,viewType);
                    privates.saveModelToFile();
                    return;
                }
            }
            openedTabsModel.append({type: type, name: tabName, tabId: setId, view: viewType});

            const trimResult5 = privates.trimTabsToLimit(openedTabsModel.count - 1);
            tabsListView.currentIndex = trimResult5.index;
            const currentTab = openedTabsModel.get(tabsListView.currentIndex);
            root.globalSignalsObject.tabSelected5(currentTab.name, currentTab.type, currentTab.tabId, currentTab.view);

            privates.saveModelToFile();

            if (tabsListView.currentIndex >= 0) {
                tabsListView.positionViewAtIndex(tabsListView.currentIndex, ListView.End);
            }
        }

        onTabSelected5: function (tabName, type, setId, viewType) {
            activeTabSettings.value = tabName;
            for (var i = 0; i < openedTabsModel.count; i++) {
                const tab = openedTabsModel.get(i);
                if (tab.name === tabName && tab.tabId === setId) {
                    tabsListView.currentIndex = i;
                    return;
                }
            }
        }
    }

    Connections {
        target: IVCustomSets

        onNewSetSavedWithId: function(previousSetId, newSetId, savedSetName) {
            for (var tabIndex = 0; tabIndex < openedTabsModel.count; tabIndex++) {
                const tab = openedTabsModel.get(tabIndex);
                if (tab.tabId === previousSetId) {
                    openedTabsModel.setProperty(tabIndex, "tabId", newSetId);
                    openedTabsModel.setProperty(tabIndex, "name", savedSetName);
                    activeTabSettings.value = savedSetName;
                    return;
                }
            }
        }
        onSetRemoved: function(setId) {
            for (var tabIndex = 0; tabIndex < openedTabsModel.count; tabIndex++) {
                const tab = openedTabsModel.get(tabIndex);
                if (tab.tabId === setId) {
                    openedTabsModel.remove(tabIndex, 1);
                    return;
                }
            }
        }
        onSetsUpdated: {
            const prevOpenedTabSettings = openedTabsSettings.value;
            const newOpenedTabSettings = privates.getStringFromModel(openedTabsModel);
            if (prevOpenedTabSettings === newOpenedTabSettings) {
                openedTabsSettings.resetModel();
            }
            else {
                privates.saveModelToFile();
            }
        }
    }

    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }

    IvVcliSetting {
        id: eventsMaps
        name: 'settings.openMapFromEvents'
    }

    IvVcliSetting {
        id: autoScroll
        name: 'sets.autoScroll'
    }

    IvVcliSetting {
        id: maxTabsLimit
        name: 'dev.maxTabs'
        Component.onCompleted: privates.getMaxTabsLimit()
    }

    IvVcliSetting {
        id: archive_fix2
        name: 'archive.fixVisible'
        Component.onCompleted: {
            if (archive_fix2.value === "true") {
                setViewType("archive");
            }
            else {
                setViewType("realtime");
            }
        }

        function setViewType(viewType) {
            var tt = null;
            for (var i = 0; i < openedTabsModel.count; i++ ) {
                openedTabsModel.setProperty(i, "view", viewType);
                if (activeTabSettings.value === openedTabsModel.get(i).name) {
                    tt = openedTabsModel.get(i);
                }
            }
            if (tt !== null) {
                root.globalSignalsObject.tabSelected5(tt.name, tt.type, tt.tabId, tt.view);
            }
        }
    }

    QtObject {
        id: privates

        property bool isMapInit: false

        readonly property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1

        function saveModelToFile() {
            openedTabsSettings.value = privates.getStringFromModel(openedTabsModel);
        }

        function getStringFromModel(model) {
            var tabsArray = [];
            for(var i = 0; i<model.count;i++) {
                var tabsObj = {
                    name: model.get(i).name,
                    type: model.get(i).type,
                    tabId: model.get(i).tabId,
                    view: model.get(i).view,
                };
                tabsArray.push(tabsObj);
            }
            var tabsStr = JSON.stringify(tabsArray);
            return tabsStr;
        }

        function trimTabsToLimit(preferredIndex) {
            var limit = getMaxTabsLimit();
            var index = preferredIndex !== undefined ? preferredIndex : tabsListView.currentIndex;
            var trimmed = false;
            var activeRemoved = false;

            while(openedTabsModel.count > limit)
            {
                var removedTab = openedTabsModel.get(0);
                openedTabsModel.remove(0,1);
                trimmed = true;
                if(index > 0)
                {
                    index--;
                }
                if(tabsListView.currentIndex > 0)
                {
                    tabsListView.currentIndex = tabsListView.currentIndex - 1;
                }
                if(activeTabSettings.value === removedTab.name)
                {
                    activeRemoved = true;
                }
            }

            if(openedTabsModel.count === 0)
            {
                index = -1;
            }
            else if(index >= openedTabsModel.count)
            {
                index = openedTabsModel.count - 1;
            }

            if(activeRemoved && openedTabsModel.count>0)
            {
                activeTabSettings.value = openedTabsModel.get(Math.max(index,0)).name;
            }

            return {index:index, trimmed:trimmed, activeRemoved:activeRemoved};
        }

        function getMaxTabsLimit() {
            var limit = parseInt(maxTabsLimit.value);
            if(isNaN(limit))
            {
                limit = 8;
            }

            if(limit < 1)
            {
                limit = 1;
            }
            else if(limit > 128)
            {
                limit = 128;
            }

            var normalizedValue = limit.toString();
            if(maxTabsLimit.value !== normalizedValue)
            {
                maxTabsLimit.value = normalizedValue;
            }
            return limit;
        }
    }
}

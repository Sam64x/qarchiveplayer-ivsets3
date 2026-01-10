import QtQuick 2.9
import QtQml 2.3
import QtQuick.Controls 2.0
import QtQuick.Window 2.2
import QtQml.Models 2.3
import QtGraphicalEffects 1.0
import iv.singletonLang 1.0
import iv.plugins.loader 1.0

import iv.colors 1.0
import iv.controls 1.0
import iv.data 1.0

Item {
    id: root

    property var firstBorderTime: setInterval ? xToTime(firstBound.getX()) : ""
    property var secondBorderTime: setInterval ? xToTime(secondBound.getX()) : ""

    property real isize: 1
    property var archivePlayer: null
    property var key2: null
    property real previewMargin: 0
    property bool isCommonPanel: false

    property bool sliderIsDragged: false
    property bool canAutoMove: true
    property var currentDate: null
    property bool ready: false
    property var nowDateTime: new Date()
    property bool isMultiscreen: false
    property int intervalBeforeIndex: 2
    property int intervalAfterIndex: 4
    property int currentScale: 0
    property bool _syncingInterval: false

    property bool isScaleChange: false
    property int timeline_model: 0
    property real elementScale: 1
    property real timerElementScale: 0
    property real scaleStep: 0.5
    property int modelStep: 5
    property int maxScale: modelStep*9
    property int delegWidth: tempWidth * Math.max(1.0,elementScale - root.timeline_model*modelStep)
    property int tempWidth: 0

    property bool showEvents: true
    property bool showBookmarks: true
    property var oldTimeEvtBegin: null
    property var oldTimeEvtEnd: null
    property bool isNeedUpdateEvents: true
    property var eventsFilter: []

    property alias timelineModelView: timelineModel
    property bool sliderFullHeight: false

    readonly property real sliderVisualX: sliderRect.x + sliderRect.width/2
    readonly property real sliderVisualWidth: sliderRect.implicitWidth
    readonly property real sliderVisualHeight: sliderRect.implicitHeight

    signal updateCalendarDT
    signal doubleClicked
    signal scaleRequested(int scale)
    signal intervalIndicesRequested(int beforeIndex, int afterIndex)

    IvVcliSetting {
        id: archFullnessColorUse
        name: 'archive.fullnessColorUse'
    }

    IvVcliSetting {
        id: archFullnessColor
        name: 'archive.fullnessColor'
    }

    Timer {
        interval: 1000
        repeat: true
        onTriggered: root.nowDateTime = new Date()
        Component.onCompleted: start()
    }

    Timer {
        id: tryToSmoothScaling
        property int loops: animSet.val ? 10 : 1
        property int loop: 0
        interval: 1
        repeat: true
        onTriggered: {
            if (loop == loops) stop()
            root.elementScale += (root.timerElementScale/loops)
            loop++;
        }
        onRunningChanged: {
            if(!running){
                loop = 0
            }
        }
    }

    Timer {
        id: eventsTimer
        interval: 3000
        onTriggered: {
            interval = 1000;
            if (!root.ready || timelineModel.count === 0 || timeline.contentWidth <= 0)
                return;

            var viewStart = timelineModel.get(0)["start"]
            var viewEnd = timelineModel.get(timelineModel.count-1)["end"]
            var spanMs = viewEnd.getTime() - viewStart.getTime()
            var marginFactor = 0.25
            var marginMs = spanMs * marginFactor
            var now = new Date()
            var start = new Date(Math.max(0, viewStart.getTime() - marginMs))
            var end = new Date(Math.min(now.getTime(), viewEnd.getTime() + marginMs))
            if (end <= start)
                return;

            var fetchSpanMs = end.getTime() - start.getTime()
            var spacing = 8 * isize
            var skipTime = fetchSpanMs > 0 ? Math.round(fetchSpanMs / Math.max(1, timeline.contentWidth) * spacing) : 0

            var a = root.oldTimeEvtBegin === null || root.oldTimeEvtEnd === null
            var b = root.oldTimeEvtBegin === undefined || root.oldTimeEvtEnd == undefined
            if (a || b)
            {
                eventsModel.clear();
                root.oldTimeEvtBegin = start
                root.oldTimeEvtEnd = end
                root.getEvents(start, end, skipTime);
                root.isNeedUpdateEvents = true;
                return;
            }
            if (root.oldTimeEvtBegin.toString() !== start.toString() ||
                root.oldTimeEvtEnd.toString() !== end.toString())
            {
                root.oldTimeEvtBegin = start
                root.oldTimeEvtEnd = end
                root.getEvents(start, end, skipTime);
                root.isNeedUpdateEvents = true;
                return;
            }
            root.isNeedUpdateEvents = false;
        }
    }

    EventsModel { id: eventsModel }

    FullnessModel { id: fullnessModel }

    function updateEvJson() {
        eventsModel.updateFromJson(archivePlayer.getEventsStr(), root.eventsFilter, root.timeline_model, eventsModel.dateCheckSum)
    }
    function updateFnJson() {
        fullnessModel.updateFromJson(archivePlayer.getFnJson(), root.timeline_model, fullnessModel.dateCheckSum)
    }

    Timer {
        id: fulnessTimer
        interval: 2000
        repeat: true
        onTriggered: {
            if (root.archivePlayer) {
                root.archivePlayer.getFullness(
                    timelineModel.get(0)["start"],
                    timelineModel.get(timelineModel.count-1)["end"],
                    root.key2,
                    root.timeline_model
                );
                updateFnJson();
            }
        }
    }

    property bool setInterval: false
    property bool firstSet: containerArea.firstSet
    property bool secondSet: containerArea.secondSet
    signal boundsChanged
    property bool isSecondSet: containerArea.secondSet

    readonly property var intervalDurationsMs: [
        5 * 1000,
        15 * 1000,
        30 * 1000,
        60 * 1000,
        5 * 60 * 1000,
        10 * 60 * 1000,
        15 * 60 * 1000,
        30 * 60 * 1000
    ]

    function intervalMs(index) {
        if (index < 0 || index >= intervalDurationsMs.length)
            return 0
        return intervalDurationsMs[index]
    }

    function closestIntervalIndex(durationMs) {
        if (intervalDurationsMs.length === 0)
            return 0
        var bestIndex = 0
        var bestDelta = Math.abs(durationMs - intervalDurationsMs[0])
        for (var i = 1; i < intervalDurationsMs.length; i++) {
            var delta = Math.abs(durationMs - intervalDurationsMs[i])
            if (delta < bestDelta) {
                bestDelta = delta
                bestIndex = i
            }
        }
        return bestIndex
    }

    function scaleForOffsets(beforeMs, afterMs) {
        var totalMs = (Math.max(0, beforeMs) + Math.max(0, afterMs)) * 2
        if (totalMs <= 60 * 1000)
            return 7
        if (totalMs <= 10 * 60 * 1000)
            return 6
        if (totalMs <= 30 * 60 * 1000)
            return 5
        if (totalMs <= 60 * 60 * 1000)
            return 4
        if (totalMs <= 24 * 60 * 60 * 1000)
            return 3
        if (totalMs <= 7 * 24 * 60 * 60 * 1000)
            return 2
        if (totalMs <= 31 * 24 * 60 * 60 * 1000)
            return 1
        return 0
    }

    function updateScaleForOffsets(beforeMs, afterMs) {
        var nextScale = scaleForOffsets(beforeMs, afterMs)
        if (currentScale !== nextScale)
            scaleRequested(nextScale)
    }

    function applyDefaultInterval() {
        if (!root.setInterval)
            return
        var center = root.currentDate
        if (!center || !center.getTime)
            center = new Date()
        var beforeMs = intervalMs(root.intervalBeforeIndex)
        var afterMs = intervalMs(root.intervalAfterIndex)
        updateScaleForOffsets(beforeMs, afterMs)
        var startMs = center.getTime() - beforeMs
        var endMs = center.getTime() + afterMs
        var now = root.nowDateTime || new Date()
        if (endMs > now.getTime())
            endMs = now.getTime()
        if (startMs < 0)
            startMs = 0
        if (startMs > endMs)
            startMs = endMs
        root._syncingInterval = true
        root.setBounds(new Date(startMs), new Date(endMs))
        root._syncingInterval = false
    }

    function syncOffsetsWithBounds() {
        if (!root.setInterval)
            return
        var left = root.firstBorderTime
        var right = root.secondBorderTime
        if (!left || !right || !left.getTime || !right.getTime)
            return
        if (left > right) {
            var swap = left
            left = right
            right = swap
        }
        var center = root.currentDate
        if (!center || !center.getTime || center < left || center > right) {
            center = new Date((left.getTime() + right.getTime()) / 2)
        }
        var beforeMs = Math.max(0, center.getTime() - left.getTime())
        var afterMs = Math.max(0, right.getTime() - center.getTime())
        root._syncingInterval = true
        intervalIndicesRequested(closestIntervalIndex(beforeMs), closestIntervalIndex(afterMs))
        root._syncingInterval = false
    }

    Timer {
        id: flickTimer

        property bool toRight: false
        property int maxInterval: 100

        repeat: true
        onTriggered: {
            var isNowDate = root.viewportOffset() + timeline.width >= timeToX(nowDateTime)
            if (!(timeline.atXBeginning || timeline.atXEnd))
            {
                if (toRight && !isNowDate) timeline.contentX += 3
                else if (!toRight) timeline.contentX -= 3
                if (containerArea.pressedItem === firstBound){
                    containerArea.bounds.first = xToTime(firstBound.getX())
                }
                if (containerArea.pressedItem === secondBound){
                    containerArea.bounds.second = xToTime(secondBound.getX())
                }
                root.boundsChanged()
            }
        }
    }

    IvVcliSetting {
        id: animSet
        name: 'interface.animations'
        property var val: JSON.parse(value)
    }

    IvVcliSetting {
        id: preview_scale
        name: 'archive.preview_scale'
        property int val: (parseInt(value)+100)/100
    }

    IvVcliSetting {
        id: arc_display_camera_previews
        name: 'archive.display_camera_previews'
        property var val: JSON.parse(value)
    }

    IvVcliSetting {
        id: iv_vcli_setting_arc
        name: 'archive.common_panel'
        property var val: JSON.parse(value)
    }

    Rectangle {
        id:main

        anchors.fill: parent
        color: "transparent"
        clip: true

        MouseArea {
            id: marea

            property bool canWheel: true && root.ready

            anchors.fill: parent
            enabled: !isCommonPanel
            acceptedButtons: isCommonPanel ? Qt.NoButton : Qt.LeftButton
            hoverEnabled: !isCommonPanel
            propagateComposedEvents: true

            onWheel: {
                var mapMouseX = mapToItem(timeline.contentItem,mouseX,mouseY).x-timeline.originX
                var zoomToTime = root.xToTime(mapMouseX)
                if (entered && canWheel){
                    if (wheel.angleDelta.y > 0 &&
                            root.elementScale + root.scaleStep < root.maxScale-1 &&
                            !tryToSmoothScaling.running &&
                            zoomToTime <= new Date())
                    {
                        root.canAutoMove = false
                        root.timerElementScale = root.scaleStep
                        tryToSmoothScaling.start()
                    }
                    else if (wheel.angleDelta.y < 0 && root.elementScale - root.scaleStep > 1 && !tryToSmoothScaling.running){
                        root.canAutoMove = false
                        root.timerElementScale = -root.scaleStep
                        tryToSmoothScaling.start()
                    }
                }
            }


            ListView {
                id: timeline

                anchors.fill: parent
                clip: true

                model: ListModel {
                    id: timelineModel
                    property int countElems: 7
                }

                enabled: !isCommonPanel
                orientation: Qt.Horizontal
                boundsBehavior: ListView.StopAtBounds
                delegate: idDelegate
                currentIndex: -1
                interactive: root.ready

                onDraggingChanged: {
                    if (dragging) marea.canWheel = false && root.ready
                    else marea.canWheel = true && root.ready
                }

                function needToUpdate(){
                    if (sliderRect.x <= 0 || sliderRect.x >= width){
                        return true
                    }
                    return false
                }
                property real prevWidth: 0
                property real prevOriginX: 0
                property real mapMouseToContent: marea.mapToItem(timeline.contentItem,marea.mouseX,marea.mouseY).x-originX
                property real mapMouseX: marea.mapToItem(timeline,marea.mouseX,marea.mouseY).x
                onMovingChanged: {
                    if (moving){
                        root.canAutoMove = false
                        marea.canWheel = false && root.ready
                    }
                    else {
                        root.requestEvents()
                        marea.canWheel = true && root.ready
                    }
                }
                onWidthChanged: {
                    if (root.ready){
                        sliderRect.setX(root.timeToX(root.currentDate))
                        containerArea.updateX()
                        if (!moving) root.requestEvents()
                    }
                }
                onContentXChanged: {
                    if (root.ready){
                        sliderRect.setX(root.timeToX(root.currentDate))
                        containerArea.updateX()
                        var pushFront = contentX-originX < contentWidth*0.25
                        var pushBack = contentX-originX + width > contentWidth*0.75
                        var canPush = (moving || root.canAutoMove || root.setInterval)
                        var date

                        if (canPush && pushFront && timeline.count > 0){
                            date = timelineModel.get(0)["start"];
                            date = root.decrementDate(root.timeline_model, date);
                            if (timelineModel.get(0)["start"] > new Date(0)){
                                timelineModel.insert(0, {"start":date,
                                                         "end":root.incrementDate(root.timeline_model, date)
                                                     })
                                if (timelineModel.count >= timelineModel.countElems) timelineModel.remove(timelineModel.count-1)
                                if (!moving) root.requestEvents()
                            }
                        }
                        else if (canPush && pushBack && timeline.count > 0){
                            date = timelineModel.get(timelineModel.count-1)["start"];
                            if (date <= new Date()){
                                date = root.incrementDate(root.timeline_model, date);
                                timelineModel.append({"start":date,
                                                         "end":root.incrementDate(root.timeline_model, date)
                                                     })
                                if (timelineModel.count >= timelineModel.countElems) timelineModel.remove(0)
                                if (!moving) root.requestEvents()
                            }
                        }
                    }
                }

                onContentWidthChanged: {
                    if (timeline.count > 0 && root.isScaleChange){
                        if (root.ready){
                            var mousePos = timeline.mapMouseToContent/timeline.prevWidth
                            var orXdec = parseInt(originX - prevOriginX)
                            var x1 = mousePos * parseInt(contentWidth - prevWidth)

                            var first = (contentX + x1 + orXdec - originX > 0)
                            var second = contentX + x1 + orXdec - originX + width < contentWidth

                            if(first && second){
                                timeline.contentX += parseInt(x1 + orXdec)
                            }
                            timeline.mapMouseToContent = marea.mapToItem(timeline.contentItem,marea.mouseX,marea.mouseY).x-timeline.originX
                        }
                        sliderRect.setX(root.timeToX(root.currentDate))
                        containerArea.updateX()
                        root.isScaleChange = false
                        if (!moving) root.requestEvents()
                    }
                }
                Timer{
                    id: refreshTimer

                    interval: 35
                    triggeredOnStart: false

                    property var today
                    property var mousePos

                    onTriggered: {
                        if (root.canAutoMove) timeline.contentX = root.timeToX(root.currentDate) - timeline.width/2 + timeline.originX
                        else timeline.contentX = root.timeToX(refreshTimer.today) - refreshTimer.mousePos + timeline.originX

                        timeline.prevWidth = timeline.contentWidth
                        timeline.prevOriginX = timeline.originX
                        timeline.mapMouseToContent = marea.mapToItem(timeline.contentItem,marea.mouseX,marea.mouseY).x-timeline.originX

                        sliderRect.setX(root.timeToX(root.currentDate))
                        containerArea.updateX()
                        root.requestEvents()
                        root.ready = true
                    }
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    visible: !isCommonPanel
                    width: childrenRect.width
                    height: childrenRect.height
                    color: IVColors.get("Colors/Background new/BgFormOverVideo")

                    Text {
                        id: dateTxt

                        color: IVColors.get("Colors/Text new/TxContrast")
                        font: IVColors.getFont("Button middle")
                        text: getLowDateText(root.timeline_model)

                        function getLowDateText(view)
                        {
                            var indAtCX = timeline.indexAt(timeline.contentX,0)
                            if (indAtCX > -1 && indAtCX < timelineModel.count)
                            {
                                var model = timelineModel.get(indAtCX)
                                if (model.start) {
                                    switch (view){
                                    case 0:
                                        return Qt.formatDate(model.start, "yyyy")
                                    case 1:
                                        return (root.getMonthModel(model.start.getMonth())) + " " + model.start.getFullYear()
                                    case 2:
                                        var yearStartTime = new Date(model.start.getFullYear(), 0, 1).getTime()
                                        var currTime = model.start.getTime()
                                        var weekNum = Math.floor( (currTime - yearStartTime) / 604800000) + 1
                                        return (weekNum + " " + Language.getTranslate("Week", "Неделя") + " " + model.start.getFullYear())
                                    case 3:
                                        return Qt.formatDate(model.start, "dd.MM.yyyy");
                                    }
                                    return Qt.formatDateTime(model.start, "d.M.yyyy hh:mm");
                                }
                            }
                            return ""
                        }
                    }
                }

                Component.onCompleted: {
                    fulnessTimer.start();
                    if (!iv_vcli_setting_arc.val && (root.showEvents || root.showBookmarks)) {
                        eventsTimer.start();
                    }
                    root.tempWidth = root.width;
                }
            }

            Item {
                id: container

                z: 50
                anchors.top: parent.top
                height: 2*parent.height/5
                width: parent.width
                visible: !isCommonPanel && !archiveStreamer.exporting

                Rectangle {
                    id: futureRect

                    color: "white"
                    opacity: 0.2
                    anchors.top: parent.top
                    anchors.right: parent.right
                    height: main.height
                    width: parent.width - (root.timeToX(root.nowDateTime) - root.viewportOffset())
                    z: 51
                }

                Rectangle {
                    id: translucentSliderRect

                    color: IVColors.get("Colors/Background new/BgModalInverse")
                    visible: previewDate.visible && !root.setInterval
                    height: marea.height
                    width: 2*root.isize
                    x: containerArea.mouseX - width/2
                    opacity: 0.6
                }

                Item {
                    id: sliderRect

                    anchors.top: parent.top
                    anchors.bottom: root.sliderFullHeight ? parent.bottom : undefined
                    anchors.topMargin: root.sliderFullHeight ? 0 : 5*parent.height/2 - height

                    implicitWidth: 16 + 4
                    implicitHeight: 28 + 4
                    height: root.sliderFullHeight ? parent.height : implicitHeight

                    Rectangle {
                        id: sliderTracer

                        anchors.top: parent.top
                        anchors.topMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter

                        implicitWidth: 16
                        implicitHeight: 16
                        radius: width/2
                        color: IVColors.get("Colors/Text new/TxAccent")
                    }

                    DropShadow {
                        anchors.fill: sliderTracer
                        source: sliderTracer
                        verticalOffset: 4
                        radius: 8
                        color: Qt.rgba(2/255, 7/255, 32/255, 0.4)
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: 2
                        implicitHeight: 19
                        color: IVColors.get("Colors/Text new/TxAccent")
                    }

                    MouseArea {
                        id: sliderHandleArea

                        anchors.fill: parent
                        enabled: !isCommonPanel
                        hoverEnabled: !isCommonPanel
                        acceptedButtons: isCommonPanel ? Qt.NoButton : Qt.LeftButton

                        drag.target: parent
                        drag.axis: Drag.XAxis

                        onPressed: {
                            containerArea.pressedItem = sliderRect
                            root.sliderIsDragged = true
                            root.canAutoMove = false
                        }

                        onPositionChanged: {
                            var correction = root.viewportOffset()
                            var mappedX = mouseX + correction
                            if (mappedX > 0 && mappedX < containerArea.width) {
                                sliderRect.setX(clampToNowX(mappedX))
                            }
                            root.canAutoMove = false
                        }

                        onReleased: {
                            root.currentDate = root.xToTime(sliderRect.getX())
                            root.sliderIsDragged = false
                            root.updateCalendarDT()
                            containerArea.pressedItem = null
                        }
                    }

                    function setX(xPos){
                        var correction = root.viewportOffset()
                        x = xPos - Math.floor(width/2) - correction
                    }

                    function getX(){
                        var correction = root.viewportOffset()
                        return x + Math.floor(width/2) + correction
                    }
                }

                Rectangle {
                    id: translucentFirstBound

                    x: containerArea.mouseX - width/2
                    width: 3/8*parent.height
                    height: parent.height
                    visible: previewDate.visible && root.setInterval
                    radius: width/2
                    color: IVColors.get("Colors/Background new/BgEvent")
                    opacity: 0.4

                    Rectangle {
                        x: parent.width/2-1
                        y: parent.height
                        color: IVColors.get("Colors/Background new/BgEvent")
                        width: 1
                        height: marea.height
                    }
                }

                Rectangle {
                    id: firstBound

                    visible: containerArea.firstSet
                    width: 7
                    height: 16
                    radius: 4
                    color: IVColors.get("Colors/Background new/BgEvent")
                    z: sliderRect.z + 1

                    function setX(xPos) {
                        var correction = root.viewportOffset()
                        x = xPos - width/2 - correction
                    }

                    function getX() {
                        var correction = root.viewportOffset()
                        return x + width/2 + correction
                    }
                }

                Rectangle {
                    id: firstSeparator

                    width: 1
                    z: sliderRect.z + 1
                    height: parent.height*4 - firstBound.height
                    anchors.horizontalCenter: firstBound.horizontalCenter
                    anchors.top: firstBound.bottom
                    visible: containerArea.firstSet
                    color: IVColors.get("Colors/Background new/BgEvent")
                }

                Rectangle {
                    id: betweenBounds

                    visible: containerArea.secondVisible
                    x: Math.min(firstBound.x+firstBound.width/2, secondBound.x+secondBound.width/2)
                    width: Math.max(
                               firstBound.x+firstBound.width/2-secondBound.x+secondBound.width/2,
                               secondBound.x+secondBound.width/2-firstBound.x+firstBound.width/2
                               )-firstBound.width
                    height: 16
                    color: IVColors.get("Colors/Background new/BgEventSecondary")
                }

                Rectangle {
                    id: belowBounds

                    visible: containerArea.secondVisible
                    width: betweenBounds.width
                    height: parent.height*4 - betweenBounds.height
                    anchors.top: betweenBounds.bottom
                    anchors.horizontalCenter: betweenBounds.horizontalCenter
                    color: IVColors.get("Colors/Background new/BgEventSecondary")
                    opacity: 0.2
                    z: sliderRect.z + 1
                }

                Rectangle {
                    id: secondBound

                    visible: containerArea.secondVisible
                    width: 7
                    height: 16
                    radius: 4
                    color: IVColors.get("Colors/Background new/BgEvent")

                    function setX(xPos){
                        var correction = root.viewportOffset()
                        x = xPos - width/2 - correction
                    }

                    function getX(){
                        var correction = root.viewportOffset()
                        return x + width/2 + correction
                    }
                }

                Rectangle {
                    id: secondSeparator
                    width: 1
                    height: parent.height*4 - secondBound.height
                    anchors.horizontalCenter: secondBound.horizontalCenter
                    anchors.top: secondBound.bottom
                    visible: containerArea.secondVisible
                    color: IVColors.get("Colors/Background new/BgEvent")
                    z: sliderRect.z + 1
                }

                MouseArea {
                    id: containerArea

                    anchors.fill: parent
                    enabled: !isCommonPanel
                    hoverEnabled: !isCommonPanel
                    acceptedButtons: isCommonPanel ? Qt.NoButton : Qt.LeftButton

                    property bool firstSet: false
                    property bool secondSet: false
                    property bool secondVisible: false
                    property var pressedItem: null
                    property var bounds: {"first": new Date(0), "second": new Date(0)}

                    property real _lastHoverMappedX: -1
                    property bool _lastHoverPressed: false
                    property real _cachedMouseX: 0
                    property real _cachedMappedX: 0
                    property bool _hoverJobQueued: false
                    property bool _skipNextClick: false

                    Timer {
                        id: __hoverTick
                        interval: 16
                        repeat: false
                        onTriggered: {
                            containerArea._hoverJobQueued = false
                            containerArea.__applyHover()
                        }
                    }

                    Popup {
                        id: previewDate
                        y: translucentSliderRect.height - contentHeight
                        x: containerArea.mouseX - contentWidth/2
                        clip: true
                        background: Rectangle{
                            color: IVColors.get("Colors/Background new/BgModalInverse")
                            border.color: "black"
                            border.width: 1
                            radius: 4
                        }
                        padding: 2
                        visible: containerArea.containsMouse && !root.sliderIsDragged
                        contentItem: Text {
                            property var date: root.xToTime(containerArea.mouseX +
                                                            root.viewportOffset())
                            property var dayNames: [
                                Language.getTranslate("Su","Вс"),
                                Language.getTranslate("Mo","Пн"),
                                Language.getTranslate("Tu","Вт"),
                                Language.getTranslate("We","Ср"),
                                Language.getTranslate("Th","Чт"),
                                Language.getTranslate("Fr","Пт"),
                                Language.getTranslate("Sa","Сб")
                            ];
                            property var monthNames: [
                                Language.getTranslate("JAN","ЯНВ"),
                                Language.getTranslate("FEB","ФЕВ"),
                                Language.getTranslate("MAR","МАР"),
                                Language.getTranslate("APR","АПР"),
                                Language.getTranslate("MAY","МАЙ"),
                                Language.getTranslate("JUNE","ИЮН"),
                                Language.getTranslate("JUL","ИЮЛ"),
                                Language.getTranslate("AUG","АВГ"),
                                Language.getTranslate("SEPT","СЕН"),
                                Language.getTranslate("OCT","ОКТ"),
                                Language.getTranslate("NOV","НОЯ"),
                                Language.getTranslate("DEC","ДЕК")
                            ];
                            text: date !== null ? dayNames[date.getDay()] + " " +
                                                  date.getDate() + " " +
                                                  monthNames[date.getMonth()] + " " +
                                                  date.getFullYear() + " " +
                                                  date.toLocaleTimeString() : ""
                            color: IVColors.get("Colors/Text new/TxPrimary")
                            font: IVColors.getFont("Label")
                        }
                    }

                    Timer {
                        id: previewTimer
                        interval: 160
                        repeat: false
                        onTriggered: {
                            previewFrame.visible = false
                        }
                    }

                    Popup {
                        id: previewFrame
                        y: -height - root.previewMargin
                        x: getX()
                        width: height * aspectRatio
                        height: 150 * root.isize * preview_scale.val
                        property real aspectRatio: imageSlider_2.sourceSize.width/imageSlider_2.sourceSize.height
                        property string source: ''
                        function getX(){
                            var mouseX = containerArea.mouseX
                            if (mouseX - width/2 < 0)
                                return 0
                            else if (mouseX + width/2 > containerArea.width)
                                return containerArea.width-width
                            else
                                return mouseX - width/2
                        }

                        background: Rectangle {
                            color: "black"
                            border.color: "lightblue"
                            border.width: 1
                            opacity: 0.8
                        }
                        padding: 1
                        visible: previewFrame.source.length>0 && containerArea.containsMouse
                        contentItem: Rectangle {
                            id: imageRect
                            property int fillmode: Image.PreserveAspectFit
                            color: "transparent"
                            clip: true
                            z: 300
                            Image {
                                id: imageSlider_2
                                source: previewFrame.source
                                anchors.fill: parent
                                fillMode: imageRect.fillmode
                                clip: true
                                visible: (status === Image.Ready)
                            }
                        }
                    }

                    onBoundsChanged: root.boundsChanged()

                    onExited: {
                        cursorShape = Qt.ArrowCursor
                        previewFrame.visible = false
                        previewTimer.stop()
                        translucentFirstBound.visible = false
                    }

                    onPressed: {
                        if (Qt.LeftButton){
                            var correction = root.viewportOffset()
                            var mappedX = clampToNowX(mouseX + correction)

                            var mouseToFirstBound = Math.abs(firstBound.x - mouseX)
                            var mouseToSecondBound = Math.abs(secondBound.x - mouseX)
                            var sliderEntered = mouseX >= sliderRect.x && mouseX <= sliderRect.x + sliderRect.width

                            if (setInterval)
                            {
                                if (!firstSet){
                                    secondVisible=true
                                    firstSet=true
                                    firstBound.setX(mappedX)
                                    bounds.first=xToTime(mappedX)
                                    root.boundsChanged()
                                    translucentFirstBound.visible = false
                                    pressedItem = secondBound
                                }
                                else {
                                    if (sliderEntered) pressedItem = sliderRect
                                    else if (mouseToSecondBound < mouseToFirstBound) pressedItem = secondBound
                                    else pressedItem = firstBound
                                }
                            }
                            else {
                                pressedItem = sliderRect
                            }
                            containerArea._lastHoverMappedX = mappedX
                            containerArea._lastHoverPressed = containerArea.pressed
                            containerArea._cachedMouseX = mouseX
                            containerArea._cachedMappedX = mappedX
                        }
                    }

                    onMouseXChanged: {
                        var correction = root.viewportOffset()
                        var mappedX = mouseX + correction
                        var skip = (Math.abs(mappedX - _lastHoverMappedX) < 2 && pressed === _lastHoverPressed)

                        _lastHoverMappedX = mappedX
                        _lastHoverPressed = pressed
                        _cachedMouseX = mouseX
                        _cachedMappedX = mappedX

                        setVisibleIfChanged(previewFrame, false)

                        if (pressed) {
                            __applyHover()
                            return
                        }

                        if (skip) {
                            if (!flickTimer.running) {
                                if (previewTimer.running && previewTimer.restart) previewTimer.restart()
                                else { if (previewTimer.running) previewTimer.stop(); previewTimer.start() }
                            }
                            return
                        }

                        if (!_hoverJobQueued) {
                            _hoverJobQueued = true
                            __hoverTick.start()
                        }
                    }

                    onReleased: {
                        var correction = root.viewportOffset()
                        var mappedX = mouseX + correction
                        if (setInterval && firstSet && !secondSet){
                            secondSet=true
                            secondVisible=true

                            if (mappedX <= timeToX(root.nowDateTime)) secondBound.setX(mappedX)
                            else secondBound.setX(timeToX(root.nowDateTime))

                            bounds.second=xToTime(secondBound.getX())
                            root.boundsChanged()
                        }
                        else if (pressedItem === sliderRect){
                            root.currentDate = root.xToTime(sliderRect.getX())
                            root.sliderIsDragged = false
                            if (mouseX < sliderRect.x || mouseX > sliderRect.x + sliderRect.width) {
                            }
                            _skipNextClick = true
                            root.updateCalendarDT()
                        }
                        flickTimer.stop()
                        pressedItem = null
                    }

                    onClicked: {
                        if (_skipNextClick) {
                            _skipNextClick = false
                            return
                        }
                        var correction = root.viewportOffset()
                        var mappedX = clampToNowX(mouseX + correction)

                        if (setInterval) {
                            if (!firstSet) {
                                firstSet = true
                                secondVisible = true
                                firstBound.setX(mappedX)
                                bounds.first = xToTime(mappedX)
                                root.boundsChanged()
                            } else {
                                var d1 = Math.abs(firstBound.getX() - mappedX)
                                var d2 = Math.abs(secondBound.getX() - mappedX)
                                if (d1 <= d2) {
                                    firstBound.setX(mappedX)
                                    bounds.first = xToTime(mappedX)
                                } else {
                                    secondBound.setX(mappedX)
                                    bounds.second = xToTime(mappedX)
                                }
                                root.boundsChanged()
                            }
                        } else {
                            var clamped = Math.min(mappedX, nowX)
                            sliderRect.setX(clamped)
                            root.currentDate = xToTime(sliderRect.getX())
                            root.updateCalendarDT()
                        }
                    }


                    function __applyHover() {
                        var mouseX = _cachedMouseX
                        var mappedX = _cachedMappedX

                        var leftFlickBound = Math.ceil(width * 0.2)
                        var rightFlickBound = Math.ceil(width * 0.8)

                        var sliderEntered = mouseX >= sliderRect.x && mouseX <= sliderRect.x + sliderRect.width

                        if (!pressed){
                            if (setInterval && containsMouse){
                                if (!firstSet){
                                    setVisibleIfChanged(translucentFirstBound, true)
                                } else {
                                    if (sliderEntered) {
                                        setVisibleIfChanged(translucentFirstBound, false)
                                    } else {
                                        setVisibleIfChanged(translucentFirstBound, true)
                                    }
                                }
                            } else if (sliderEntered){
                            } else {
                                setVisibleIfChanged(translucentFirstBound, false)
                            }
                        } else {
                            if (translucentFirstBound.visible) setVisibleIfChanged(translucentFirstBound, false)

                            if (setInterval){
                                var precentSpeed = 0
                                if (pressedItem === firstBound){
                                    if (mouseX > 0 && mouseX < width && mappedX <= nowX){
                                        firstBound.setX(mappedX)
                                        if (mouseX < leftFlickBound && !timeline.atXBeginning){
                                            root.canAutoMove = false
                                            flickTimer.toRight = false
                                            flickTimer.interval = Math.ceil((mouseX / leftFlickBound) * flickTimer.maxInterval)
                                            if (!flickTimer.running) flickTimer.start()
                                        } else if (mouseX > rightFlickBound && !timeline.atXEnd){
                                            root.canAutoMove = false
                                            flickTimer.toRight = true
                                            precentSpeed = 1 - (mouseX - rightFlickBound) / (width - rightFlickBound)
                                            flickTimer.interval = Math.ceil(precentSpeed * flickTimer.maxInterval)
                                            if (!flickTimer.running) flickTimer.start()
                                        } else {
                                            flickTimer.stop()
                                        }
                                        bounds.first = xToTime(mappedX)
                                    }
                                    root.boundsChanged()
                                } else if (pressedItem === secondBound){
                                    if (mouseX > 0 && mouseX < width && mappedX <= nowX){
                                        secondBound.setX(mappedX)
                                        if (mouseX < leftFlickBound && !timeline.atXBeginning){
                                            root.canAutoMove = false
                                            flickTimer.toRight = false
                                            flickTimer.interval = Math.ceil((mouseX / leftFlickBound) * flickTimer.maxInterval)
                                            if (!flickTimer.running) flickTimer.start()
                                        } else if (mouseX > rightFlickBound && !timeline.atXEnd){
                                            root.canAutoMove = false
                                            flickTimer.toRight = true
                                            precentSpeed = 1 - (mouseX - rightFlickBound) / (width - rightFlickBound)
                                            flickTimer.interval = Math.ceil(precentSpeed * flickTimer.maxInterval)
                                            if (!flickTimer.running) flickTimer.start()
                                        } else {
                                            flickTimer.stop()
                                        }
                                        bounds.second = xToTime(mappedX)
                                    }
                                    root.boundsChanged()
                                } else if (pressedItem === sliderRect){
                                    root.sliderIsDragged = true
                                    if (mouseX > 0 && mouseX < width) sliderRect.setX(clampToNowX(mappedX))
                                    root.canAutoMove = false
                                }
                            } else {
                                root.sliderIsDragged = true
                                if (mouseX > 0 && mouseX < width) sliderRect.setX(clampToNowX(mappedX))
                                root.canAutoMove = false
                            }
                        }

                        if (!flickTimer.running) {
                            if (previewTimer.restart) previewTimer.restart();
                            else { if (previewTimer.running) previewTimer.stop(); previewTimer.start(); }
                        }
                    }

                    function updateX(){
                        if (containerArea.pressedItem !== firstBound)
                            firstBound.setX(timeToX(bounds.first))
                        if (containerArea.pressedItem !== secondBound)
                            secondBound.setX(timeToX(bounds.second))
                    }
                }
            }
        }

        Component {
            id: idDelegate

            Rectangle {
                id: content
                width: root.delegWidth
                height: parent.height
                color: IVColors.get("Colors/Background new/BgContextMenuThemed")
                anchors.bottom: parent.bottom
                property var startDate: model.start
                property var endDate: model.end
                property var fnModel: fnProj
                property var evModel: evProj

                function loadFullness() {
                    fnProj.project()
                }

                function loadEvents() {
                    if (!root.showEvents || !content.startDate || !content.endDate)
                        return
                    evProj.project()
                }

                onStartDateChanged: loadEvents()
                onEndDateChanged: loadEvents()

                FullnessProjectionModel {
                    id: fnProj
                    source: fullnessModel
                    startDate: content.startDate
                    endDate: content.endDate
                    viewWidth: content.width
                    minPx: 0
                    clampNow: true
                }

                EventsProjectionModel {
                    id: evProj
                    source: eventsModel
                    startDate: content.startDate
                    endDate: content.endDate
                    viewWidth: content.width
                    minPx: 0
                }

                Canvas {
                    height: parent.height
                    width: parent.width/4
                    opacity: 0.2
                    property var from: {"x":0, "y":0}
                    property var to: {"x":width, "y":0}
                    property var startColor: IVColors.get("Colors/Text new/TxContrast")
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.globalAlpha = 0.3
                        var gradient = ctx.createLinearGradient(from.x, from.y, to.x, to.y)
                        gradient.addColorStop(0, startColor)
                        gradient.addColorStop(1, "transparent")
                        ctx.fillStyle = gradient
                        ctx.fillRect(0, 0, width, height)
                    }
                    Component.onCompleted: {
                        requestPaint()
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    enabled: !isCommonPanel
                    acceptedButtons: isCommonPanel ? Qt.NoButton : Qt.LeftButton
                    hoverEnabled: !isCommonPanel
                    cursorShape: timeline.dragging ? Qt.ClosedHandCursor :
                                 containsMouse ? Qt.OpenHandCursor :
                                                 Qt.ArrowCursor
                    onDoubleClicked: function(mouse) {
                        if (root.setInterval)
                            return

                        var viewPoint = mapToItem(containerArea, mouse.x, mouse.y)
                        var mappedX = Math.max(0, viewPoint.x) + root.viewportOffset()
                        root.handleTimelineDoubleClick(mappedX)
                        root.doubleClicked()
                    }
                }

                Rectangle {
                    id: valueBar
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    color: "transparent"
                    height: parent.height/3
                    property var count_: switch (root.timeline_model){
                                         case 0: return 12;
                                         case 1:
                                             if (model.start){
                                                 var month = model.start.getMonth()
                                                 var year = model.start.getFullYear()
                                                 return new Date(year, month+1, 0).getDate();
                                             }
                                             else return 0
                                         case 2: return 7
                                         case 3: return 24
                                         case 4: return 60
                                         case 5: return 30
                                         case 6: return 10
                                         case 7: return 60
                                         default: return 12
                                         }
                    Canvas {
                        id: fulnessLine

                        property real margs: 8
                        property string eventColor: "rgba(53, 165, 92, 0.6)"
                        property real radius: 4

                        visible: !isCommonPanel
                        height: 16
                        width: parent.width
                        anchors.top: parent.bottom
                        anchors.topMargin: margs

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();

                            for (var i = 0; i < content.fnModel.count; i++) {
                                var interval = content.fnModel.get(i);
                                var x = fulnessLine.width * interval.s;
                                var w = fulnessLine.width * (interval.f - interval.s);
                                var h = fulnessLine.height;
                                if (w <= 0) continue;

                                var r = Math.min(fulnessLine.radius, h/2, w/2);

                                ctx.fillStyle = eventColor

                                if (w < 2 * fulnessLine.radius) {
                                    ctx.fillRect(x, 0, w, h);
                                } else {
                                    ctx.beginPath();
                                    ctx.moveTo(x + r,  0);
                                    ctx.lineTo(x + w - r,0);
                                    ctx.arcTo(x + w, 0, x + w, r,   r);
                                    ctx.lineTo(x + w, h - r);
                                    ctx.arcTo(x + w, h, x + w - r, h, r);
                                    ctx.lineTo(x + r, h);
                                    ctx.arcTo(x, h, x, h - r, r);
                                    ctx.lineTo(x, r);
                                    ctx.arcTo(x, 0, x + r, 0, r);
                                    ctx.closePath();
                                    ctx.fill();
                                }
                            }
                        }
                    }

                    Item {
                        id: eventsLayer

                        anchors.fill: parent
                        visible: !isCommonPanel && root.showEvents

                        function updateEventsModel() {
                            eventsListView.model = !isCommonPanel && root.showEvents ? content.evModel : null
                        }

                        Component.onCompleted: updateEventsModel()

                        Component {
                            id: eventsDelegateComponent

                            Item {
                                id: eventDelegate

                                width: 0
                                height: 0

                                property real margs: 8 * root.isize
                                property var eventData: model

                                function switchToEvent(date){
                                    if (!date)
                                        return
                                    root.canAutoMove = true
                                    root.sliderIsDragged = false
                                    root.currentDate = date
                                    root.updateCalendarDT()
                                }

                                Component.onCompleted: eventArea.opacity = 1
                                onEventDataChanged: eventArea.opacity = 1
                                Component.onDestruction: {
                                    if (eventArea)
                                        eventArea.destroy()
                                }

                                MouseArea {
                                    id: eventArea

                                    enabled: !isCommonPanel
                                    parent: eventsLayer
                                    hoverEnabled: true
                                    opacity: 0
                                    x: valueBar.width * eventDelegate.eventData.s - width/2
                                    height: content.height - valueBar.height - 2*eventDelegate.margs
                                    width: height
                                    anchors.top: parent.bottom
                                    anchors.topMargin: eventDelegate.margs

                                    Rectangle {
                                        width: 16
                                        height: 16
                                        radius: 4
                                        color: IVColors.get("Colors/Background new/BgBtnCritical")

                                        IVImage {
                                            width: 16
                                            height: 16
                                            name: "new_images/Event"
                                            color: IVColors.get("Colors/Text new/TxContrast")

                                            ToolTip {
                                                property var s: eventDelegate.eventData.startDate
                                                property string f: "yyyy.MM.dd hh:mm:ss.zzz"
                                                property string dateString: Qt.formatDateTime(s, f)
                                                text: dateString + "\n" + eventDelegate.eventData.comment
                                                visible: eventArea.containsMouse
                                                delay: 150
                                            }
                                        }
                                    }

                                    Behavior on opacity { NumberAnimation { duration: 150 }}

                                    Timer {
                                        id: eventClickTimer
                                        interval: 250
                                        onTriggered: clicked()
                                        function clicked() {
                                            eventDelegate.switchToEvent(eventDelegate.eventData.startDate)
                                        }
                                        function doubleClicked()
                                        {
                                            if (!root.setInterval) root.doubleClicked()
                                            var lTime = eventDelegate.eventData.startDate
                                            var rTime = new Date(lTime.getTime() + 10000)
                                            containerArea.bounds = {"first": lTime, "second": rTime}
                                            firstBound.setX(timeToX(containerArea.bounds.first))
                                            secondBound.setX(timeToX(containerArea.bounds.second))
                                        }
                                    }

                                    onClicked: {
                                        if (eventClickTimer.running) {
                                            eventClickTimer.doubleClicked()
                                            eventClickTimer.stop()
                                        }
                                        else
                                            eventClickTimer.restart()
                                    }
                                }
                            }
                        }

                        ListView {
                            id: eventsListView
                            visible: !isCommonPanel
                            anchors.fill: parent
                            interactive: false
                            orientation: ListView.Horizontal
                            spacing: 0
                            cacheBuffer: width
                            model: null
                            delegate: eventsDelegateComponent
                        }
                    }

                    Row {
                        leftPadding: root.isize
                        rightPadding: root.isize
                        anchors.leftMargin: 1
                        anchors.rightMargin: 1
                        anchors.fill: parent
                        Repeater {
                            id: tpRepeater
                            model: valueBar.count_
                            anchors.fill: parent
                            anchors.leftMargin: root.isize
                            property int elementsCount: 0
                            property int hideElems: -1
                            Rectangle {
                                id: valueTP
                                 width: valueBar.count_ > 0 ? valueBar.width/valueBar.count_ : 0
                                height: valueBar.height
                                color: "transparent"
                                property real textWidth: tpText.contentWidth
                                Label {
                                    id: tpText
                                    text: content.getHighDateText(root.timeline_model, model)
                                    anchors{
                                        left: parent.left
                                        leftMargin: contentWidth > valueTP.width ? getMargin() : 0
                                    }
                                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                    font: IVColors.getFont("subtext")
                                    lineHeight: 14
                                    lineHeightMode: Text.FixedHeight
                                    property real defOpacity: 0.8
                                    opacity: tpRepeater.hideElems < 0 ? 0 :
                                             tpRepeater.hideElems === 0 ? defOpacity :
                                             model.index%(tpRepeater.hideElems) === 0 ? defOpacity : 0
                                    Behavior on opacity {
                                        NumberAnimation { duration: 150 }
                                    }
                                    function getMargin(){
                                        var res = 2*isize
                                        if (model.index > 0){
                                            res = valueTP.width - contentWidth - 2*isize
                                        }
                                        return res
                                    }
                                }
                                Rectangle {
                                    width: 1
                                    height: 6
                                    anchors.horizontalCenter: tpText.horizontalCenter
                                    anchors.top: tpText.bottom
                                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                }
                                function delims(){
                                    var f = Math.floor(width/40)
                                    var res = Math.pow(2, Math.min(4,f))
                                    return (res-1);
                                }
                                Component.onCompleted: {
                                    tpRepeater.elementsCount = parent.children.length-1
                                }
                            }
                            function getHideElems() {
                                if (valueBar.count_ === 0) {
                                    tpRepeater.hideElems = -1
                                    return
                                }
                                var currWidth = width / valueBar.count_
                                var minTextWidth = currWidth
                                for (var i = 0; i < valueBar.count_; i++){
                                    minTextWidth = Math.min(minTextWidth, itemAt(i).textWidth)
                                }
                                if (minTextWidth * 2 < currWidth) tpRepeater.hideElems = 0
                                else if (minTextWidth * 1.5 < currWidth) tpRepeater.hideElems = 2
                                else if (minTextWidth < currWidth) tpRepeater.hideElems = 5
                                else tpRepeater.hideElems = 10
                            }
                            onElementsCountChanged: {
                                if (elementsCount === valueBar.count_) getHideElems()
                            }
                            onWidthChanged: {
                                if (elementsCount > 0) getHideElems()
                            }
                        }
                    }
                }

                Connections {
                    target: fullnessModel
                    onCountChanged: content.loadFullness()
                    onDateCheckSumChanged: content.loadFullness()
                }

                Connections {
                    target: fnProj
                    onCountChanged: fulnessLine.requestPaint()
                }

                Connections {
                    target: evProj
                    onCountChanged: eventsLayer.updateEventsModel()
                }

                Connections {
                    target: eventsModel
                    onDateCheckSumChanged: content.loadEvents()
                }

                Connections {
                    target: root
                    onShowEventsChanged: {
                        if (root.showEvents)
                            content.loadEvents()
                        eventsLayer.updateEventsModel()
                    }
                }

                Component.onCompleted: {
                    loadFullness()
                    if (root.showEvents) loadEvents()
                }

                function getHighDateText(view, model_){
                    if (model_){
                        if (model.start){
                            var time = model.start;
                            var date = time.getDate()
                            var month = time.getMonth()+1
                            var hours = time.getHours()
                            var minutes = time.getMinutes()
                            var seconds = time.getSeconds()

                            var d_WeekScale = new Date(new Date(time).setDate(date+model_.index))

                            switch (view){
                            case 0: return root.getMonthModel(model_.index)
                            case 1: return (model_.index+1 < 10 ? "0"+(model_.index+1) : (model_.index+1)) + "." + (month < 10 ? "0"+month : month)
                            case 2: return (d_WeekScale.getDate() < 10 ? "0"+(d_WeekScale.getDate()) : (d_WeekScale.getDate())) + "." + ((d_WeekScale.getMonth()+1) < 10 ? "0"+(d_WeekScale.getMonth()+1) : (d_WeekScale.getMonth()+1))
                            case 3: return (model_.index < 10 ? "0"+model_.index : model_.index) + ":00"
                            case 4: return (hours < 10 ? "0"+hours : hours) + ":" + (model_.index < 10 ? "0"+model_.index : model_.index)
                            case 5: return (hours < 10 ? "0"+hours : hours) + ":" + ((minutes+model_.index) < 10 ? "0"+(minutes+model_.index) : (minutes+model_.index))
                            case 6: return (hours < 10 ? "0"+hours : hours) + ":" + ((minutes+model_.index) < 10 ? "0"+(minutes+model_.index) : (minutes+model_.index))
                            case 7: return (hours < 10 ? "0"+hours : hours) + ":" + (minutes < 10 ? "0"+minutes : minutes) + ":" + (model_.index < 10 ? "0"+model_.index : model_.index)
                            }
                        }
                    }
                    return ""
                }
            }
        }
    }
    function getMonthModel(ind){
        switch (ind){
        case 0: return Language.getTranslate("January", "Январь");
        case 1: return Language.getTranslate("February", "Февраль");
        case 2: return Language.getTranslate("March", "Март");
        case 3: return Language.getTranslate("April", "Апрель");
        case 4: return Language.getTranslate("May", "Май");
        case 5: return Language.getTranslate("June", "Июнь");
        case 6: return Language.getTranslate("July", "Июль");
        case 7: return Language.getTranslate("August", "Август");
        case 8: return Language.getTranslate("September", "Сентябрь");
        case 9: return Language.getTranslate("October", "Октябрь");
        case 10: return Language.getTranslate("November", "Ноябрь");
        case 11: return Language.getTranslate("December", "Декабрь");
        }
    }
    onArchivePlayerChanged: updateFilter()
    onCurrentDateChanged: {
        if (currentDate < new Date(10) || currentDate > new Date()){
            currentDate = new Date();
        }
        if (!root.sliderIsDragged) sliderRect.setX(root.timeToX(root.currentDate))
        if (root.canAutoMove){
            if (timeline.needToUpdate()){
                root.ready = false;
                refreshModel()
            }
            timeline.contentX = sliderRect.getX()-timeline.width/2+timeline.originX
        }
    }
    onIsMultiscreenChanged: {
        root.ready = false;
        refreshModel()
        timeline.contentX = sliderRect.getX()-timeline.width/2+timeline.originX
        root.canAutoMove = true;
    }
    onDelegWidthChanged: {
        timeline.prevWidth = timeline.contentWidth
        timeline.prevOriginX = timeline.originX
        timeline.mapMouseToContent = marea.mapToItem(timeline.contentItem,marea.mouseX,marea.mouseY).x-timeline.originX
        firstBound.setX(timeToX(containerArea.bounds.first))
        secondBound.setX(timeToX(containerArea.bounds.second))
    }
    onTimeline_modelChanged: refreshModel()
    onCanAutoMoveChanged: {
        if (root.canAutoMove){
            if (timeline.needToUpdate()){
                root.ready = false;
                refreshModel()
            }
            timeline.contentX = sliderRect.getX()-timeline.width/2+timeline.originX
        }
    }

    onElementScaleChanged: {
        root.syncScale()
        root.isScaleChange = true
    }

    onSetIntervalChanged: {
        if (setInterval) {
            containerArea.firstSet = true
            containerArea.secondSet = true
            containerArea.secondVisible = true
            applyDefaultInterval()
        } else {
            containerArea.firstSet = false
            containerArea.secondSet = false
            containerArea.secondVisible = false
        }
    }

    onWidthChanged: {
        if (root.tempWidth < root.width/2)
            root.tempWidth = root.width
    }

    onIntervalBeforeIndexChanged: {
        var beforeMs = intervalMs(root.intervalBeforeIndex)
        var afterMs = intervalMs(root.intervalAfterIndex)
        if (!root._syncingInterval)
            updateScaleForOffsets(beforeMs, afterMs)
        if (!root._syncingInterval)
            applyDefaultInterval()
    }

    onIntervalAfterIndexChanged: {
        var beforeMs = intervalMs(root.intervalBeforeIndex)
        var afterMs = intervalMs(root.intervalAfterIndex)
        if (!root._syncingInterval)
            updateScaleForOffsets(beforeMs, afterMs)
        if (!root._syncingInterval)
            applyDefaultInterval()
    }

    onBoundsChanged: {
        if (!root._syncingInterval)
            syncOffsetsWithBounds()
    }

    function setVisibleIfChanged(obj, v) { if (obj && obj.visible !== v) obj.visible = v }
    function setXIfChanged(obj, vx) { if (obj && obj.x !== vx) obj.x = vx }
    function viewportOffset() {
        var offset = timeline.contentX - timeline.originX
        var maxOffset = timeline.contentWidth - timeline.width
        if (!isFinite(offset))
            offset = 0
        if (!isFinite(maxOffset))
            maxOffset = 0
        maxOffset = Math.max(0, maxOffset)
        if (offset < 0)
            offset = 0
        else if (offset > maxOffset)
            offset = maxOffset
        return offset
    }

    function handleTimelineDoubleClick(mappedX) {
        if (root.setInterval)
            return

        var maxX = Math.min(nowX, timeline.contentWidth)
        var centerX = Math.max(0, Math.min(mappedX, maxX))

        root.sliderIsDragged = false
        root.canAutoMove = true

        sliderRect.setX(centerX)

        root.currentDate = root.xToTime(sliderRect.getX())
        root.updateCalendarDT()
    }

    function clampToNowX(mappedX) {
        var maxX = nowX
        if (!isFinite(maxX) || maxX <= 0)
            maxX = mappedX
        return Math.min(mappedX, maxX)
    }

    property real nowX: 0
    onNowDateTimeChanged: nowX = timeToX(nowDateTime)

    function updateFilter(mylist){
        var resFilter = []
        if (mylist) resFilter = mylist
        eventsFilter = resFilter
        updateEvJson()
    }

    function toLeftEvents(evtType) {
        var currTimeMs = root.currentDate && root.currentDate.getTime ? root.currentDate.getTime() : 0
        var resMs = eventsModel.leftEventTime(currTimeMs, evtType)
        if (resMs >= 0) {
            root.canAutoMove = true
            root.sliderIsDragged = false
            root.currentDate = new Date(resMs)
            return true
        }
        return false
    }

    function toRightEvents(evtType) {
        var currTimeMs = root.currentDate && root.currentDate.getTime ? root.currentDate.getTime() : 0
        var resMs = eventsModel.rightEventTime(currTimeMs, evtType)
        if (resMs >= 0 && resMs < root.nowDateTime.getTime()) {
            root.canAutoMove = true
            root.sliderIsDragged = false
            root.currentDate = new Date(resMs)
            return true
        }
        return false
    }

    function getEvents(start, end, skipTime) {
        if (root.archivePlayer) {
            root.archivePlayer.getEvents(start, end, skipTime, root.key2, root.timeline_model);
        }
    }
    function requestEvents(){
        var a = !root.isCommonPanel
        var b = !iv_vcli_setting_arc.val
        var c = root.showEvents
        var d = root.showBookmarks
        if (a && b && (c || d)){
            eventsTimer.start()
        }
    }

    function refreshModel(){
        var today
        if (!root.ready) today = root.currentDate
        else {
            var tl_start = timelineModel.get(0)["start"]
            var tl_end = timelineModel.get(timelineModel.count-1)["end"]
            var tl_time = tl_end - tl_start

            today = new Date(tl_start.getTime() + tl_time * timeline.mapMouseToContent/timeline.contentWidth)
            refreshTimer.mousePos = timeline.mapMouseX;
        }
        refreshTimer.today = today

        if  (root.timeline_model == 2) {
            today = new Date(new Date(today).setDate(today.getDate()-today.getDay()+1))
        }
        timelineModel.clear()

        var currentDateIndex = parseInt(root.getCurrDateIndex(today))
        for (var j = 0; j < currentDateIndex; j++){
            today = root.decrementDate(root.timeline_model, today)
        }
        for (var i = 0; i < timelineModel.countElems; i ++){
            var obj = {"start": today,
                "end":root.incrementDate(root.timeline_model, today)
            }
            timelineModel.append(obj)
            today = root.incrementDate(root.timeline_model, today)
        }
        timeline.positionViewAtIndex(root.getCurrDateIndex(root.currentDate), ListView.SnapPosition)
        refreshTimer.start()
    }
    function setPreviewSource(source) {
        previewFrame.source = source
        if (source !== '' && containerArea.containsMouse){
            previewFrame.visible = true
        }
    }
    function getSelectedInterval(){
        var first = containerArea.bounds.first
        var second = containerArea.bounds.second
        return {"left":Math.min(first, second), "right": Math.max(first, second)}
    }
    function getViewBounds(){
        var offset = viewportOffset()
        var width = timeline.width

        return {"left": xToTime(offset), "right": xToTime(offset + width)}
    }
    function setBounds(first, second){
        var now = root.nowDateTime || new Date()
        var clampedFirst = first
        var clampedSecond = second
        if (clampedFirst && clampedFirst.getTime && clampedFirst.getTime() > now.getTime())
            clampedFirst = now
        if (clampedSecond && clampedSecond.getTime && clampedSecond.getTime() > now.getTime())
            clampedSecond = now
        firstBound.setX(timeToX(clampedFirst))
        containerArea.bounds.first = clampedFirst
        secondBound.setX(timeToX(clampedSecond))
        containerArea.bounds.second = clampedSecond
    }
    // обновить масштаб в зависимости от множителя ширины
    function syncScale(){
        if (root.elementScale < modelStep) {root.timeline_model = 0; return true}
        else if (root.elementScale < modelStep * 2) {root.timeline_model = 1; return true}
        else if (root.elementScale < modelStep * 3) {root.timeline_model = 2; return true}
        else if (root.elementScale < modelStep * 4) {root.timeline_model = 3; return true}
        else if (root.elementScale < modelStep * 5) {root.timeline_model = 4; return true}
        else if (root.elementScale < modelStep * 6) {root.timeline_model = 5; return true}
        else if (root.elementScale < modelStep * 7) {root.timeline_model = 6; return true}
        else if (root.elementScale < root.maxScale) {root.timeline_model = 7; return true}
        return false;
    }
    // задать множитель ширины по значению масштаба
    function setScale(new_timeline_model){
        if (new_timeline_model === root.timeline_model) return
        root.ready = false
        root.canAutoMove = true
        if (new_timeline_model === 0) root.elementScale = 1
        else if (new_timeline_model === 1) root.elementScale = modelStep * 1
        else if (new_timeline_model === 2) root.elementScale = modelStep * 2
        else if (new_timeline_model === 3) root.elementScale = modelStep * 3
        else if (new_timeline_model === 4) root.elementScale = modelStep * 4
        else if (new_timeline_model === 5) root.elementScale = modelStep * 5
        else if (new_timeline_model === 6) root.elementScale = modelStep * 6
        else if (new_timeline_model === 7) root.elementScale = modelStep * 7
    }
    function getCurrDateIndex(today){
        var now = new Date()
        var y = now.getFullYear();
        var m = now.getMonth();
        var d = now.getDate();
        var h = now.getHours();
        var min = now.getMinutes();
        var currDateIndex = parseInt(timelineModel.countElems/2)

        switch (root.timeline_model)
        {
        case 0: if (today >= new Date(y, 0, 1, 0, 0, 0))
                currDateIndex = timelineModel.countElems-2
            break
        case 1: if (today >= new Date(y, m, 1, 0, 0, 0))
                currDateIndex = timelineModel.countElems-2
            break
        case 2: if (today >= new Date(y, m, Math.floor(d/7), 0, 0, 0))
                currDateIndex = timelineModel.countElems-2
            break
        case 3: if (today >= new Date(y, m, d, h, 0, 0))
                currDateIndex = timelineModel.countElems-2
            break
        case 4: if (today >= new Date(y, m, d, h, min, 0))
                currDateIndex = timelineModel.countElems-2
            break
        case 5: if (today >= new Date(y, m, d, h, Math.floor(min/30)*30, 0)) //30 min
                currDateIndex = timelineModel.countElems-2;
            break
        case 6: if (today >= new Date(y, m, d, h, Math.floor(min/10)*10, 0)) //10 min
                currDateIndex = timelineModel.countElems-2;
            break;
        case 7: if (today >= new Date(y, m, d, h, min, 0))
                currDateIndex = timelineModel.countElems-2;
            break
        }
        return currDateIndex;
    }
    function incrementDate(view, date){
        var second = date.getSeconds();
        var minute = date.getMinutes();
        var hour = date.getHours();
        var day = date.getDate();
        var month = date.getMonth();
        var year = date.getFullYear();
        var new_date;

        switch (view){
        case 0:
            new_date = new Date(year+1, 0, 1,0,0,0,0,0,0);
            return new_date;
        case 1:
            new_date = new Date(year, month+1, 1,0,0,0,0,0);
            return new_date;
        case 2:
            new_date = new Date(year, month, day+7,0,0,0,0);
            return new_date;
        case 3:
            new_date = new Date(year, month, day+1,0,0,0,0);
            return new_date;
        case 4:
            new_date = new Date(year, month, day, hour+1,0,0,0,0,0);
            return new_date;
        case 5:
            minute = Math.floor(minute/30)*30
            new_date = new Date(year, month, day, hour, minute+30,0,0,0,0);
            return new_date;
        case 6:
            minute = Math.floor(minute/10)*10
            new_date = new Date(year, month, day, hour, minute+10,0,0,0,0);
            return new_date;
        case 7:
            new_date = new Date(year, month, day, hour, minute+1,0,0);
            return new_date;
        }
    }
    function decrementDate(view, date){
        var second = date.getSeconds();
        var minute = date.getMinutes();
        var hour = date.getHours();
        var day = date.getDate();
        var month = date.getMonth();
        var year = date.getFullYear();
        var new_date;

        switch (view){
        case 0:
            new_date = new Date(year-1, 0, 1,0,0,0,0,0,0);
            return new_date;
        case 1:
            new_date = new Date(year, month-1, 1,0,0,0,0,0);
            return new_date;
        case 2:
            new_date = new Date(year, month, day-7,0,0,0,0);
            return new_date;
        case 3:
            new_date = new Date(year, month, day-1,0,0,0,0);
            return new_date;
        case 4:
            new_date = new Date(year, month, day, hour-1,0,0,0);
            return new_date;
        case 5:
            minute = Math.floor(minute/30)*30
            new_date = new Date(year, month, day, hour, minute-30,0,0,0,0);
            return new_date;
        case 6:
            minute = Math.floor(minute/10)*10
            new_date = new Date(year, month, day, hour, minute-10,0,0,0,0);
            return new_date;
        case 7:
            new_date = new Date(year, month, day, hour, minute-1,0,0);
            return new_date;
        }
    }

    function xToTime(posX){
        var indexAtPos = Math.floor(posX / root.delegWidth)

        if (indexAtPos < 0 || timelineModel.count < 1)
            return new Date(0);
        if (indexAtPos >= timelineModel.count || posX === root.delegWidth*timelineModel.count)
            return timelineModel.get(timelineModel.count-1)["end"]
        if (posX === 0)
            return timelineModel.get(0)["start"]

        var start = 0, allTime = 0, posAtDeleg = 0, res
        if (root.timeline_model < 2){
            posAtDeleg = (posX % root.delegWidth) / root.delegWidth
            start = timelineModel.get(indexAtPos)["start"].getTime()
            allTime = timelineModel.get(indexAtPos)["end"].getTime()
        }
        else {
            posAtDeleg = posX / (root.delegWidth*timelineModel.count)
            start = timelineModel.get(0)["start"].getTime()
            allTime = timelineModel.get(timelineModel.count-1)["end"].getTime()
        }
        allTime -= start
        res = Math.floor(start + (allTime * posAtDeleg))
        return new Date(res)
    }

    function timeToX(date){
        if (timelineModel.count < 1) return -1
        var start = timelineModel.get(0)["start"].getTime()
        var end = timelineModel.get(timelineModel.count-1)["end"].getTime()
        if (date.getTime() <= start) return 0
        else if (date.getTime() >= end) return timeline.contentWidth

        var res = 0, i = 0, ratio = (date.getTime() - start) / (end - start)
        if (root.timeline_model >= 2){
            return ratio * timeline.contentWidth
        }
        while (date.getTime() > timelineModel.get(i)["end"].getTime()){
            i++
        }
        start = timelineModel.get(i)["start"].getTime()
        end = timelineModel.get(i)["end"].getTime()
        ratio = (date.getTime() - start) / (end - start)
        return (i * root.delegWidth) + ratio * root.delegWidth
    }
}

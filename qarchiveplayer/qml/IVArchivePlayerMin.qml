import QtQml 2.3
import QtQuick 2.11
import iv.renders.renderselector 1.0
import iv.plugins.loader 1.0
import QtQuick.Window 2.2
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.0
import QtQml.Models 2.3
import QtQuick.Dialogs 1.2
import iv.guicomponents 1.0
import iv.calendar 1.0
import iv.archivecomponents.selectinterval 1.0
import ArchiveComponents 1.0
import QtQuick.Controls.Styles 1.4

import iv.plugins.users 1.0
import iv.singletonLang 1.0

import iv.colors 1.0
import iv.controls 1.0 as C

Item {
    id: root

    property var globalComponent: null
    property bool __registeredInCommonArchive: false
    property var __registeredCommonArchiveTarget: null

    property alias idarchive_player: idarchive_player
    property alias archiveStreamer: archiveStreamer

    readonly property bool commonArchiveStripVisible: __registeredCommonArchiveTarget
                                                     && __registeredCommonArchiveTarget.commonArchiveStrip
                                                     && __registeredCommonArchiveTarget.commonArchiveStrip.visible

    function registerInCommonArchive(target) {
        if (!target || !target.registerArchivePlayerMin)
            return;
        target.registerArchivePlayerMin(root);
        __registeredInCommonArchive = true;
        __registeredCommonArchiveTarget = target;
    }

    function unregisterFromCommonArchive() {
        if (!__registeredInCommonArchive || !__registeredCommonArchiveTarget)
            return;
        if (__registeredCommonArchiveTarget.unregisterArchivePlayerMin)
            __registeredCommonArchiveTarget.unregisterArchivePlayerMin(root);
        __registeredInCommonArchive = false;
        __registeredCommonArchiveTarget = null;
    }

    function getFrameTime() {
        if (archiveStreamer)
            return archiveStreamer.currentTime;
    }

    onGlobalComponentChanged: {
        if (__registeredCommonArchiveTarget && __registeredCommonArchiveTarget !== globalComponent)
            unregisterFromCommonArchive();

        if (!__registeredInCommonArchive && globalComponent)
            registerInCommonArchive(globalComponent);
    }

    function validateSettings(value){
        try { JSON.parse(value) }
        catch (e) { return null }
        return JSON.parse(value)
    }

    function funcSwitchSelectIntervalMode() {
        if (!root.exportEnabled)
            return;
        isIntervalMode = !isIntervalMode
        iv_arc_slider_new.setInterval=isIntervalMode
    }

    function funcSwitchToFullScreen() {
        if (viewer_command_obj !== null || viewer_command_obj !== undefined) {
            viewer_command_obj.command_to_viewer('viewers:fullscreen')
        }
    }

    function functReturnToRealtime() {
        if (viewer_command_obj !== null || viewer_command_obj !== undefined) {
            viewer_command_obj.command_to_viewer('viewers:switch')
        }
    }

    function funcCloseCamera() {
        var control = root.viewer_command_obj.myGlobalComponent.ivSetsArea
        if (control !== null && control !== undefined) {
            root.viewer_command_obj.command_to_viewer('sets:area:removecamera2')
        } else {
            root.viewer_command_obj.myGlobalComponent.command1('windows:hide',
                                                               root, {
                                                                   id: root.Window.window.unique
                                                               })
        }
    }

    function funcCloseSet() {
        shortcutLastSequence1.value = "Ctrl+W"
        shortcutLastSequence1.value = "@$##$&*()#"
    }

    Component.onCompleted: {
        if (globalComponent)
            registerInCommonArchive(globalComponent);
    }

    Component.onDestruction: unregisterFromCommonArchive()

    IvVcliSetting {
        id: shortcutLastSequence1
        name: 'keyboard.signals.' + root.Window.window.unique
    }

    IvVcliSetting {
      id: vcliStretching
      name: 'cameras.stretching'
    }

    IvVcliSetting {
        id: stripScale
        name: 'archive.strip_scale'
    }

    SoundSlider {
        id: soundSlider

        z: mainMouseArea.z+1
        visible: false

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 8
        }
    }

    ArchiveMarker {
        id: _archiveMarker
        z: mainMouseArea.z+6

        anchors.fill: parent
        anchors.margins: 1

        onClicked: {
            if (!root.common_panel) {
                if (viewer_command_obj !== null || viewer_command_obj !== undefined) {
                    viewer_command_obj.command_to_viewer('viewers:switch')
                }
            }
        }
    }

    ArchivePlayer {
        id: idarchive_player

        isNewStrip: true

        onFnJsonChanged: {
            iv_arc_slider_new.updateFnJson();
        }

        onEvJsonChanged: {
            iv_arc_slider_new.updateEvJson();
        }

        onDrawPreviewQML123: {
            if (status !== -1) {
                iv_arc_slider_new.setPreviewSource(url)
            }
        }
    }

    WebSocketClient {
        id: wsClient
        url: appInfo.wsUrl
    }


    ImagePipeline {
        id: imagePipeline
        cameraId: root.cameraId
    }


    ArchiveSegmentStreamer {
        id: archiveStreamer

        client: wsClient
        imagePipeline: imagePipeline

        cameraName: root.cameraId
        archiveId: root.archiveId

    }

    property string cameraId: root.key2 ? root.key2 : ""
    property string archiveId: "Quality"
    property bool exportEnabled: true
    property bool stretchImage: vcliStretching.value==="true"?true:false

    property real cameraAspectRatio: {
        var resolution = archiveStreamer.cameraResolution || ""
        var match = resolution.match(/(\d+)\D+(\d+)/)
        if (match && match.length >= 3) {
            var w = Number(match[1])
            var h = Number(match[2])
            if (w > 0 && h > 0)
                return w / h
        }
        if (root.width > 0 && root.height > 0)
            return root.width / root.height
        return 1
    }

    property string archiveBackTime: archiveStreamer.currentTime || ""
    property string archiveBackDate: archiveStreamer.currentDate || ""

    property bool _suppressTimeUpdates: false

    Timer {
        id: _coalesceBackendTs

        interval: 0
        repeat: false
        onTriggered: {
            if (_suppressTimeUpdates) return
            if (!archiveBackDate || !archiveBackTime) return
            var s  = archiveBackDate + " " + archiveBackTime
            var dt = Date.fromLocaleString(Qt.locale(), s, "dd.MM.yyyy hh:mm:ss.zzz")
            var dtPlus5 = new Date(dt.getTime() + 1500)
            _suppressTimeUpdates = true
            archiveControls.calendarButton.calendar.chosenDate = Qt.formatDate(dt, "dd.MM.yyyy")
            archiveControls.calendarButton.calendar.chosenTime = Qt.formatTime(dt, "hh:mm:ss")
            root.archiveTime = dt
            iv_arc_slider_new.currentDate = dt
            _suppressTimeUpdates = false
        }
    }

    onArchiveBackTimeChanged: _coalesceBackendTs.restart()
    onArchiveBackDateChanged: _coalesceBackendTs.restart()

    property bool isCommonPanel: false
    property var archiveTime
    property bool needToUpdateArchive: true
    property bool archiveIsPlaying: !archiveStreamer.paused
    property bool archiveIsPaused: Boolean(archiveStreamer.paused)
    property bool running: true

    property bool isMinutesLimit: false
    property bool isMemoryLimit: false
    property bool isCombinedLimit: false

    property int exportIntervalBeforeIndex: 2
    property int exportIntervalAfterIndex: 4

    property int m_i_curr_scale: validateSettings(stripScale.value) !== null ? validateSettings(stripScale.value) : 4

    onM_i_curr_scaleChanged: {
        if (iv_arc_slider_new) {
            iv_arc_slider_new.setScale(root.m_i_curr_scale)
        }
    }

    function updateTimeFromCalendar() {
        if (_suppressTimeUpdates) return
        var chosenDateTime = archiveControls.calendarButton.calendar.chosenDate + " " + archiveControls.calendarButton.calendar.chosenTime
        var time = Date.fromLocaleString(Qt.locale(), chosenDateTime, "dd.MM.yyyy hh:mm:ss")
        _suppressTimeUpdates = true
        iv_arc_slider_new.currentDate = time
        root.archiveTime = time
        _suppressTimeUpdates = false

        if (root.archiveIsPaused) {
            archiveStreamer.requestPreviewAt(root.cameraId, root.archiveTime, root.archiveId)
            root.needToUpdateArchive = true
        } else {
            archiveStreamer.delayStart(root.cameraId, root.archiveTime, root.archiveId)
        }
    }

    function updateTimeFromSlider() {
        if (_suppressTimeUpdates) return
        var time = iv_arc_slider_new.currentDate
        _suppressTimeUpdates = true
        archiveControls.calendarButton.calendar.chosenDate = Qt.formatDate(time, "dd.MM.yyyy")
        archiveControls.calendarButton.calendar.chosenTime = Qt.formatTime(time, "hh:mm:ss")
        root.archiveTime = time
        _suppressTimeUpdates = false

        if (root.archiveIsPaused) {
            archiveStreamer.requestPreviewAt(root.cameraId, root.archiveTime, root.archiveId)
            root.needToUpdateArchive = true
        } else {
            archiveStreamer.delayStart(root.cameraId, root.archiveTime, root.archiveId)
        }
    }

    Binding {
        target: appInfo
        property: "archiveKey2"
        value: root.key2
    }

    property string key2: ''
    property string key3: ''

    property variant viewer_command_obj: null
    property int is_export_media: 0
    property bool isFullscreen: false
    property bool isIntervalMode: false

    property int m_uu_i_ms_begin_interval: 0
    property int m_uu_i_ms_end_interval: 0

    property var cache_preview: []
    property bool is_multiscreen: false
    property bool prev_condition_is_fullscreen

    onIsFullscreenChanged: {
        if (root.prev_condition_is_fullscreen === false && root.isFullscreen === true) {
            if (root.viewer_command_obj != null
                    && root.viewer_command_obj != undefined
                    && root.viewer_command_obj.myGlobalComponent !== null
                    && root.viewer_command_obj.myGlobalComponent !== undefined
                    && root.viewer_command_obj.myGlobalComponent.isOneCamInSet !== undefined)
            {
                if (root.viewer_command_obj.myGlobalComponent.isOneCamInSet === true)root.is_multiscreen = false;
            }
            else
                root.is_multiscreen = false;
        }
        else if (root.prev_condition_is_fullscreen === true && root.isFullscreen === false)
        {
            if (root.viewer_command_obj != null
                    && root.viewer_command_obj != undefined
                    && root.viewer_command_obj.myGlobalComponent !== null
                    && root.viewer_command_obj.myGlobalComponent !== undefined
                    && root.viewer_command_obj.myGlobalComponent.isOneCamInSet !== undefined)
            {
                if (root.viewer_command_obj.myGlobalComponent.isOneCamInSet === true){
                    root.is_multiscreen = true;
                }
            }
            else {
                root.is_multiscreen = false;
            }
            idarchive_player.stop_thread()
            root.cache_preview.splice(0, root.cache_preview.length)
        }
        root.prev_condition_is_fullscreen = root.isFullscreen
    }

    onViewer_command_objChanged: {
        if (root.viewer_command_obj != null && root.viewer_command_obj != undefined &&
                root.viewer_command_obj.myGlobalComponent !== null && root.viewer_command_obj.myGlobalComponent !== undefined
                && root.viewer_command_obj.myGlobalComponent.isOneCamInSet !== undefined)
        {
            if (root.viewer_command_obj.myGlobalComponent.isOneCamInSet === true
                    || (root.prev_condition_is_fullscreen === false && root.isFullscreen === true) ||
                    (root.prev_condition_is_fullscreen === true && root.isFullscreen === true))
            {
                root.is_multiscreen = false;
            }
            else
            {
                root.is_multiscreen = true;
            }
        }
        else
        {
            root.is_multiscreen = false;
        }
    }

    signal nessUpdateCalendarDecrAP

    MouseArea {
        id: mainMouseArea
        z: 1
        anchors.fill: parent
        anchors.margins:
        {
            left:1
            right:1
            top:1
            bottom:1
        }

        acceptedButtons: Qt.RightButton
        hoverEnabled: true
        propagateComposedEvents: true

        Item {
            id: render_rct
            anchors.fill: parent
            z: 1

            Rectangle {
                anchors.fill: parent
                color: 'transparent'
                z: 1

                MouseArea {
                    id: mouseAreaRender

                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    hoverEnabled: true
                    propagateComposedEvents: true

                    onPressed: if (mouse.button === Qt.LeftButton) mouse.accepted = false
                    onPositionChanged: if (mouse.buttons & Qt.LeftButton) mouse.accepted = false

                    onClicked: {
                        if (mouse.button & Qt.RightButton) {
                            contextMenu.x = mouse.x
                            contextMenu.y = mouse.y
                            contextMenu.open()
                            mouse.accept = true
                        }
                        else mouse.accepted = false
                    }

                    Loader {
                        id: menuLoaderContext_menu2

                        asynchronous: true

                        property var componentMenu: null
                        property string menu_source0_text: ''
                        property string menu_source1_text: ''
                        property string menu_source2_text: ''
                        property string menu_source3_text: ''
                        property string menu_source4_text: ''
                        property string menu_source5_text: ''
                        property string menu_source6_text: ''

                        function create() {
                            var qmlFile2 = 'file:///' + applicationDirPath
                                    + '/qtplugins/iv/ivcontextmenurealtime/IVContextMenuRealtime.qml'
                            menuLoaderContext_menu2.source = qmlFile2
                        }
                        function refresh() {
                            menuLoaderContext_menu2.destroy()
                            menuLoaderContext_menu2.create()
                        }
                        function destroy() {
                            if (menuLoaderContext_menu2.status !== Loader.Null)
                                menuLoaderContext_menu2.source = ""
                        }
                        onStatusChanged: {
                            if (menuLoaderContext_menu2.status === Loader.Ready) {
                                menuLoaderContext_menu2.componentMenu = menuLoaderContext_menu2.item
                            }
                            if (menuLoaderContext_menu2.status === Loader.Error) {
                            }
                            if (menuLoaderContext_menu2.status === Loader.Null) {

                            }
                        }
                    }
                }
            }

            Item {
                id: videoSurface

                anchors.centerIn: parent
                z: 2

                readonly property real containerAspect: (parent.height > 0) ? parent.width / parent.height : 1
                readonly property real sourceAspect: root.cameraAspectRatio > 0 ? root.cameraAspectRatio : containerAspect

                width: root.stretchImage
                        ? parent.width
                        : (containerAspect > sourceAspect
                            ? parent.height * sourceAspect
                            : parent.width)
                height: root.stretchImage
                        ? parent.height
                        : (containerAspect > sourceAspect
                            ? parent.height
                            : (sourceAspect > 0
                                ? parent.width / sourceAspect
                                : parent.height))

                Item {
                    id: content
                    anchors.fill: parent

                    layer.enabled: true
                    layer.smooth: true
                    layer.mipmap: true

                    property real zoom: 1.0
                    property real minZoom: 1.0
                    property real maxZoom: 12.0
                    property real tx: 0.0
                    property real ty: 0.0

                    property real anchorCx: 0
                    property real anchorCy: 0

                    function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }


                    function viewToContent(px, py) {
                        return { x: (px - tx) / zoom, y: (py - ty) / zoom }
                    }

                    function zoomAt(px, py, factor) {
                        var oldZoom = zoom
                        var newZoom = clamp(oldZoom * factor, minZoom, maxZoom)
                        if (newZoom === oldZoom) return

                        var c = viewToContent(px, py)
                        zoom = newZoom
                        tx = px - c.x * zoom
                        ty = py - c.y * zoom
                        boundTranslation()
                    }

                    function boundTranslation() {
                        var vw = videoWrapper.width
                        var vh = videoWrapper.height
                        var cw = vw * zoom
                        var ch = vh * zoom

                        var vpw = videoSurface.width
                        var vph = videoSurface.height

                        var minTx = (cw >= vpw) ? (vpw - cw) : (vpw - cw) / 2
                        var maxTx = (cw >= vpw) ? 0 : (vpw - cw) / 2
                        var minTy = (ch >= vph) ? (vph - ch) : (vph - ch) / 2
                        var maxTy = (ch >= vph) ? 0 : (vph - ch) / 2

                        tx = clamp(tx, minTx, maxTx)
                        ty = clamp(ty, minTy, maxTy)
                    }

                    Item {
                        id: videoWrapper
                        width: parent.width
                        height: parent.height

                        transform: [
                            Scale { origin.x: 0; origin.y: 0; xScale: content.zoom; yScale: content.zoom },
                            Translate { x: content.tx; y: content.ty }
                        ]

                        VideoItem {
                            id: videoItem
                            anchors.fill: parent
                            source: archiveStreamer
                            pipeline: imagePipeline
                            fillMode: root.stretchImage ? VideoItem.Fill : VideoItem.Fit

                            transform: Scale {
                                yScale: -1
                                origin.x: videoItem.width / 2
                                origin.y: videoItem.height / 2
                            }
                        }

                        PrimitiveOverlay {
                            id: overlayCanvas
                            anchors.fill: parent
                            visible: archiveStreamer.drawPrimitives
                            primitives: archiveStreamer.currentPrimitives

                            transform: Scale {
                                yScale: -1
                                origin.x: videoItem.width / 2
                                origin.y: videoItem.height / 2
                            }
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true

                        property real lastX: 0
                        property real lastY: 0

                        onPressed: {
                            lastX = mouse.x
                            lastY = mouse.y
                        }
                        onPositionChanged: {
                            if (mouse.buttons & Qt.LeftButton) {
                                var dx = mouse.x - lastX
                                var dy = mouse.y - lastY
                                content.tx += dx
                                content.ty += dy
                                content.boundTranslation()
                                lastX = mouse.x
                                lastY = mouse.y
                            }
                        }
                        onWheel: {
                            var steps = (wheel.angleDelta.y || wheel.angleDelta.x) / 120.0
                            if (!steps) return
                            var factor = Math.pow(1.2, steps)
                            content.zoomAt(wheel.x, wheel.y, factor)
                            wheel.accepted = true
                        }
                        onDoubleClicked: {
                          if (mouse.button === Qt.LeftButton) {
                            viewer_command_obj && viewer_command_obj.command_to_viewer("viewers:fullscreen")
                            mouse.accepted = true
                          } else {
                            mouse.accepted = false
                          }
                        }
                    }

                    PinchArea {
                        anchors.fill: parent
                        pinch.target: null

                        property real startZoom: 1.0
                        property real startTx: 0.0
                        property real startTy: 0.0

                        onPinchStarted: {
                            startZoom = content.zoom
                            startTx = content.tx
                            startTy = content.ty
                            var p = content.viewToContent(pinch.center.x, pinch.center.y)
                            content.anchorCx = p.x
                            content.anchorCy = p.y
                        }
                        onPinchUpdated: {
                            var z = content.clamp(startZoom * pinch.scale, content.minZoom, content.maxZoom)
                            content.zoom = z

                            var px = pinch.center.x
                            var py = pinch.center.y
                            content.tx = px - content.anchorCx * z + pinch.translation.x
                            content.ty = py - content.anchorCy * z + pinch.translation.y

                            content.boundTranslation()
                        }
                        onPinchFinished: content.boundTranslation()
                    }

                    Connections {
                        target: root
                        onWidthChanged: content.boundTranslation()
                        onHeightChanged: content.boundTranslation()
                    }
                    Connections {
                        target: videoSurface
                        onWidthChanged: content.boundTranslation()
                        onHeightChanged: content.boundTranslation()
                    }
                }
            }
        }


        IVButtonTopPanel {
            id: ivButtonTopPanel
            anchors.top: parent.top
            mouseOnPane: mainMouseArea.containsMouse
            parentComponent: root
        }

        Item {
            id: wndControlPanel
            z: 5
            anchors.fill: parent

            ColumnLayout {
                id: cameraInfoBlock

                readonly property bool isTopRight: (archiveControls.settingButtons.posAlignment & (Qt.AlignTop | Qt.AlignRight)) === (Qt.AlignTop | Qt.AlignRight)

                z: mainMouseArea.z + 1

                anchors.fill: parent
                anchors.margins: 2
                anchors.bottomMargin: wndControlPanel.visible ? iv_arc_slider_new.height : 0
                anchors.topMargin: (_archiveMarker.visible && isTopRight) ? 24 : 0

                ColumnLayout {
                    Layout.alignment: archiveControls.settingButtons.posAlignment
                    spacing: 0

                    Label {
                        text: root.cameraId
                        Layout.alignment: archiveControls.settingButtons.posAlignment
                        font: IVColors.getFont("Label accent")
                        color: IVColors.get("Colors/Text new/TxContrast")
                        leftPadding: 4
                        rightPadding: 4
                        background: Rectangle {
                            visible: parent.text.length > 0
                            color: IVColors.get("Colors/Background new/BgFormOverVideo")
                        }
                    }

                    RowLayout {
                        spacing: 0
                        Layout.alignment: archiveControls.settingButtons.posAlignment

                        Label {
                            text: archiveStreamer.currentDate || ""
                            Layout.alignment: archiveControls.settingButtons.posAlignment
                            font: IVColors.getFont("Label accent")
                            leftPadding: 4
                            rightPadding: 4
                            color: IVColors.get("Colors/Text new/TxContrast")
                            background: Rectangle {
                                visible: parent.text.length > 0
                                color: IVColors.get("Colors/Background new/BgFormOverVideo")
                            }
                        }
                        Label {
                            text: archiveStreamer.currentTime || ""
                            Layout.alignment: archiveControls.settingButtons.posAlignment
                            font: IVColors.getFont("Label accent")
                            leftPadding: 4
                            rightPadding: 4
                            color: IVColors.get("Colors/Text new/TxContrast")
                            background: Rectangle {
                                visible: parent.text.length > 0
                                color: IVColors.get("Colors/Background new/BgFormOverVideo")
                            }
                        }
                    }

                    RowLayout {
                        spacing: 0
                        Layout.alignment: archiveControls.settingButtons.posAlignment

                        Label {
                            text: archiveStreamer.cameraResolution || ""
                            Layout.alignment: archiveControls.settingButtons.posAlignment
                            font: IVColors.getFont("Label accent")
                            leftPadding: 4
                            rightPadding: 4
                            color: IVColors.get("Colors/Text new/TxContrast")
                            background: Rectangle {
                                visible: parent.text.length > 0
                                color: IVColors.get("Colors/Background new/BgFormOverVideo")
                            }
                        }
                        Label {
                            text: archiveStreamer.cameraResolution ? Math.round(Number(archiveStreamer.currentFPS)) + " к/c" : ""
                            Layout.alignment: archiveControls.settingButtons.posAlignment
                            font: IVColors.getFont("Label accent")
                            leftPadding: 4
                            rightPadding: 4
                            color: IVColors.get("Colors/Text new/TxContrast")
                            background: Rectangle {
                                visible: parent.text.length > 0
                                color: IVColors.get("Colors/Background new/BgFormOverVideo")
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: iv_arc_menu_new

                property real spacing: 4
                z: cameraInfoBlock.z + 1
                width: archiveControls.width + 2 * spacing
                height: 32
                visible: !root.commonArchiveStripVisible && root.width > archiveControls.implicitWidth

                anchors {
                    bottom: iv_arc_slider_new.top
                    bottomMargin: 8
                    horizontalCenter: parent.horizontalCenter
                }

                color: IVColors.get("Colors/Background new/BgFormOverVideo")
                radius: 8

                ArchiveControls {
                    id: archiveControls

                    z: mainMouseArea.z + 2
                    height: parent.height - parent.spacing*2
                    spacing: parent.spacing

                    anchors {
                        centerIn: parent
                        margins: parent.spacing
                    }

                    archiveStreamer: archiveStreamer
                    iv_arc_slider_new: iv_arc_slider_new
                    imagePipeline: imagePipeline
                    m_i_curr_scale: root.m_i_curr_scale
                    needToUpdateArchive: root.needToUpdateArchive
                    archiveId: root.archiveId
                    rootRef: root
                    cameraId: root.cameraId
                    isIntervalMode: root.isIntervalMode
                    archiveTime: root.archiveTime
                    updateTimeFromSlider: root.updateTimeFromSlider
                    updateTimeFromCalendar: root.updateTimeFromCalendar
                    funcSwitchSelectIntervalMode: root.funcSwitchSelectIntervalMode

                    onScaleChosen: {
                        root.m_i_curr_scale = index
                    }
                    onClearPendingUpdate: {
                        root.needToUpdateArchive = false
                    }
                }
            }

            IVArc_slider_new2 {
                id: iv_arc_slider_new

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                visible: !root.commonArchiveStripVisible && root.width > 622
                height: 40
                archivePlayer: idarchive_player
                key2: root.key2
                previewMargin: iv_arc_menu_new.height
                isMultiscreen: root.is_multiscreen
                isCommonPanel: root.isCommonPanel
                showEvents: [-1,2].indexOf(archiveControls.iv_butt_spb_events_skip.type) > -1
                showBookmarks: [-1,6].indexOf(archiveControls.iv_butt_spb_events_skip.type) > -1
                intervalBeforeIndex: root.exportIntervalBeforeIndex
                intervalAfterIndex: root.exportIntervalAfterIndex
                currentScale: root.m_i_curr_scale

                onScaleRequested: root.m_i_curr_scale = scale
                onIntervalIndicesRequested: {
                    root.exportIntervalBeforeIndex = beforeIndex
                    root.exportIntervalAfterIndex = afterIndex
                }

                Timer {
                    id: onTimer

                    property int loops: 0

                    interval: 25
                    repeat: true

                    onTriggered: {
                        loops++
                        if (root.getFrameTime() > 0 || loops >= 50) { stop() }
                    }
                }

                Component.onCompleted: {
                    iv_arc_slider_new.ready = false
                    iv_arc_slider_new.setScale(root.m_i_curr_scale)
                    onTimer.start()
                }

                onTimeline_modelChanged:{
                    root.m_i_curr_scale = iv_arc_slider_new.timeline_model
                }

                onUpdateCalendarDT: {
                   root.updateTimeFromSlider()
                }

                onDoubleClicked: {
                    root.funcSwitchSelectIntervalMode()
                }

                onCurrentDateChanged: {
                    idarchive_player.currentDate = iv_arc_slider_new.currentDate
                }

                onBoundsChanged: {
                    var bounds = iv_arc_slider_new.getSelectedInterval()
                    var left = bounds.left - bounds.left%1000
                    var right = bounds.right - bounds.right%1000
                    if (left !== root.m_uu_i_ms_begin_interval) root.m_uu_i_ms_begin_interval = left
                    if (right !== root.m_uu_i_ms_end_interval) root.m_uu_i_ms_end_interval = right
                }
            }
        }
    }

    IVArchiveContextMenu {
        id: contextMenu
        functReturnToRealtime: root.functReturnToRealtime
        funcCloseSet: root.funcCloseSet
    }
}

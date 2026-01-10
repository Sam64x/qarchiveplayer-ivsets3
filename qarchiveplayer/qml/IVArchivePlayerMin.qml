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
import iv.photocam 1.0
import ArchiveComponents 1.0
import QtQuick.Controls.Styles 1.4

import iv.plugins.users 1.0
import iv.exprogress 1.0
import iv.export 1.0
import iv.singletonLang 1.0

import iv.colors 1.0
import iv.controls 1.0 as C

Item {
    id: root

    function getFrameTime() {
        if (archiveStreamer)
            return archiveStreamer.currentTime;
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


    function compare_events(a, b) {
        if (a.event_time_begin > b.event_time_begin)
            return 1
        if (a.event_time_begin === b.event_time_begin)
            return 0
        if (a.event_time_begin < b.event_time_begin)
            return -1
    }

    IvAccess {id: move_to_event; access: "{move_to_event}"}

    IvAccess {id: move_to_bmark; access: "{move_to_bmark}"}

    IvAccess {id: can_export_acc; access: "{upload_media_files}"}

    IvVcliSetting {
      id: vcliStretching
      name: 'cameras.stretching'
    }

    IvVcliSetting {
        id: stripScale
        name: 'archive.strip_scale'
    }

    IvVcliSetting {
        id: shortcutLastSequence1
        name: 'keyboard.signals.' + root.Window.window.unique
    }

    IvVcliSetting {
        id: export_save_directory
        name: 'export_save_directory'
    }

    IvVcliSetting {
        id: snapshot_save_directory
        name: 'snapshot_save_directory'
    }

    IvVcliSetting {
        id: wsPortVcli
        name: 'ws_server_client.port'
    }

    IvVcliSetting {
        id: iv_vcli_setting_arc
        name: 'archive.common_panel'
        onValueChanged: root.common_panel = iv_vcli_setting_arc.value === 'true'
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

    function componentCompleted() {
        if (root.key2 === '' || root.key2 === null || root.key2 === undefined) {
            return
        }
        m_i_started = 1

        var i_id_group_lv = 0
        if (false !== root.fromRealtime)
            i_id_group_lv = 1

        var s_time_iv_lv = ''
        var b_is_ness_cont_work_lv = true
        var controls = null
        setMode904()
        var i_is_this_common_panel_lv = 0
        if (false === root.common_panel)
            i_is_this_common_panel_lv = 0
        else
            i_is_this_common_panel_lv = 1

        if (0 === root.getCamCommonPanelMode()) {
            if (false === root.common_panel) {
            }
        }
        if (false === root.common_panel) {
            if (0 !== root.getCamCommonPanelModeUseSetPanel_Deb())
                root.m_i_c_control_panel_height = 38
        }

        m_component_completed_2303 = true
        if (is_export_media === 1) {
            root.m_i_is_comleted = 1
        }
    }

    function startPlugin() {
        if (root.arc_vers > 0) {
            if (0 !== m_i_is_comleted && 0 === m_i_started)
                root.componentCompleted()
        }
        m_i_start_called = 1
    }

    function setMode904() {
        var i_is_correct_parent_finded_lv = 0
        var i_is_this_common_panel_lv = 0
        if (false === root.common_panel)
            i_is_this_common_panel_lv = 0
        else {
            i_is_this_common_panel_lv = 1
        }
        var b_is_ness_cont_work_lv = true
        if (b_is_ness_cont_work_lv) {
            if (root.is_export_media === 1) {
                root.m_b_is_caused_by_unload = true
            }
            if (0 !== root.from_export_media) {
                root.m_b_is_caused_by_unload = true
            }
            if (root.m_b_is_caused_by_unload) {
                if ('keepAspectRatioExport' in render)
                    render.keepAspectRatioExport = 1
            }
        }
        var i_iv_vcli_setting_arc_lv = 0
        if ('true' === iv_vcli_setting_arc.value)
            i_iv_vcli_setting_arc_lv = 1
        else
            i_iv_vcli_setting_arc_lv = 0

        var v_deb_window_1 = null
        var controls = null

        controls = root.Window.window.ivComponent.findByIvType('IVSETSAREA',
                                                               true)
        i_is_correct_parent_finded_lv = 1
        var s_controls_lv = 'xxx'
        s_controls_lv = controls
        var s_controls2_lv = ''
        var v_1_lv = false
        var v_2_lv = false
        v_1_lv = (null === s_controls2_lv)
        v_2_lv = ('' === s_controls2_lv)
        var v_11_lv = false
        var v_21_lv = false
        v_11_lv = (null == s_controls2_lv)
        v_21_lv = ('' == s_controls2_lv)
        var v_3_lv = false
    }

    property string cameraId: root.key2 ? root.key2 : ""
    property bool initCamera: false
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
            calendarButton.calendar.chosenDate = Qt.formatDate(dt, "dd.MM.yyyy")
            calendarButton.calendar.chosenTime = Qt.formatTime(dt, "hh:mm:ss")
            root.archiveTime = dt
            iv_arc_slider_new.currentDate = dt
            _suppressTimeUpdates = false
        }
    }

    onArchiveBackTimeChanged: _coalesceBackendTs.restart()
    onArchiveBackDateChanged: _coalesceBackendTs.restart()

    property var archiveTime
    property bool needToUpdateArchive: true
    property bool archiveIsPlaying: !archiveStreamer.paused
    property bool archiveIsPaused: Boolean(archiveStreamer.paused)

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
        var chosenDateTime = calendarButton.calendar.chosenDate + " " + calendarButton.calendar.chosenTime
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
        calendarButton.calendar.chosenDate = Qt.formatDate(time, "dd.MM.yyyy")
        calendarButton.calendar.chosenTime = Qt.formatTime(time, "hh:mm:ss")
        root.archiveTime = time
        _suppressTimeUpdates = false

        if (root.archiveIsPaused) {
            archiveStreamer.requestPreviewAt(root.cameraId, root.archiveTime, root.archiveId)
            root.needToUpdateArchive = true
        } else {
            archiveStreamer.delayStart(root.cameraId, root.archiveTime, root.archiveId)
        }
    }

    property string key2: ''
    Binding {
        target: appInfo
        property: "archiveKey2"
        value: root.key2
    }
    property int print_image: 0
    property string time: ''
    property bool m_b_is_caused_by_unload: false
    property bool common_panel: false
    property int m_i_c_control_panel_height: 69
    property int m_i_ness_all_switch_to_realtime: 0
    property int m_i_ness_all_switch_to_realtime_prev: 0
    property int m_i_select_interv_state: 0
    property int c_I_IS_FIERST_SELECT_INTERV: 0
    property int c_I_IS_SECOND_SELECT_INTERV: 1
    property int c_I_IS_CORRECT_INTERV: 2
    property int c_I_NOT_FOUND_907: 0
    property int c_I_SUCCESS_907: 1
    property int c_I_TIMEOUT_907: 2
    property int c_I_ERROR_907: 3
    property string m_s_tooltip_select_interv_1: Language.getTranslate("Select the first boundary of the interval and click",
                                                                       "Выберите первую границу интервала и нажмите")
    property int m_i_is_interval_corresp_event: 0
    property int m_i_is_interval_corresp_event_bookmark: 0
    property string m_s_exch_event_id: ''
    property int m_i_current_timeout_request_to_events: 2000
    property int m_i_marker_last_request_to_events: 0

    property int c_I_ELEM_VERTIC_OFFSET_909: 3
    property string end: ''
    property string text_primit: ''

    property bool m_b_image_corrector_created: false
    property string trackFrameAfterImageCorrectorRoot: ''
    property bool running: true

    property int m_i_menu_height: 30
    property bool m_b_no_actions: false
    property bool fromRealtime: false
    property bool m_isTestMode009: false
    property int arc_vers: 0
    property int m_i_started: 0
    property int m_i_is_comleted: 0
    property int m_i_start_called: 0
    property int m_i_counter006: 0


    property var m_primit: null
    property var m_equal: null
    property int from_export_media: 0
    property var m_pane_sound: null
    signal nessUpdateCalendarAP
    signal setCurrTimeCommandAP

    property int m_i_is_sound_created: 0
    property int m_i_ness_activate_sound: 0
    property int m_i_already_set_008: 0

    property string m_s_is_video_present: ""

    property string savedSetName: ""
    property variant m_v_component_main_export: null

    property string on_frame_profile: ''
    property string key3: ''
    property bool possibility_switch_realtime: false
    property bool draw_contures: false
    property bool repeat: false
    property real speed: 1000

    property int m_i_210929_deb: 1000

    property string cmd: 'stop'
    property bool move: false
    property bool mousedown: false
    property bool mouseup: false
    property bool b_slider_value_outside_change: false
    property bool b_range_slider_value_outside_change: false
    property bool b_range_slider_802_value_beg_outside_change: false
    property bool b_range_slider_802_value_beg_outside_change_fierst: false
    property bool b_range_slider_802_value_end_outside_change: false
    property bool b_range_slider_802_value_end_outside_change_fierst: false
    property bool b_input_time_outside_cahange: false
    property int m_uu_i_ms_begin_interval: 0
    property int m_uu_i_ms_end_interval: 0

    property string m_s_start_event_id: ''

    property int m_i_max_scale: 7
    property int m_i_min_scale: 0
    property string time811: ''
    property int m_i_width_visible_bound5: 200
    property int m_i_width_visible_bound4: 350
    property int smallSizePanel: 520
    property int normalSizePanel: 720
    property bool m_b_is_by_events: false
    property real m_rl_min_scale: 0.0
    property bool m_b_ness_pass_params: false
    property string guid: ""

    property string m_s_key3_audio_ap: ''
    property string m_s_track_source_univ_ap: ''

    property int m_i_is_ness_switch_to_realtime_common_panel: 0
    property int m_i_is_ness_switch_to_realtime_common_panel_prev: 0

    property bool small_mode_panel_ppUp: false
    property int speed_ch_box_rec_size: 33
    property bool ppUpRowLayoutFillState: false
    property int m_i_event_not_found_visible_counter: 0
    property string m_s_tooltip_select_interv_2: Language.getTranslate("Change interval boundary and other interval operations",
                                                                       "Изменить границу интервала и другие операции с интервалом")
    property variant viewer_command_obj: null
    property var export_avi_object: null
    property int is_export_media: 0
    property bool isFullscreen: false
    property bool isIntervalMode: false

    property string m_s_selected_sna_ip: ""
    property string m_s_selected_zna_ip_output: ""
    property string shortcutExportAviArchive: ''
    property bool debug_mode: debugVcli !== null && debugVcli !== undefined ? debugVcli.value === "true" ? true : false : false

    property bool m_b_ke2_changed_2303: false
    property bool m_component_completed_2303: false
    property bool m_b_complete_2303_fierst_time: true

    property var cache_preview: []

    property bool first_init: true
    property bool calendar_date_change: false
    property bool calendar_time_change: false
    property bool is_multiscreen: false
    property bool prev_condition_is_fullscreen: false

    property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1

    property string hoveredColor: "#55FFFFFF"
    property string attentionHovColor: "#88FF0000"
    property string pressedColor: "#55000000"
    property string chkdColor: "#44000000"

    property string buttonColorPressed: "#f0f0f0"
    property string buttonColor: "#f3f3f3"
    property string buttonBorderColorPressed: "#808080"
    property string buttonBorderColor: "#303030"

    property bool fast_edits: fastEdits.value === 'true' ? true : false

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
                            console.log("appInfo.wsUrl = ", appInfo.wsUrl)
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
            opacity: (!root.isSmallMode() || mainMouseArea.containsMouse || root.common_panel) ? 1.0 : 0.0

            ColumnLayout {
                id: cameraInfoBlock

                readonly property bool isTopRight: (settingButtons.posAlignment & (Qt.AlignTop | Qt.AlignRight)) === (Qt.AlignTop | Qt.AlignRight)

                z: mainMouseArea.z + 1

                anchors.fill: parent
                anchors.margins: 2
                anchors.bottomMargin: wndControlPanel.visible ? iv_arc_slider_new.height : 0
                anchors.topMargin: (_archiveMarker.visible && isTopRight) ? 24 : 0

                ColumnLayout {
                    Layout.alignment: settingButtons.posAlignment
                    spacing: 0

                    Label {
                        text: root.cameraId
                        Layout.alignment: settingButtons.posAlignment
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
                        Layout.alignment: settingButtons.posAlignment

                        Label {
                            text: archiveStreamer.currentDate || ""
                            Layout.alignment: settingButtons.posAlignment
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
                            Layout.alignment: settingButtons.posAlignment
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
                        Layout.alignment: settingButtons.posAlignment

                        Label {
                            text: archiveStreamer.cameraResolution || ""
                            Layout.alignment: settingButtons.posAlignment
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
                            Layout.alignment: settingButtons.posAlignment
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

                property real spacing: 4 * root.isize
                z: cameraInfoBlock.z + 1
                width: centerBlock.width + 2 * spacing
                height: 32 * root.isize
                visible: root.width > centerBlock.implicitWidth

                anchors {
                    bottom: iv_arc_slider_new.top
                    bottomMargin: 8 * root.isize
                    horizontalCenter: parent.horizontalCenter
                }

                color: IVColors.get("Colors/Background new/BgFormOverVideo")
                radius: 8*root.isize

                RowLayout {
                    id: centerBlock

                    z: mainMouseArea.z + 2

                    anchors {
                        centerIn: parent
                        margins: parent.spacing
                    }
                    spacing: parent.spacing
                    height: parent.height - parent.spacing*2

                    IntervalScaleButton {
                        id: intervalScale
                        m_i_curr_scale: root.m_i_curr_scale
                        onScaleChosen: {
                            root.m_i_curr_scale = index
                        }
                    }

                    LabeledCalendarButton {
                        id: calendarButton
                    }

                    PlayerControls {
                        id: videoPlayerControls
                        archiveTime: root.archiveTime
                        archiveId: root.archiveId
                        cameraId: root.cameraId
                        needToUpdateArchive: root.needToUpdateArchive
                        onClearPendingUpdate: root.needToUpdateArchive = false
                        archiveStreamer: archiveStreamer
                    }

                    FrameRewindButtons {
                        id: stepButtons
                        archiveStreamer: archiveStreamer
                    }

                    IVSeparator {}

                    FrameTimeButton {
                        iv_arc_slider_new: iv_arc_slider_new
                    }

                    EventButtons {
                        id: iv_butt_spb_events_skip
                        archiveStreamer: archiveStreamer
                        iv_arc_slider_new: iv_arc_slider_new
                        updateTimeFromSlider: root.updateTimeFromSlider
                    }

                    ScreenshotButton {}

                    SettingsButton {
                        id: settingButtons
                        rootRef: root
                    }

                    Rectangle {
                        height: parent.height
                        width: height
                        radius: 4*root.isize
                        color: IVColors.get("Colors/Background new/BgEvent")
                        visible: select_interval_ButtonPane_new.mainVisible &&
                                 !root.common_panel &&
                                 root.isIntervalMode && !archiveStreamer.exporting

                        ExportSettingsButton {
                            id: exportSettings
                            anchors.fill: parent
                            archiveId: root.archiveId
                            cameraId: root.cameraId
                            rootRef: root
                            iv_arc_slider_new: iv_arc_slider_new
                            imagePipeline: imagePipeline
                        }
                    }

                    Rectangle {
                        height: parent.height
                        width: height
                        radius: 4*root.isize
                        color: IVColors.get("Colors/Background new/BgEvent")
                        visible: select_interval_ButtonPane_new.mainVisible &&
                                 !root.common_panel &&
                                 root.isIntervalMode && !archiveStreamer.exporting
                        C.IVButtonControl {
                            id: select_interval_ButtonPane_new
                            property bool mainVisible: true
                            anchors.fill: parent
                            source: "new_images/x-close"
                            size: C.IVButtonControl.Size.Small
                            type: C.IVButtonControl.Type.Tertiary
                            toolTipText: Language.getTranslate("Exit from interval selection","Выйти из режима выбора интервала")
                            enabled: true
                            onClicked: root.funcSwitchSelectIntervalMode()
                        }
                    }
                }
            }

            IVArc_slider_new2 {
                id: iv_arc_slider_new

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                visible: root.width > 622

                isize: root.isize
                height: 40 * (root.isize)
                archivePlayer: idarchive_player
                key2: root.key2
                previewMargin: iv_arc_menu_new.height
                isMultiscreen: root.is_multiscreen
                isCommonPanel: root.common_panel
                showEvents: [-1,2].indexOf(iv_butt_spb_events_skip.type) > -1
                showBookmarks: [-1,6].indexOf(iv_butt_spb_events_skip.type) > -1
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

                    onRunningChanged: {
                        if(!running){
                            var fTime = root.getFrameTime()
                            if (fTime > 10) iv_arc_slider_new.currentDate = new Date(fTime)
                            else {
                                var dateTime = calendarButton.calendar.chosenDate + " " + calendarButton.calendar.chosenTime
                                var parts = dateTime.split(/[. :]/)
                                var dateObject = new Date(parts[2], parts[1] - 1, parts[0], parts[3], parts[4], parts[5])
                                iv_arc_slider_new.currentDate = dateObject
                            }
                            if (root.m_uu_i_ms_begin_interval < 1 && root.m_uu_i_ms_end_interval < 1) root.funcReset_selection()
                            iv_arc_slider_new.refreshModel()
                        }
                    }
                }

                Component.onCompleted: {
                    iv_arc_slider_new.ready = false
                    iv_arc_slider_new.setScale(m_i_curr_scale)
                    onTimer.start()
                }

                onTimeline_modelChanged:{
                    root.m_i_curr_scale = iv_arc_slider_new.timeline_model
                }

                onUpdateCalendarDT: {
                    updateTimeFromSlider()
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


    function getMenuObjectByIndex(i_menu_index_av){
        switch (i_menu_index_av){
            case 0: return menu_item_source_0
            case 1: return menu_item_source_1
            case 2: return menu_item_source_2
            case 3: return menu_item_source_3
            case 4: return menu_item_source_4
            case 5: return menu_item_source_5
            case 6: return menu_item_source_6
            default: return 0
        }
    }
    function isSmallMode() {
        var b_lv = false

        b_lv = (wndControlPanel.width < root.smallSizePanel)

        return b_lv
    }

    function correctIntervalSelectLeft_ByCommand2(time) {
        correctIntervalSelectLeft_Level1(time)
    }

    function correctIntervalSelectLeft_Level1(i_uu_64_new_bound_time_av) {
        var i_uu_64_bound_time_lv = i_uu_64_new_bound_time_av
        idLog3.warn('<interv>correctIntervalSelectLeft_Level1 '
                    + 'm_uu_i_ms_begin_interval ' + root.m_uu_i_ms_begin_interval
                    + ' i_uu_64_bound_time_lv '+ i_uu_64_bound_time_lv)

        if (i_uu_64_bound_time_lv >= root.m_uu_i_ms_begin_interval + 5000)
            root.m_uu_i_ms_end_interval = i_uu_64_bound_time_lv
    }
    function correctIntervalSelectRight_Level1(i_uu_64_new_bound_time_av) {
        var i_uu_64_bound_time_lv = i_uu_64_new_bound_time_av
        idLog3.warn('<interv>correctIntervalSelectLeft m_uu_i_ms_end_interval '
                    + root.m_uu_i_ms_end_interval + ' i_uu_64_bound_time_lv '
                    + i_uu_64_bound_time_lv)

        if (root.m_uu_i_ms_end_interval + 5000 < i_uu_64_bound_time_lv) {
            //console.info("correctIntervalSelectRight_Level1 1")
            //ch00604 root.m_uu_i_ms_begin_interval = root.m_uu_i_ms_end_interval;
            //ch00604 root.m_uu_i_ms_end_interval = i_uu_64_frame_time_lv;
        }
        else root.m_uu_i_ms_begin_interval = i_uu_64_bound_time_lv
    }

    function correctIntervalSelectRight_ByCommand2(time) {
        correctIntervalSelectRight_Level1(time)
    }

    //ch90918 - это - спрятать или пок-ть общ панель е
    function commonPanelSetVisible(i_val_av) {
        idLog3.warn('<common_pan> 200712 31 ')

        var i_height_lv = root.height
        var i_height_contr_panel_lv = wndControlPanel.height

        root.visible = (0 !== i_val_av)

        if (0 !== i_val_av) root.height = i_height_contr_panel_lv
        else root.height = 0
    }

    function updateTime811_Causing1() {
        idLog3.warn('<calendar> updateTime811_Causing1 b_input_time_outside_cahange ' + b_input_time_outside_cahange)
        updateTime811()
    }

     function updateTime811() {
         idLog3.warn('updateTime811 begin ')
         var s_date_lv = calendarButton.calendar.chosenDate

         idLog3.warn('<calendar> updateTime811 calendarButton.calendar.chosenDate ' + calendarButton.calendar.chosenDate
                     + ' calendarButton.calendar.chosenTime ' + calendarButton.calendar.chosenTime
                     + ' s_date_lv ' + s_date_lv
                     + ' input_time_outside_cahange ' + root.b_input_time_outside_cahange)

         idLog3.warn('calendarButton.calendar.chosenDate ' + calendarButton.calendar.chosenDate
                     + ' calendarButton.calendar.chosenTime ' + calendarButton.calendar.chosenTime
                     + ' s_date_lv ' + s_date_lv)

         idLog3.warn('updateTime811 root.time811' + root.time811
                     + ' b_input_time_outside_cahange ' + root.b_input_time_outside_cahange)
         if (root.time811 == "") {

         } else {
             idLog3.warn('updateTime811 root.time811 301')
             if (!root.b_input_time_outside_cahange)
             {
                 if (!iv_arc_slider_new.sliderIsDragged)
                     iv_arc_slider_new.currentDate = new Date(root.time811)
             }
         }
         idLog3.warn('updateTime811 root.time811 4')
         root.b_input_time_outside_cahange = false
     }

    function updateSpeedSlider() {
        root.speed = Math.abs(videoPlayerControls.iv_speed_slider.speed)
        if (playerLoader.item !== null){
            var o = {};
            o.speed = videoPlayerControls.iv_speed_slider.speed/1000
            playerLoader.item.setSpeed(o);
        }
    }

    function correctIntervalSelectLeft_Causing1() {
        root.correctIntervalSelectLeft()
        correctIntervalSelect_CommonPart()
    }

    function correctIntervalSelect_CommonPart() {
        root.m_i_is_interval_corresp_event = 0
        root.m_s_start_event_id = 0
    }
    function correctIntervalSelectLeft_ByCommand_Causing1() {
        root.correctIntervalSelectLeft_ByCommand()
        correctIntervalSelect_CommonPart()
    }

    function correctIntervalSelectRight_Causing1() {
        idLog3.warn('<interv> correctIntervalSelectRight_Causing1 beg')

        root.correctIntervalSelectRight()
        correctIntervalSelect_CommonPart()
    }

    function correctIntervalSelectRight_ByCommand_Causing1() {
        idLog3.warn('<interv> correctIntervalSelectRight_ByCommand_Causing1 beg')

        root.correctIntervalSelectRight_ByCommand()
        correctIntervalSelect_CommonPart()
    }

    function correctInterval_Causing1(i_uu_64_time_av) {
        correctInterval_Level1(i_uu_64_time_av)

        root.m_i_is_interval_corresp_event = 0
        root.m_s_start_event_id = 0
        root.m_i_select_interv_state = root.c_I_IS_CORRECT_INTERV
    }

    function drawStartInterval_Level1(i_uu_64_changed_time_av) {
        //зададим маленький начальный интервал е
        var i_uu_64_frame_time_lv = 0
        i_uu_64_frame_time_lv = i_uu_64_changed_time_av
        //idLog3.warn('select_interval_ivichb onClicked bef addDeltaTimeUU64' );
        root.m_uu_i_ms_begin_interval = i_uu_64_frame_time_lv
        root.m_uu_i_ms_begin_interval = root.m_uu_i_ms_begin_interval - 5000

        root.m_uu_i_ms_end_interval = i_uu_64_frame_time_lv
        root.m_uu_i_ms_end_interval = root.m_uu_i_ms_end_interval + 5000
        root.m_i_select_interv_state = root.c_I_IS_SECOND_SELECT_INTERV

        //upload_left_bound_lb.visible4 = true
        //upload_left_bound_2_lb.visible4 = true
        root.m_i_is_interval_corresp_event = 0
        //ch90723 root.m_b_ness_check_present_event = 0;
        root.m_s_start_event_id = 0
    }

    function extComponentsSetVisible(b_is_visible_av) {
        //upload_left_bound_2_lb.visible2 = b_is_visible_av
        //upload_left_bound_lb.visible2 = b_is_visible_av
        //iv_butt_spb_bmark_skip.visible2 = b_is_visible_av

        export_media_button.visible = can_export_acc.isAllowed
        sound_Loader.create()
        photocam_Loader.create()
        switch_to_real_time_button.visible = true
        image_correct_Loader.create()
        fullscreen_button.visible = true
    }

    function complete2() {
        var b_cond_lv = false
        soundLoader.create()
        imageCorrLoader.create()
        photocamLoader.create()

        b_cond_lv = (0 === root.getCamCommonPanelModeUseSetPanel())

        idLog3.warn('<root> complete2 getCamCommonPanelModeUseSetPanel ' + b_cond_lv)

        if (0 === root.getCamCommonPanelModeUseSetPanel_Deb())
        {
            b_cond_lv = root.isSmallMode()
            idLog3.warn('<root> complete2 b_cond_lv ' + b_cond_lv)
            if (!root.isSmallMode())
                mainMouseArea.enabled = false
        }
        else extComponentsSetVisible(false)
    }

    //ch90917
    function showInterval908(uu_i_ms_begin_interval_av, uu_i_ms_end_interval_av, s_event_text_interval_av) {
        var s_event_text_trunc_lv = ''
        root.m_uu_i_ms_begin_interval = uu_i_ms_begin_interval_av
        root.m_uu_i_ms_end_interval = uu_i_ms_end_interval_av
        root.m_i_select_interv_state = root.c_I_IS_CORRECT_INTERV

        idLog3.warn('<' + root.key2 + '_' + root.key3 + '_events>'
                    + ' showInterval908 m_uu_i_ms_begin_interval ' + root.m_uu_i_ms_begin_interval
                    + ' m_uu_i_ms_end_interval ' + root.m_uu_i_ms_end_interval)

        //upload_left_bound_2_lb.text = Language.getTranslate("Interval selected", "Выбран интервал")
        if ('' !== s_event_text_interval_av) {
            if (s_event_text_interval_av === s_event_text_trunc_lv) {
                //upload_left_bound_2_lb.text += ' ' + s_event_text_interval_av
                //tooltip908.contentItem.text = ''
            } else {
                upload_left_bound_2_lb.text += ' ' + s_event_text_trunc_lv
                tooltip908.contentItem.text = s_event_text_interval_av
            }
        }
        //upload_left_bound_lb.visible4 = true
        //upload_left_bound_2_lb.visible4 = true
    }

    function moveToEventBySlider_Causing1(b_is_right_av, b_is_bookmarks_av, rl_mess_x_av, rl_mess_y_av) {
        var i_res_lv = 0

        var s_event_text_lv = ''
        var i_is_already_interval_selected_lv = 0
        var s_warning_pref_lv = ''

        if (root.m_i_current_timeout_request_to_events > 20000
                || root.m_i_marker_last_request_to_events + 40000 < i_curr_time_lv)
            root.m_i_current_timeout_request_to_events = 2000

        if (0 !== root.m_uu_i_ms_begin_interval)
            i_is_already_interval_selected_lv = 1

        if (root.c_I_TIMEOUT_907 === i_res_lv) {
            root.m_i_current_timeout_request_to_events += 2000
            root.showNextEventNotFoundMess(
                        root.m_i_current_timeout_request_to_events,
                        rl_mess_x_av, rl_mess_y_av,
                        'событие за ' + root.m_i_current_timeout_request_to_events
                        / 1000 + ' сек не найденно, попробуйте еще раз')
            //e ch90731
        } //e
        else if (root.c_I_NOT_FOUND_907 === i_res_lv) {
            if (b_is_bookmarks_av)
                s_warning_pref_lv = 'метка'
            else
                s_warning_pref_lv = 'событие'
            root.showNextEventNotFoundMess(
                        root.m_i_current_timeout_request_to_events,
                        rl_mess_x_av, rl_mess_y_av,
                        s_warning_pref_lv + ' для заданного промежутка не существует')
        } //e
        else if (root.c_I_SUCCESS_907 === i_res_lv) {
            root.m_i_is_interval_corresp_event = 1
            root.m_i_is_interval_corresp_event_bookmark = b_is_bookmarks_av ? 1 : 0
        }
        //e
        root.m_i_marker_last_request_to_events = i_curr_time_lv
    }

    function positioningContextMenu() {
        var coord_x = mouseAreaRender.mouseX
        var coord_y = mouseAreaRender.mouseY
        if (coord_x + menuLoaderContext_menu2.componentMenu.width > root.width) {
            coord_x = (root.width - menuLoaderContext_menu2.componentMenu.width) - 15
        }

        menuLoaderContext_menu2.componentMenu.x = coord_x
        menuLoaderContext_menu2.componentMenu.y = coord_y
    }

    function timerActions() {
        m_i_event_not_found_visible_counter--
        if (0 === m_i_event_not_found_visible_counter) {
            next_event_not_found_rct_hint.visible = false
        }
    }
    function showNextEventNotFoundMess(i_timeout_av, rl_x_av, rl_y_av, s_text_av) {
        var i_x_lv = 10
        var i_y_lv = 10
        next_event_not_found_rct_hint.visible = true
        m_i_event_not_found_visible_counter = 7
        i_x_lv = rl_x_av
        i_y_lv = rl_y_av
        next_event_not_found_rct_hint.x = i_x_lv
        next_event_not_found_rct_hint.y = i_y_lv

        next_event_not_found_rct_hint_text.text = s_text_av
        next_event_not_found_rct_hint.width = next_event_not_found_rct_hint_text.contentWidth
        next_event_not_found_rct_hint.height = next_event_not_found_rct_hint_text.contentHeight
        idLog3.warn('<events> showNextEventNotFoundMess i_x_lv ' + i_x_lv
                    + ' i_y_lv ' + i_y_lv + ' next_event_not_found_rct_hint.x '
                    + next_event_not_found_rct_hint.x + ' next_event_not_found_rct_hint.y '
                    + next_event_not_found_rct_hint.y + ' next_event_not_found_rct_hint_text.text '
                    + next_event_not_found_rct_hint_text.text)
    }

    function safeSetProperty(component, prop, func) {
        if (prop in component) {
            component[prop] = func
        }
    }

    function funcReset_selection() {
        if (iv_arc_slider_new.setInterval){
            iv_arc_slider_new.setInterval = false
            iv_arc_slider_new.setInterval = true
        }
        root.m_uu_i_ms_begin_interval = iv_arc_slider_new.currentDate.getTime()
        root.m_uu_i_ms_end_interval = iv_arc_slider_new.currentDate.getTime()
    }

    function validateSettings(value){
        try { JSON.parse(value) }
        catch (e) { return null }
        return JSON.parse(value)
    }
}

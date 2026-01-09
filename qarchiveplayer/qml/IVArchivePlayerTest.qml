import QtQuick 2.11
import iv.devices.univreaderex 1.0
import iv.player 1.0
import iv.renders.renderselector 1.0
import iv.plugins.loader 1.0
import QtQuick.Window 2.2
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtQml.Models 2.3
import QtQuick.Dialogs 1.2
import iv.viewers.archiveplayer 1.0
import iv.guicomponents 1.0
import iv.calendar 1.0
import iv.archivecomponents.selectinterval 1.0
import iv.photocam 1.0
import QtQuick.Controls.Styles 1.4

import ArchiveComponents 1.0
import iv.plugins.users 1.0
import iv.exprogress 1.0
import iv.export 1.0
import iv.singletonLang 1.0

import iv.colors 1.0
import iv.controls 1.0 as IVControl

Item {
    id: root
    readonly property point frameLeftTop: root.mapFromItem(render,render.frameLeft,render.frameTop)
    readonly property point frameRightBottom: root.mapFromItem(render, render.frameRight,render.frameBottom)
    readonly property alias frameLeft: root.frameLeftTop.x
    readonly property alias frameTop: root.frameLeftTop.y
    readonly property alias frameRight: root.frameRightBottom.x
    readonly property alias frameBottom: root.frameRightBottom.y
    property IVComponent2 ivComponent: null
    property string key2: ''
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
    //ch90723 property int m_b_ness_check_present_event: 0
    property int m_i_is_interval_corresp_event_bookmark: 0
    property string m_s_exch_event_id: ''
    property int m_i_current_timeout_request_to_events: 2000
    property int m_i_marker_last_request_to_events: 0

    property int c_I_ELEM_VERTIC_OFFSET_909: 3
    property string end: ''
    property string text_primit: ''

    property bool m_b_image_corrector_created: false
    property string trackFrameAfterImageCorrectorRoot: ''
    property bool isServer: stabServer.value === "true"
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
    property int speed: 1000

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
    property variant m_uu_i_ms_begin_interval: 0
    property variant m_uu_i_ms_end_interval: 0
    onM_uu_i_ms_begin_intervalChanged: {
        intervalCenterRow.isExporting = false
        var dateTimeObj = new Date(m_uu_i_ms_begin_interval)

        calendTime_from.chosenDate = Qt.formatDate(dateTimeObj, "dd.MM.yyyy")
        calendTime_from.timeString = dateTimeObj.toString()
        calendTime_from.updateDateTimeText()

        var bounds = iv_arc_slider_new.getSelectedInterval()
        var left = bounds.left - bounds.left%1000
        if (left !== root.m_uu_i_ms_begin_interval) iv_arc_slider_new.setBounds(dateTimeObj, new Date(m_uu_i_ms_end_interval))
    }
    onM_uu_i_ms_end_intervalChanged: {
        intervalCenterRow.isExporting = false
        var dateTimeObj = new Date(m_uu_i_ms_end_interval)

        calendTime_to.chosenDate = Qt.formatDate(dateTimeObj, "dd.MM.yyyy")
        calendTime_to.timeString = dateTimeObj.toString()
        calendTime_to.updateDateTimeText()

        var bounds = iv_arc_slider_new.getSelectedInterval()
        var right = bounds.right - bounds.right%1000
        if (right !== m_uu_i_ms_end_interval) iv_arc_slider_new.setBounds(new Date(m_uu_i_ms_begin_interval), dateTimeObj)
    }

    property string m_s_start_event_id: ''

    IvVcliSetting {
        id: stripScale
        name: 'archive.strip_scale'
    }
    property int m_i_curr_scale: validateSettings(stripScale.value) !== null ? validateSettings(stripScale.value) : 4//[0-7] 4 = hour
    onM_i_curr_scaleChanged: {
        if (root.m_i_curr_scale >= 0){
            idarchive_player.setScale(root.m_i_curr_scale)
            iv_arc_slider_new.setScale(root.m_i_curr_scale)
            interv_lv_new.currentIndex = root.m_i_curr_scale
            if (lm_intervals.count > 0) txt_razmer.text = lm_intervals.get(root.m_i_curr_scale).name
        }
    }

    property int m_i_max_scale: 7
    property int m_i_min_scale: 0
    property string time811: ''
    property int m_i_width_visible_bound5: 200
    property int m_i_width_visible_bound4: 350
    property int smallSizePanel: 520
    property int normalSizePanel: 720
    property bool m_b_is_by_events: false
    property real m_rl_min_scale: 0.0
    //ch90918 это типа нужно чтоб вынести в др поток е
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
    property bool display_camera_previews: arc_display_camera_previews !== null
                                           && arc_display_camera_previews !== undefined ?
                                               arc_display_camera_previews.value === "true" ? true : false : false

    property bool m_b_ke2_changed_2303: false
    property bool m_component_completed_2303: false
    property bool m_b_complete_2303_fierst_time: true

    property var cache_preview: []

    property bool first_init: true
    property bool calendar_date_change: false
    property bool calendar_time_change: false
    property bool is_multiscreen: false
    property bool prev_condition_is_fullscreen: false
    property bool needToPause: play_ivichb.chkd

    Timer{
        id: timer1111
        interval: 10
        repeat: true
        property var frTime
        onTriggered: {
            if (root.getFrameTime() !== frTime){
                if (needToPause){
                    if (revers_ivichb.chkd) univreaderex.setCmd005('play_backward')
                    else univreaderex.setCmd005('play')
                }
                timer1111.stop()
            }
        }
    }

    property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1

    /// colors
    property string hoveredColor: "#55FFFFFF"
    property string attentionHovColor: "#88FF0000"
    property string pressedColor: "#55000000"
    property string chkdColor: "#44000000"

    property string buttonColorPressed: "#f0f0f0"
    property string buttonColor: "#f3f3f3"
    property string buttonBorderColorPressed: "#808080"
    property string buttonBorderColor: "#303030"


    IvVcliSetting{
        id: animations
        name: 'interface.animations'
        property bool val: true
    }

    property bool fast_edits: fastEdits.value === 'true' ? true : false
    property bool is_set_edit: isSetEdit.value === 'true' ? true : false

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

    onExport_avi_objectChanged: {

    }
    onM_s_selected_sna_ipChanged: {
        idLog3.warn("<select_source> m_s_selected_sna_ip " + m_s_selected_sna_ip)
        univreaderex.switchSource_Vart2(m_s_selected_sna_ip)
    }

    /*
    Loader {
        id: export_aviLoader
        property var componentExport_avi: null
        function create() {
            if (export_aviLoader.status !== Loader.Null)
                export_aviLoader.source = ""
            var qmlfile = "file:///" + applicationDirPath + '/qtplugins/iv/viewers/archiveplayer/qmainexport.qml'
            export_aviLoader.source = qmlfile
        }
        function refresh() {
            export_aviLoader.destroy()
            export_aviLoader.create()
        }
        function destroy() {
            if (export_aviLoader.status !== Loader.Null)
                export_aviLoader.source = ""
        }
        onStatusChanged: {
            if (export_aviLoader.status === Loader.Ready)
            {
                export_aviLoader.componentExport_avi = export_aviLoader.item
                root.m_v_component_main_export = export_aviLoader.componentExport_avi
                idLog3.warn('<' + root.key2 + '_' + root.key3+ '>' + 'onBindings 180110')
                var s_begin_lv = ''
                var s_end_lv = ''
                var s_zna_ip_lv = ''
                idLog2.warn('onBindings 180110')

                if (0 === root.m_uu_i_ms_begin_interval){
                    s_begin_lv = univreaderex.intervTime2(0)
                    idLog3.warn('unload_to_avi_ivibt clicked time before ' + root.end)
                    if ('' === root.end) {
                        s_end_lv = univreaderex.addDeltaTime(univreaderex.intervTime2(0),120000)
                        idLog3.warn('<' + root.key2 + '_' + root.key3 + '>' + 'unload_to_avi_ivibt clicked end after ' + s_end_lv)
                    }
                    else s_end_lv = root.end
                }
                else {
                    s_begin_lv = univreaderex.uu64ToHumanEv(root.m_uu_i_ms_begin_interval,3)
                    s_end_lv = univreaderex.uu64ToHumanEv(root.m_uu_i_ms_end_interval,3)
                }
                root.safeSetProperty(export_aviLoader.componentExport_avi,
                                     'key2',
                                     Qt.binding(function () {return root.key2})
                                     )
                var s1 = s_begin_lv.indexOf('27')
                idLog3.warn('<mwork> s_begin_lv ' + s_begin_lv + ' s_end_lv ' + s_end_lv + ' ' + root.time811 + ' s1 ')
                if (s1 === 0) {
                    s_begin_lv = root.time811
                    s_end_lv = s_begin_lv
                    idLog3.warn('<mwork>corrected ' + s_begin_lv + ' ' + s_end_lv)
                }
                root.safeSetProperty(export_aviLoader.componentExport_avi,
                                     'from',
                                     Qt.binding(function () {return s_begin_lv})
                                     )
                root.safeSetProperty(export_aviLoader.componentExport_avi,
                                     'to',
                                     Qt.binding(function () {return s_end_lv})
                                     )
                if (0 !== root.m_s_start_event_id
                        && '' !== root.m_s_start_event_id)
                    root.safeSetProperty(export_aviLoader.componentExport_avi,
                                         'evtid',
                                         Qt.binding(function () {return root.m_s_start_event_id})
                                         )
                //ch221021
                //получим из c++ e
                s_zna_ip_lv = univreaderex.getSelectedZnaIp()
                idLog3.warn("<select_source> export_aviLoader onStatusChanged s_zna_ip_lv " + s_zna_ip_lv)
                root.safeSetProperty(export_aviLoader.componentExport_avi,
                                     'selected_zna_ip',
                                     Qt.binding(function () {return s_zna_ip_lv})
                                     )
                //export_aviLoader.componentExport_avi.selected_zna_ip = "[\n{\n\"IP\" : \"192.168.40.107\", \n\"port\": 20001\n}\n]";
                idLog3.warn('<unload> onBindings from ' + export_aviLoader.componentExport_avi.from +
                            ' to ' +
                            export_aviLoader.componentExport_avi.to +
                            ' evtid ' +
                            root.m_s_start_event_id
                            )
                export_aviLoader.componentExport_avi.parent_arc_obj = sel_interv
            }
        }
    }
    */

    QtObject {
        id: sel_interv
        signal put_to_archiveplayer(bool val)
        signal set_m_i_210929_deb(int val_deb)
        onPut_to_archiveplayer: function (val) {
            root.m_b_ness_pass_params = val
        }
        onSet_m_i_210929_deb: function (val_deb) {
            root.m_i_210929_deb = val_deb
        }
    }

    Timer {
        id: timer_context_menu2_close
        interval: 30000
        onTriggered: {
            menuLoaderContext_menu2.componentMenu._close()
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
        Component.onCompleted: {
            if (root.debug_mode === true) {
                IVCompCounter.addComponent(idarchive_player)
            }
            idLog.trace('###### idarchive_player onCompleted = ######')
        }
        Component.onDestruction: {
            if (root.debug_mode) {
                IVCompCounter.removeComponent(idarchive_player)
            }
            idLog.trace('###### idarchive_player onDestruction = ######')
        }
    }

    Iv7Stable{
        id: idStable
        who: 163
    }
    Iv7Log {
        id: idLog
        name: 'qt'
    }
    Iv7Log {
        id: idLog2
        name: 'arc.trace'
    }
    Iv7Log {
        id: idLog3
        name: 'qtplugins.iv.viewers.archiveplayer'
    }

    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }
    IvVcliSetting {
        id: arc_display_camera_previews
        name: 'archive.display_camera_previews'
    }

    IvVcliSetting {
        id: stabServer
        name: 'image_stabilizer'
    }
    IvVcliSetting {
        id: export_status_window
        name: 'qml.export.export_status_window'
    }
    IvVcliSetting {
        id: shortcutLastSequence1
        name: 'keyboard.signals.' + root.Window.window.unique
    }
    IvVcliSetting {
        id: shortcutLastSequenceArchive
        name: 'keyboard.signals.archive'
        onValueChanged: {
            if (shortcutLastSequenceArchive.value === "Ctrl+Up") {
                if (root.m_i_curr_scale > m_i_min_scale) {
                    root.m_i_curr_scale -= 1
                }
            }
            if (shortcutLastSequenceArchive.value === "Ctrl+Down") {
                if (root.m_i_curr_scale < m_i_max_scale) {
                    root.m_i_curr_scale += 1
                }
            }
        }
    }

    IvVcliSetting {
        id: debugVcli
        name: 'debug.enable'
    }
    IvVcliSetting {
        id: integration_flag
        name: 'cmd_args.mode'
    }
    IvVcliSetting {
        id: fastEdits
        name: 'sets.fastEdits' //быстрое редактирование
    }
    IvVcliSetting {
        id: isSetEdit
        name: "is_set_edits" //обычное редактирование
    }
    IvVcliSetting {
        id: interfaceButtonsCloseSets
        name: 'interface.buttons.closeSets'
    }
    onShortcutExportAviArchiveChanged: {
        //console.info("onShortcutExportAviArchiveChanged root.shortcutExportAviArchive = ", root.shortcutExportAviArchive);
        if (root.shortcutExportAviArchive === "Ctrl+Up"){
            if (root.m_i_curr_scale > m_i_min_scale) root.m_i_curr_scale -= 1
            root.shortcutExportAviArchive = ''
        }
        else if (root.shortcutExportAviArchive === "Ctrl+Down") {
            if (root.m_i_curr_scale < m_i_max_scale) root.m_i_curr_scale += 1
            root.shortcutExportAviArchive = ''
        }
    }

    function validateSettings(value){
        try { JSON.parse(value) }
        catch (e) { return null }
        return JSON.parse(value)
    }

    IvVcliSetting {
        id: iv_vcli_setting_arc_play_back
        name: 'archive.interface.playBackVis'
        property var val: validateSettings(value)
    }
    IvVcliSetting {
        id: iv_vcli_setting_arc_events_skip
        name: 'archive.interface.eventsSkipVis'
        property var val: validateSettings(value)
    }
    IvVcliSetting {
        id: iv_vcli_setting_arc_bmark_skip
        name: 'archive.interface.bmarkSkipVis'
        property var val: validateSettings(value)
    }
    IvVcliSetting {
        id: iv_vcli_setting_arc_speed
        name: 'archive.interface.speedVis'
        property var val: validateSettings(value)
    }
    IvVcliSetting {
        id: iv_vcli_setting_arc
        name: 'archive.common_panel'
        onValueChanged: {
            //ch90528 нижеследующее исполняем только если
            //у данного кземляра не нулевой ид набора
            //и существует общая панель с таким ид е
            if (univreaderex.isCommonPanelForThisPresent())
            {
                idLog3.warn(' 190410 NEW VALUE=' + iv_vcli_setting_arc.value)
                var i_lv = 0

                if ('true' === iv_vcli_setting_arc.value) i_lv = 1
                else i_lv = 0

                var i_prev_lv = univreaderex.getCommonPanelMode()
                var i_is_changed_lv = 0
                if (i_prev_lv !== i_lv) i_is_changed_lv = 1

                //ch90427 изменить нужно после того как все
                //закроется univreaderex.setCommonPanelMode( i_lv );
                univreaderex.setCommonPanelModeCommand(i_lv)
                if (0 !== i_is_changed_lv){
                    if (root.common_panel){
                        idLog3.warn('<common_pan> m_i_ness_all_switch_to_realtime ' + root.m_i_ness_all_switch_to_realtime
                                    + ' getCamCommonPanelMode() ' + root.getCamCommonPanelMode())
                        root.m_i_ness_all_switch_to_realtime++
                    }
                }
            }
        }
        property var val: validateSettings(value)
    }

    IvAccess {
        id: move_to_event
        access: "{move_to_event}"
    }
    IvAccess {
        id: move_to_bmark
        access: "{move_to_bmark}"
    }
    IvAccess {
        id: can_export_acc
        access: "{upload_media_files}"
    }
    Iv7Test {
        id: test_id_call_archive_menu
        guid: '43_call_archive_menu'
        key2: root.key2
        onCommandReceived: {
            idLog3.warn(value) //value - json, указанный в ws запросе.
            //select_interval_ivibt.clicked(); //- кликнуть кнопку
            test_id_call_archive_menu.result = "{\"result\":\"OK\"}"
        }
    }
    Iv7Test {
        id: test_id_click_change_interval
        guid: '43_click_archive_change_interval'
        key2: root.key2
        onCommandReceived: {
            idLog3.warn(value) //value - json, указанный в ws запросе.
            //menu_item_change.onTriggered();// - кликнуть кнопку
            root.funcChange()
            test_id_click_change_interval.result = "{\"result\":\"OK\"}"
        }
    }
    Iv7Test {
        id: test_id_click_unload_interval
        guid: '43_click_archive_unload_interval'
        key2: root.key2
        onCommandReceived: {
            idLog3.warn(value) //value - json, указанный в ws запросе.
            //menu_item_unload.onTriggered();// - кликнуть кнопку
            root.funcUnload()
            test_id_click_unload_interval.result = "{\"result\":\"OK\"}"
        }
    }
    Iv7Test {
        id: test_id_click_reset_selection_interval
        guid: '43_click_archive_reset_selection_interval'
        key2: root.key2
        onCommandReceived: {
            idLog3.warn(value) //value - json, указанный в ws запросе.
            //menu_item_reset_selection.onTriggered();// - кликнуть кнопку
            root.funcReset_selection()
            test_id_click_reset_selection_interval.result = "{\"result\":\"OK\"}"
        }
    }
    Iv7Test {
        id: test_id_click_cancel111_interval
        guid: '43_click_archive_cancel111_interval'
        key2: root.key2
        onCommandReceived: {
            idLog3.warn(value) //value - json, указанный в ws запросе.
            //menu_item_cancel111.onTriggered();// - кликнуть кнопку
            test_id_click_cancel111_interval.result = "{\"result\":\"OK\"}"
        }
    }
//    Iv7Test {
//        id: test_id_click_call_export_window
//        guid: '43_click_archive_call_export_window'
//        key2: root.key2
//        onCommandReceived: {
//            idLog3.warn(value) //value - json, указанный в ws запросе.
//            //menu_item_call_unload_window.onTriggered(); //- кликнуть кнопку
//            root.funcCall_Unload_window()
//            test_id_click_call_export_window.result = "{\"result\":\"OK\"}"
//        }
//    }
    Iv7Test {
        id: test_id_set_time
        guid: '43_archive_set_time'
        key2: root.key2
        onKey2Changed: {
            idLog3.warn('200922_2 ') //value - json, указанный в ws запросе.
        }
        onCommandReceived: {
            idLog3.warn('200922_1 ') //value - json, указанный в ws запросе.
            idLog3.warn(value) //value - json, указанный в ws запросе.
            idLog3.warn('210809_1 ')
            var obj = JSON.parse(value)
            if (root.key2 !== "common_panel"
                    || obj.set_name === root.savedSetName) {
                idLog3.warn('210809_2 ')
                root.m_isTestMode009 = true
                root.time = obj.value
                root.m_isTestMode009 = false
                idLog3.warn('210809_3 ')
                test_id_set_time.result = "{\"result\":\"OK\"}"
                idLog3.warn('210809_4 ')
            }
        }
    }
    Iv7Test {
        id: test_archive_result
        guid: "43_archive_result"
        key2: root.key2
        result: ''
        error: ''
        onCommandReceived: {
            var _json = {

            }
            _json["x"] = root.Window.window.x
            _json["y"] = root.Window.window.y
            _json["width"] = root.width
            _json["height"] = root.height
            //ch01002 console.info(JSON.stringify(_json));
            idLog3.warn(JSON.stringify(_json))
            test_archive_result.result = JSON.stringify(_json)
        }
    }
    Iv7Test {
        id: test_id_click_switch_to_realtime
        guid: '43_click_archive_switch_to_realtime'
        key2: root.key2
        onCommandReceived: {
            idLog3.warn("<210927> 43_click_archive_switch_to_realtime onCommandReceived"
                        + " from_export_media " + root.from_export_media
                        + " root.common_panel " + root.common_panel)
            if (0 === root.from_export_media) {
                idLog3.warn(value) //value - json, указанный в ws запросе.
                var obj = JSON.parse(value)
                idLog3.warn("<210927> 43_click_archive_switch_to_realtime onCommandReceived"
                            + " root.key2 " + root.key2 + " obj.set_name "
                            + obj.set_name + " root.savedSetName " + root.savedSetName)
                if (root.key2 === "common_panel"
                        && obj.set_name === root.savedSetName) {
                    idLog3.warn("<210927> 500 1 ")
                    univreaderex.switchToRealtime2204()
                } else {
                    idLog3.warn("<210927> 500 ")
                    univreaderex.switchToRealtime109()
                }
                test_id_click_switch_to_realtime.result = "{\"result\":\"OK\"}"
            }
            idLog3.warn("<210927> after action 43_click_archive_switch_to_realtime ")
        }
    }
    Iv7Test {
        id: test_id_play_command
        guid: '43_archive_play_command'
        key2: root.key2
        onKey2Changed: {
            idLog3.warn('220228 ') //value - json, указанный в ws запросе.
        }
        onCommandReceived: {
            idLog3.warn('220228_1 ') //value - json, указанный в ws запросе.
            idLog3.warn(value) //value - json, указанный в ws запросе.
            idLog3.warn('220228_100 ')
            var obj = JSON.parse(value)
            if (root.key2 !== "common_panel"
                    || obj.set_name === root.savedSetName) {
                idLog3.warn('220228_2 ')
                if (play_ivichb.chkd) {
                    idLog3.warn('220228_20 ')
                    test_id_play_command.result
                            = "{\"result\":\"Error: command play when play state\"}"
                } else {
                    idLog3.warn('220228_400 ')
                    idLog3.warn('220228_401 ')
                    play_ivichb.chkd = true
                    idLog3.warn('220228_3 ')
                    //ch220228 play_ivichb.onClicked();
                    //root.funcPlayCommand2202()
                    root.playCmd(true)
                    //e
                    idLog3.warn('220228_710 ')
                    test_id_play_command.result = "{\"result\":\"OK\"}"
                }
            }
            idLog3.warn('220228_4 ')
        }
    }
    Iv7Test {
        id: test_id_pause_command
        guid: '43_archive_pause_command'
        key2: root.key2
        onKey2Changed: {
            idLog3.warn('220228_200 ') //value - json, указанный в ws запросе.
        }
        onCommandReceived: {
            idLog3.warn('220228_299 ') //value - json, указанный в ws запросе.
            idLog3.warn(value) //value - json, указанный в ws запросе.
            idLog3.warn('220228_201 ')
            var obj = JSON.parse(value)
            if (root.key2 !== "common_panel"
                    || obj.set_name === root.savedSetName) {
                idLog3.warn('220228_202 ')
                if (play_ivichb.chkd) {
                    idLog3.warn('220228_410 ')
                    idLog3.warn('220228_411 ')
                    play_ivichb.chkd = false
                    //ch220228 play_ivichb.onClicked();
                    //root.funcPlayCommand2202()
                    root.playCmd(false)
                    //e
                    idLog3.warn('220228_203 ')
                    test_id_pause_command.result = "{\"result\":\"OK\"}"
                } else {
                    idLog3.warn('220228_220 ')
                    test_id_pause_command.result
                            = "{\"result\":\"Error: command pause when pause state\"}"
                }
            }
            idLog3.warn('220228_204 ')
        }
    }

    Component.onDestruction: {
        idLog3.warn('<210927> onDestruction from_export_media ' + root.from_export_media)
        idLog3.warn('<load> onDestruction')

        univreaderex.onDestroy101()
        menuLoaderSelInterv.destroy()
        menuLoaderContext_menu2.destroy()
        if (root.debug_mode === true) {
            IVCompCounter.removeComponent(root)
        }
        idLog3.warn('<load> onDestruction 2')
    }
    onNessUpdateCalendarAP: {
        idLog3.warn('onNessUpdateCalendarAP before ' + calend_time.chosenDate)
        var s_date_lv = ''
        s_date_lv = univreaderex.incrementDate(calend_time.chosenDate, 1)
        root.b_input_time_outside_cahange = true
        calend_time.chosenDate = univreaderex.timeToComponentDate(s_date_lv)
        idLog3.warn('onNessUpdateCalendarAP after ' + calend_time.chosenDate)
        root.b_input_time_outside_cahange = false
    }
    onSetCurrTimeCommandAP: {
        idLog3.warn('onSetCurrTimeCommandAP begin')
        univreaderex.setCurrentTime()
        idLog3.warn('onSetCurrTimeCommandAP begin')
    }
    signal nessUpdateCalendarDecrAP
    onNessUpdateCalendarDecrAP: {
        idLog3.warn('onNessUpdateCalendarDecrAP before ' + calend_time.chosenDate)

        var s_date_lv = ''
        s_date_lv = univreaderex.incrementDate(calend_time.chosenDate, -1)
        root.b_input_time_outside_cahange = true

        calend_time.chosenDate = univreaderex.timeToComponentDate(s_date_lv)

        idLog3.warn('onNessUpdateCalendarDecrAP after ' + calend_time.chosenDate)

        root.b_input_time_outside_cahange = false
    }
    onText_primitChanged: {
        idLog3.warn('<prim> onText_primitChanged beg 5' + root.text_primit)
        univreaderex.outputPrimitiv_Causing1(root.text_primit)
    }
    onCommon_panelChanged: {
        if (common_panel)
            key2 = "common_panel"
    }
    onM_i_210929_debChanged: {
        idLog3.warn('<210927> 193')

//        if (root.m_v_component_main_export !== null) {
//            if (export_aviLoader.status !== Loader.Null)
//                export_aviLoader.source = ""
//        }
    }
    onSpeedChanged: {
        if (0 === root.arc_vers) {
            univreaderex.setSpeed005(root.speed)
        } else {
            if (0 === m_i_started)
                univreaderex.setSpeed005Value(root.speed)
            else {
                if (!(root.fromRealtime))
                    univreaderex.setSpeed005(root.speed)
            }
        }
    }
    onCmdChanged: {
        if (0 === root.arc_vers) {
            univreaderex.setCmd005(cmd)
        } else {
            if (0 === m_i_started)
                univreaderex.setCmd005Value(cmd)
        }
    }
    onM_s_exch_event_idChanged: {
        idLog3.warn('<events>  m_s_exch_event_id ' + root.m_s_exch_event_id)
        root.m_s_start_event_id = root.m_s_exch_event_id
        root.m_i_select_interv_state = c_I_IS_CORRECT_INTERV
        root.m_i_is_interval_corresp_event = 1
        root.m_i_is_interval_corresp_event_bookmark = 1
        univreaderex.refreshEventsOnBar()
        //upload_left_bound_lb.visible4 = true
        //upload_left_bound_2_lb.visible4 = true
    }
    onIs_export_mediaChanged: {}
    onKey2Changed: {
        console.info("onKey2Changed root.width = ", root.width,
                     " root.Window.window.width = ", root.Window.window.width)
        idLog3.warn('<common_pan> onKey2Changed beg key2 ' + root.key2 + ' vers ' + root.arc_vers)
        idLog3.warn('<load> 210113 1 ')
        if ('window' in root.Window) {
            idLog3.warn('<load> 210113 2 ')
            if ('unique' in root.Window.window) {
                idLog3.warn('<load> 210113 3 ' + ' unique ' + root.Window.window.unique)
                univreaderex.setSliderNew2303(1)
                univreaderex.setId101(root.Window.window.unique)
            }
        }
        if (root.arc_vers === 0) setMode904()
        univreaderex.key2 = root.key2
        if ((0 !== m_i_start_called || 0 === root.arc_vers)
                && is_export_media === 1 &&  0 === m_i_started)
        {
            root.componentCompleted()
        }
        m_b_ke2_changed_2303 = true
        root.complete2303()
    }
    onTimeChanged: {
        idLog3.warn('200904 2')
        var i_is_ness_time_change_actions = 0

        var s_time_iv_lv = ''
        s_time_iv_lv = univreaderex.convertTimeFromIntegraciyaIfNess(root.time)

        var s_end_iv_lv = ''
        s_end_iv_lv = univreaderex.convertTimeFromIntegraciyaIfNess(root.end)
        idLog3.warn('<' + root.key2 + '_' + root.key3 + '>onTimeChanged root.time '
                    + root.time + ' s_time_iv_lv ' + s_time_iv_lv)

        if (0 === root.arc_vers) i_is_ness_time_change_actions = 1
        else if (0 !== root.m_i_started){
            if (!(root.fromRealtime) || root.m_isTestMode009)
                i_is_ness_time_change_actions = 1
        }
        idLog3.warn(' i_is_ness_time_change_actions ' + i_is_ness_time_change_actions)

        if (0 !== i_is_ness_time_change_actions) {
            univreaderex.outsideSetTimeAP(s_time_iv_lv)
            if ('' !== s_time_iv_lv && '' !== s_end_iv_lv) {

                //выделим интервал е
                var i64_lu_beg_lv = univreaderex.strToMSTime(s_time_iv_lv)
                var i64_lu_end_lv = univreaderex.strToMSTime(s_end_iv_lv)
                var i64_uu_beg_lv = univreaderex.timeToUniv(i64_lu_beg_lv)
                var i64_uu_end_lv = univreaderex.timeToUniv(i64_lu_end_lv)
                root.showInterval908(i64_uu_beg_lv, i64_uu_end_lv, '')
            }
        }

        if ((0 !== m_i_start_called || 0 === root.arc_vers)
                && is_export_media === 1 &&  0 === m_i_started){
            root.componentCompleted()
        }
    }
    onEndChanged: {
        if ('' !== root.time && '' !== root.end){
            var s_time_iv_lv = ''
            s_time_iv_lv = univreaderex.convertTimeFromIntegraciyaIfNess(root.time)

            var s_end_iv_lv = ''
            s_end_iv_lv = univreaderex.convertTimeFromIntegraciyaIfNess(root.end)

            univreaderex.end = s_end_iv_lv

            //выделим интервал е
            var i64_lu_beg_lv = univreaderex.strToMSTime(s_time_iv_lv)
            var i64_lu_end_lv = univreaderex.strToMSTime(s_end_iv_lv)
            var i64_uu_beg_lv = univreaderex.timeToUniv(i64_lu_beg_lv)
            var i64_uu_end_lv = univreaderex.timeToUniv(i64_lu_end_lv)

            idLog3.warn('<' + root.key2 + '_' + root.key3 + '_interv>' + ' onEndChanged '
                        + ' i64_uu_beg_lv ' + i64_uu_beg_lv + ' i64_uu_end_lv ' + i64_uu_end_lv)
            root.showInterval908(i64_uu_beg_lv, i64_uu_end_lv, '')
        }
        if ((0 !== m_i_start_called || 0 === root.arc_vers)
                && is_export_media === 1 && 0 === m_i_started)
        {
            root.componentCompleted()
        }
    }
    onM_s_key3_audio_apChanged: {
        idLog3.warn('<audio> onM_s_key3_audio_apChanged ' + root.m_s_key3_audio_ap)
        univreaderex.initAudioAP(root.m_s_key3_audio_ap,
                                 root.m_s_track_source_univ_ap)
    }
    onM_s_track_source_univ_ap: {
        idLog3.warn('<audio> m_s_track_source_univ_ap ' + root.m_s_track_source_univ_ap)
        univreaderex.initAudioAP(root.m_s_key3_audio_ap,
                                 root.m_s_track_source_univ_ap)
    }
//    onM_b_ness_pass_paramsChanged: {
//        idLog3.warn('onM_b_ness_pass_paramsChanged m_b_ness_pass_params ' + m_b_ness_pass_params
//                    + ' root.m_b_is_caused_by_unload ' + root.m_b_is_caused_by_unload)
//        if (m_b_ness_pass_params) {
//            if (root.m_b_is_caused_by_unload) {
//                if (root.export_avi_object !== null
//                        && root.export_avi_object !== undefined) {
//                    root.export_avi_object.set_from(
//                                univreaderex.uu64ToHumanEv(
//                                    root.m_uu_i_ms_begin_interval, 3))
//                }
//                if (root.export_avi_object !== null
//                        && root.export_avi_object !== undefined) {
//                    root.export_avi_object.set_to(
//                                univreaderex.uu64ToHumanEv(
//                                    root.m_uu_i_ms_end_interval, 3))
//                }
//            }
//            else {
//                idLog3.warn('<unload> 2')
//                if (false === root.common_panel) {
//                    export_aviLoader.create()
//                }
//            }
//        }
//    }
    onWidthChanged: {
        if (root.width < root.Window.window.width * 0.75 && root.isFullscreen === false){
            root.is_multiscreen = true
            root.cache_preview.splice(0, cache_preview.length)
        }
        else {
            root.is_multiscreen = false
        }
    }
    onHeightChanged: {
        idLog3.warn('<IVArchivePlayer.qml> onHeightChanged root height = ' + root.height)
    }
    Component.onCompleted: {
        idLog3.warn('<common_pan> onCompleted beg key2 ' + root.key2 + 'vers' + root.arc_vers)

        if (root.debug_mode === true) {
            IVCompCounter.addComponent(root)
        }
        if (is_export_media !== 1) {
            if ((0 !== m_i_start_called || 0 === root.arc_vers)
                    && 0 === m_i_started) {
                root.componentCompleted()
            }
        }
        root.m_i_is_comleted = 1
        menuLoaderSelInterv.create()
        menuLoaderContext_menu2.create()
    }

    Iv7Plugin {
        id: stabilizer
        //ch91113_2 old plugin: (root.running&& stabServer.value === "true")?  'image_stabilizer': ''
        plugin: root.running ? root.isServer ? 'image_stabilizer' : 'StabilizerClient' : ""
        key1: univreaderex.key1
        key2: root.key2
        key3: root.key3
        //привязали его вход к своему е
        trackIn: //ch91113 univviewer.trackFrame.
                 univreaderex.trackFrameAfterSynchr.slice(//ch91113 univviewer.
                                                          univreaderex.trackCmd.length + 1)
        trackOut: 'image_stabilizer'
        sectionName: "common_settings"
        inFieldName: "in"
        outFieldName: "out"
    }

    Rectangle {
        id: event_select_rct_hint
        width: 120
        height: 33
        color: "white"
        //ch91017 anchors.bottom:
        //ch91017 event_select_rct.top
        //ch91017 anchors.bottomMargin: 10
        x: 0
        y: 80
        z: 300
        visible: false
        //ch91017 deb sht true
        radius: 3
        Text {
            id: event_select_rct_hint_text
            anchors.centerIn: parent
            renderType: Text.NativeRendering
            text: "2222-22-22 22:22:22"
            font.pixelSize: 14 * root.isize
        }
    }

    Rectangle {
        id: next_event_not_found_rct_hint
        width: 120
        height: 15
        z: 300
        color: "white"
        //anchors.top:
        //            iv_butt_spb_events_skip.bottom
        //anchors.bottomMargin: 10
        visible: false
        Text {
            id: next_event_not_found_rct_hint_text
            anchors.centerIn: parent
            renderType: Text.NativeRendering
            text: "2222-22-22 22:22:22"
        }
    }
    readonly property string trackFrameAfterSynchrRoot: {
        return univreaderex.trackFrameAfterSynchr
    }
    readonly property string trackFrameAfterStabilizerRoot: {
        var s_res_lv = univreaderex.trackFrameAfterSynchr
        if (stabilizer.isCreated) {
            var __trackOut = stabilizer.key1 + '_' + stabilizer.key2 + '_'
                    + stabilizer.key3 + '_' + stabilizer.trackOut
            s_res_lv = __trackOut
        }
        return s_res_lv
    }
    Timer {
        id: timer809
        interval: 500
        running: false
        repeat: true
        onTriggered: {
            root.m_i_counter006++
            if (root.m_i_counter006 === 5) {
                idLog3.warn('<prim> onText_primitChanged beg 8 ' + root.text_primit)
                univreaderex.outputPrimitiv_Causing1(root.text_primit)
            }

            if (0 !== root.m_i_is_sound_created
                    && 0 !== root.m_i_ness_activate_sound
                    && 0 === root.m_i_already_set_008) {
                m_i_already_set_008 = 1
                if ('change_state_sound_checkbox' in root.m_pane_sound)
                    root.m_pane_sound.change_state_sound_checkbox(true)
            }
            root.timerActions()
        }
    }
    Timer {
        id: timer904
        interval: 200
        running: false
        repeat: true
        onTriggered: {
            idLog3.warn('<common_pan> 00425 ' + root.key2 + " key3 " + root.key3
                        + ' common_panel ' + root.common_panel)
            idLog3.warn('<210927> 510 ')
            if (false !== root.common_panel)
                univreaderex.commonPanelRefresh()
            if (false === root.common_panel) {
                idLog3.warn('<210927> 511 ness_swith_to_realtime '
                            + univreaderex.ness_swith_to_realtime)

                if (1 === univreaderex.ness_swith_to_realtime) {
                    idLog3.warn('<210927> 512 ')
                    if (univreaderex.ness_swith_to_realtime
                            !== univreaderex.m_i_ness_swith_to_realtime_prev) {
                        idLog3.warn('<210927> 513 ')
                        if (viewer_command_obj !== null
                                || viewer_command_obj !== undefined) {
                            viewer_command_obj.command_to_viewer(
                                        'viewers:switch')
                        }
                        univreaderex.m_i_ness_swith_to_realtime_prev
                                = univreaderex.ness_swith_to_realtime
                        idLog3.warn('<210927> 513 ')
                    }
                }
            } else {
                if (root.m_i_ness_all_switch_to_realtime
                        !== root.m_i_ness_all_switch_to_realtime_prev) {
                    idLog3.warn('<common_pan> timer904 bef allArcPlayersSwitchToRealtime')
                    univreaderex.allArcPlayersSwitchToRealtime()
                }
                root.m_i_ness_all_switch_to_realtime_prev = root.m_i_ness_all_switch_to_realtime
                //ch220403 svyazano s testom ws
                if (m_i_is_ness_switch_to_realtime_common_panel
                        !== m_i_is_ness_switch_to_realtime_common_panel_prev) {
                    m_i_is_ness_switch_to_realtime_common_panel_prev
                            = m_i_is_ness_switch_to_realtime_common_panel
                    univreaderex.allArcPlayersSwitchToRealtime()
                }
                //e
            }
            idLog3.warn('<210927> 516 ')
        }
    }

    Timer {
        id: freqTimer
        triggeredOnStart: false
        interval: 4000
        repeat: false
        running: true
        onTriggered: {
            if (m_equal != null && m_equal != undefined)
                m_equal.running = Qt.binding(function () {
                    return (!root.m_s_is_video_present && root.m_pane_sound.is_audio) && root.running
                })
        }
    }
    MouseArea {
        id: mousearea_CommonPanMode
        z: 99
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        propagateComposedEvents: true
        property bool mouseOnPane910: false
        onEntered: {
            mousearea_CommonPanMode.mouseOnPane910 = true
            idLog3.warn('onEntered 91026')
            ivButtonTopPanel.mouseOnPane = true
        }
        onExited: {
            mousearea_CommonPanMode.mouseOnPane910 = false
            idLog3.warn('onExited 91026')
            ivButtonTopPanel.mouseOnPane = false
        }
        onWidthChanged: {
            //idLog3.warn("<ArchivePlayer.qml> onWidthChanged mousearea_CommonPanMode.width = "+mousearea_CommonPanMode.width);
        }
        Loader{
            id: playerLoader
            active: false // включить когда будет готов модуль на сервере для обратного проигрывания
            sourceComponent: Player{}
        }
        Rectangle {
            id: render_rct
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            //anchors.bottomMargin: wndControlPanel.height //root.m_i_c_control_panel_height
            anchors.left: parent.left
            anchors.right: parent.right
            color: "transparent"
            z: 1

            Rectangle {
                id: primitivesRect
                anchors.fill: parent
                color: 'transparent'
                z: 110
                property int frameLeft_905: render.frameLeft
                property int frameTop_905: render.frameTop
                property int frameRight_905: render.frameRight
                property int frameBottom_905: render.frameBottom
                Loader {
                    id: primitivesLoader
                    anchors.fill: primitivesRect
                    asynchronous: true
                    property var componentPrimitives: null
                    function create() {
                        var qmlfile = "file:///" + applicationDirPath
                                + '/qtplugins/iv/primitives/IVPrimitives.qml'
                        primitivesLoader.source = qmlfile
                    }
                    function refresh() {
                        primitivesLoader.destroy()
                        primitivesLoader.create()
                    }
                    function destroy() {
                        if (primitivesLoader.status !== Loader.Null)
                            primitivesLoader.source = ""
                    }
                    onStatusChanged: {
                        if (primitivesLoader.status === Loader.Ready) {
                            primitivesLoader.componentPrimitives = primitivesLoader.item
                            root.m_primit = primitivesLoader.componentPrimitives

                            root.safeSetProperty(
                                        primitivesLoader.componentPrimitives,
                                        'anchors.left', Qt.binding(function () {
                                            return primitivesRect.left
                                        }))

                            root.safeSetProperty(
                                        primitivesLoader.componentPrimitives,
                                        'anchors.leftMargin',
                                        Qt.binding(function () {
                                            return primitivesRect.frameLeft_905
                                        }))

                            root.safeSetProperty(
                                        primitivesLoader.componentPrimitives,
                                        'anchors.top', Qt.binding(function () {
                                            return primitivesRect.top
                                        }))

                            root.safeSetProperty(
                                        primitivesLoader.componentPrimitives,
                                        'anchors.topMargin',
                                        Qt.binding(function () {
                                            return primitivesRect.frameTop_905
                                        }))

                            root.safeSetProperty(
                                        primitivesLoader.componentPrimitives,
                                        'width', Qt.binding(function () {
                                            return primitivesRect.frameRight_905
                                                    - primitivesRect.frameLeft_905
                                        }))

                            root.safeSetProperty(
                                        primitivesLoader.componentPrimitives,
                                        'height', Qt.binding(function () {
                                            return primitivesRect.frameBottom_905
                                                    - primitivesRect.frameTop_905
                                        }))

                            root.safeSetProperty(
                                        primitivesLoader.componentPrimitives,
                                        'key1', Qt.binding(function () {
                                            return univreaderex.key1
                                        }))
                            root.safeSetProperty(
                                        primitivesLoader.componentPrimitives,
                                        'key2', Qt.binding(function () {
                                            return univreaderex.key2
                                        }))
                            root.safeSetProperty(
                                        primitivesLoader.componentPrimitives,
                                        'key3', Qt.binding(function () {
                                            return root.key3
                                        }))

                            root.safeSetProperty(
                                        primitivesLoader.componentPrimitives,
                                        'isAudioExist', Qt.binding(function () {
                                            return root.m_pane_sound.visible
                                        }))

                            root.safeSetProperty(
                                        primitivesLoader.componentPrimitives,
                                        'frame_time', Qt.binding(function () {
                                            return root.m_s_is_video_present
                                        }))

                            root.safeSetProperty(
                                        primitivesLoader.componentPrimitives,
                                        'running', Qt.binding(function () {
                                            return render.running
                                        }))
                        }
                        if (primitivesLoader.status === Loader.Error) {
                            console.error("primitivesLoader error")
                        }
                        if (primitivesLoader.status === Loader.Null) {

                        }
                    }
                }
                Loader {
                    id: equalizerLoader
                    anchors.fill: primitivesRect
                    asynchronous: true
                    property var componentEqualizer: null
                    function create() {
                        var qmlfile = "file:///" + applicationDirPath
                                + '/qtplugins/frequencyequalizer/FrequencyEqualizers.qml'
                        equalizerLoader.source = qmlfile
                    }
                    function refresh() {
                        equalizerLoader.destroy()
                        equalizerLoader.create()
                    }
                    function destroy() {
                        if (equalizerLoader.status !== Loader.Null)
                            equalizerLoader.source = ""
                    }
                    onStatusChanged: {
                        if (equalizerLoader.status === Loader.Ready) {
                            equalizerLoader.componentEqualizer = equalizerLoader.item
                            root.m_equal = equalizerLoader.componentEqualizer

                            root.safeSetProperty(
                                        equalizerLoader.componentEqualizer,
                                        'anchors.fill', Qt.binding(function () {
                                            return primitivesRect
                                        }))

                            root.safeSetProperty(
                                        equalizerLoader.componentEqualizer,
                                        'key1', Qt.binding(function () {
                                            return univreaderex.key1
                                        }))

                            root.safeSetProperty(
                                        equalizerLoader.componentEqualizer,
                                        'key2', Qt.binding(function () {
                                            return univreaderex.key2
                                        }))

                            root.safeSetProperty(
                                        equalizerLoader.componentEqualizer,
                                        'key3', Qt.binding(function () {
                                            return root.m_s_key3_audio_ap
                                        }))
                        }
                    }
                }
                MouseArea {
                    id: mouseAreaRender
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    Loader {
                        id: menuLoaderContext_menu2
                        //anchors.fill: parent
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

                                //console.error("menuLoaderContext_menu2.componentMenu error");
                            }
                            if (menuLoaderContext_menu2.status === Loader.Null) {

                            }
                        }
                    }

                    onDoubleClicked: {
                        if (mouse.button & Qt.LeftButton) {
                            if (viewer_command_obj !== null || viewer_command_obj !== undefined)
                                viewer_command_obj.command_to_viewer('viewers:fullscreen')
                            mouse.accept = true
                        }
                        else mouse.accept = false
                    }
                    onClicked: {
                        if (mouse.button & Qt.RightButton) {
                            root.callContextMenu907(mouseX, mouseY)
                            mouse.accept = true
                        }
                        else mouse.accept = false
                    }
                } //MouseArea
            }
            IVRender {
                id: render
                anchors.fill: parent
                trackFrame: {
                    if (root.m_b_image_corrector_created) return root.trackFrameAfterImageCorrectorRoot
                    else return root.trackFrameAfterStabilizerRoot
                }
                trackCmd: univreaderex.trackCmd
                z: 80
            } //render
        } //renderrect

        IVButtonTopPanel {
            id: ivButtonTopPanel
            anchors.top: parent.top
            mouseOnPane: false
            parentComponent: root
            m_idLog2_btp: idLog2
            m_idLog3_btp: idLog3
            //viewer_cmd_obj: root.viewer_command_obj
        }
        Rectangle {
            id: r910Rect
            anchors.fill: parent
            color: "transparent"
            z: 5
            opacity: ((0 === root.getCamCommonPanelModeUseSetPanel_Deb() && !root.isSmallMode())
                      || mousearea_CommonPanMode.mouseOnPane910 || root.common_panel) ? 1.0 : 0.0
            onWidthChanged: {
                idLog3.warn('<calendar> onWidthChanged r910Rect width = ' + r910Rect.width)
            }
            Rectangle { // нижняя панели на камере при вкл. общей архивной полосе
                id: r910_2Rect
                anchors.bottom: parent.bottom
                height: 32 * root.isize
                anchors.left: parent.left
                anchors.right: parent.right
                color: "steelblue" //"brown"
                opacity: ((mousearea_CommonPanMode.mouseOnPane910
                           && //если еще режим полной панели,  то становится не прзрачным
                           (0 !== root.getCamCommonPanelModeUseSetPanel_Deb()
                            //еще вариант - маленькая панель
                            || root.isSmallMode())
                           && !(root.common_panel)) ? 0.7 : 0.0)
                RowLayout {
                    id: panel_mode_common_panel
                    height: parent.height
                    width: contentWidth
                    layoutDirection: Qt.LeftToRight
                    anchors.right: parent.right
                    spacing: 2
                    Rectangle {
                        id: rect_export_media
                        width: 24 * root.isize
                        height: 24 * root.isize
                        color: "transparent"
                        IVImageButton {
                            id: export_media_button
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.fill: rect_export_media
                            size: "normal"
                            txt_tooltip: Language.getTranslate("export to AVI, MKV","экспорт в AVI, MKV")
                            on_source: 'file:///' + applicationDirPath + '/images/white/archSave.svg'
                            visible: false
                            onClicked: export_mediaLoader.create()
                            hoveredColor: root.hoveredColor
                            pressedColor: root.pressedColor
                            Loader {
                                id: export_mediaLoader
                                asynchronous: true
                                property var componentExport_avi: null
                                function create() {
                                    if (export_mediaLoader.status !== Loader.Null)
                                        export_mediaLoader.source = ""
                                    var qmlfile = "file:///" + applicationDirPath + '/qtplugins/iv/viewers/archiveplayer/qmainexport.qml'
                                    export_mediaLoader.source = qmlfile
                                }
                                function refresh() {
                                    export_mediaLoader.destroy()
                                    export_mediaLoader.create()
                                }
                                function destroy() {
                                    if (export_mediaLoader.status !== Loader.Null)
                                        export_mediaLoader.source = ""
                                }
                                onStatusChanged: {
                                    if (export_mediaLoader.status === Loader.Ready) {
                                        export_mediaLoader.componentExport_avi = export_mediaLoader.item
                                        root.m_v_component_main_export = export_mediaLoader.componentExport_avi

                                        idLog3.warn('<' + root.key2 + '_' + root.key3 + '>' + 'onBindings 180110')

                                        var s_begin_lv = ''
                                        var s_end_lv = ''
                                        var s_zna_ip_lv = ''

                                        idLog2.warn('onBindings 180110')

                                        if (0 === root.m_uu_i_ms_begin_interval) {
                                            s_begin_lv = univreaderex.intervTime2(0)
                                            idLog3.warn('unload_to_avi_ivibt clicked time before ' + root.end)

                                            if ('' === root.end) {
                                                s_end_lv = univreaderex.addDeltaTime(univreaderex.intervTime2(0), 120000)
                                                idLog3.warn('<' + root.key2 + '_' + root.key3 + '>' + 'unload_to_avi_ivibt clicked end after ' + s_end_lv)
                                            }
                                            else s_end_lv = root.end
                                        }
                                        else {
                                            s_begin_lv = univreaderex.uu64ToHumanEv(root.m_uu_i_ms_begin_interval, 3)
                                            s_end_lv = univreaderex.uu64ToHumanEv(root.m_uu_i_ms_end_interval, 3)
                                        }
                                        root.safeSetProperty(
                                                    export_mediaLoader.componentExport_avi,
                                                    'key2',
                                                    Qt.binding(function () {
                                                        return root.key2
                                                    }))
                                        var s1 = s_begin_lv.indexOf('27')
                                        idLog3.warn('<mwork> s_begin_lv ' + s_begin_lv
                                                    + ' s_end_lv ' + s_end_lv
                                                    + ' ' + root.time811 + ' s1 ')

                                        if (s1 === 0) {
                                            s_begin_lv = root.time811
                                            s_end_lv = s_begin_lv
                                            idLog3.warn('<mwork>corrected '
                                                        + s_begin_lv + ' ' + s_end_lv)
                                        }
                                        root.safeSetProperty(
                                                    export_mediaLoader.componentExport_avi,
                                                    'from',
                                                    Qt.binding(function () {
                                                        return s_begin_lv
                                                    }))
                                        root.safeSetProperty(
                                                    export_mediaLoader.componentExport_avi,
                                                    'to',
                                                    Qt.binding(function () {
                                                        return s_end_lv
                                                    }))
                                        if (0 !== root.m_s_start_event_id
                                                && '' !== root.m_s_start_event_id) {
                                            root.safeSetProperty(
                                                        export_mediaLoader.componentExport_avi,
                                                        'evtid',
                                                        Qt.binding(function () {
                                                            return root.m_s_start_event_id
                                                        }))
                                        }

                                        s_zna_ip_lv = univreaderex.getSelectedZnaIp()

                                        idLog3.warn("<select_source> export_mediaLoader onStatusChanged s_zna_ip_lv " + s_zna_ip_lv)
                                        root.safeSetProperty(
                                                    export_mediaLoader.componentExport_avi,
                                                    'selected_zna_ip',
                                                    Qt.binding(function () {
                                                        return s_zna_ip_lv
                                                    }))

                                        idLog3.warn('<unload> onBindings from ' + export_mediaLoader.componentExport_avi.from + ' to ' + export_mediaLoader.componentExport_avi.to + ' evtid ' + root.m_s_start_event_id)
                                        export_mediaLoader.componentExport_avi.parent_arc_obj = sel_interv
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: rect_sound
                        width: 24 * root.isize
                        height: 24 * root.isize
                        color: "transparent"
                        Loader {
                            id: sound_Loader
                            anchors.fill: rect_sound
                            asynchronous: true
                            property var componentSound: null
                            function create() {
                                var qmlfile = "file:///" + applicationDirPath
                                        + '/qtplugins/iv/sound/PaneSound.qml'
                                sound_Loader.source = qmlfile
                            }
                            function refresh() {
                                sound_Loader.destroy()
                                sound_Loader.create()
                            }
                            function destroy() {
                                if (sound_Loader.status !== Loader.Null)
                                    sound_Loader.source = ""
                            }
                            onStatusChanged: {
                                if (sound_Loader.status === Loader.Ready) {
                                    sound_Loader.componentSound = sound_Loader.item

                                    idLog3.warn('<sound> onCreated180904 2 '
                                                + sound_Loader.componentSound)
                                    var sound808_lv = sound_Loader.componentSound

                                    root.m_pane_sound = sound_Loader.componentSound
                                    idLog3.warn('<sound> 200811 50')
                                    root.m_i_is_sound_created = 1
                                    //e
                                    sound808_lv.owneraddress_arch = univreaderex.getAddr808()
                                    sound808_lv.funaddress_arch = univreaderex.getFunct808()
                                    univreaderex.storeSoundInfo(
                                                sound808_lv.owneraddress,
                                                sound808_lv.funaddress)

                                    sound_Loader.componentSound.key2 = root.key2
                                    sound_Loader.componentSound.key3 = root.key3
                                    sound_Loader.componentSound.is_archive = 1

                                    root.safeSetProperty(root,
                                                         'm_s_key3_audio_ap',
                                                         Qt.binding(
                                                             function () {
                                                                 return sound_Loader.componentSound.key3_audio
                                                             }))

                                    root.safeSetProperty(
                                                root,
                                                'm_s_track_source_univ_ap',
                                                Qt.binding(function () {
                                                    return sound_Loader.componentSound.track_source_univ
                                                }))
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: rect_photo_cam
                        width: 24 * root.isize
                        height: 24 * root.isize
                        color: "transparent"
                        Loader {
                            id: photocam_Loader
                            anchors.fill: rect_photo_cam
                            asynchronous: true
                            property var componentPhotocam: null
                            function create() {
                                var qmlfile = "file:///" + applicationDirPath
                                        + '/qtplugins/iv/photocam/PanePhotoCam.qml'
                                photocam_Loader.source = qmlfile
                            }
                            function refresh() {
                                photocam_Loader.destroy()
                                photocam_Loader.create()
                            }
                            function destroy() {
                                if (photocam_Loader.status !== Loader.Null)
                                    photocam_Loader.source = ""
                            }
                            onStatusChanged: {
                                if (photocam_Loader.status === Loader.Ready) {
                                    photocam_Loader.componentPhotocam = photocam_Loader.item
                                    root.safeSetProperty(
                                                photocam_Loader.componentPhotocam,
                                                'key2', Qt.binding(function () {
                                                    return root.key2
                                                }))

                                    root.safeSetProperty(
                                                photocam_Loader.componentPhotocam,
                                                'track',
                                                Qt.binding(function () {
                                                    return root.trackFrameAfterSynchrRoot
                                                }))

                                    root.safeSetProperty(
                                                photocam_Loader.componentPhotocam,
                                                'parent2',
                                                Qt.binding(function () {
                                                    return root
                                                }))
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: rect_switch_to_real_time
                        width: 24 * root.isize
                        height: 24 * root.isize
                        color: "transparent"
                        //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
                        IVImageButton {
                            //ch90423 id: archive
                            id: switch_to_real_time_button
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: parent.height
                            visible: false
                            txt_tooltip: Language.getTranslate(
                                             "return to realtime",
                                             "возврат в реалтайм")
                            on_source: 'file:///' + applicationDirPath
                                       + //ch90423 '/images/white/video_lib.svg'
                                       //ch10216 '/images/white/camera.svg'
                                       '/images/white/video_lib_exit.svg'
                            size: "normal" //(parentComponent.isFullscreen? "normal":"small")
                            onClicked: {
                                //ch90425 parentComponent
                                if (!root.common_panel) {
                                    idLog3.trace('<210927> unload_to_avi_ivibt 2 clicked bef act ')
                                    if (viewer_command_obj !== null
                                            || viewer_command_obj !== undefined) {
                                        viewer_command_obj.command_to_viewer(
                                                    'viewers:switch')
                                    }
                                    idLog3.trace('<210927> unload_to_avi_ivibt 2 clicked aft act ')
                                } else {
                                    univreaderex.allArcPlayersSwitchToRealtime()
                                }
                            }
                        }
                    }

                    Rectangle {
                        //ch90423 id:imageCorrector
                        id: rect_image_corr_rec
                        width: 24 * root.isize
                        height: 24 * root.isize
                        color: "transparent"
                        //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
                        Loader {
                            id: image_correct_Loader
                            anchors.fill: rect_image_corr_rec
                            asynchronous: true
                            property var componentImage_correct: null
                            function create() {
                                var qmlfile = "file:///" + applicationDirPath
                                        + '/qtplugins/iv/imagecorrector/ImageCorrector.qml'
                                image_correct_Loader.source = qmlfile
                            }
                            function refresh() {
                                image_correct_Loader.destroy()
                                image_correct_Loader.create()
                            }
                            function destroy() {
                                if (image_correct_Loader.status !== Loader.Null)
                                    image_correct_Loader.source = ""
                            }
                            onStatusChanged: {
                                if (image_correct_Loader.status === Loader.Ready) {
                                    image_correct_Loader.componentImage_correct
                                            = image_correct_Loader.item

                                    //ch91113 входная очередь данного плагина е
                                    image_correct_Loader.componentImage_correct.inProfileName
                                            = root.//ch91112_3 trackFrameAfterSynchrRoot;
                                    trackFrameAfterStabilizerRoot
                                    //ch91113 выходная очередь данного плагина е
                                    image_correct_Loader.componentImage_correct.outProfileName
                                            = //ch91112_3 univreaderex.trackFrameAfterSynchr
                                            root.trackFrameAfterStabilizerRoot
                                            + "_correct" // просто присвоение свойства
                                    //ch91113 render.trackFrame
                                    root.trackFrameAfterImageCorrectorRoot = image_correct_Loader.componentImage_correct.outProfileName

                                    root.safeSetProperty(
                                                image_correct_Loader.item,
                                                'key2', Qt.binding(function () {
                                                    return root.key2
                                                }))

                                    image_correct_Loader.componentImage_correct._x_position
                                            = -image_correct_Loader.componentImage_correct.custom_width
                                    image_correct_Loader.componentImage_correct._y_position
                                            = -image_correct_Loader.componentImage_correct.custom_height - 40

                                    //ch91113
                                    root.m_b_image_corrector_created = true
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: rect_fullscreen_button
                        width: 24 * root.isize
                        height: 24 * root.isize
                        color: "transparent"

                        //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
                        IVImageButton {
                            id: fullscreen_button
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: parent.height
                            visible: false
                            txt_tooltip: (//ch90425 parentComponent
                                          root.isFullscreen ? Language.getTranslate(
                                                                  "Minimize",
                                                                  "Свернуть") : Language.getTranslate(
                                                                  "Maximize",
                                                                  "Развернуть"))
                            on_source: (//ch90425 parentComponent
                                        root.isFullscreen ? 'file:///' + applicationDirPath + '/images/white/fullscreen_exit.svg' : 'file:///' + applicationDirPath + '/images/white/fullscreen.svg')
                            size: "normal" //(parentComponent.isFullscreen? "normal":"small")
                            onEntered: {
                                fullscreen_button_bckg.opacity = 0.3
                            }
                            onExited:{
                                fullscreen_button_bckg.opacity = 0
                            }
                            Rectangle {
                                id: fullscreen_button_bckg
                                anchors.fill: parent
                                color: root.hoveredColor
                                opacity: 0
                            }
                            onClicked: {
                                //ch90425 parentComponent
                                if (viewer_command_obj !== null
                                        || viewer_command_obj !== undefined) {
                                    viewer_command_obj.command_to_viewer(
                                                'viewers:fullscreen')
                                }
                            }
                            Component.onCompleted: {

                            }
                        }
                    }
                }
            }

            Rectangle {
                id: rootRect
                anchors.fill: parent
                color: "transparent"
                z: 97

                onWidthChanged: {
                    idLog3.warn('<calendar> onWidthChanged rootRect width = ' + rootRect.width)
                }
                Loader {
                    id: select_intervalLoader
                    asynchronous: true
                    property var componentSelect_interval: null
                    function create() {
                        if (select_intervalLoader.status !== Loader.Null)
                            select_intervalLoader.source = ""
                        var qmlfile = "file:///" + applicationDirPath
                                + '/qtplugins/iv/archivecomponents/selectinterval/qselectinterval3.qml'
                        select_intervalLoader.source = qmlfile
                    }
                    function refresh() {
                        select_intervalLoader.destroy()
                        select_intervalLoader.create()
                    }
                    function destroy() {
                        if (select_intervalLoader.status !== Loader.Null)
                            select_intervalLoader.source = ""
                    }
                    onStatusChanged: {
                        if (select_intervalLoader.status === Loader.Ready) {
                            select_intervalLoader.componentSelect_interval
                                    = select_intervalLoader.item

                            root.safeSetProperty(
                                        select_intervalLoader.componentSelect_interval,
                                        'parent2', Qt.binding(function () {
                                            return univreaderex.key2
                                        }))

                            var point_00525_fr_lv = mapFromGlobal(0, 0)
                            var point_00525_to_lv = mapToGlobal(0, 0)
                            var point_00525_to_r_lv = root.mapToGlobal(0, 0)

                            idLog3.warn('onBindings 808_5 fr_gl x ' + point_00525_fr_lv.x
                                        + ' y ' + point_00525_fr_lv.y
                                        + ' to_gl x ' + point_00525_to_lv.x
                                        + ' y ' + point_00525_to_lv.y
                                        + ' to_r_gl x ' + point_00525_to_r_lv.x
                                        + ' y ' + point_00525_to_r_lv.y
                                        + ' root.width ' + root.width + ' root.height ' + root.height + ' select_intervalLoader.componentSelect_interval.width ' + select_intervalLoader.componentSelect_interval.width + ' select_intervalLoader.componentSelect_interval.height ' + select_intervalLoader.componentSelect_interval.height)

                            select_intervalLoader.componentSelect_interval.key2 = root.key2 // просто присвоение свойства
                            select_intervalLoader.componentSelect_interval.begin = root.m_uu_i_ms_begin_interval
                            select_intervalLoader.componentSelect_interval.end = root.m_uu_i_ms_end_interval

                            select_intervalLoader.componentSelect_interval.parent_qml = 'IVArchivePlayer.qml'
                            select_intervalLoader.componentSelect_interval.select_interv = sel_interv
                            root.safeSetProperty(root, 'm_s_exch_event_id',
                                                 Qt.binding(function () {
                                                     return select_intervalLoader.componentSelect_interval.m_s_exch_event_id_si
                                                 }))

                            select_intervalLoader.componentSelect_interval.m_b_unload_mode
                                    = root.m_b_is_caused_by_unload
                            idLog2.warn('181031 bind beg ' + select_intervalLoader.componentSelect_interval.begin + 'end '
                                        + select_intervalLoader.componentSelect_interval.end)

                            componentSelect_interval.x = point_00525_to_r_lv.x
                                    + root.width / 2 - componentSelect_interval.width / 2
                            componentSelect_interval.y = point_00525_to_r_lv.y
                                    + root.height / 2 - componentSelect_interval.height / 2
                        }
                    }
                }

                Rectangle {
                    id: wndControlPanel
                    color: "transparent"
                    anchors.bottom: parent.bottom
                    height: iv_arc_slider_new.height + iv_arc_menu_new.height
                    width: parent.width
                    z: 85
                    onWidthChanged: {
                        univreaderex.putLog807('onWidthChanged ')
                        idLog3.warn('<calendar> onWidthChanged wndControlPanel width = ' + wndControlPanel.width)

                        if (root.common_panel){
                            root.commonPanelExtButtonsSetVisible(false)
                        }
                        else if (0 !== root.getCamCommonPanelModeUseSetPanel_Deb()){
                            root.commonPanelExtButtonsSetVisible(false)
                        }
                        else {
                            if (root.isSmallMode()) {
                                idLog3.warn('onWidthChanged vis false before')
                                render_rct.anchors.bottomMargin = 0
                                section_909_rec_high.anchors.topMargin = 67 //65
                                idLog3.warn('onWidthChanged vis false after')
                            }
                            else {
                                idLog3.warn('onWidthChanged vis true before')
                                render_rct.anchors.bottomMargin = wndControlPanel.height// root.m_i_c_control_panel_height
                                section_909_rec_high.anchors.topMargin = 0
                                wndControlPanel.anchors.bottomMargin = 0
                                idLog3.warn('onWidthChanged vis true after')
                            }
                        }
                    }
                    //ch91029 otsech end
                    Rectangle {
                        id: section_909_rec
                        anchors.left: parent.left
                        height: parent.height
                        width: parent.width
                        color: "transparent"
                        anchors.verticalCenter: parent.verticalCenter

                        onWidthChanged: {
                            idLog3.warn('<calendar> onWidthChanged section_909_rec width = '
                                        + section_909_rec.width)
                        }

                        Rectangle {
                            id: section_909_rec_high
                            anchors.left: parent.left
                            anchors.top: parent.top
                            height: 0
                            width: 0 //parent.width
                            color: "cadetblue"
                            visible: true
                        }

                        Rectangle {
                            id: iv_arc_menu_new
                            width: contWidth
                            height: 32 * root.isize
                            anchors {
                                bottom: iv_arc_slider_new.top
                                bottomMargin: 8 * root.isize
                                horizontalCenter: parent.horizontalCenter
                            }
                            color: IVColors.get("Colors/Background new/BgFormOverVideo")
                            property real spacing: 4 * root.isize
                            property real margins: 6 * root.isize
                            property real contWidth: centerBlock.width
                            onContWidthChanged: {
                                if (hideList.count > 0) hideTimer.restart()
                            }
                            // список компонентов, которые будут скрываться при недостаточной ширине полосы
                            ListModel {
                                id: hideList
                                Component.onCompleted: {
                                    // элементы расположены в порядке очереди на скрытие
                                    append({"element": photocamLoader})
                                    append({"element": soundLoader})
                                    append({"element": imageCorrLoader})
                                    append({"element": calend_time})
                                    append({"element": iv_speed_slider})
                                    append({"element": revers_ivichb})
                                    append({"element": iv_butt_spb_bmark_skip})
                                    append({"element": iv_butt_spb_events_skip})
                                    append({"element": ev_filter_butt})
                                    append({"element": row_time_start})
                                    append({"element": row_time_end})
                                    append({"element": saveToBookmarksButton})
                                    append({"element": rectInterval_mashtab_new})
                                    append({"element": reset_interval})
                                    append({"element": hideSettings_new})
                                    append({"element": startExportButton})
                                    append({"element": play_ivichb})
                                    append({"element": iv_butt_spb_to_curs})
                                    append({"element": fullscreenButton})
                                    append({"element": switchToRealTimeButt})
                                    append({"element": select_interval_ButtonPane_new})
                                    hideTimer.restart()
                                }
                            }
                            Timer {
                                id: hideTimer
                                interval: 3
                                repeat: true
                                onTriggered: {
                                    var i;
                                    if (iv_arc_menu_new.width > section_909_rec.width){
                                        for (i = 0; i < hideList.count-1; i++){
                                            if (hideList.get(i)["element"].mainVisible) break
                                        }
                                        hideList.get(i)["element"].mainVisible = false
                                    }
                                    else {
                                        var el;
                                        for (i = hideList.count-1; i >= 0; i--){
                                            el = hideList.get(i)["element"]
                                            if (!el.mainVisible && el.parent.visible) break
                                        }
                                        if (iv_arc_menu_new.width <= section_909_rec.width + el.width * 1.25 && i >= 0){
                                            hideList.get(i)["element"].mainVisible = true
                                        }
                                        else stop()
                                    }
                                }
                            }

                            Row {
                                id: centerBlock
                                //x: (parent.width - leftBlock.width - rightBlock.width + width/2) / 2
                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    verticalCenter: parent.verticalCenter
                                    margins:iv_arc_menu_new.margins/2
                                }
                                spacing: iv_arc_menu_new.spacing

                                CalendarTimeComponents2 {
                                    id: calend_time
                                    property bool mainVisible: true
                                    visible: mainVisible
                                    _height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                    chosenDate: '05.11.2018'
                                    color: "transparent"
                                    size: "normal"
                                    btn_color: "white"
                                    key2: root.key2
                                    onDateChanged: {
                                        if (!root.b_input_time_outside_cahange) {
                                            updateTimeFromCalendar();
                                        }
                                    }
                                    onSetCurrTimeCommand: {
                                        calendar_date_change = true
                                        if (!root.b_input_time_outside_cahange) {
                                            updateTimeFromCalendar();
                                        }
                                    }
                                }

                                Row {
                                    id: mainCenterRow
                                    spacing: iv_arc_menu_new.spacing
                                    IVImageCheckbox {
                                        id: play_ivichb
                                        property bool mainVisible: true
                                        visible: mainVisible
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: height
                                        size: "normal"
                                        txt_tooltip: chkd ? Language.getTranslate("Pause", "Пауза") :
                                                            Language.getTranslate("Archive playback","Проигрывание архива")

                                        on_source: 'file:///' + applicationDirPath + '/images/white/pause.svg'
                                        off_source: 'file:///' + applicationDirPath + '/images/white/play.svg'
                                        onClicked: {
                                            idLog3.warn('<cmd> play_ivichb onClicked key2 ' + root.key2)
                                            idLog3.warn('<cmd> savedSetName ' + root.savedSetName)
                                            idLog3.warn('<cmd> savedSetName 2 ')
                                            //root.funcPlayCommand2202()
                                            root.playCmd(play_ivichb.chkd)
                                        }
                                        hoveredColor: root.hoveredColor
                                        pressedColor: root.pressedColor
                                        chkdColor: root.chkdColor
                                    }
                                    IVImageCheckbox {
                                        id: revers_ivichb
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: height
                                        size: "normal"
                                        txt_tooltip: !chkd ? Language.getTranslate("Play back","Проигрывать назад") :
                                                             Language.getTranslate("Play ahead","Проигрывать вперед")
                                        property bool mainVisible: true
                                        property bool visible2: true
                                        property bool visible3: true
                                        visible: visible2 && visible3 && iv_vcli_setting_arc_play_back.val
                                        on_source: 'file:///' + applicationDirPath + '/images/white/reward.svg'
                                        off_source: ''
                                        hoveredColor: root.hoveredColor
                                        pressedColor: root.pressedColor
                                        chkdColor: root.chkdColor
                                        onClicked: {
                                            if (play_ivichb.chkd)
                                            {
                                                // пока что так, чтобы обновлять "на ходу"
                                                root.playCmd(false)
                                                root.playCmd(true)
                                            }
                                        }
                                    }
                                    IVSpeedSlider {
                                        id: iv_speed_slider
                                        property bool mainVisible: true
                                        speed: 1
                                        size: "normal"
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        property bool visible2: true
                                        property bool visible3: true
                                        visible: visible2 && visible3 && mainVisible && iv_vcli_setting_arc_speed.val
                                        onPosChanged: {
                                            if (!root.m_b_no_actions) {
                                                idLog3.warn('<params> onPosChanged ' + ' visible '
                                                            + visible + ' visible2 ' + visible2
                                                            + ' visible3 ' + visible3)
                                                updateSpeedSlider()
                                            }
                                        }
                                        onStateChanged: {
                                            idLog3.warn('iv_speed_slider onStateChanged {')
                                            idLog3.warn('iv_speed_slider onStateChanged }')
                                        }
                                    }

                                    IVImageButton {
                                        id: ev_filter_butt
                                        property bool mainVisible: true
                                        visible: mainVisible && !root.common_panel
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: height
                                        color: "transparent"
                                        txt_tooltip: Language.getTranslate("Events filter", "Фильтр событий")
                                        enabled: iv_arc_slider_new.isSecondSet
                                        on_source: 'file:///' + applicationDirPath + '/images/white/filter.svg'
                                        hoveredColor: root.hoveredColor
                                        pressedColor: root.pressedColor
                                        onClicked: {
                                            filterWind.open()
                                        }
                                        Popup {
                                            id: filterWind
                                            width: 320 * root.isize
                                            height: 440 * root.isize
                                            x: -width/2
                                            y: -height
                                            visible: false
                                            padding:12 * isize//0
                                            background:Rectangle{
                                                color: "#313131"
                                            }
                                            onActiveFocusChanged: {
                                                if (!activeFocus) {
                                                    filterWind.close()
                                                }
                                            }
                                            contentItem: Rectangle{
                                                color: "transparent"
                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    spacing: 12 * isize
                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        Text {
                                                            text: "Фильтр событий"
                                                            font.pixelSize: 16 * isize
                                                            font.bold: true
                                                            color: "white"
                                                            Layout.alignment: Qt.AlignLeft
                                                        }
                                                        /*
                                                        IVImageButton {
                                                            width: 16 * isize
                                                            height: width
                                                            on_source: 'file:///' + applicationDirPath + "/images/white/" +
                                                                       (showAll ? "clear" : "done") + ".svg"
                                                            txt_tooltip: showAll ? Language.getTranslate("Hide all events","Скрывать все события") :
                                                                                   Language.getTranslate("Show all events","Отображать все события")
                                                            property bool showAll: true
                                                            hoveredColor: enabled ? root.hoveredColor : "transparent"
                                                            pressedColor: root.pressedColor
                                                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                                            onClicked:{
                                                                showAll = !showAll
                                                                myFilterModel.setAllActivated(showAll)
                                                            }
                                                        }
                                                        */
                                                    }
                                                    RowLayout{
                                                        height: 24 * isize
                                                        Layout.fillWidth: true
                                                        spacing: 8 * isize
                                                        Text {
                                                            text: "Поиск"
                                                            font.pixelSize: 12 * isize
                                                            color: "white"
                                                            Layout.alignment: Qt.AlignVCenter
                                                        }
                                                        Rectangle{
                                                            color: "#22ffffff"
                                                            height: 24 * isize
                                                            Layout.fillWidth: true
                                                            Layout.alignment: Qt.AlignVCenter
                                                            clip: true
                                                            TextArea {
                                                                id: filterInput
                                                                anchors.fill: parent
                                                                placeholderText: "Начните ввод названия или кода события"
                                                                color: "white"
                                                                font.pixelSize: 12 * isize
                                                                onTextChanged: {
                                                                    for (var i = 0; i < myFilterModel.count; i++){
                                                                        var value = (myFilterModel.get(i).value).toString()
                                                                        var name = myFilterModel.get(i).name.toLowerCase()
                                                                        if (!name.match(text.toLowerCase()) && !value.match(text.toLowerCase())){
                                                                            myFilterModel.setProperty(i, "visible", false)
                                                                        }
                                                                        else {
                                                                            myFilterModel.setProperty(i, "visible", true)
                                                                        }
                                                                    }
                                                                    eventList.model = myFilterModel
                                                                }
                                                            }
                                                        }
                                                        IVImageButton {
                                                            height: 16 * isize
                                                            width: height
                                                            visible: filterInput.text.length > 0
                                                            size: "normal"
                                                            txt_tooltip: Language.getTranslate("Clear","Очистить")
                                                            enabled: true
                                                            on_source: 'file:///' + applicationDirPath + '/images/white/erase.svg'
                                                            hoveredColor: enabled ? root.hoveredColor : "transparent"
                                                            pressedColor: root.pressedColor
                                                            Layout.alignment: Qt.AlignVCenter
                                                            onClicked: {
                                                                if (enabled) filterInput.clear()
                                                            }
                                                        }
                                                    }
                                                    ListView {
                                                        id: eventList
                                                        Layout.fillWidth: true
                                                        Layout.fillHeight: true
                                                        clip: true
                                                        boundsBehavior: Flickable.StopAtBounds
                                                        model: ListModel {
                                                            id: myFilterModel
                                                            function setAllActivated(val){
                                                                var filter = []
                                                                for (var i = 0; i < count; i++) {
                                                                    setProperty(i, "activated", val)
                                                                    if (!val) filter.push(get(i)["value"])
                                                                }
                                                                iv_arc_slider_new.updateFilter(filter)
                                                            }

                                                            Component.onCompleted: {
                                                                var types = idarchive_player.getAllEvTypes()
                                                                for (var i in types) {
                                                                    var name = idarchive_player.getEvtDescription(types[i])
                                                                    append({"value": types[i], "name": name.replace(/\\/g, ""), "activated": true, "visible": true})
                                                                }
                                                            }
                                                        }
                                                        delegate: MouseArea {
                                                            width: parent.width
                                                            height: visible ? 24 * isize : 0
                                                            hoverEnabled: true
                                                            visible: model.visible
                                                            Rectangle {
                                                                id: bckg
                                                                anchors.fill: parent
                                                                opacity: 0.2
                                                            }
                                                            Row {
                                                                spacing: 12 * isize
                                                                anchors {
                                                                    margins: 4 * isize
                                                                    left: parent.left
                                                                    verticalCenter: parent.verticalCenter
                                                                }
                                                                Image {
                                                                    id: filterIndicator
                                                                    width: 20 * isize
                                                                    height: width
                                                                    source: 'file:///' + applicationDirPath + '/images/white/' +
                                                                            (active ? "done" : "clear") + '.svg'
                                                                    property bool active: model.activated
                                                                }
                                                                Text {
                                                                    text: model.name
                                                                    color: "white"
                                                                    font.pixelSize: 12 * isize
                                                                }
                                                            }
                                                            ToolTip {
                                                                visible: parent.containsMouse
                                                                delay: 500
                                                                text: model.name
                                                            }

                                                            onEntered: bckg.opacity = 0.5
                                                            onExited: bckg.opacity = 0.2
                                                            onPressed: bckg.opacity = 0
                                                            onReleased: bckg.opacity = 0.2
                                                            onClicked: {
                                                                var newActive = !filterIndicator.active
                                                                myFilterModel.setProperty(model.index, "activated", newActive)
                                                                var filter = []
                                                                for (var i = 0; i < myFilterModel.count; i++){
                                                                    if (!myFilterModel.get(i)["activated"])
                                                                        filter.push(myFilterModel.get(i)["value"])
                                                                }
                                                                iv_arc_slider_new.updateFilter(filter)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }


                                    IVButtonSpinbox {
                                        id: iv_butt_spb_events_skip
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        //width: height*3
                                        checkable: true
                                        chkd: true
                                        size: root.isize <= 1 ? "small" : root.isize > 1
                                                                && root.isize < 2 ? "normal" : "big"
                                        btn_color: "white"
                                        left_tooltip: Language.getTranslate("Go to previous event","Перейти к предыдущему событию")
                                        center_tooltip: Language.getTranslate("Events","События")
                                        right_tooltip: Language.getTranslate("Go to next event","Перейти к следующему событию")
                                        left_src: 'arrow_left.svg'
                                        center_src: 'thunder.svg'
                                        right_src: 'arrow_right.svg'
                                        hoveredColor: root.hoveredColor
                                        pressedColor: root.pressedColor
                                        chkdColor: root.chkdColor
                                        property bool mainVisible: true
                                        property bool visible2: true
                                        property bool visible3: true
                                        property bool visible4: true
                                        visible: move_to_event.isAllowed && visible2 && visible3
                                                 && visible4  && mainVisible && iv_vcli_setting_arc_events_skip.val
                                        onVisibleChanged: {
                                            idLog3.warn(' iv_butt_spb_events_skip onVisibleChanged isAllowed ' + move_to_event.isAllowed + ' visible2 ' + visible2 + ' visible3 ' + visible3 + ' visible4 ' + visible4 + ' visible ' + visible)
                                        }
                                        onLeftClick: {
                                            if (!chkd) return
                                            var isFoundEvents = iv_arc_slider_new.toLeftEvents(2);
                                            if (isFoundEvents)
                                            {
                                                if (needToPause){
                                                    timer1111.stop()
                                                    univreaderex.setCmd005('pause')
                                                    timer1111.frTime = root.getFrameTime()
                                                }
                                                updateTimeFromSlider()
                                                iv_arc_slider_new.canAutoMove = true
                                                timer1111.start()
                                            }
                                        }
                                        onCenterClick: {
                                            iv_arc_slider_new.showEvents = chkd
                                        }
                                        onRightClick: {
                                            if (!chkd) return
                                            var isFoundEvents = iv_arc_slider_new.toRightEvents(2);
                                            if (isFoundEvents) {
                                                if (needToPause){
                                                    timer1111.stop()
                                                    univreaderex.setCmd005('pause')
                                                    timer1111.frTime = root.getFrameTime()
                                                }
                                                updateTimeFromSlider()
                                                iv_arc_slider_new.canAutoMove = true
                                                timer1111.start()
                                            }
                                        }
                                    }
                                    IVButtonSpinbox {
                                        id: iv_butt_spb_bmark_skip
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        //width: height*3
                                        checkable: true
                                        chkd: true
                                        size: root.isize <= 1 ? "small" : root.isize > 1 && root.isize < 2 ? "normal" : "big"
                                        btn_color: "white"
                                        left_tooltip: Language.getTranslate("Go to previous mark","Перейти к предыдущей метке")
                                        center_tooltip: Language.getTranslate("Marks","Метки")
                                        right_tooltip: Language.getTranslate("Go to next mark","Перейти к следующей метке")
                                        left_src: 'arrow_left.svg'
                                        center_src: 'bookmark.svg'
                                        right_src: 'arrow_right.svg'
                                        hoveredColor: root.hoveredColor
                                        pressedColor: root.pressedColor
                                        chkdColor: root.chkdColor
                                        property bool visible2: true
                                        property bool visible3: true
                                        property bool visible4: true
                                        property bool mainVisible: true
                                        visible: move_to_bmark.isAllowed
                                                 && visible2 && visible3
                                                 && visible4 && mainVisible && iv_vcli_setting_arc_bmark_skip.val
                                        onLeftClick: {
                                            if (!chkd) return
                                            var isFoundEvents = iv_arc_slider_new.toLeftEvents(6);
                                            if (isFoundEvents){
                                                updateTimeFromSlider()
                                                iv_arc_slider_new.canAutoMove = true
                                            }
                                            return;
                                        }
                                        onCenterClick: {
                                            iv_arc_slider_new.showBookmarks = chkd
                                        }
                                        onRightClick: {
                                            if (!chkd) return
                                            var isFoundEvents = iv_arc_slider_new.toRightEvents(6);
                                            if (isFoundEvents) {
                                                updateTimeFromSlider()
                                                iv_arc_slider_new.canAutoMove = true
                                            }
                                            return;
                                        }
                                    }
                                    IVImageButton {
                                        id: iv_butt_spb_to_curs_1
                                        property bool mainVisible: iv_butt_spb_to_curs.mainVisible
                                        property bool visible_1: playerLoader.item === null
                                        visible: mainVisible && visible_1
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: height
                                        size: "normal"
                                        txt_tooltip: Language.getTranslate("Return to frame time","Вернуться к времени кадра")
                                        enabled: true
                                        on_source: 'file:///' + applicationDirPath + '/images/white/redo.svg'
                                        hoveredColor: enabled ? root.hoveredColor : "transparent"
                                        pressedColor: root.pressedColor
                                        onClicked: {
                                            if (enabled) iv_arc_slider_new.canAutoMove = true
                                        }
                                    }
                                    IVButtonSpinbox {
                                        id: iv_butt_spb_to_curs
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        size: root.isize <= 1 ? "small" : root.isize > 1 && root.isize < 2 ? "normal" : "big"
                                        btn_color: "white"
                                        left_tooltip: Language.getTranslate("Go to previous frame","Перейти к предыдущему кадру")
                                        center_tooltip: Language.getTranslate("Return to frame time","Вернуться к времени кадра")
                                        right_tooltip: Language.getTranslate("Go to next frame","Перейти к следующему кадру")
                                        left_src: 'arrow_left.svg'
                                        center_src: 'redo.svg'
                                        right_src: 'arrow_right.svg'
                                        hoveredColor: root.hoveredColor
                                        pressedColor: root.pressedColor
                                        chkdColor: root.chkdColor
                                        property bool mainVisible: true
                                        property bool visible_1: playerLoader.item !== null
                                        visible: mainVisible && visible_1
                                        onLeftClick: {
                                            iv_arc_slider_new.canAutoMove = true
                                            var param = {}
                                            param.key2 = root.key2
                                            param.key3 = "12345";//univreaderex.key3_urx
                                            param.speed = iv_speed_slider.speed
                                            var dt = iv_arc_slider_new.currentDate
                                            dt = Qt.formatDateTime(dt, "yyyy-MM-dd hh:mm:ss,zzz")
                                            console.info("================ iv_arc_slider_new.currentDate = ", dt);
                                            param.from = dt
                                            param.track_name = render.trackFrame
                                            param.cmd = "backward"

                                            playerLoader.item.setTime(param)
                                            if (root.needToPause){
                                                root.playCmd(true)
                                            }
                                        }
                                        onCenterClick: {
                                            iv_arc_slider_new.canAutoMove = true
                                        }
                                        onRightClick: {
                                            iv_arc_slider_new.canAutoMove = true
                                            var param = {}
                                            param.key2 = root.key2
                                            param.key3 = "12345";//univreaderex.key3_urx
                                            param.speed = iv_speed_slider.speed
                                            var dt = iv_arc_slider_new.currentDate
                                            dt = Qt.formatDateTime(dt, "yyyy-MM-dd hh:mm:ss,zzz")
                                            console.info("================ iv_arc_slider_new.currentDate = ", dt);
                                            param.from = dt
                                            param.track_name = render.trackFrame
                                            param.cmd = "forward"

                                            playerLoader.item.setTime(param)
                                            if (root.needToPause){
                                                root.playCmd(true)
                                            }
                                        }
                                    }
                                    Loader {
                                        id: soundLoader
                                        property bool mainVisible: true
                                        visible: mainVisible && !root.common_panel
                                        asynchronous: true
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: height
                                        property var componentSound: null
                                        function create() {
                                            var qmlfile = "file:///" + applicationDirPath + '/qtplugins/iv/sound/PaneSound.qml'
                                            soundLoader.source = qmlfile
                                        }
                                        function refresh() {
                                            soundLoader.destroy()
                                            soundLoader.create()
                                        }
                                        function destroy() {
                                            if (soundLoader.status !== Loader.Null) soundLoader.source = ""
                                        }
                                        onStatusChanged: {
                                            if (soundLoader.status === Loader.Ready) {
                                                soundLoader.componentSound = soundLoader.item

                                                idLog3.warn('<sound> onCreated180904 2 ' + soundLoader.componentSound)
                                                var sound808_lv = soundLoader.componentSound

                                                root.m_pane_sound = soundLoader.componentSound
                                                idLog3.warn('<sound> 200811 50')
                                                root.m_i_is_sound_created = 1
                                                sound808_lv.owneraddress_arch = univreaderex.getAddr808()
                                                sound808_lv.funaddress_arch = univreaderex.getFunct808()
                                                univreaderex.storeSoundInfo(sound808_lv.owneraddress, sound808_lv.funaddress)
                                                soundLoader.componentSound.key2 = root.key2
                                                soundLoader.componentSound.key3 = root.key3
                                                soundLoader.componentSound.is_archive = 1

                                                root.safeSetProperty(root,'m_s_key3_audio_ap',
                                                                     Qt.binding(function () {
                                                                         return soundLoader.componentSound.key3_audio
                                                                     }))

                                                root.safeSetProperty(root,'m_s_track_source_univ_ap',
                                                                     Qt.binding(function () {
                                                                         return soundLoader.componentSound.track_source_univ
                                                                     }))
                                            }
                                        }
                                    }
                                    Loader {
                                        id: photocamLoader
                                        property bool mainVisible: true
                                        asynchronous: true
                                        visible: mainVisible && !root.common_panel
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: height
                                        property var componentPhotocam: null
                                        function create() {
                                            var qmlfile = "file:///" + applicationDirPath + '/qtplugins/iv/photocam/PanePhotoCam.qml'
                                            photocamLoader.source = qmlfile
                                        }
                                        function refresh() {
                                            photocamLoader.destroy()
                                            photocamLoader.create()
                                        }
                                        function destroy() {
                                            if (photocamLoader.status !== Loader.Null)
                                                photocamLoader.source = ""
                                        }
                                        onStatusChanged: {
                                            if (photocamLoader.status === Loader.Ready)
                                            {
                                                photocamLoader.componentPhotocam = photocamLoader.item

                                                root.safeSetProperty(photocamLoader.componentPhotocam,'key2',
                                                                     Qt.binding(function () {return root.key2}))
                                                root.safeSetProperty(
                                                            photocamLoader.componentPhotocam,'track',
                                                            Qt.binding(function () {
                                                                return root.trackFrameAfterSynchrRoot
                                                            }))

                                                root.safeSetProperty(photocamLoader.componentPhotocam,
                                                                     'parent2',Qt.binding(function () {return root}))
                                            }
                                        }
                                    }
                                    Rectangle {
                                        id: rectInterval_mashtab_new
                                        property bool mainVisible: true
                                        visible: mainVisible
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: height * 3
                                        color: "transparent"

                                        Button {
                                            id: interval_razmer_new
                                            width: parent.width
                                            height: parent.height
                                            Text {
                                                id: txt_razmer
                                                text: lm_intervals.get(root.m_i_curr_scale).name
                                                color: "white"
                                                font.pixelSize: 14 * root.isize
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.verticalCenter: parent.verticalCenter
                                                leftPadding: 2
                                            }

                                            background: Rectangle {
                                                implicitWidth: 70 * root.isize
                                                implicitHeight: 20 * root.isize
                                                opacity: enabled ? 1 : 0.3
                                                border.color: interval_razmer_new.down ? "#FA8072" : "steelblue"
                                                border.width: 1
                                                color: "transparent" //"darkslateblue"
                                            }

                                            onClicked: {
                                                if (!ppUp2_new.opened) {
                                                    ppUp2_new.open()
                                                }
                                            }
                                        }

                                        Popup {
                                            id: ppUp2_new
                                            focus: true
                                            closePolicy: Popup.CloseOnEscape
                                                         | Popup.CloseOnPressOutsideParent
                                                         | Popup.CloseOnPressOutside
                                            width: 100 * root.isize
                                            height: 18 * lm_intervals.count * root.isize
                                            x: 0 - ((ppUp2_new.width - rectInterval_mashtab_new.width) / 2)
                                            y: 0 - height - 3*root.isize
                                            padding: 0

                                            Component.onCompleted: {

                                            }

                                            background: Rectangle {
                                                width: ppUp2_new.width
                                                height: ppUp2_new.height
                                                color: "steelblue"
                                                opacity: 0.4
                                                clip: true
                                                radius: 3
                                                border.color: "white"
                                                border.width: 1
                                            }

                                            Rectangle {
                                                z: 2
                                                width: ppUp2_new.width
                                                height: ppUp2_new.height
                                                color: "transparent"

                                                ListView {
                                                    id: interv_lv_new
                                                    width: ppUp2_new.width - 2
                                                    height: ppUp2_new.height
                                                    highlightFollowsCurrentItem: true
                                                    currentIndex: root.m_i_curr_scale
                                                    //keyNavigationEnabled: true
                                                    interactive: false
                                                    focus: true

                                                    highlight: Rectangle {
                                                        color: "#343434"
                                                    }
                                                    model: lm_intervals
                                                    delegate: Component {
                                                        Rectangle {
                                                            id: delegateItem_new
                                                            width: parent.width
                                                            height: 18 * root.isize
                                                            clip: true
                                                            color: "transparent"
                                                            Text {
                                                                text: name
                                                                color: "white"
                                                                font.pixelSize: 14 * root.isize
                                                                leftPadding: 2
                                                            }

                                                            MouseArea {
                                                                anchors.fill: parent
                                                                onClicked: {
                                                                    idLog3.warn('<cmd> interv_lv_new MouseArea onClicked')
                                                                    delegateItem_new.ListView.view.currentIndex = model.index
                                                                }
                                                            }
                                                        }
                                                    }
                                                    onCurrentIndexChanged: {
                                                        if (currentIndex < 0) return
                                                        idLog3.warn('<cmd> interv_lv_new onCurrentIndexChanged = ' + interv_lv_new.currentIndex)
                                                        if (root.m_i_curr_scale != interv_lv_new.currentIndex){
                                                            root.m_i_curr_scale = interv_lv_new.currentIndex
                                                            univreaderex.putLog807('bef setScaleF811 2 m_i_curr_scale ' + root.m_i_curr_scale)
                                                            idLog3.warn('<cmd> onCurrentIndexChanged root.m_i_max_scale = ' + root.m_i_max_scale)
                                                            idLog3.warn('<cmd> onCurrentIndexChanged root.m_i_max_scale = ' + root.m_i_curr_scale)
                                                            txt_razmer.text = lm_intervals.get(root.m_i_curr_scale).name
                                                        }
                                                        //univreaderex.setScaleF811(root.m_i_max_scale + 1 - root.m_i_curr_scale)
                                                    }

                                                    onCurrentItemChanged: {
                                                        idLog3.warn('<cmd> interv_lv_new onCurrentItemChanged OOOOO =' + currentItem)
                                                    }
                                                    Component.onCompleted: {
                                                        currentIndex = root.m_i_curr_scale
                                                    }
                                                }
                                            }
                                        }
                                        ListModel {
                                            id: lm_intervals
                                            Component.onCompleted: {
                                                append({"name": Language.getTranslate("Year","Год")})
                                                append({"name": Language.getTranslate("Month","Месяц")})
                                                append({"name": Language.getTranslate("Week","Неделя")})
                                                append({"name": Language.getTranslate("Day","День")})
                                                append({"name": Language.getTranslate("Hour","Час")})
                                                append({"name": Language.getTranslate("30 minutes","30 минут")})
                                                append({"name": Language.getTranslate("10 minutes","10 минут")})
                                                append({"name": Language.getTranslate("1 minute", "1 минута")})
                                                txt_razmer.text = lm_intervals.get(root.m_i_curr_scale).name
                                            }
                                        }
                                    }
                                    Rectangle{
                                        id: select_interval_ButtonPane_new
                                        property bool mainVisible: true
                                        visible: mainVisible && !root.common_panel
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: height
                                        color: "transparent"
                                        IVImageCheckbox {
                                            id: select_interval_ButtonPane_new_chb
                                            anchors.fill: parent
                                            size: "normal"
                                            chkd: root.isIntervalMode
                                            txt_tooltip: chkd ? Language.getTranslate("Exit from interval selection","Выйти из режима выбора интервала") :
                                                                Language.getTranslate("Select interval","Выбрать интервал")
                                            property bool visible2: true
                                            property bool visible3: true
                                            visible: visible2 && visible3
                                            on_source: 'file:///' + applicationDirPath + '/images/white/flag_left.svg'
                                            off_source: ''

                                            hoveredColor: root.hoveredColor
                                            pressedColor: root.pressedColor
                                            chkdColor: root.chkdColor

                                            onClicked:{
                                                root.funcSwitchSelectIntervalMode()
                                            }
                                        }
                                    }
                                }
                                Row {
                                    id: intervalCenterRow
                                    spacing: iv_arc_menu_new.spacing
                                    visible: root.isIntervalMode
                                    property bool isCorrectTime: row_time_start.getTimestamp() < row_time_end.getTimestamp()
                                    property bool isExporting: false
                                    Rectangle {
                                        id: row_time_start
                                        property bool mainVisible: true
                                        visible: mainVisible
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: 150 * root.isize
                                        color: "transparent"
                                        CalendarTimeComponents2 {
                                            id: calendTime_from
                                            _height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                            chosenDate: '05.11.2018'
                                            color: "transparent"
                                            size: "normal"
                                            btn_color: "white"
                                            maxDate: calendTime_to.iv_date
                                            onDateChanged2: {
                                                if (!root.b_input_time_outside_cahange) {
                                                    parent.updateBounds()
                                                }
                                            }
                                            onDateChanged: {
                                                if (!root.b_input_time_outside_cahange){
                                                    parent.updateBounds()
                                                }
                                            }
                                            onSetCurrTimeCommand: {
                                                parent.updateBounds()
                                            }
                                        }
                                        Rectangle {
                                            color: "grey"
                                            visible: !iv_arc_slider_new.firstSet
                                            opacity: 0.4
                                            anchors.fill: parent
                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                propagateComposedEvents: false
                                            }
                                        }
                                        function getTimestamp(){
                                            var dateTime = calendTime_from.chosenDate + " " + calendTime_from.chosenTime
                                            var parts = dateTime.split(/[. :]/)
                                            var dateObject = new Date(parts[2], parts[1] - 1, parts[0],
                                                                      parts[3], parts[4], parts[5])
                                            return dateObject.getTime()
                                        }
                                        function updateBounds(){
                                            if (intervalCenterRow.isCorrectTime) {
                                                root.m_uu_i_ms_begin_interval = getTimestamp();
                                            }
                                        }
                                    }
                                    Rectangle {
                                        id: row_time_end
                                        property bool mainVisible: true
                                        visible: mainVisible
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: 150 * root.isize
                                        color: "transparent"
                                        CalendarTimeComponents2 {
                                            id: calendTime_to
                                            _height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                            chosenDate: '05.11.2018'
                                            color: "transparent"
                                            size: "normal"
                                            btn_color: "white"
                                            minDate: calendTime_from.iv_date
                                            onDateChanged2: {
                                                if (!root.b_input_time_outside_cahange) {
                                                    parent.updateBounds()
                                                }
                                            }
                                            onDateChanged: {
                                                if (!root.b_input_time_outside_cahange){
                                                    parent.updateBounds()
                                                }
                                            }
                                            onSetCurrTimeCommand: {
                                                parent.updateBounds()
                                            }
                                        }
                                        Rectangle {
                                            color: "grey"
                                            visible: !iv_arc_slider_new.secondSet
                                            opacity: 0.4
                                            anchors.fill: parent
                                            MouseArea{
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                propagateComposedEvents: false
                                            }
                                        }
                                        function getTimestamp(){
                                            var dateTime = calendTime_to.chosenDate + " " + calendTime_to.chosenTime
                                            var parts = dateTime.split(/[. :]/);
                                            var dateObject = new Date(parts[2], parts[1] - 1, parts[0], parts[3], parts[4], parts[5]);
                                            return dateObject.getTime();
                                        }
                                        function updateBounds(){
                                            if (intervalCenterRow.isCorrectTime) {
                                                root.m_uu_i_ms_end_interval = getTimestamp();
                                            }
                                        }
                                    }
                                    IVImageButton {
                                        id: hideSettings_new
                                        property bool mainVisible: true
                                        visible: mainVisible && can_export_acc.isAllowed
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: height
                                        color: "transparent"
                                        txt_tooltip: Language.getTranslate("Show export settings", "Показать настройки экспорта")
                                        enabled: iv_arc_slider_new.isSecondSet
                                        on_source: 'file:///' + applicationDirPath + '/images/white/more.svg'
                                        hoveredColor: root.hoveredColor
                                        pressedColor: root.pressedColor
                                        onClicked: {
                                            expwind.open()
                                            if (setExportLoader.status === Loader.Ready){
                                                setExportLoader.item.getValsFromMediaJs()
                                            }
                                        }
                                        Popup {
                                            id: expwind
                                            width: 320 * root.isize
                                            height: 440 * root.isize
                                            x: -width/2
                                            y: -height
                                            visible: false
                                            padding:0
                                            background:Rectangle{
                                                color: "transparent"
                                            }
                                            property var setExport: null
                                            Loader {
                                                id: setExportLoader
                                                anchors.fill: parent
                                                asynchronous: true
                                                active: false
                                                sourceComponent: SettingsPage {
                                                    anchors.fill: parent
                                                    comment: root.key2
                                                    mexport: MExport {
                                                        id: idmexport
                                                        Component.onCompleted: {
                                                            if (root.debug_mode === true) IVCompCounter.addComponent(idmexport)
                                                        }
                                                        Component.onDestruction: {
                                                            if (root.debug_mode === true) IVCompCounter.removeComponent(idmexport)
                                                        }
                                                    }
                                                    debug_mode: root.debug_mode
                                                    root_window: root.Window.window
                                                    property bool sameSettings: false
                                                    onSettingsChanged:{
                                                        if (sameSettings) sameSettings = false
                                                    }
                                                }
                                                onLoaded: {
                                                    expwind.setExport = item
                                                    setExportLoader.item.getValsFromMediaJs()
                                                }
                                            }
                                            onOpened:{
                                                //setExportLoader.active = true
                                            }

                                            onActiveFocusChanged: {
                                                if (!activeFocus) {
                                                    expwind.close()
                                                    //hideSettings_new.active = false
                                                }
                                            }
                                        }
                                        Component.onCompleted: {
                                            setExportLoader.active = true
                                            //setExportLoader.update()
                                        }
                                    }
                                    IVImageButton {
                                        id: reset_interval
                                        property bool mainVisible: true
                                        visible: mainVisible
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: height
                                        size: "normal"
                                        txt_tooltip: Language.getTranslate("Reset selection", "Сбросить выделение")
                                        enabled: iv_arc_slider_new.isSecondSet

                                        on_source: 'file:///' + applicationDirPath + '/images/white/refresh.svg'
                                        hoveredColor: enabled ? root.hoveredColor : "transparent"
                                        pressedColor: root.pressedColor
                                        onClicked: {
                                            if (enabled) root.funcReset_selection()
                                        }
                                        onEnabledChanged: {
                                            if (enabled) opacity = 1
                                            else opacity = 0.4
                                        }
                                    }
                                    IVImageButton {
                                        id: startExportButton
                                        property bool mainVisible: true
                                        visible: mainVisible && can_export_acc.isAllowed
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: height
                                        size: "normal"
                                        txt_tooltip: enabled ? Language.getTranslate("Export selected interval","Выгрузить выбранный интервал") :
                                                               Language.getTranslate("Exporting is not possible","Выгрузка невозможна")
                                                               + ". " + getReason()
                                        on_source: 'file:///' + applicationDirPath + '/images/white/upload.svg'
                                        enabled: reset_interval.enabled &&
                                                 intervalCenterRow.isCorrectTime &&
                                                 (!intervalCenterRow.isExporting ||
                                                 !setExportLoader.item.sameSettings)// сюда можно добавить еще зависимостей

                                        hoveredColor: enabled ? root.hoveredColor : root.attentionHovColor
                                        pressedColor: root.pressedColor
                                        onClicked: {
                                            if (enabled){
                                                intervalCenterRow.isExporting = true
                                                setExportLoader.item.sameSettings = true
                                                if (expwind.setExport !== null) root.funcUnload2()
                                                else root.funcUnload()
                                            }
                                        }
                                        onEnabledChanged: {
                                            if (enabled) opacity = 1
                                            else opacity = 0.4
                                        }
                                        // сюда можно добавить еще зависимостей
                                        function getReason(){
                                            if (!reset_interval.enabled){
                                                return Language.getTranslate("Interval is not selected", "Интервал не задан")
                                            }
                                            else if (!intervalCenterRow.isCorrectTime){
                                                return Language.getTranslate("The start time must be less than the end time of the interval.",
                                                                             "Время начала должно быть меньше времени конца интервала.")
                                            }
                                            else if (intervalCenterRow.isExporting){
                                                return Language.getTranslate("The selected interval is already being exported.",
                                                                             "Выбранный интервал уже выгружается.")
                                            }
                                        }
                                    }
                                    IVImageButton {
                                        id: saveToBookmarksButton
                                        property bool mainVisible: true
                                        visible: mainVisible
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                        width: height
                                        size: "normal"
                                        txt_tooltip: enabled ? Language.getTranslate("Add to bookmarks","Добавить в закладки") :
                                                               Language.getTranslate("Bookmarking is not possible","Невозможно добавить в закладки")
                                                               + ". " + getReason()

                                        on_source: 'file:///' + applicationDirPath + '/images/white/bookmark.svg'
                                        enabled: reset_interval.enabled && intervalCenterRow.isCorrectTime// сюда можно добавить еще зависимостей
                                        hoveredColor: enabled ? root.hoveredColor : root.attentionHovColor
                                        pressedColor: root.pressedColor
                                        onClicked: {
                                            if (enabled) root.funcSave_interval()
                                        }
                                        onEnabledChanged: {
                                            if (enabled) opacity = 1
                                            else opacity = 0.4
                                        }
                                        // сюда можно добавить еще зависимостей
                                        function getReason(){
                                            if (!reset_interval.enabled){
                                                return Language.getTranslate("Interval is not selected", "Интервал не задан")
                                            }
                                            else if (!intervalCenterRow.isCorrectTime){
                                                return Language.getTranslate("The start time must be less than the end time of the interval.",
                                                                             "Время начала должно быть меньше времени конца интервала.")
                                            }
                                        }
                                    }
                                }

                                Loader {
                                    id: imageCorrLoader
                                    property bool mainVisible: true
                                    visible: mainVisible && !root.common_panel
                                    height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                    asynchronous: true
                                    width: height
                                    property var componentImage_correct: null
                                    function create() {
                                        var qmlfile = "file:///" + applicationDirPath + '/qtplugins/iv/imagecorrector/ImageCorrector.qml'
                                        imageCorrLoader.source = qmlfile
                                    }
                                    function refresh() {
                                        imageCorrLoader.destroy()
                                        imageCorrLoader.create()
                                    }
                                    function destroy() {
                                        if (imageCorrLoader.status !== Loader.Null)
                                            imageCorrLoader.source = ""
                                    }
                                    onStatusChanged: {
                                        if (imageCorrLoader.status === Loader.Ready) {
                                            imageCorrLoader.componentImage_correct = imageCorrLoader.item
                                            imageCorrLoader.componentImage_correct.inProfileName = trackFrameAfterStabilizerRoot
                                            imageCorrLoader.componentImage_correct.outProfileName = root.trackFrameAfterStabilizerRoot + "_correct"
                                            root.trackFrameAfterImageCorrectorRoot = imageCorrLoader.componentImage_correct.outProfileName
                                            root.safeSetProperty(
                                                        imageCorrLoader.item,
                                                        'key2', Qt.binding(
                                                            function () {
                                                                return root.key2
                                                            }))
                                            imageCorrLoader.item._x_position = -imageCorrLoader.componentImage_correct.custom_width + 35 * root.isize
                                            imageCorrLoader.item.arch_y_position = -10*root.isize
                                            imageCorrLoader.item.custom_color = "steelblue"
                                            root.m_b_image_corrector_created = true
                                        }
                                    }
                                }
                                IVImageButton {
                                    id: switchToRealTimeButt
                                    property bool mainVisible: true
                                    visible: mainVisible
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                    width: height
                                    txt_tooltip: Language.getTranslate("return to realtime","возврат в реалтайм")
                                    on_source: 'file:///' + applicationDirPath + '/images/white/video_lib_exit.svg'
                                    size: "normal"
                                    hoveredColor: root.hoveredColor
                                    pressedColor: root.pressedColor
                                    onClicked: {
                                        if (!root.common_panel) {
                                            idLog3.trace('<210927> unload_to_avi_ivibt 2 clicked bef act ')
                                            if (viewer_command_obj !== null || viewer_command_obj !== undefined) {
                                                viewer_command_obj.command_to_viewer('viewers:switch')
                                            }
                                            idLog3.trace('<210927> unload_to_avi_ivibt 2 clicked aft act ')
                                        }
                                        else univreaderex.allArcPlayersSwitchToRealtime()
                                    }
                                }
                                IVImageButton {
                                    id: fullscreenButton
                                    property bool mainVisible: true
                                    visible: mainVisible && !root.common_panel
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: iv_arc_menu_new.height - iv_arc_menu_new.margins
                                    width: height
                                    txt_tooltip: (root.isFullscreen ? Language.getTranslate("Minimize", "Свернуть") : Language.getTranslate("Maximize", "Развернуть"))
                                    on_source: (root.isFullscreen ? 'file:///' + applicationDirPath + '/images/white/fullscreen_exit.svg' : 'file:///' + applicationDirPath + '/images/white/fullscreen.svg')
                                    size: "normal"
                                    hoveredColor: root.hoveredColor
                                    pressedColor: root.pressedColor
                                    onClicked: {
                                       if (viewer_command_obj !== null || viewer_command_obj !== undefined) {
                                            viewer_command_obj.command_to_viewer('viewers:fullscreen')
                                       }
                                    }
                                }

                            }
                            onWidthChanged: {
                                if (!hideTimer.running && hideList.count > 0) hideTimer.restart()
                            }
                        }

                        IVArc_slider_new {
                            id: iv_arc_slider_new
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            isize: root.isize
                            height: 48 * (root.isize)
                            archivePlayer: idarchive_player
                            key2: root.key2
                            previewMargin: iv_arc_menu_new.height
                            isMultiscreen: root.is_multiscreen
                            isCommonPanel: root.common_panel
                            Timer{
                                id: onTimer
                                interval: 25
                                repeat: true
                                property int loops: 0
                                onTriggered: {
                                    loops++
                                    if (root.getFrameTime() > 0 || loops >= 50) { stop() }
                                }
                                onRunningChanged: {
                                    if(!running){
                                        var fTime = root.getFrameTime()
                                        if (fTime > 10) iv_arc_slider_new.currentDate = new Date(fTime)
                                        else {
                                            var dateTime = calend_time.chosenDate + " " + calend_time.chosenTime
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
                            onUpdateCalendarDT:{
                                updateTimeFromSlider()
                            }
                            onCurrentDateChanged:{
                                idarchive_player.currentDate = iv_arc_slider_new.currentDate
                                //calend_time.chosenDate = Qt.formatDate(iv_arc_slider_new.currentDate, "dd.MM.yyyy")
                                //calend_time.chosenTime = Qt.formatTime(iv_arc_slider_new.currentDate, "hh:mm:ss.zzz")
                            }
                            onBoundsChanged:{ //EG
                                var bounds = iv_arc_slider_new.getSelectedInterval()
                                var left = bounds.left - bounds.left%1000
                                var right = bounds.right - bounds.right%1000
                                if (left !== root.m_uu_i_ms_begin_interval) root.m_uu_i_ms_begin_interval = left
                                if (right !== root.m_uu_i_ms_end_interval) root.m_uu_i_ms_end_interval = right
                            }
                        }
                    }
                }

                Timer {
                    id: timeUpdater
                    repeat: true
                    interval: 50
                    onTriggered: {
                        var currFrameTime = playerLoader.item.getCurrentFrameTimeUU64()/1000
                        if (currFrameTime !== 0)
                            iv_arc_slider_new.currentDate = new Date(currFrameTime)
                    }
                }
                IVUnivReaderex {
                    id: univreaderex
                    key2: ''
                    time_urx: '' //root.time
                    end: '' //ch91226 root.end
                    repeat: root.repeat
                    time_field_correct: ''
                    slider_value_correct: 100013
                    interv_time_left_correct: 0
                    app_path_correct: ''
                    on_frame_profile_urx: ''
                    key3_urx: ''
                    property int m_i_ness_swith_to_realtime_prev: 0
                    property real m_qr_prev_tick_coord_x_2: 0.0
                    property real m_qr_prev_tick_coord_y_2: 0.0
                    property int m_i_events_intervales_need_refresh_mem: 0
                    onNess_draw_fill_calendarChanged: onNessDrawFIllCalendarChangedReal()
                    Component.onCompleted: {
                        IVCompCounter.addComponent(univreaderex)
                    }
                    Component.onDestruction: {
                        IVCompCounter.removeComponent(univreaderex)
                    }
                    function onNessDrawFIllCalendarChangedReal() {
                        var b_is_ness_cont_work_lv = true
                        var i_months_lv = 0
                        var i_day_lv = 0
                        var rl_percent_lv = 0
                        critSect903(true)
                        if (b_is_ness_cont_work_lv) {
                            while (true) {
                                i_months_lv = getNextMonth()
                                i_day_lv = getNextDay()
                                rl_percent_lv = getNextPersent()
                                idLog.trace('onNessDrawFIllCalendarChangedReal day ' + i_day_lv
                                            + ' mon ' + i_months_lv + ' pers ' + rl_percent_lv)
                                if (-1 != i_months_lv && -1 != i_day_lv) {
                                    calend_time.drawArch(i_months_lv, i_day_lv,
                                                         rl_percent_lv)
                                }
                                if (!incremIndex())
                                    break
                            }
                        }
                        critSect903(false)
                    }
                    onCommon_panel_visibleChanged: {
                        root.commonPanelSetVisible(univreaderex.common_panel_visible)
                        iv_arc_slider_new.refreshModel()
                    }

                    onScale_time_rightChanged: {
                        //console.info("onScale_time_rightChanged");
                        onScaleTimeRightChangedReal()
                    }
                    function onScaleTimeRightChangedReal() {
                        var s_increase_scale_text_lv = univreaderex.getNextScaleTextCausing1(
                                    true)
                        var s_decrease_scale_text_lv = univreaderex.getNextScaleTextCausing1(
                                    false)

                        idLog2.warn('onScaleTimeRightChangedReal '
                                    + 's_increase_scale_text_lv ' + s_increase_scale_text_lv
                                    + 's_decrease_scale_text_lv ' + s_decrease_scale_text_lv)
                    }
                    onTime_field_correctChanged: onTimeFieldCorrectChangedReal()
                    function onTimeFieldCorrectChangedReal() {
                        idLog3.warn('onTimeFieldCorrectChangedReal begin root.time : ' + root.time)
                        root.b_input_time_outside_cahange = true
                        root.time811 = time_field_correct
                        calend_time.chosenDate = univreaderex.timeToComponentDate(
                                    time_field_correct)
                        var s_lv = calend_time.chosenDate + ' ' + univreaderex.timeToComponentTime(
                                    time_field_correct)
                        //ch00203 univreaderex.putLog807
                        idLog3.warn('onTimeFieldCorrectChangedReal s_lv ' + s_lv
                                    + ' time_field_correct ' + time_field_correct
                                    + ' timeToComponentDate ' + univreaderex.timeToComponentDate(
                                        time_field_correct))
                        root.b_input_time_outside_cahange = true

                        idLog3.warn('onTimeFieldCorrectChangedReal bef calend_time.timeString =; ')
                        calend_time.timeString = time_field_correct
                        root.b_input_time_outside_cahange = false
                        idLog3.warn('onTimeFieldCorrectChangedReal end ')
                    }

                    onSlider_value_correctChanged: onSliderValueCorrectChangedReal()
                    function onSliderValueCorrectChangedReal() {
                        idLog2.warn('onSliderValueCorrectChangedReal slider_value_correct ' + slider_value_correct)
                        if (play_ivichb.chkd) {
                            if (!iv_arc_slider_new.sliderIsDragged)
                            iv_arc_slider_new.currentDate = new Date(root.getFrameTime())
                        }
                    }
                    onEventsIntervalesNeedRefresh006: {
                        //univreaderex.onEventsIntervalesNeedRefreshChangedReal
                        // ( i_events_intervales_need_refresh_av, i_is_global_refresh_av );
                    }

                    onClearPrimitives: {
                        idLog3.warn('<prim> 200714 100 ')
                        if (root.m_primit !== null && 'clearData' in root.m_primit)
                        {
                            idLog3.warn('<prim> 200714 101 ')
                            root.m_primit.clearData()
                            idLog3.warn('<prim> 200714 102 ')
                        }
                    }
                    onInterv_time_left_correctChanged: onIntervTimeLeftCorrectChangedReal()
                    function onIntervTimeLeftCorrectChangedReal() {
                        var b_is_ness_cont_work_lv = true
                        var i_coord_res_lv = 1
                        var x_last_begin_point_lv = 1
                        var x_last_end_point_lv = 1
                        var s_beg_point_lv = ''
                        if (b_is_ness_cont_work_lv) {
                            i_coord_res_lv = univreaderex.sliderCoordByTime(0)
                            if (-1 == i_coord_res_lv) {
                                b_is_ness_cont_work_lv = false
                                x_last_begin_point_lv = 1
                                x_last_end_point_lv = 1
                            }
                            else if (-2 == i_coord_res_lv) x_last_begin_point_lv = 1
                            else x_last_begin_point_lv = i_coord_res_lv

                            idLog2.warn('onScaleTimeLeftChangedReal beg '
                                        + 'coord_res ' + i_coord_res_lv
                                        + 'last_begin_point ' + x_last_begin_point_lv)
                        }
                        if (b_is_ness_cont_work_lv) {
                            //vichilim prav coordinatu e
                            i_coord_res_lv = univreaderex.sliderCoordByTime(1)
                            if (-1 == i_coord_res_lv) {
                                b_is_ness_cont_work_lv = false
                                x_last_begin_point_lv = 1
                                x_last_end_point_lv = 1
                            } else if (-2 == i_coord_res_lv) {
                                x_last_end_point_lv = 100000
                            } else {
                                x_last_end_point_lv = i_coord_res_lv // / 1000;
                            }
                            idLog2.warn('onScaleTimeLeftChangedReal end ' + 'coord_res '
                                        + i_coord_res_lv + 'last_end_point ' + x_last_end_point_lv)
                        }
                        root.b_range_slider_802_value_beg_outside_change = true
                        root.b_range_slider_802_value_end_outside_change = true
                        root.b_range_slider_802_value_beg_outside_change_fierst = true
                        root.b_range_slider_802_value_end_outside_change_fierst = true
                        root.b_range_slider_802_value_beg_outside_change = false
                        root.b_range_slider_802_value_end_outside_change = false
                    }
                    onApp_path_correctChanged: onApp_path_correctChangedReal()
                    function onApp_path_correctChangedReal() {
                        idLog2.warn('---onApp_path_correctChangedReal ' + app_path_correct)
                    }

                    onOn_frame_profile_urxChanged: onOn_frame_profile_urxChangedReal()
                    function onOn_frame_profile_urxChangedReal() {
                        root.on_frame_profile = on_frame_profile_urx
                    }
                    onKey3_urxChanged: onKey3_urxChangedReal()
                    function onKey3_urxChangedReal() {
                        root.key3 = key3_urx
                        idLog2.warn('onKey3_urxChangedReal key3 ' + key3_urx)
                    }
                    onSendToQml910: {
                        //scale_interv_len_lb.text = newValue;
                    }

                    onSliderNewInit: {
                        if (root.first_init == true) {
                            root.first_init = false
                            //root.refresh123()
                        }
                        if (calendar_date_change == true || calendar_time_change == true){
                            root.calendar_date_change = false
                            root.calendar_time_change = false
                            //root.refresh123()
                        }
                    }

                    onSetMenuText: {
                        //var menu_item912 = getMenuObjectByIndex( i_menu_index_av );
                        //menu_item912.text = qs_menu_text_av;
                        //menu_item912.visible2 = true;
                        //menu_item912.height = 30;
                        switch (i_menu_index_av){
                            case 0: menuLoaderContext_menu2.menu_source0_text = qs_menu_text_av; break
                            case 1: menuLoaderContext_menu2.menu_source1_text = qs_menu_text_av; break
                            case 2: menuLoaderContext_menu2.menu_source2_text = qs_menu_text_av; break
                            case 3: menuLoaderContext_menu2.menu_source3_text = qs_menu_text_av; break
                            case 4: menuLoaderContext_menu2.menu_source4_text = qs_menu_text_av; break
                            case 5: menuLoaderContext_menu2.menu_source5_text = qs_menu_text_av; break
                            case 6: menuLoaderContext_menu2.menu_source6_text = qs_menu_text_av; break

                        }
                        idLog2.warn('<sel_source> onSetMenuText i_menu_index_av ' + i_menu_index_av)
                    }
                    onNessAudioEnable: {
                        idLog3.warn('<sound> 200729 3 ')
                        root.m_i_ness_activate_sound = 1
                        idLog3.warn('<sound> 200729 2 ')
                    }
                    onSttVideoPresent: {
                        idLog3.warn('<sound> 210714 ')
                        root.m_s_is_video_present = "1"
                    }
                    onSetControlElements: {
                        root.m_b_no_actions = true

                        if ('pause' === qs_cmd_av) play_ivichb.chkd = false
                        else if ('play' === qs_cmd_av) play_ivichb.chkd = true

                        switch (i_speed_av){
                            case 125: iv_speed_slider.speed = 0.125; break
                            case 250: iv_speed_slider.speed = 0.25; break
                            case 500: iv_speed_slider.speed = 0.5; break
                            case 1000: iv_speed_slider.speed = 1; break
                            case 2000: iv_speed_slider.speed = 2; break
                            case 4000: iv_speed_slider.speed = 4; break
                            case 8000: iv_speed_slider.speed = 8; break
                            case 16000: iv_speed_slider.speed = 16; break
                            case 32000: iv_speed_slider.speed = 32; break
                            case 64000: iv_speed_slider.speed = 64; break
                            case 128000: iv_speed_slider.speed = 128; break
                        }
                        root.m_b_no_actions = false
                    }
                    onDrawPreviewQML: {
                        console.info("qs_paramPreview_av = ", qs_provider_param_lv);
                        imageSlider.setSource( "image://iv7univ_readerex/" + qs_provider_param_lv );
                    }
                    onSetSelectedZnaIpOutput: {
                        idLog3.warn("<select_source> onSetSelectedZnaIpOutput qs_selected_zna_ip_output_av "
                                    + qs_selected_zna_ip_output_av)
                        m_s_selected_zna_ip_output = qs_selected_zna_ip_output_av
                    }
                    /*
                    onSetWSResponceParams: {
                      root.arc_vers = 1;
                      root.from_realtime = ( 0 !== i_from_realtime_av );
                      root.common_panel = ( 0 !== i_common_panel_av );
                      if ( i_key2_present_av )
                        root.key2 = qs_key2_av;
                      if ( i_time_present_av )
                        root.time = qs_time_av;
                      if ( i_end_present_av )
                        root.end = qs_end_av;
                      if ( i_cmd_present_av )
                        root.cmd = qs_cmd_av;
                      root.startPlugin();
                    }
                    */
                    //e
                    //onSetSetName: {
                    //  root.savedSetName = qs_set_name_av;
                    //  idLog3.warn( 'onSetSetName root.key2 ' +
                    //               root.key2 +
                    //               ' root.savedSetName ' +
                    //               root.savedSetName
                    //               );
                    //ch220330 root.key2 = "common_panel";
                    //}
                    //ch220403
                    //onSetNessSwitchToRealtimeCommonPanel: {
                    //  root.m_i_is_ness_switch_to_realtime_common_panel++;
                    //  idLog3.warn( 'onSetNessSwitchToRealtimeCommonPanel' );
                    //}
                    //e

                }
                //rex
            } //rootrect
        } //r910rect
    } //mousearea

    function funcCloseSet() {
        shortcutLastSequence1.value = "Ctrl+W"
        shortcutLastSequence1.value = "@$##$&*()#"
    }

    function funcSwitchToFullScreen() {
        if (viewer_command_obj !== null || viewer_command_obj !== undefined) {
            viewer_command_obj.command_to_viewer('viewers:fullscreen')
        }
    }

    function funcSwitchSelectIntervalMode(){ //EG
        isIntervalMode = !isIntervalMode
        iv_arc_slider_new.setInterval=isIntervalMode
    }

    function compare_events(a, b) {
        if (a.event_time_begin > b.event_time_begin)
            return 1 // если первое значение больше второго
        if (a.event_time_begin === b.event_time_begin)
            return 0 // если равны
        if (a.event_time_begin < b.event_time_begin)
            return -1 // если первое значение меньше второго
    }
    function playCmd(toPlay) {
        var param = {}
        if (!root.m_b_no_actions)
        {
            var stringDate = iv_arc_slider_new.currentDate
            var stringTime = iv_arc_slider_new.currentDate
            calend_time.chosenDate = Qt.formatDate(stringDate, "dd.MM.yyyy")
            calend_time.timeString = stringTime.toString()
            calend_time.updateDateTimeText()
            root.time811 = univreaderex.timeFromComponents(Qt.formatDate(iv_arc_slider_new.currentDate, "dd.MM.yyyy"),
                                                           Qt.formatTime(iv_arc_slider_new.currentDate, "hh:mm:ss.zzz")
                                                           )
            univreaderex.time_urx = root.time811


            if (!iv_vcli_setting_arc.val && playerLoader.item !== null) {
                root.key3 = univreaderex.key3_urx + "_qplayer"
                if (toPlay){
                    param.key2 = root.key2
                    param.key3 = "12345";//root.key3
                    param.speed = iv_speed_slider.speed
                    param.from = Qt.formatDateTime(iv_arc_slider_new.currentDate, "yyyy-MM-dd hh:mm:ss,zzz")
                    if (root.m_b_image_corrector_created) render.trackFrame = root.trackFrameAfterImageCorrectorRoot + "_qplayer"
                    else render.trackFrame = root.trackFrameAfterStabilizerRoot + "_qplayer"
                    param.track_name = render.trackFrame

                    if (revers_ivichb.chkd) param.cmd = "backward"
                    else param.cmd = "forward"

                    timeUpdater.start()
                    playerLoader.item.playVideo(param)
                }
                else {
                    playerLoader.item.pauseVideo(param)
                    timeUpdater.stop()
                    if (root.m_b_image_corrector_created) render.trackFrame = root.trackFrameAfterImageCorrectorRoot+ "_qplayer"
                    else render.trackFrame = root.trackFrameAfterStabilizerRoot+ "_qplayer"
                }
            }
            else {
                root.key3 = univreaderex.key3_urx
                if (root.m_b_image_corrector_created) render.trackFrame = root.trackFrameAfterImageCorrectorRoot
                else render.trackFrame = root.trackFrameAfterStabilizerRoot
                funcPlayCommand2202(toPlay)
            }
        }
    }

    function funcPlayCommand2202(toPlay) {
        idLog3.warn('220228_700 ')
        idLog3.warn('220228_600 ')
        if (!root.m_b_no_actions) {
            idLog3.warn('220228_601 ')
            if (toPlay){
                idLog3.warn('220228_602 ')
                if (revers_ivichb.chkd){
                    idLog3.warn('220228_603 ')
                    univreaderex.setCmd005('play_backward')
                }
                else {
                    idLog3.warn('220228_6   ')
                    univreaderex.setCmd005('play')
                }
            }
            else {
                idLog3.warn('220228_601 ')
                univreaderex.setCmd005('pause')
            }
        }
        idLog3.warn('220228_605 ')
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

    function componentCompleted() {

        //console.info("componentCompleted() {");
        if (root.key2 === '' || root.key2 === null || root.key2 === undefined) {
            return
        }

        if (root.is_export_media === 1) {
            if (root.key2 === '' || root.key2 === null
                    || root.key2 === undefined) {
                return
            }

            if (root.time === '' || root.time === null
                    || root.time === undefined) {
                return
            }

            if (root.end === '' || root.end === null
                    || root.end === undefined) {
                return
            }
        }

        //ch00804
        if ('nessUpdateCalendar' in calend_time) {
            calend_time.nessUpdateCalendar.connect(nessUpdateCalendarAP)
        }
        if ('nessUpdateCalendarDecr' in calend_time) {
            calend_time.nessUpdateCalendarDecr.connect(nessUpdateCalendarDecrAP)
        }
        //e
        //ch220418
        if ('setCurrTimeCommand' in calend_time) {
            idLog3.warn('<calendar> componentCompleted setCurrTimeCommand connect ')
            calend_time.setCurrTimeCommand.connect(setCurrTimeCommandAP)
        }
        //e
        m_i_started = 1

        if ('play' === root.cmd)
            play_ivichb.chkd = true

        var i_id_group_lv = 0
        if (false !== root.fromRealtime)
            i_id_group_lv = 1

        univreaderex.setIdCamerasGroup(i_id_group_lv)

        var s_time_iv_lv = ''
        s_time_iv_lv = univreaderex.convertTimeFromIntegraciyaIfNess(root.time)

        idLog3.warn('<common_pan> on completed 90115 ' + ' key2 ' + root.key2 + ' key3 '
                    + root.key3 + ' parent ' + parent + ' time '
                    + root.time + ' s_time_iv_lv ' + s_time_iv_lv + ' settings '
                    + iv_vcli_setting_arc.value + ' root.common_panel ' + root.common_panel + ' fromRealtime '
                    + root.fromRealtime + ' i_id_group_lv ' + i_id_group_lv + ' root.x '
                    + root.x + ' root.Window.window.x ' + root.Window.window.x + ' root.y '
                    + root.y + ' root.Window.window.y ' + root.Window.window.y)
        var b_is_ness_cont_work_lv = true
        var controls = null

        //deb ch91029
        iv_speed_slider.visible3 = ('' === iv_vcli_setting_arc_speed.value
                                    || 'true' === iv_vcli_setting_arc_speed.value) ? 1 : 0

        revers_ivichb.visible3 = ('true' === iv_vcli_setting_arc_play_back.value
                                  || '' === iv_vcli_setting_arc_play_back.value) ? 1 : 0
        iv_butt_spb_events_skip.visible4
                = ('true' === iv_vcli_setting_arc_events_skip.value
                   || '' === iv_vcli_setting_arc_events_skip.value) ? 1 : 0
        iv_butt_spb_bmark_skip.visible4
                = ('true' === iv_vcli_setting_arc_bmark_skip.value
                   || '' === iv_vcli_setting_arc_bmark_skip.value) ? 1 : 0

        setMode904()
        var i_is_this_common_panel_lv = 0
        if (false === root.common_panel)
            i_is_this_common_panel_lv = 0
        else
            i_is_this_common_panel_lv = 1

        if (b_is_ness_cont_work_lv) {
            idLog3.warn('<common_pan> onCompleted bef change root.height '
                        + root.height + ' rootRect.height ' + rootRect.height
                        + ' iv_vcli_setting_arc.value ' + iv_vcli_setting_arc.value)
            idLog3.warn('<common_pan> onCompleted 90415 9 getCamCommonPanelMode() '
                        + root.getCamCommonPanelMode())
            idLog3.warn('<common_pan> onCompleted 90415 9 aft getCamCommonPanelMode() '
                        + root.getCamCommonPanelMode())
            univreaderex.setIsThisCommonPanel(i_is_this_common_panel_lv)
            if (root.common_panel) {
                idLog3.warn('<common_pan> is thiis common panel true key2 ' + key2)

                //ch90919
                //prot rootRect_ButtonPane.mousearea_CommonPanMode.enabled = false;
                mousearea_CommonPanMode.enabled = false
                //e
                //это - общ панель - при этом панель кнопок делаем невидимой
                commonPanelSetVisible(//ch90918 false
                                      0)
                render_rct.visible = false
                //ch90730 root
                root.commonPanelExtButtonsSetVisible(false)
                //ch90918
                root.commonPanelElementsSetVisible(false)
                //e
            } else {
                idLog3.warn('<common_pan> not root.common_panel')
                if (0 !== root.getCamCommonPanelModeUseSetPanel_Deb()) {

                    //ch91111
                    //wndControlPanel_phone.height = 0;
                    //wndControlPanel_phone.visible = false;
                    //e ch91111
                    idLog3.warn('<common_pan> onCompleted 0 !== root.getCamCommonPanelMode() ')
                    wndControlPanel.height = 0
                    //ch91024
                    render_rct.anchors.bottomMargin = 0
                    //e
                    wndControlPanel.visible = false
                    //iv_arc_slider_control
                    //  .visible = false;
                } else {

                    //                  idLog3.warn('<common_pan> onCompleted 0 === root.getCamCommonPanelMode() ' );
                    //                  mousearea_CommonPanMode.height = 0;
                    //                  mousearea_CommonPanMode.width = 0;
                    //                  ivButtonPane
                    //                    .height = 0;
                    //                  ivButtonPane
                    //                    .visible = false;
                }
            }
            idLog3.warn('<but_pan> onCompleted after change k2 ' + root.key2
                        + ' root.height ' + root.height + ' rootRect.height '
                        + rootRect.height + ' mousearea_CommonPanMode.enabled '
                        + mousearea_CommonPanMode.enabled)
        }

        if (b_is_ness_cont_work_lv) {
            if (root.m_b_is_caused_by_unload) {
                root.complete5()
            }
        }
        idLog3.warn('90704 bef complete901 key2 ' + root.key2 + ' savedSetName '
                    + root.savedSetName)
        univreaderex.complete901(s_time_iv_lv, root.savedSetName)

        if (0 === root.getCamCommonPanelMode()) {
            if (false === root.common_panel) {
                //ch90917 ivButtonPane.complete3();
            }
        }
        idLog3.warn('<prim 3> common_panel ' + root.common_panel)
        if (false === root.common_panel) {
            idLog3.warn('<prim 100>')
            complete4()
            if (0 !== root.getCamCommonPanelModeUseSetPanel_Deb())
                root.m_i_c_control_panel_height = 38
        }
        root.complete2()
        idLog3.warn('<prim 4>')

        if (false === root.common_panel || 0 !== root.getCamCommonPanelMode()) {
            idLog3.warn('<common_pan> 00425 1')
            timer809.running = true
            timer904.running = true
        }

        mousearea_CommonPanMode.enabled = true
        //ch00121
        if (true === root.common_panel)
            ivButtonTopPanel.visible = false

        //e
        m_component_completed_2303 = true
        root.complete2303()
        //e
        if (is_export_media === 1) {
            root.m_i_is_comleted = 1
        }
        idLog3.warn('<compl end >' + ' key2 ' + root.key2 + ' key3 ' + root.key3)
        //console.info("componentCompleted() }");
    }

    function startPlugin() {
        idLog3.warn('<common_pan> start beg key2 ' + root.key2 + ' arc_vers ' + root.arc_vers)
        if (root.arc_vers > 0) {
            idLog3.warn('<common_pan> start 2 key2 ' + root.key2)
            if (0 !== m_i_is_comleted && 0 === m_i_started)
                root.componentCompleted()
        }
        m_i_start_called = 1
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

        idLog3.warn('<root> isSmallMode wndControlPanel.width '
                    + wndControlPanel.width + ' root.smallSizePanel '
                    + root.smallSizePanel + ' b_lv ' + b_lv)
        return b_lv
    }
    function callContextMenu907(rl_mouse_x_av, rl_mouse_y_av) {
        onClicked: {
            menuLoaderContext_menu2.componentMenu._clearMenu()
            menuLoaderContext_menu2.componentMenu.createMenuItem(
                        root.funcSwitchToFullScreen,
                        root.isFullscreen ? Language.getTranslate("Switch to multiscreen", "Переключиться в мультиэкран") :
                                            Language.getTranslate("Switch to full screen", "Переключиться в полный экран"),
                                            true,
                                            "fullscreen.svg")
            menuLoaderContext_menu2.componentMenu.createMenuItem(
                        root.functReturnToRealtime,
                        Language.getTranslate("Return to realtime","Возврат в реалтайм"),
                        true,
                        "video_lib_exit.svg")
//            menuLoaderContext_menu2.componentMenu.createMenuItem(
//                        root.funcCall_Unload_window,
//                        Language.getTranslate("Open export menu","Открыть меню экспорта"),
//                        true,
//                        "archSave.svg")
            if (root.fast_edits === true) {
                menuLoaderContext_menu2.componentMenu.createMenuItem(
                            root.funcCloseCamera,
                            Language.getTranslate("Close camera","Закрыть камеру"),
                            true,
                            'clear.svg')
                if (interfaceButtonsCloseSets.value === "true") {
                    menuLoaderContext_menu2.componentMenu.createMenuItem(
                                root.funcCloseSet,
                                Language.getTranslate("Close tab","Закрыть вкладку"),
                                true,
                                'clear.svg')
                }
            }
            else {
                if (isSetEdit.value === "true" ){
                    menuLoaderContext_menu2.componentMenu.createMenuItem(
                                root.funcCloseCamera,
                                Language.getTranslate("Close camera","Закрыть камеру"),
                                true,
                                'clear.svg')
                }
                else {
                    if (integration_flag.value === "SDK"){
                        if(!root.viewer_command_obj.myGlobalComponent.ivSetsArea){
                            menuLoaderContext_menu2.componentMenu.createMenuItem(
                                        root.funcCloseCamera,
                                        Language.getTranslate("Close camera", "Закрыть камеру"),
                                        true,
                                        'clear.svg')
                        }
                        else {
                            if (interfaceButtonsCloseSets.value === "true") {
                                menuLoaderContext_menu2.componentMenu.createMenuItem(
                                            root.funcCloseSet,
                                            Language.getTranslate("Close tab","Закрыть вкладку"),
                                            true,
                                            'clear.svg')
                            }
                        }
                    }
                    else {
                        if (interfaceButtonsCloseSets.value === "true"){
                            menuLoaderContext_menu2.componentMenu.createMenuItem(
                                        root.funcCloseSet,
                                        Language.getTranslate("Close tab","Закрыть вкладку"),
                                        true,
                                        'clear.svg')
                        }
                    }
                }
            }

            if (menuLoaderContext_menu2.menu_source0_text !== '') {
                menuLoaderContext_menu2.componentMenu.createMenuItem(
                            root.funcSwitchSource0,
                            menuLoaderContext_menu2.menu_source0_text, true, "")
            }
            if (menuLoaderContext_menu2.menu_source1_text !== '') {
                menuLoaderContext_menu2.componentMenu.createMenuItem(
                            root.funcSwitchSource1,
                            menuLoaderContext_menu2.menu_source1_text, true, "")
            }
            if (menuLoaderContext_menu2.menu_source2_text !== '') {
                menuLoaderContext_menu2.componentMenu.createMenuItem(
                            root.funcSwitchSource2,
                            menuLoaderContext_menu2.menu_source2_text, true, "")
            }
            if (menuLoaderContext_menu2.menu_source3_text !== '') {
                menuLoaderContext_menu2.componentMenu.createMenuItem(
                            root.funcSwitchSource3,
                            menuLoaderContext_menu2.menu_source3_text, true, "")
            }
            if (menuLoaderContext_menu2.menu_source4_text !== '') {
                menuLoaderContext_menu2.componentMenu.createMenuItem(
                            root.funcSwitchSource4,
                            menuLoaderContext_menu2.menu_source4_text, true, "")
            }
            if (menuLoaderContext_menu2.menu_source5_text !== '') {
                menuLoaderContext_menu2.componentMenu.createMenuItem(
                            root.funcSwitchSource5,
                            menuLoaderContext_menu2.menu_source5_text, true, "")
            }
            if (menuLoaderContext_menu2.menu_source6_text !== '') {
                menuLoaderContext_menu2.componentMenu.createMenuItem(
                            root.funcSwitchSource6,
                            menuLoaderContext_menu2.menu_source6_text, true, "")
            }

            positioningContextMenu()

            var menuPoint = mapToItem(Window.window.contentItem,
                                      menuLoaderContext_menu2.componentMenu.x,
                                      menuLoaderContext_menu2.componentMenu.y)
            if (menuPoint.y + menuLoaderContext_menu2.componentMenu.height
                    >= Window.window.height) {
                menuLoaderContext_menu2.componentMenu.y
                        -= (menuPoint.y + menuLoaderContext_menu2.componentMenu.height
                            - Window.window.height)
            }
            menuLoaderContext_menu2.componentMenu.side = 'right'
            if (menuPoint.x + menuLoaderContext_menu2.componentMenu.width
                    + menuLoaderContext_menu2.componentMenu.width >= Window.window.width) {
                menuLoaderContext_menu2.componentMenu.side = 'left'
            }

            if (menuPoint.x + menuLoaderContext_menu2.componentMenu.width
                    > Window.window.width - 20) {
                menuLoaderContext_menu2.componentMenu.x
                        -= (menuPoint.x + menuLoaderContext_menu2.componentMenu.width
                            - Window.window.width + 20)
            }

            if (root.is_export_media !== true) {
                menuLoaderContext_menu2.componentMenu._open()
            }

            if (timer_context_menu2_close.running) {
                timer_context_menu2_close.stop()
            }
            timer_context_menu2_close.start()
        }
    }
    function setMode904() {
        var i_is_correct_parent_finded_lv = 0
        var i_is_this_common_panel_lv = 0
        if (false === root.common_panel)
            i_is_this_common_panel_lv = 0
        else {
            i_is_this_common_panel_lv = 1
            //ke2 = 'common_panel908';
        }
        var b_is_ness_cont_work_lv = true
        if (b_is_ness_cont_work_lv) {
            if (root.is_export_media === 1) {
                idLog3.warn(' 200715 30 ')
                root.m_b_is_caused_by_unload = true
            }
            if (0 !== root.from_export_media) {
                idLog3.warn(' 200715 31 ')
                root.m_b_is_caused_by_unload = true
            }
            if (root.m_b_is_caused_by_unload) {
                if ('keepAspectRatioExport' in render)
                    render.keepAspectRatioExport = 1
            }
            idLog3.warn('<common_pan> setMode904 root.m_b_is_caused_by_unload xx2 ' + root.m_b_is_caused_by_unload)
        }
        var i_iv_vcli_setting_arc_lv = 0
        if ('true' === iv_vcli_setting_arc.value)
            i_iv_vcli_setting_arc_lv = 1
        else
            i_iv_vcli_setting_arc_lv = 0

        var v_deb_window_1 = null
        var controls = null

        //ch00425 var iii = 8;
        //ch00425 iii = univreaderex.getI00425(  5 );

        //if (viewer_command_obj && viewer_command_obj.myGlobalComponent)
        //{
        //    controls = viewer_command_obj.myGlobalComponent;
        controls = root.Window.window.ivComponent.findByIvType('IVSETSAREA',
                                                               true)
        console.info("========================= controls = ", controls)
        i_is_correct_parent_finded_lv = 1
        var s_controls_lv = 'xxx'
        s_controls_lv = controls
        var s_controls2_lv = ''
        s_controls2_lv = univreaderex.stringFromC004(s_controls_lv)
        var v_1_lv = false
        var v_2_lv = false
        v_1_lv = (null === s_controls2_lv)
        v_2_lv = ('' === s_controls2_lv)
        var v_11_lv = false
        var v_21_lv = false
        v_11_lv = (null == s_controls2_lv)
        v_21_lv = ('' == s_controls2_lv)
        var v_3_lv = false
        v_3_lv = (0 !== univreaderex.getIdCamerasGroup())
        idLog3.warn('<common_pan> ' + ' v_1_lv ' + v_1_lv + ' v_2_lv ' + v_2_lv
                    + ' v_11_lv ' + v_11_lv + ' v_21_lv ' + v_21_lv + ' v_3_lv ' + v_3_lv)

        if ((null === s_controls2_lv || '' === s_controls2_lv) && 0 !== univreaderex.getIdCamerasGroup()){
            idLog3.warn('<common_pan> 00425 10 ')
            s_controls_lv = 'global_set_200421_' + univreaderex.getIdCamerasGroupAsString()
        }

        idLog3.warn('<common_pan> controls 90429 4 xx ' + s_controls_lv
                    + ' i_is_correct_parent_finded_lv ' + i_is_correct_parent_finded_lv
                    + " getIdCamerasGroup() " + univreaderex.getIdCamerasGroup())

        univreaderex.setCommonPanelMode(i_is_this_common_panel_lv,
                                        i_iv_vcli_setting_arc_lv,
                                        i_is_correct_parent_finded_lv,
                                        s_controls_lv)
        idLog3.warn('<prim> 4 ' + text_primit)
    }

    function correctIntervalSelectLeft_ByCommand() {
        var i_uu_64_command_time_lv = univreaderex.getCommandTimeUUI64()
        correctIntervalSelectLeft_Level1(i_uu_64_command_time_lv)
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

    function correctIntervalSelectRight_ByCommand() {
        var i_uu_64_command_time_lv = univreaderex.getCommandTimeUUI64()
        correctIntervalSelectRight_Level1(i_uu_64_command_time_lv)
    }

    function correctIntervalSelectRight_ByCommand2(time) {
        correctIntervalSelectRight_Level1(time)
    }

    function getCamCommonPanelMode() {
        var i_lv = 0
        if (1 === univreaderex.getCommonPanelMode())
            i_lv = 1
        return i_lv
    }
    function getCamCommonPanelModeUseSetPanel_Deb() {
        var i_lv = 0
        i_lv = root.getCamCommonPanelModeUseSetPanel()
        return i_lv
    }

    function getCamCommonPanelModeUseSetPanel() {
        if (0 !== univreaderex.isGlobalSet200421()) return 0
        return root.getCamCommonPanelMode()
    }

    function complete4() {
        primitivesLoader.create()
        equalizerLoader.create()
    }

    //ch90918 - это - спрятать или пок-ть общ панель е
    function commonPanelSetVisible(i_val_av) {
        idLog3.warn('<common_pan> 200712 31 ')

        var i_height_lv = root.height
        var i_height_contr_panel_lv = wndControlPanel.height

        root.visible = (0 !== i_val_av)

        if (0 !== i_val_av) root.height = i_height_contr_panel_lv
        else root.height = 0
        wndControlPanel.visible = (0 !== i_val_av)
        //iv_arc_slider_control.visible = (0 !== i_val_av)
    }

    function updateTime811_Causing1() {
        idLog3.warn('<calendar> updateTime811_Causing1 b_input_time_outside_cahange ' + b_input_time_outside_cahange)
        updateTime811()
    }

    function updateTimeFromCalendar(){
        var chosenDateTime = calend_time.chosenDate+" "+calend_time.chosenTime
        var new_date = Date.fromLocaleString(Qt.locale(), chosenDateTime, "dd.MM.yyyy hh:mm:ss");
        iv_arc_slider_new.canAutoMove = true
        iv_arc_slider_new.currentDate = new_date
        calend_time.updateDateTimeText()
        root.time811 = univreaderex.timeFromComponents(Qt.formatDate(iv_arc_slider_new.currentDate, "dd.MM.yyyy"),
                                                       Qt.formatTime(iv_arc_slider_new.currentDate, "hh:mm:ss.zzz")
                                                       )
        if (!iv_vcli_setting_arc.val && playerLoader.item !== null){
            univreaderex.time_urx = root.time811
            if (root.needToPause){
                root.playCmd(false)
            }
            var param = {}
            param.time = iv_arc_slider_new.currentDate.getTime().toString()
            param.key2 = root.key2
            param.key3 = "12345";//univreaderex.key3_urx
            param.speed = iv_speed_slider.speed
            param.from = Qt.formatDateTime(iv_arc_slider_new.currentDate, "yyyy-MM-dd hh:mm:ss,zzz")
            param.track_name = render.trackFrame
            if (revers_ivichb.chkd) param.cmd = "backward"
            else param.cmd = "forward"
            playerLoader.item.setTime(param)
            if (root.needToPause){
                root.playCmd(true)
            }
        }
        else {
            timer1111.stop()
            if (needToPause){
                timer1111.frTime = root.getFrameTime()
            }
            univreaderex.time_urx = root.time811
            timer1111.start()
        }
    }

    function updateTimeFromSlider(){
        var stringDate = iv_arc_slider_new.currentDate
        var stringTime = iv_arc_slider_new.currentDate
        calend_time.chosenDate = Qt.formatDate(stringDate, "dd.MM.yyyy")
        calend_time.timeString = stringTime.toString()
        calend_time.updateDateTimeText()
        root.time811 = univreaderex.timeFromComponents(Qt.formatDate(iv_arc_slider_new.currentDate, "dd.MM.yyyy"),
                                                       Qt.formatTime(iv_arc_slider_new.currentDate, "hh:mm:ss.zzz")
                                                       )
        if (!iv_vcli_setting_arc.val && playerLoader.item !== null){
            univreaderex.time_urx = root.time811
            if (root.needToPause){
                root.playCmd(false)
            }
            var param = {}
            param.time = iv_arc_slider_new.currentDate.getTime().toString()
            param.key2 = root.key2
            param.key3 = "12345";//univreaderex.key3_urx
            param.speed = iv_speed_slider.speed
            param.from = Qt.formatDateTime(iv_arc_slider_new.currentDate, "yyyy-MM-dd hh:mm:ss,zzz")
            param.track_name = render.trackFrame
            if (revers_ivichb.chkd) param.cmd = "backward"
            else param.cmd = "forward"
            playerLoader.item.setTime(param)
            if (root.needToPause){
                root.playCmd(true)
            }
        }
        else {
            timer1111.stop()
            if (needToPause){
                timer1111.frTime = root.getFrameTime()
            }
            univreaderex.time_urx = root.time811
            timer1111.start()
        }
    }

    function updateTime811() {
        idLog3.warn('updateTime811 begin ')
        var s_date_lv = calend_time.chosenDate

        idLog3.warn('<calendar> updateTime811 calend_time.chosenDate ' + calend_time.chosenDate
                    + ' calend_time.chosenTime ' + calend_time.chosenTime
                    + ' s_date_lv ' + s_date_lv
                    + ' timeString ' + calend_time.timeString
                    + ' input_time_outside_cahange ' + root.b_input_time_outside_cahange)

        idLog3.warn('calend_time.chosenDate ' + calend_time.chosenDate
                    + ' calend_time.chosenTime ' + calend_time.chosenTime
                    + ' s_date_lv ' + s_date_lv)

        root.time811 = univreaderex.timeFromComponents(s_date_lv,calend_time.chosenTime)
        idLog3.warn('updateTime811 root.time811' + root.time811
                    + ' b_input_time_outside_cahange ' + root.b_input_time_outside_cahange)
        if (root.time811 == "") {

        } else {
            idLog3.warn('updateTime811 root.time811 301')
            if (!root.b_input_time_outside_cahange)
            {
                idLog3.warn('updateTime811 302'
                            + ' univreaderex.time ' + univreaderex.time_urx
                            + ' root.time811 ' + root.time811)

                console.error("updateTime811 root.time811 = ", root.time811,
                             " univreaderex.time = ", univreaderex.time_urx)

                univreaderex.time_urx = root.time811
                if (!iv_arc_slider_new.sliderIsDragged)
                    iv_arc_slider_new.currentDate = new Date(root.time811)

                idLog3.warn('updateTime811 root.time811' + root.time811
                            + ' univreaderex.time ' + univreaderex.time_urx)
            }
        }
        idLog3.warn('updateTime811 root.time811 4')
        root.b_input_time_outside_cahange = false
    }

    function updateSpeedSlider() {
        var i_speed_lv = 1
        switch (iv_speed_slider.speed){
            case 0.125: i_speed_lv = 125; break
            case 0.25: i_speed_lv = 250; break
            case 0.5: i_speed_lv = 500; break
            case 1: i_speed_lv = 1000; break
            case 2: i_speed_lv = 2000; break
            case 4: i_speed_lv = 4000; break
            case 8: i_speed_lv = 8000; break
            case 16: i_speed_lv = 16000; break
            case 32: i_speed_lv = 32000; break
            case 64: i_speed_lv = 64000; break
            case 128: i_speed_lv = 128000; break
        }
        if (playerLoader.item !== null){
            var o = {};
            o.speed = iv_speed_slider.speed
            playerLoader.item.setSpeed(o);
        }
        else {
            univreaderex.setSpeed005(i_speed_lv)
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
        //ch00608 univreaderex.getFrameTimeUUI64();
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

    function getFrameTime() {
        var i64_time_lv = 0
        i64_time_lv = univreaderex.getFrameTimeUUI64()
        idLog3.warn('<photocam> getFrameTime time ' + i64_time_lv)
        return univreaderex.getFrameTimeUUI64()
    }
    function extComponentsSetVisible(b_is_visible_av) {
        //upload_left_bound_2_lb.visible2 = b_is_visible_av
        //upload_left_bound_lb.visible2 = b_is_visible_av
        iv_butt_spb_events_skip.visible2 = b_is_visible_av
        iv_butt_spb_bmark_skip.visible2 = b_is_visible_av

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
                mousearea_CommonPanMode.enabled = false
        }
        else extComponentsSetVisible(false)
    }

    //ch90917
    function showInterval908(uu_i_ms_begin_interval_av, uu_i_ms_end_interval_av, s_event_text_interval_av) {
        var s_event_text_trunc_lv = ''
        s_event_text_trunc_lv = univreaderex.truncUTF8StrUR(
                    s_event_text_interval_av, 20)
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
        var i_curr_time_lv = univreaderex.getCurrTime()

        var s_event_text_lv = ''
        var i_is_already_interval_selected_lv = 0
        var s_warning_pref_lv = ''

        if (root.m_i_current_timeout_request_to_events > 20000
                || root.m_i_marker_last_request_to_events + 40000 < i_curr_time_lv)
            root.m_i_current_timeout_request_to_events = 2000

        if (0 !== root.m_uu_i_ms_begin_interval)
            i_is_already_interval_selected_lv = 1
        i_res_lv = univreaderex.moveToEventBySlider(
                    b_is_right_av, b_is_bookmarks_av,
                    i_is_already_interval_selected_lv,
                    root.m_i_current_timeout_request_to_events)

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
            //ch90723 root.m_b_ness_check_present_event = 0;
            root.m_i_is_interval_corresp_event_bookmark = b_is_bookmarks_av ? 1 : 0
            root.m_s_start_event_id = univreaderex.getLastSelectedEventStartId()

            s_event_text_lv = univreaderex.getLastSelectedEventText()
            showInterval908(univreaderex.getLastSelectedEventBegin(),
                            univreaderex.getLastSelectedEventEnd(),
                            s_event_text_lv)
        }
        //e
        root.m_i_marker_last_request_to_events = i_curr_time_lv
    }
    function positioningMenu() {//menu_interval2.x =
        //menuLoaderSelInterv.componentMenu.x = select_interval_ivibt.x;
        //select_interval_ivichb
        //select_interval_ivibt
        //rectSelect_interval_ivibt.x;
        //if ( menu_interval2.width + 10 <
        //select_interval_ivichb
        //select_interval_ivibt
        //        rectSelect_interval_ivibt.x )
        //{
        //    menu_interval2.x =
        //select_interval_ivichb
        //select_interval_ivibt
        //            rectSelect_interval_ivibt.x + 20;
        //};
        //menu_interval2.y =
        //menuLoaderSelInterv.componentMenu.y =rectSelect_interval_ivibt.y;
        //select_interval_ivichb
        //select_interval_ivibt
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
    function commonPanelExtButtonsSetVisible(b_av) {
        /*ch90916
        sound_rect_rec.visible = b_av;
        photo_cam_rec.visible = b_av;
        image_corr_rec.visible = b_av;
        ch90916*/
        //ср91031 force_write_ivibt.visible = b_av;
        //select_interval_ivibt.visible2 = b_av;
        iv_butt_spb_events_skip.visible2 = b_av
        iv_butt_spb_bmark_skip.visible2 = b_av
        //ch90916 unload_to_avi_ivibt.visible = b_av;
    }

    function commonPanelElementsSetVisible(b_av) {//sound_rect_rec_ButtonPane.visible = b_av;
        //photo_cam_rec_ButtonPane.visible = b_av;
        //image_corr_rec_ButtonPane.visible = b_av;
        //ср91031 force_write_ivibt.visible = b_av;
        //select_interval_ivibt.visible2 = b_av;
        //iv_butt_spb_events_skip.visible2 = b_av;
        //iv_butt_spb_bmark_skip.visible2 = b_av;
        //unload_to_avi_ivibt_ButtonPane.visible = b_av;
        //upload_left_bound_2_lb.visible3 = b_av;
        //upload_left_bound_lb.visible3 = b_av;
        //fullscreenButton_ButtonPane.visible = b_av;
    }

    function complete5() {
        idLog2.warn('onCompleted prop present')
        //ch90916 unload_to_avi_ivibt.visible = false;
        //ch90916 realtime_ivibt.visible = false;
//        unload_to_avi_ivibt_ButtonPane.visible = false
//        switchToRealTime_ButtonPane.visible = false

        //iv_butt_spb_events_skip.visible2 = false;
        //iv_butt_spb_bmark_skip.visible2 = false;
    }

    function correctInterval_Level1(i_uu_64_time_av) {
        var i_uu_64_frame_time_lv = //ch00608 univreaderex.getFrameTimeUUI64();
                i_uu_64_time_av
        if (i_uu_64_frame_time_lv < root.m_uu_i_ms_begin_interval)
            root.m_uu_i_ms_begin_interval = i_uu_64_frame_time_lv
        else if (root.m_uu_i_ms_end_interval < i_uu_64_frame_time_lv)
            root.m_uu_i_ms_end_interval = i_uu_64_frame_time_lv
        //ch00708 e
        idLog3.warn('<' + root.key2 + '_' + root.key3 + '>' + 'correctInterval_Level1 '
                    + ' m_uu_i_ms_begin_interval ' + root.m_uu_i_ms_begin_interval
                    + ' m_uu_i_ms_end_interval ' + root.m_uu_i_ms_end_interval)
    }

    function safeSetProperty(component, prop, func) {
        if (prop in component) {
            component[prop] = func
        }
    }

    function funcSelectInterval_right() {
        if (0 !== univreaderex.isFrameCounterCorrespondCommand()) {
            console.info("funcSelectInterval_right 1")
            idLog3.warn("<interv> 107")
            root.correctIntervalSelectLeft_Causing1()
        } else {
            console.info("funcSelectInterval_right 2")
            idLog3.warn("<interv> 108")
            //ch00607
            //ch00607 univreaderex.setDelayCorrectIntervalSelectRight( 1 );
            //root.correctIntervalSelectLeft_ByCommand_Causing1();
            root.correctIntervalSelectLeft_ByCommand_Causing2()
            //e
        }
    }
    function funcSelectInterval_left() {
        idLog3.warn('<interv>	507')
        if (0 !== univreaderex.isFrameCounterCorrespondCommand()) {
            //console.info("funcSelectInterval_left 1");
            idLog3.warn('<interv>	508')
            root.correctIntervalSelectRight_Causing1()
        } else {
            //console.info("funcSelectInterval_left 2");
            idLog3.warn('<interv>	509')
            //ch00607
            //ch00607 univreaderex.setDelayCorrectIntervalSelectLeft( 1 );
            //root.correctIntervalSelectRight_ByCommand_Causing1();
            root.correctIntervalSelectRight_ByCommand_Causing2()
            //e
        }
    }
    function funcSave_interval() {
        root.m_i_is_interval_corresp_event = 1
        //ch90723 root.m_b_ness_check_present_event = 1;
        root.m_b_ness_pass_params = false
        root.m_i_is_interval_corresp_event_bookmark = 1

        select_intervalLoader.create()
        idLog2.warn(//'181031 end time ' +
                    //ch90510 time811
                    //s_frame_time_2_lv
                    //+
                    ' ness_pass_params ' + root.m_b_ness_pass_params)
    }
//    function funcCall_Unload_window() {
//        export_aviLoader.create()
//    }

    function funcUnload() {
        univreaderex.unload007(root.m_uu_i_ms_begin_interval,root.m_uu_i_ms_end_interval)
        var win_count = MExprogress.windows_count
        idLog3.trace('<IVButtonPaneArc.qml> menu_item_unload onTriggered win_count = ' + win_count)
        idLog3.trace('<IVButtonPaneArc.qml> menu_item_unload onTriggered  export_status_window.value = ' + export_status_window.value)

        if (win_count === 0 && export_status_window.value === "true") {
            idarchive_player.createExprogressWindow()
        }
    }
    function funcUnload2() {
        idStable.start(16300018);
        idLog.trace("Export.qml download {");

        setExportLoader.item.getValsFromMediaJs()

        var setExport = expwind.setExport

        var o = {};
        o.mask = []

        if (root.key2) o.camera = root.key2
        else o.camera = currentCamera

        idLog.trace('Export.qml download o.camera ' + o.camera)

        o.from_date = calendTime_from.chosenDate;
        o.from_time = calendTime_from.chosenTime;
        o.to_date = calendTime_to.chosenDate;
        o.to_time = calendTime_to.chosenTime;
        o.create_on_client = setExport.create_on_client;

        idLog.trace('Export.qml download o.from_date ' + o.from_date)
        idLog.trace('Export.qml download o.from_time ' + o.from_time)
        idLog.trace('Export.qml download o.to_date ' + o.to_date)
        idLog.trace('Export.qml download o.to_time ' + o.to_time)
        idLog.trace('Export.qml download o.create_on_client ' + o.create_on_client)

        o.codec = setExport.codec;
        if (setExport.codec === "mpeg4") o.codec = "mp4v"

        idLog.trace('Export.qml download o.codec ' + o.codec)
        idLog.trace('Export.qml download textOverlay ' + setExport.textOverlay.toString())
        idLog.trace('Export.qml download timeOverlay ' + setExport.timeOverlay.toString())
        idLog.trace('Export.qml download horizont_pos ' + setExport.horizont_pos.toString())
        idLog.trace('Export.qml download vertical_pos ' + setExport.vertical_pos.toString())
        idLog.trace('Export.qml download font_size ' + setExport.font_size.toString())

        if (setExport.textOverlay.toString() === "true" || setExport.timeOverlay.toString() === "true")
        {
            if (setExport.horizont_pos === "слева")
                o.horizont_pos = "font_left"
            else if (setExport.horizont_pos === "по центру")
                o.horizont_pos = "font_center"
            else if (setExport.horizont_pos === "справа")
                o.horizont_pos = "font_right"

            if (setExport.vertical_pos === "сверху")
                o.vertical_pos = "font_top"
            else if (setExport.vertical_pos === "по центру")
                o.vertical_pos = "font_mid"
            else if (setExport.vertical_pos === "снизу")
                o.vertical_pos = "font_bot"

            o.font_size = setExport.font_size;
        }

        if (setExport.currentSoundCamera !== null
                && setExport.currentSoundCamera !== ""
                && setExport.soundSource)
        {
            idLog.trace('Export.qml download setExport.currentSoundCamera1 ' + setExport.currentSoundCamera)
            o.audio_id = setExport.currentSoundCamera;
        }
        else {
            idLog.trace('Export.qml download setExport.currentSoundCamera2 ' + setExport.currentSoundCamera)
            o.audio_id = null;
        }

        idLog.trace('Export.qml download o.audio_id ' + o.audio_id)

        if (setExport.resolution[0] > 0 && setExport.resolution[1] > 0){
            o.width = setExport.resolution[0]
            o.height = setExport.resolution[1]
        }
        idLog.trace('Export.qml download o.width ' + o.width)
        idLog.trace('Export.qml download o.height ' + o.height)

        o.file_type = setExport.fileType;
        o.quality = setExport.quality;
        o.fps = setExport.fps;
        o.only_keys = setExport.onlyKeys;
        o.contours = setExport.exp_contours
        o.comment = setExport.comment;
        o.save_source = setExport.saveSource;
        //o.unique_root_win = itemExport.unique_root_win;

        //idLog.trace('Export.qml download o.unique_root_win ' + o.unique_root_win)
        idLog.trace('Export.qml download o.file_type ' + o.file_type)
        idLog.trace('Export.qml download o.quality ' + o.quality)
        idLog.trace('Export.qml download o.fps ' + o.fps)
        idLog.trace('Export.qml download o.only_keys ' + o.only_keys)
        idLog.trace('Export.qml download o.contours ' + o.contours)
        idLog.trace('Export.qml download o.comment ' + o.comment)
        idLog.trace('Export.qml download o.save_source ' + o.save_source)

        if (setExport.textOverlay.toString() === "true") o.text_overlay = true
        else o.text_overlay = false

        if (setExport.timeOverlay.toString() === "true") o.time_overlay = true
        else o.time_overlay = false

        o.path = setExport.currentPath;
        idLog.trace('Export.qml download o.path ' + o.path)

        if (root.m_s_selected_zna_ip_output !== null && root.m_s_selected_zna_ip_output !== undefined)
            o.ip_zna = root.m_s_selected_zna_ip_output

        o.list_cams = setExport.list_cams;
        idLog.trace('Export.qml download o.list_cams ' + o.list_cams)
        setExportLoader.item.mexport.downloadTime(o);
        setExport.list_cams = "";
        var win_count = MExprogress.windows_count
        if (win_count === 0 && export_status_window.value === "true") {
            idarchive_player.createExprogressWindow()
        }

        idLog.trace("Export.qml download {");
        idStable.end();
    }

    function funcReset_selection() {
        if (iv_arc_slider_new.setInterval){
            iv_arc_slider_new.setInterval = false
            iv_arc_slider_new.setInterval = true
        }
        root.m_uu_i_ms_begin_interval = iv_arc_slider_new.currentDate.getTime()
        root.m_uu_i_ms_end_interval = iv_arc_slider_new.currentDate.getTime()
    }

    function complete2303() {
        console.info("complete2303 m_b_complete_2303_fierst_time = ", m_b_complete_2303_fierst_time)
        if (m_b_ke2_changed_2303 && m_component_completed_2303) { }
    }

    function funcSwitchSource0() {
        univreaderex.switchSource(0)
    }
    function funcSwitchSource1() {
        univreaderex.switchSource(1)
    }
    function funcSwitchSource2() {
        univreaderex.switchSource(2)
    }
    function funcSwitchSource3() {
        univreaderex.switchSource(3)
    }
    function funcSwitchSource4() {
        univreaderex.switchSource(4)
    }
    function funcSwitchSource5() {
        univreaderex.switchSource(5)
    }
    function funcSwitchSource6() {
        univreaderex.switchSource(6)
    }

    function functReturnToRealtime() {
        if (viewer_command_obj !== null || viewer_command_obj !== undefined) {
            viewer_command_obj.command_to_viewer('viewers:switch')
        }
    }

    function compare(a, b) {
        if (a.time_begin > b.time_begin)
            return 1 // если первое значение больше второго
        if (a.time_begin === b.time_begin)
            return 0 // если равны
        if (a.time_begin < b.time_begin)
            return -1 // если первое значение меньше второго
    }

    function compare2(a, b) {
        if (a.frame_time > b.frame_time)
            return 1 // если первое значение больше второго
        if (a.frame_time === b.frame_time)
            return 0 // если равны
        if (a.frame_time < b.frame_time)
            return -1 // если первое значение меньше второго
    }
    Shortcut {
        sequence: StandardKey.ZoomIn
        onActivated: {
            //console.info("========================== ZoomIn")
        }
    }

    Loader {
        id: menuLoaderSelInterv
        //anchors.fill: parent
        asynchronous: true
        property var componentMenu: null
        property bool menu_item_select_interval_right_visible: false
        property bool menu_item_select_interval_left_visible: false
        property bool menu_item_change_visible: false
        property bool menu_item_go_to_begin_visible: false
        property bool menu_item_go_to_end_visible: false
        property bool menu_item_save_interval_visible: false
        property bool menu_item_call_unload_window_visible: false
        property bool menu_item_unload_visible: false
        property bool menu_item_reset_selection_visible: false
        property bool menu_item_cancel111_visible: false

        function create() {
            var qmlFile2 = 'file:///' + applicationDirPath
                    + '/qtplugins/iv/ivcontextmenurealtime/IVContextMenuRealtime.qml'
            menuLoaderSelInterv.source = qmlFile2
        }
        function refresh() {
            menuLoaderSelInterv.destroy()
            menuLoaderSelInterv.create()
        }
        function destroy() {
            if (menuLoaderSelInterv.status !== Loader.Null)
                menuLoaderSelInterv.source = ""
        }
        onStatusChanged: {
            if (menuLoaderSelInterv.status === Loader.Ready) {
                menuLoaderSelInterv.componentMenu = menuLoaderSelInterv.item
                //console.error("<<<<<<<<<<<<<<<<<<<<<<<<< menuLoaderSelInterv.componentMenu Loader.Ready");
            }
            if (menuLoaderSelInterv.status === Loader.Error) {
                //console.error("menuLoaderSelInterv.componentMenu error");
            }
            if (menuLoaderSelInterv.status === Loader.Null) {

            }
        }
    }
}

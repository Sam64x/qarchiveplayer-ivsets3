import QtQuick 2.7
import iv.devices.univreaderex 1.0
import iv.renders.renderselector 1.0
import iv.plugins.loader 1.0
import QtQuick.Window 2.2
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2
import iv.viewers.archiveplayer 1.0
import iv.guicomponents 1.0
import iv.calendar 1.0
import iv.archivecomponents.selectinterval 1.0
import iv.photocam 1.0
import QtQuick.Controls.Styles 1.4

import iv.plugins.users 1.0
import iv.exprogress 1.0

import iv.singletonLang 1.0

Item {
    id: root

    readonly property point frameLeftTop: root.mapFromItem(render,
                                                           render.frameLeft,
                                                           render.frameTop)
    readonly property point frameRightBottom: root.mapFromItem(
                                                  render, render.frameRight,
                                                  render.frameBottom)
    readonly property alias frameLeft: root.frameLeftTop.x
    readonly property alias frameTop: root.frameLeftTop.y
    readonly property alias frameRight: root.frameRightBottom.x
    readonly property alias frameBottom: root.frameRightBottom.y
    property IVComponent2 ivComponent: null
    property string key2: ''
    property string time: ''
    property string time_009_deb: ''
    property bool m_b_is_caused_by_unload: false
    property bool common_panel: false
    property int m_i_c_control_panel_height: 69
    property int m_i_c_control_panel_high_part_height: 34
    property int m_i_c_control_panel_law_part_bottom_marging: 19
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
    property string m_s_tooltip_select_interv_1: Language.getTranslate(
                                                     "select the first boundary of the interval and click",
                                                     "выберите первую границу интервала и нажмите")
    property int m_i_is_interval_corresp_event: 0
    //ch90723 property int m_b_ness_check_present_event: 0
    property int m_i_is_interval_corresp_event_bookmark: 0
    property string m_s_exch_event_id: ''
    property int m_i_current_timeout_request_to_events: 2000
    property variant m_i_marker_last_request_to_events: 0

    property int c_I_ELEM_VERTIC_OFFSET_909: 3
    property string end: ''
    property string text_primit: ''

    //ch91113
    property bool m_b_image_corrector_created: false
    property string trackFrameAfterImageCorrectorRoot: ''
    //e
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

    //ch91029 otsech beg
    property var m_primit: null

    property var m_equal: null

    property int from_export_media: 0

    property var m_pane_sound: null

    signal nessUpdateCalendarAP
    //ch220418
    signal setCurrTimeCommandAP
    //e
    property int m_i_is_sound_created: 0
    property int m_i_ness_activate_sound: 0
    property int m_i_already_set_008: 0

    property string m_s_is_video_present: ""

    property string savedSetName: ""
    property variant m_v_component_main_export: null

    //ch91029 otsech end
    property string on_frame_profile: ''
    property string key3: ''
    property bool possibility_switch_realtime: false
    property bool draw_contures: false
    property bool repeat: false
    property int speed: 1000

    //property int speedDeb: 1000
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
    //ch91102 это значит, что изменение времени пришло не
    //от ввода пользователя в поле календарь, а задания изве
    //- чтобы календарь восприняв это время не стал его сам вводить е
    property bool b_input_time_outside_cahange: false
    property string buttonColorPressed: "#f0f0f0"
    property string buttonColor: "#f3f3f3"
    property string buttonBorderColorPressed: "#808080"
    property string buttonBorderColor: "#303030"
    //    почти чернй "#303030"
    //    средне серый "#bdbebf"
    //    свето серый "#f0f0f0"
    //    более свето серый "#f6f6f6"
    //ch90511 время как INT64 десятичная строка e
    //ch90716 это - интервал выбираемый широкой шкалой е
    property variant m_uu_i_ms_begin_interval: 0
    property variant m_uu_i_ms_end_interval: 0
    property string m_s_start_event_id: ''

    //ch90702 property string m_s_fierst_bound_interval: ""
    property int m_i_curr_scale: 6
    property int m_i_max_scale: 7
    property int m_i_min_scale: 1
    property string time811: ''
    property int m_i_width_visible_bound5: 200
    property int m_i_width_visible_bound4: 350
    property int m_i_width_visible_bound3: ppUp.x + root.getSmallSizePanel(
                                               ) //520
    property int m_i_width_visible_bound2: ppUp.x + root.getNormalSizePanel(
                                               ) //720
    property bool m_b_is_by_events: false
    property real m_rl_min_scale: 0.0
    //ch90918 это типа нужно чтоб вынести в др поток е
    property bool m_b_ness_pass_params: false
    property string guid: ""

    //ch90719 property string m_s_unload_begin_interval: ""
    //ch90719 property string m_s_unload_end_interval: ""

    //ch91029 otsech beg
    property string m_s_key3_audio_ap: ''
    property string m_s_track_source_univ_ap: ''

    //ch10324
    /*
    property variant m_univreaderex_ap2: univreaderex;
    property variant m_idLog3_ap2: idLog3;
    */
    //e
    //ch220403
    property int m_i_is_ness_switch_to_realtime_common_panel: 0
    property int m_i_is_ness_switch_to_realtime_common_panel_prev: 0
    //e
    property bool small_mode_panel_ppUp: false
    property int speed_ch_box_rec_size: 33
    property bool ppUpRowLayoutFillState: false
    property int m_i_event_not_found_visible_counter: 0
    property string m_s_tooltip_select_interv_2: Language.getTranslate(
                                                     "change interval boundary and other interval operations", "изменить границу интервала и другие операции с интервалом")
    property variant viewer_command_obj: null
    property var export_avi_object: null
    property int is_export_media: 0
    property bool isFullscreen: false
    property bool prev_condition_is_fullscreen: false
    //ch221021
    property string m_s_selected_sna_ip: ""
    property string m_s_selected_zna_ip_output: ""
    property string shortcutExportAviArchive: ''
    property bool debug_mode: debugVcli !== null
                              && debugVcli !== undefined ? debugVcli.value
                                                           === "true" ? true : false : false
    property bool display_camera_previews: arc_display_camera_previews !== null
                              && arc_display_camera_previews !== undefined ? arc_display_camera_previews.value
                                                           === "true" ? true : false : false
    //e
    //ch230324
    property bool m_b_ke2_changed_2303: false
    property bool m_component_completed_2303: false
    property bool m_b_complete_2303_fierst_time: true
    property bool arc_common_panel: iv_vcli_setting_arc.value === 'true' ? true : false
    property bool fast_edits: fastEdits.value === 'true' ? true : false
    property bool is_set_edit: isSetEdit.value === 'true' ? true : false
    property bool is_multiscreen: false

    //e

    property real isize: interfaceSize.value !== "" ? parseFloat(
                                                          interfaceSize.value) : 1
    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }

    IvVcliSetting {
        id: arc_display_camera_previews
        name: 'archive.display_camera_previews'
    }

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

    onIsFullscreenChanged: {
        if (root.prev_condition_is_fullscreen === false && root.isFullscreen === true) {

            if (root.viewer_command_obj != null && root.viewer_command_obj != undefined &&
                    root.viewer_command_obj.myGlobalComponent != null && root.viewer_command_obj.myGlobalComponent != undefined
                    && root.viewer_command_obj.myGlobalComponent.isOneCamInSet != undefined)
            {
                if (root.viewer_command_obj.myGlobalComponent.isOneCamInSet === true)
                {
                    root.is_multiscreen = false;
                }
            }
            else
            {
                root.is_multiscreen = false;
            }
        } else if (root.prev_condition_is_fullscreen === true
                           && root.isFullscreen === false) {
            if (root.viewer_command_obj != null && root.viewer_command_obj != undefined &&
                    root.viewer_command_obj.myGlobalComponent != null && root.viewer_command_obj.myGlobalComponent != undefined
                    && root.viewer_command_obj.myGlobalComponent.isOneCamInSet != undefined)
            {
                if (root.viewer_command_obj.myGlobalComponent.isOneCamInSet === true)
                {
                    root.is_multiscreen = true;
                }
            }
            else
            {
                root.is_multiscreen = false;
            }
        }
        root.prev_condition_is_fullscreen = root.isFullscreen
    }

    onViewer_command_objChanged: {
        if (root.viewer_command_obj != null && root.viewer_command_obj != undefined &&
                root.viewer_command_obj.myGlobalComponent != null && root.viewer_command_obj.myGlobalComponent != undefined
                && root.viewer_command_obj.myGlobalComponent.isOneCamInSet != undefined)
        {
            if (root.viewer_command_obj.myGlobalComponent.isOneCamInSet === true ||
                    (root.prev_condition_is_fullscreen === false && root.isFullscreen === true) ||
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

    //ch221021
    onM_s_selected_sna_ipChanged: {
        //console.info("ArchivePlayer onM_s_selected_sna_ipChanged", m_s_selected_sna_ip);
        idLog3.warn("<select_source> m_s_selected_sna_ip " + m_s_selected_sna_ip)
        univreaderex.switchSource_Vart2(m_s_selected_sna_ip)
    }

    //e
    Timer {
        id: timer_context_menu2_close
        interval: 30000
        onTriggered: {

            //if (context_menu2.opened)
            //{
            //    context_menu2.close();
            //}
            menuLoaderContext_menu2.componentMenu._close()
        }
    }

    ArchivePlayer {
        id: idarchive_player

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

    Iv7Log {
        id: idLog
        name: 'qt'
    }
    //ch91029 otsech end/
    Iv7Log {
        id: idLog2
        name: 'arc.trace'
    }
    Iv7Log {
        id: idLog3
        name: 'qtplugins.iv.viewers.archiveplayer'
    }

    IvVcliSetting {
        id: stabServer
        name: 'image_stabilizer'
    }

    IvVcliSetting {
        id: export_status_window
        name: 'qml.export.export_status_window'
    }

    //ch210202
    IvVcliSetting {
        id: shortcutLastSequence1
        name: 'keyboard.signals.' + root.Window.window.unique
    }

    IvVcliSetting {
        id: shortcutLastSequenceArchive /// _switch
        name: 'keyboard.signals.archive'
        onValueChanged: {
            if (shortcutLastSequenceArchive.value === "Ctrl+Up") {

                //if (shortcutLastSequenceArchive.value === "Ctrl+Up")
                //{
                //    shortcutLastSequenceArchive.value = "@$#f$&*()#";
                //}
                if (root.m_i_curr_scale > 1) {
                    root.m_i_curr_scale -= 1
                }
            }
            if (shortcutLastSequenceArchive.value === "Ctrl+Down") {

                //if (shortcutLastSequenceArchive.value === "Ctrl+Down")
                //{
                //    shortcutLastSequenceArchive.value = "@$#f$j&*()#";
                //}
                if (root.m_i_curr_scale < 7) {
                    root.m_i_curr_scale += 1
                }
            }
        }
    }

    IvVcliSetting {
        id: debugVcli
        name: 'debug.enable'
    }

    onShortcutExportAviArchiveChanged: {
        //console.info("onShortcutExportAviArchiveChanged root.shortcutExportAviArchive = ", root.shortcutExportAviArchive);
        if (root.shortcutExportAviArchive === "Ctrl+Up") {
            if (root.m_i_curr_scale > 1) {
                root.m_i_curr_scale -= 1
            }
            root.shortcutExportAviArchive = ''
        } else if (root.shortcutExportAviArchive === "Ctrl+Down") {
            if (root.m_i_curr_scale < 7) {
                root.m_i_curr_scale += 1
            }
            root.shortcutExportAviArchive = ''
        }
    }

    IvVcliSetting {
        id: iv_vcli_setting_arc_play_back //это предназначена для обращения внутри QML e
        name: 'archive.interface.playBackVis' //По этому осуществляется навигация в базе данных е
        //ch90817
        //      onValueChanged: {
        //        idLog3.warn(' 190816 NEW VALUE=' + iv_vcli_setting_arc_play_back.value);
        //        revers_ivichb.visible3 =
        //          ( 'true' === iv_vcli_setting_arc_play_back.value ) ? 1 : 0;
        //      }
        //e
    }

    IvVcliSetting {
        id: iv_vcli_setting_arc_events_skip //это предназначена для обращения внутри QML e
        name: 'archive.interface.eventsSkipVis' //По этому осуществляется навигация в базе данных е
        //ch90817
        //      onValueChanged: {
        //        idLog3.warn(' 190816 1 NEW VALUE=' + iv_vcli_setting_arc_events_skip.value);
        //        m_iv_butt_spb_events_skip_bfpa.visible4 =
        //          ( 'true' === iv_vcli_setting_arc_events_skip.value ) ? 1 : 0;
        //      }
        //e
    }
    IvVcliSetting {
        id: iv_vcli_setting_arc_bmark_skip //это предназначена для обращения внутри QML e
        name: 'archive.interface.bmarkSkipVis' //По этому осуществляется навигация в базе данных е
        //ch90817
        //      onValueChanged: {
        //        idLog3.warn(' 190816 1 NEW VALUE=' + iv_vcli_setting_arc_bmark_skip.value);
        //        m_iv_butt_spb_bmark_skip_bfpa.visible4 =
        //          ( 'true' === iv_vcli_setting_arc_bmark_skip.value ) ? 1 : 0;
        //      }
        //e
    }

    IvVcliSetting {
        id: iv_vcli_setting_arc //это предназначена для обращения внутри QML e
        name: 'archive.common_panel' //По этому осуществляется навигация в базе данных е
        onValueChanged: {

            //ch90528 нижеследующее исполняем только если
            //у данного кземляра не нулевой ид набора
            //и существует общая панель с таким ид е
            root.arc_common_panel = iv_vcli_setting_arc.value === 'true' ? true : false

            if (univreaderex.isCommonPanelForThisPresent()) {

                idLog3.warn(' 190410 NEW VALUE=' + iv_vcli_setting_arc.value)
                var i_lv = 0
                if ('true' === iv_vcli_setting_arc.value) {
                    complete2()
                    i_lv = 1
                } else {
                    i_lv = 0
                }
                var i_prev_lv = univreaderex.getCommonPanelMode()
                var i_is_changed_lv = 0
                if (i_prev_lv !== i_lv)
                    i_is_changed_lv = 1
                //ch90427 изменить нужно после того как все
                //закроется univreaderex.setCommonPanelMode( i_lv );
                univreaderex.setCommonPanelModeCommand(i_lv)
                //e
                if (0 !== i_is_changed_lv) {
                    if (root.common_panel) {
                        idLog3.warn('<common_pan> m_i_ness_all_switch_to_realtime '
                                    + root.m_i_ness_all_switch_to_realtime
                                    + ' getCamCommonPanelMode() ' + root.getCamCommonPanelMode(
                                        ))
                        root.m_i_ness_all_switch_to_realtime++
                    }
                }
            }
            ;
        }
    }

    //ch230831 e
    IvVcliSetting {
        id: iv_vcli_setting_arc_automatic_source_select //это предназначена для обращения внутри QML e
        name: 'archive.automatic_source_select' //По этому осуществляется навигация в базе данных е
        onValueChanged: {
            var i_automatic_lv = 0;
            if ( 'true' === iv_vcli_setting_arc_automatic_source_select.value )
              i_automatic_lv = 1;
            univreaderex.avtomaticSourceSelectSet( i_automatic_lv );
        }
    }

    IvVcliSetting {
        id: iv_vcli_setting_arc_speed //это предназначена для обращения внутри QML e
        name: 'archive.interface.speedVis' //По этому осуществляется навигация в базе данных е

        //ch90817
        //      onValueChanged: {
        //        idLog3.warn(' 190816 NEW VALUE=' + iv_vcli_setting_arc_speed.value);
        //        iv_speed_slider.
        //          visible3
        //                  =
        //          ( 'true' === iv_vcli_setting_arc_speed.value ) ? 1 : 0;
        //        idLog3.warn(' 190817 iv_speed_slider.visible '
        //                    + iv_speed_slider.visible3 + ' res === ' +
        //                    ( 'true' === iv_vcli_setting_arc_speed.value )
        //        );
        //      }
        //e
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

    /*#zu666su35*/
    Iv7Test {
        id: test_id_call_archive_menu
        guid: '43_call_archive_menu'
        key2: root.key2
        onCommandReceived: {
            idLog3.warn(value) //value - json, указанный в ws запросе.
            select_interval_ivibt.clicked() //- кликнуть кнопку
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
    //ch11110
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
    //e
    Iv7Test {
        id: test_id_click_call_export_window
        guid: '43_click_archive_call_export_window'
        key2: root.key2
        onCommandReceived: {
            idLog3.warn(value) //value - json, указанный в ws запросе.
            //menu_item_call_unload_window.onTriggered(); //- кликнуть кнопку
            root.funcCall_Unload_window()
            test_id_click_call_export_window.result = "{\"result\":\"OK\"}"
        }
    }
    /*#zu666su35*/
    //e

    /*#zu666su35*/
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
    /*#zu666su35*/
    /*#zu666su35*/
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
            idLog3.warn(JSON.stringify(_json))
            test_archive_result.result = JSON.stringify(_json)
        }
    }
    /*#zu666su35*/
    //e

    //ch10820
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
    //e
    //ch220228
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
                    root.funcPlayCommand2202()
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
                    root.funcPlayCommand2202()
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

    //e

    //Shortcut {
    //id: sh_up
    //sequence: "Ctrl+T"
    //enabled: true
    //onActivated: {
    //idLog3.warn('Shortcut Up onActivated');

    //if (ppUp2.opened)
    //{
    //if (interv_lv.currentIndex > 1)
    //{
    //interv_lv.decrementCurrentIndex();
    //idLog3.warn( '<cmd> interv_lv onCurrentIndexChanged = '+interv_lv.currentIndex);
    //root.m_i_curr_scale -= 1;//interv_lv.currentIndex+1;
    //univreaderex.putLog807('bef setScaleF811 2 m_i_curr_scale ' + root.m_i_curr_scale);
    //idLog3.warn( '<cmd> onCurrentIndexChanged root.m_i_max_scale = '+root.m_i_max_scale);
    //idLog3.warn( '<cmd> onCurrentIndexChanged root.m_i_max_scale = '+root.m_i_curr_scale);
    //univreaderex.setScaleF811(root.m_i_max_scale + 1 - root.m_i_curr_scale);
    //}
    //}
    //}
    //}

    //Shortcut {
    //id: sh_down
    //sequence: "Down"
    //onActivated: {
    //idLog3.warn('Shortcut Down onActivated');

    //if (ppUp2.opened)
    //{
    //interv_lv.focus=true;
    //idLog3.warn('Shortcut Down onActivated 1');
    //if (interv_lv.currentIndex < 6)
    //{
    //interv_lv.incrementCurrentIndex();
    //root.m_i_curr_scale += 1;//interv_lv.currentIndex+1;
    //univreaderex.putLog807('bef setScaleF811 2 m_i_curr_scale ' + root.m_i_curr_scale);
    //}
    //}
    //}
    //}
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
    //ch220418
    onSetCurrTimeCommandAP: {
        idLog3.warn('onSetCurrTimeCommandAP begin')
        univreaderex.setCurrentTime()
        idLog3.warn('onSetCurrTimeCommandAP begin')
    }
    //e
    signal nessUpdateCalendarDecrAP

    //vart signal nessActivateSoundAP;
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


    //onSpeedDebChanged:
    //{
    //    idLog3.warn('<210927> 192' );
    //}
    onCommon_panelChanged: {
        if (common_panel)
            key2 = "common_panel"
    }
    onM_i_210929_debChanged: {
        idLog3.warn('<210927> 193')

        if (root.m_v_component_main_export !== null) {
            //export_aviLoader.destroy();
            //export_aviLoader.source='';
            if (export_aviLoader.status !== Loader.Null)
                export_aviLoader.source = ""
        }
    }
    onSpeedChanged: {


        //idLog3.warn('<210927> 191' );
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

    //ch90806 - это из формы выгрузки пришло е
    onM_s_exch_event_idChanged: {
        idLog3.warn('<events>  m_s_exch_event_id ' + root.m_s_exch_event_id)
        root.m_s_start_event_id = root.m_s_exch_event_id
        root.m_i_select_interv_state = c_I_IS_CORRECT_INTERV
        root.m_i_is_interval_corresp_event = 1
        root.m_i_is_interval_corresp_event_bookmark = 1
        univreaderex.refreshEventsOnBar()
        //ch90806
        upload_left_bound_lb.visible4 = true
        upload_left_bound_2_lb.visible4 = true
        //e ch90806
    }

    onIs_export_mediaChanged: {

    }

    onKey2Changed: {
        idLog3.warn('<common_pan> onKey2Changed beg key2 ' + root.key2 + ' vers ' + root.arc_vers)
        idLog3.warn("<slider_new> 54 root.key2 " + root.key2)
        //ch230906
        if ( root.key2 !== ""  )
        {
        //e        
        
        //ch10112
        //if ( 'Window' in root )
        //{
        idLog3.warn('<load> 210113 1 ')
        idLog3.warn( "<load> 210113 171 root.Window " + root.Window )
        if ('window' in root.Window) {
            idLog3.warn( "<load> 210113 172 root.Window.window " + root.Window.window )
            idLog3.warn('<load> 210113 2 ')
            //ch230906
            if ( root.Window.window !== null )
            {
            //e
              if ('unique' in root.Window.window) {
                  idLog3.warn('<load> 210113 3 ' + ' unique ' + root.Window.window.unique)
                  univreaderex.setId101(root.Window.window.unique)
                  idLog3.warn( "<load> 210113 173 " )
              }
            }
        }
        //}
        //e
        if (root.arc_vers === 0) {
            idLog3.warn("<load> 230809 1 root.key2 " + root.key2)
            setMode904()
        }

        //ch00430 deb
        //temp complete4();
        //e
        univreaderex.key2 = root.key2
        if (is_export_media === 1 && (0 !== m_i_start_called
                                      || 0 === root.arc_vers)
                && 0 === m_i_started) {
            idLog3.warn("<load> 230809 2 root.key2 " + root.key2)
            root.componentCompleted()
        }
        //ch230324
        m_b_ke2_changed_2303 = true
        idLog3.warn("<slider_new> 50 root.key2 " + root.key2)
        root.complete2303()
        //e
        }
    }

    onTime_009_debChanged: {
        idLog3.warn('onTime_009_debChanged 200904 3')
    }

    onTimeChanged: {
        idLog3.warn('200904 2')

        //ch91227 temp deb
        //ch91227 temp deb root.time = '2019.12.27-10:10:33';
        //ch91227 temp deb root.end = '2019.12.27-10:13:33';
        //e

        //ch00424 if ( '' !== root.time  )
        //ch00424 univreaderex.setTimeFromParentAccepted( 1 );
        var i_is_ness_time_change_actions = 0

        var s_time_iv_lv = ''
        s_time_iv_lv = univreaderex.convertTimeFromIntegraciyaIfNess(root.time)

        var s_end_iv_lv = ''
        s_end_iv_lv = univreaderex.convertTimeFromIntegraciyaIfNess(root.end)
        idLog3.warn('<' + root.key2 + '_' + root.key3 + '>onTimeChanged root.time '
                    + root.time + ' s_time_iv_lv ' + s_time_iv_lv)
        if (0 === root.arc_vers) {
            i_is_ness_time_change_actions = 1
        } else {
            if (0 !== root.m_i_started) {
                if (!(root.fromRealtime) || root.m_isTestMode009)
                    i_is_ness_time_change_actions = 1
            }
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

        if (is_export_media === 1 && (0 !== m_i_start_called
                                      || 0 === root.arc_vers)
                && 0 === m_i_started) {
            root.componentCompleted()
        }
    }
    onEndChanged: {
        if ('' !== root.time && '' !== root.end) {


            //ch91227 temp deb
            //ch91227 temp deb root.time = '2019.12.27-10:10:33';
            //ch91227 temp deb root.end = '2019.12.27-10:13:33';
            //e
            var s_time_iv_lv = ''
            s_time_iv_lv = univreaderex.convertTimeFromIntegraciyaIfNess(
                        root.time)

            var s_end_iv_lv = ''
            s_end_iv_lv = univreaderex.convertTimeFromIntegraciyaIfNess(
                        root.end)

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

        if (is_export_media === 1 && (0 !== m_i_start_called
                                      || 0 === root.arc_vers)
                && 0 === m_i_started) {
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
        idLog3.warn('<start_stop> 241017 021 ')
    }

    onM_b_ness_pass_paramsChanged: {
        idLog3.warn('onM_b_ness_pass_paramsChanged m_b_ness_pass_params ' + m_b_ness_pass_params
                    + ' root.m_b_is_caused_by_unload ' + root.m_b_is_caused_by_unload)
        if (m_b_ness_pass_params) {
            if (root.m_b_is_caused_by_unload) {
                if (root.export_avi_object !== null
                        && root.export_avi_object !== undefined) {
                    root.export_avi_object.set_from(
                                univreaderex.uu64ToHumanEv(
                                    root.m_uu_i_ms_begin_interval, 3))
                }

                if (root.export_avi_object !== null
                        && root.export_avi_object !== undefined) {
                    root.export_avi_object.set_to(
                                univreaderex.uu64ToHumanEv(
                                    root.m_uu_i_ms_end_interval, 3))
                }

                /*if ( 'from' in root.ivComponent.parentComponent.qml )
              {
                root.ivComponent.parentComponent.from =
                  univreaderex.uu64ToHumanEv( root.m_uu_i_ms_begin_interval
                                , 3
                                );

                idLog2.warn('onM_b_ness_pass_paramsChanged set vigruzka from ' +
                           root.ivComponent.parentComponent.from
                            );
              }
              if ( 'to' in root.ivComponent.parentComponent.qml )
              {
                root.ivComponent.parentComponent.to =
                      univreaderex.uu64ToHumanEv( root.m_uu_i_ms_end_interval
                                    , 3
                                    );
              }*/
            } else {
                idLog3.warn('<unload> 2')
                //ch90704
                if (false === root.common_panel) {
                    export_aviLoader.create()
                }
            }
        }
    }

    onWidthChanged: {
        idLog3.warn('<IVArchivePlayer.qml> onWidthChanged root width = ' + root.width)
    }

    onHeightChanged: {
        idLog3.warn('<IVArchivePlayer.qml> onHeightChanged root height = ' + root.height)
    }

    Component.onCompleted: {
        
        idLog3.warn('<common_pan> onCompleted beg key2 ' + root.key2 + 'vers' + root.arc_vers)

        if (root.debug_mode === true) {
            IVCompCounter.addComponent(root)
        }
        //ch00505 if ( root.arc_vers === 0 )
        if (is_export_media !== 1) {
            if ((0 !== m_i_start_called || 0 === root.arc_vers)
                    && 0 === m_i_started) {
                root.componentCompleted()
            }
        }
        root.m_i_is_comleted = 1
        menuLoaderSelInterv.create()
        menuLoaderContext_menu2.create()
    } //complete


    //ch91002 перенес е
    //ch91029 otsech2 end

    //ch91112_3
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
    Timer {
        id: timer_finish_preview
        interval: 3000
        onTriggered: {
            //imageSlider.imageVisible_2 = false
            //imageSlider.border.color = "transparent"
            imageSlider_1.source = "";
            imageSlider_1.visible = false;
            imageSlider.visible = false;
        }
    }

    //e ch91112_3
    Rectangle {
        id: imageSlider
        property int imageVisible: 1
        property bool imageVisible_2: false
        property string initialSource
        property int fillmode: Image.PreserveAspectCrop //Image.PreserveAspectFit
        color: "transparent" //deb "yellow"
        x: 0
        y: 40
        height: (root.height * 0.32) * root.isize //116*root.isize
        width: (root.width * 0.4) * root.isize // 200*root.isize
        border.color: "transparent"
        border.width: 5 * root.isize
        //anchors.fill: parent
        //ch91010 asynchronous: true
        //ch91010 fillMode: Image.PreserveAspectFit
        visible: (imageSlider_1.status === Image.Ready)
        clip: true
        z: 300

        Image {
            id: imageSlider_1
            asynchronous: true
            source: ''
            //anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.right: parent.right
            //anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: 5 * root.isize
            anchors.rightMargin: 5 * root.isize
            anchors.topMargin: 5 * root.isize
            //anchors.right: parent.right
            height: imageSlider.height - imageSlider.border.width * 2
            width: imageSlider.width - imageSlider.border.width * 2
            fillMode: imageSlider.fillmode
            clip: true
            visible: imageSlider.imageVisible === 1
                     && imageSlider.imageVisible_2
            onStatusChanged: {
                if (imageSlider_1.status == Image.Ready && imageSlider_1.source !="") {
                    imageSlider.border.color = "steelblue"
                } else {
                    imageSlider.border.color = "transparent"
                }
            }
        }
        /*Image {
            id: imageSlider_2
            asynchronous: true
            source: ''
            //anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.right: parent.right
            //anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: 5 * root.isize
            anchors.rightMargin: 5 * root.isize
            anchors.topMargin: 5 * root.isize
            //anchors.right: parent.right
            height: imageSlider.height - imageSlider.border.width * 2
            width: imageSlider.width - imageSlider.border.width * 2
            fillMode: imageSlider.fillmode
            clip: true
            visible: imageSlider.imageVisible === 1
                     && imageSlider.imageVisible_2
            onStatusChanged: {
                if (imageSlider_2.status == Image.Ready && imageSlider_2.source !="") {
                    imageSlider.border.color = "steelblue"
                } else {
                    imageSlider.border.color = "transparent"
                }
            }
        }*/

        function setSource(source) {

            //ch91010 2
            //imageSlider_1.source = source;
            //e
            var imageNew = imageVisible === 1 ? imageSlider_2 : imageSlider_1
            var imageOld = imageVisible === 2 ? imageSlider_2 : imageSlider_1

            imageNew.source = source

            function finishImage() {
                if (imageNew.status === Component.Ready) {
                    imageNew.statusChanged.disconnect(finishImage)
                    imageVisible = imageVisible === 1 ? 2 : 1
                }
            }

            if (imageNew.status === Component.Loading) {
                imageNew.statusChanged.connect(finishImage)
            } else {
                finishImage()
            }
        }
    }

    Rectangle {
        id: event_select_rct_hint
        width: 120
        height: 33
        color: "white"
        x: 0
        y: 80
        z: 300
        visible: false
        radius: 3
        Text {
            id: event_select_rct_hint_text
            anchors.centerIn: parent
            renderType: Text.NativeRendering
            text: "2222-22-22 22:22:22"
            font.pixelSize: 14 * root.isize
        }
    }

    //ch91029 otsech2 beg
    Rectangle {
        id: next_event_not_found_rct_hint
        width: 120
        height: 15
        z: 300
        color: "white"
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
    //ch91112_3
    readonly property string trackFrameAfterStabilizerRoot: {
        var s_res_lv = univreaderex.trackFrameAfterSynchr
        if (stabilizer.isCreated) {
            var __trackOut = stabilizer.key1 + '_' + stabilizer.key2 + '_'
                    + stabilizer.key3 + '_' + stabilizer.trackOut
            s_res_lv = __trackOut
        }
        return s_res_lv
    }

    /*Menu {
        id: context_menu2
        MenuItem {
            id: menu_item_return_to_realtime
            //ch00108 height: visible ? implicitHeight : 0
            height: root.m_i_menu_height*root.isize
            //text: Language.getTranslate("Return to realtime", "Возврат в реалтайм") //"Возврат в реалтайм"
            Text{
                color: "black"
                text: Language.getTranslate("Return to realtime", "Возврат в реалтайм")
                font.pixelSize: 12*root.isize
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
            }
            onTriggered:
            {
                if (viewer_command_obj !== null || viewer_command_obj !== undefined)
                {
                    viewer_command_obj.command_to_viewer('viewers:switch');
                }
            }
        }
        MenuItem {
            id: menu_item_camera_close
            height: root.m_i_menu_height*root.isize
            //text: Language.getTranslate("Close camera", "Закрыть камеру") //"Закрыть камеру"
            Text{
                color: "black"
                text: Language.getTranslate("Close camera", "Закрыть камеру")
                font.pixelSize: 12*root.isize
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
            }
            onTriggered:
            {
              root.funcCloseCamera();
            }
        }
        MenuItem {
            id: menu_item_set_close
            height: root.m_i_menu_height*root.isize
            //text: Language.getTranslate("Close set", "Закрыть набор") //"Закрыть набор"
            Text{
                color: "black"
                text: Language.getTranslate("Close set", "Закрыть набор")
                font.pixelSize: 12*root.isize
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
            }
            onTriggered:
            {
              root.funcCloseSet();
            }
        }
        //ch90814 dvp
        MenuItem {
            id: menu_item_source_0
            //vart height: visible ? menu_item_return_to_realtime.height : 0
            height: visible2 ? root.m_i_menu_height*root.isize : 0
            //text: "x0"
            Text{
                color: "black"
                text: "x0"
                font.pixelSize: 12*root.isize
            }
            property bool visible2: false
            onTriggered:
            {
                univreaderex.switchSource( 0 );
            }
        }
        MenuItem {
            id: menu_item_source_1
            height: visible2 ? root.m_i_menu_height*root.isize : 0
            //ch00108 vart height: visible2 ? menu_item_return_to_realtime.height : 0
            //text: "x1"
            Text{
                color: "black"
                text: "x1"
                font.pixelSize: 12*root.isize
            }
            property bool visible2: false
            onTriggered:
            {
                univreaderex.switchSource( 1 );
            }
        }
        MenuItem {
            id: menu_item_source_2
            height: visible2 ? root.m_i_menu_height*root.isize : 0
            //text: "x2"
            Text{
                color: "black"
                text: "x2"
                font.pixelSize: 12*root.isize
            }
            property bool visible2: false
            onTriggered:
            {
                univreaderex.switchSource( 2 );
            }
        }
        MenuItem {
            id: menu_item_source_3
            height: visible2 ? root.m_i_menu_height*root.isize : 0
            //text: "x3"
            Text{
                color: "black"
                text: "x3"
                font.pixelSize: 12*root.isize
            }
            property bool visible2: false
            onTriggered:
            {
                univreaderex.switchSource( 3 );
            }
        }
        MenuItem {
            id: menu_item_source_4
            height: visible2 ? root.m_i_menu_height*root.isize : 0
            //text: "x4"
            Text{
                color: "black"
                text: "x4"
                font.pixelSize: 12*root.isize
            }
            property bool visible2: false
            onTriggered:
            {
                univreaderex.switchSource( 4 );
            }
        }
        MenuItem {
            id: menu_item_source_5
            height: visible2 ? root.m_i_menu_height*root.isize : 0
            //text: "x5"
            Text{
                color: "black"
                text: "x5"
                font.pixelSize: 12*root.isize
            }
            property bool visible2: false
            onTriggered:
            {
                univreaderex.switchSource( 5 );
            }
        }
        MenuItem {
            id: menu_item_source_6
            height: visible2 ? root.m_i_menu_height*root.isize : 0
            //text: "x6"
            Text{
                color: "black"
                text: "x6"
                font.pixelSize: 12*root.isize
            }
            property bool visible2: false
            onTriggered:
            {
                univreaderex.switchSource( 6 );
            }
        }
        //e
    }*/

    //ch00918

    //deb ch91029 otsech beg
    Timer {
        id: timer809
        interval: //ch91016 1000
                  500
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
                //vart2 root.nessActivateSoundAP();
                //ch00811
                if ('change_state_sound_checkbox' in root.m_pane_sound)
                    root.m_pane_sound.change_state_sound_checkbox(true)
            }

            /*ch91031 перенес в др компроонент
            var b_is_by_events_lv = univreaderex.getByEventsRecordState();
            root.m_b_is_by_events = b_is_by_events_lv;
            var b_state_lv = univreaderex.forceRecordCurrState();
            var b_visible_lv = false;
            if ( b_is_by_events_lv !==
                    ivButtonPane.m_force_write_ivibt_bpa.visible )
            {
              b_visible_lv = b_is_by_events_lv
            }
            if (
                    //ch91021 wndControlPanel.width < root.m_i_width_visible_bound3
                    root.isSmallMode()
                    )
                b_visible_lv = false;
            ivButtonPane.m_force_write_ivibt_bpa.visible = b_visible_lv;
            if ( b_is_by_events_lv )
            {
                if ( b_forceRecordCurrState !== b_state_lv )
                {
                    b_forceRecordCurrState = b_state_lv;
                    if ( b_forceRecordCurrState )
                        ivButtonPane.m_force_write_ivibt_bpa.on_source =
                          'file:///' + applicationDirPath + '/images/white/fiber.svg'
                    else
                        ivButtonPane.m_force_write_ivibt_bpa.on_source =
                          'file:///' + applicationDirPath + '/images/white/rec_off.svg'
                }
            }
            ch91031*/
            //ch91012 sliderEventActions();
            root.timerActions()
            iv_arc_slider_control.timerActionsSC()
        }
        //ch91012 function sliderEventActions()
        //ch91012 {
        //ch91012 univreaderex.m_i_timer_counter++;
        //ch91012 }
    }
    //ch230913 etot timer obslugivaet tolko obshuyu panel vrluchen
    //tolko dlya ojekta obshaya panel i pri regime obshei paneli e
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
            idLog3.warn('<210927> 516 ')
        }
    }

    //ch230913 etot timer obslugivaet tolko pereklyuchenie v realtime vkluchen vsegda e
    Timer {
        id: timer2309
        interval: 200
        running: true
        repeat: true
        onTriggered: {
            idLog3.warn('<common_pan> 00425 2 ' + root.key2 + " key3 " + root.key3
                        + ' common_panel ' + root.common_panel)

            if (false !== root.common_panel && 0 !== root.getCamCommonPanelMode()) {
                idLog3.warn('<common_pan> 00425 70 key2 '
                            + root.key2 + " common_panel " + common_panel +
                            " getCamCommonPanelMode " + root.getCamCommonPanelMode() )
                timer904.running = true
            }


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
            idLog3.warn('<210927> 516 2 ')
        }
    }
    // ch91029 otsech end

    //ch11103
    Timer {
        id: freqTimer
        triggeredOnStart: false
        interval: 4000
        repeat: false
        running: true
        onTriggered: {
            if (m_equal != null && m_equal != undefined)
                m_equal.running = Qt.binding(function () {
                    return (//ch11103 ivCreator.componentViewer.frameTime ===""
                            !root.m_s_is_video_present //e
                            && //ch11103 ivButtonPane.componentSound.is_audio
                            root.m_pane_sound.is_audio//e
                            ) && root.running
                })
        }
    }
    //e
    MouseArea {
        id: mousearea_CommonPanMode
        z: 99
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.left: parent.left

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        propagateComposedEvents: true
        property bool mouseOnPane910: false

        onEntered: {
            mousearea_CommonPanMode.mouseOnPane910 = true
            ivButtonTopPanel.mouseOnPane = true
        }
        onWheel: {
            //console.info("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ArcSlider");
            if (wheel.angleDelta.y > 0) {
                if (root.m_i_curr_scale < 7) {
                    //root.m_i_curr_scale += 1;
                    interv_lv.currentIndex += 1
                }
            } else {
                if (root.m_i_curr_scale > 1) {
                    //root.m_i_curr_scale -= 1;
                    interv_lv.currentIndex -= 1
                }
            }
        }
        /*Shortcut {
          sequence: StandardKey.ZoomIn //"Ctrl+Plus"
          onActivated: {
          }
      }

      Shortcut {
          sequence: StandardKey.ZoomOut //"Ctrl+Minus"
          onActivated: {
          }
      }*/
        onExited: {
            mousearea_CommonPanMode.mouseOnPane910 = false
            idLog3.warn('onExited 91026')
            //ch91023_3 ivButtonPane
            //ch91023_3 .mouseOnPane = false;

            //e

            //ch91102
            ivButtonTopPanel.mouseOnPane = false
            //e
        }
        onWidthChanged: {

            //idLog3.warn("<ArchivePlayer.qml> onWidthChanged mousearea_CommonPanMode.width = "+mousearea_CommonPanMode.width);
        }

        Rectangle {
            id: render_rct
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: wndControlPanel.height //root.m_i_c_control_panel_height
            anchors.left: parent.left
            anchors.right: parent.right
            color: "transparent"
            z: 1

            onWidthChanged: {
                var small_ppUpWidth = root.getSmallSizePanel()
                var normal_ppUpWidth = root.getNormalSizePanel()
                var common_panel_mode_ppUpWidth = root.getPanelSizeCommonPanelMode()
                var small_x = (parent.width / 2) - (small_ppUpWidth / 2)
                var normal_x = (parent.width / 2) - (normal_ppUpWidth / 2)
                var comm_panel_mode_x = (parent.width / 2) - (common_panel_mode_ppUpWidth / 2)

                idLog3.warn('<qarchiveplayer> render_rct onWidthChanged {')

                if (ppUp.x < 0) {
                    ppUp.x = 1
                }

                if (root.key2 !== "common_panel") {
                    if (ppUp.x === 1 && normal_ppUpWidth < render_rct.width) {
                        ppUp.x = (parent.width / 2) - (normal_ppUpWidth / 2)
                    } else if (ppUp.x === 1
                               && small_ppUpWidth < render_rct.width) {
                        ppUp.x = (parent.width / 2) - (small_ppUpWidth / 2)
                    }

                    idLog3.warn('<qarchiveplayer> onWidthChanged render_rct.width = '
                                + render_rct.width)

                    if (0 + ppUp.width > render_rct.width) {
                        idLog3.warn('<calendar> ppUp.x = ' + ppUp.x)

                        if (normal_x + normal_ppUpWidth < render_rct.width
                                && ppUp.width > normal_ppUpWidth) {
                            idLog3.warn('<qarchiveplayer> render_rct 2')
                            ppUp.width = normal_ppUpWidth
                            ppUp.x = normal_x
                            rectRevers_ivichb.visible = true
                            speed_ch_box_rec.visible = true
                            rectEvents_skip.visible = true
                            rectBmark_skip.visible = true
                            rectSelect_interval_ivibt.visible = true
                            sound_rect_rec_ButtonPane.visible = true
                            photo_cam_rec_ButtonPane.visible = true
                            image_corr_rec_ButtonPane.visible = true
                            small_mode_panel_ppUp = false
                            //rectPpupBackgr.color = "red";
                            idLog3.warn('<qarchiveplayer> render_rct 3')
                        } else if (small_x + small_ppUpWidth < render_rct.width
                                   && ppUp.width > small_ppUpWidth) {
                            idLog3.warn('<qarchiveplayer> render_rct 4')

                            rectRevers_ivichb.visible = false
                            speed_ch_box_rec.visible = false
                            rectEvents_skip.visible = false
                            rectBmark_skip.visible = false
                            rectSelect_interval_ivibt.visible = false
                            sound_rect_rec_ButtonPane.visible = false
                            photo_cam_rec_ButtonPane.visible = false
                            image_corr_rec_ButtonPane.visible = false
                            small_mode_panel_ppUp = true
                            ppUp.width = small_ppUpWidth
                            ppUp.x = small_x
                            //rectPpupBackgr.color = "green";
                            idLog3.warn('<qarchiveplayer> render_rct 5')
                        } else if (small_x + small_ppUpWidth > render_rct.width) {
                            //idLog3.warn('<qarchiveplayer> render_rct 6');
                            small_mode_panel_ppUp = false
                            ppUp.close()
                            //idLog3.warn('<qarchiveplayer> render_rct 7');
                        }

                        //idLog3.warn('<qarchiveplayer> render_rct 8');
                        //idLog3.warn('<calendar> revers_ivichb.visible after');
                    } else {
                        idLog3.warn('<calendar> ppUp.x2 = ' + ppUp.x)

                        if (normal_x + normal_ppUpWidth < render_rct.width) {
                            idLog3.warn('<qarchiveplayer> render_rct 10')
                            //speed_ch_box_rec.color="red"
                            ppUp.width = normal_ppUpWidth
                            ppUp.x = normal_x
                            rectRevers_ivichb.visible = true
                            speed_ch_box_rec.visible = true
                            rectEvents_skip.visible = true
                            rectBmark_skip.visible = true
                            rectSelect_interval_ivibt.visible = true
                            sound_rect_rec_ButtonPane.visible = true
                            photo_cam_rec_ButtonPane.visible = true
                            image_corr_rec_ButtonPane.visible = true
                            small_mode_panel_ppUp = false
                            //rectPpupBackgr.color = "pink";
                            idLog3.warn('<qarchiveplayer> render_rct 11')
                        } else if (small_x + small_ppUpWidth < render_rct.width) {
                            idLog3.warn('<qarchiveplayer> render_rct 12')

                            rectRevers_ivichb.visible = false
                            speed_ch_box_rec.visible = false
                            rectEvents_skip.visible = false
                            rectBmark_skip.visible = false
                            rectSelect_interval_ivibt.visible = false
                            sound_rect_rec_ButtonPane.visible = false
                            photo_cam_rec_ButtonPane.visible = false
                            image_corr_rec_ButtonPane.visible = false
                            small_mode_panel_ppUp = true
                            ppUp.width = small_ppUpWidth
                            ppUp.x = small_x
                            //rectPpupBackgr.color = "green";
                            idLog3.warn('<qarchiveplayer> render_rct 13')
                        }
                        idLog3.warn('<calendar> revers_ivichb.visible after1')
                    }
                } else {
                    ppUp.x = (parent.width / 2) - (common_panel_mode_ppUpWidth / 2)
                    ppUp.width = common_panel_mode_ppUpWidth
                    ppUp.x = comm_panel_mode_x
                }

                //idLog3.warn('<qarchiveplayer> render_rct 14');
                idLog3.warn('<qarchiveplayer> render_rct onWidthChanged }')
            }

            Rectangle {
                id: primitivesRect
                anchors.fill: parent
                color: 'transparent'
                //'red'
                z: 110

                property int frameLeft_905: render.frameLeft
                property int frameTop_905: render.frameTop
                property int frameRight_905: render.frameRight
                property int frameBottom_905: render.frameBottom
                Loader {
                    id: primitivesLoader
                    anchors.fill: primitivesRect

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
                                            return univreaderex.key3_urx
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
                            primitivesLoader.componentPrimitives.isRealtime = false
                        }
                        if (primitivesLoader.status === Loader.Error) {
                        }
                        if (primitivesLoader.status === Loader.Null) {

                        }
                    }
                }
                Loader {
                    id: equalizerLoader
                    anchors.fill: primitivesRect
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
                        asynchronous: false
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
                            if (viewer_command_obj !== null
                                    || viewer_command_obj !== undefined) {
                                viewer_command_obj.command_to_viewer(
                                            'viewers:fullscreen')
                            }
                            mouse.accept = true
                        } else {
                            mouse.accept = false
                        } //if
                    } //onDoubleClicked
                    onClicked: {

                        if (mouse.button & Qt.RightButton) {
                            root.callContextMenu907(mouseX, mouseY)
                            mouse.accept = true
                        } else {
                            mouse.accept = false
                        }
                    } //onClicked
                    onWheel: {
                        //console.info("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Render");
                        if (wheel.angleDelta.y > 0) {
                            if (root.m_i_curr_scale < 7) {
                                //root.m_i_curr_scale += 1;
                                interv_lv.currentIndex += 1
                            }
                        } else {
                            if (root.m_i_curr_scale > 1) {
                                //root.m_i_curr_scale -= 1;
                                interv_lv.currentIndex -= 1
                            }
                        }
                    }
                    onMouseXChanged: {
                        var ppUp_x = (parent.width / 2) - (ppUp.width / 2)
                        var ppUp_y = root.height - (section_909_rec.height + 60 * (root.isize))

                        if (root.arc_common_panel === false) {
                            if ((mouseX > ppUp_x)
                                    && (mouseX < (ppUp_x + ppUp.width))
                                    && (mouseY > ppUp_y)
                                    && (mouseY < (ppUp_y + ppUp.height))) {
                                if (!ppUp.opened) {
                                    var small_ppUpWidth = root.getSmallSizePanel()
                                    var small_x = (parent.width / 2) - (small_ppUpWidth / 2)

                                    if (small_x > 0 && !root.is_export_media) {
                                        ppUp.open()
                                    }
                                }
                            }
                        }
                    }

                    onMouseYChanged: {
                        var ppUp_x = (parent.width / 2) - (ppUp.width / 2)
                        var ppUp_y = parent.height - (section_909_rec.height + 60 * (root.isize))

                        if (root.arc_common_panel === false) {
                            if ((mouseX > ppUp_x)
                                    && (mouseX < (ppUp_x + ppUp.width))
                                    && (mouseY > ppUp_y)
                                    && (mouseY < (ppUp_y + ppUp.height))) {
                                if (!ppUp.opened) {
                                    var small_ppUpWidth = root.getSmallSizePanel()
                                    var small_x = (parent.width / 2) - (small_ppUpWidth / 2)

                                    if (small_x > 0 && !root.is_export_media) {
                                        ppUp.open()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            /*ch11112 vart
          Rectangle
          {
              id: equalizerRect
              anchors.fill: parent
              color: 'transparent'
              z: 111
          }
          */
            IVRender {
                id: render
                anchors.fill: parent
                trackFrame: {
                    var s_lv = ''
                    if (root.m_b_image_corrector_created)
                        s_lv = root.trackFrameAfterImageCorrectorRoot
                    else
                        s_lv = root.trackFrameAfterStabilizerRoot
                    return s_lv
                }
                trackCmd: univreaderex.trackCmd
                //ch90901 archive: true
                z: 80
            } //render
        } //renderrect

        //ch91102
        IVButtonTopPanel {
            id: ivButtonTopPanel
            anchors.top: parent.top
            mouseOnPane: false
            parentComponent: root
            m_idLog2_btp: idLog2
            m_idLog3_btp: idLog3
            //viewer_cmd_obj: root.viewer_command_obj
        }
        //e ch91102
        Rectangle {
            id: r910Rect
            anchors.fill: parent
            color: "transparent"
            //ch91024
            z: 5
            //e
            //ch91029  otsech beg
            opacity: ((//мышь навели на панель,
                       //тогда элементы становятся
                       //непрозрачными е
                       //ch91023_3 rootRect_ButtonPane.mouseOnPane
                       mousearea_CommonPanMode.mouseOnPane910 //e
                       || (//если у нас не общий режим, то делаем
                           //непрозрачными
                           0 === root.getCamCommonPanelModeUseSetPanel_Deb()
                           //и если не маленькое окно е
                           && //ch91021 wndControlPanel.width >= root.m_i_width_visible_bound3
                           !root.isSmallMode()) //ch00121
                       || root.common_panel//e
                       ) ? 1.0 : 0.0)

            // ch91029 otsech end
            //затеняет область с кнопками е
            onWidthChanged: {
                idLog3.warn('<calendar> onWidthChanged r910Rect width = ' + r910Rect.width)
            }

            Rectangle {
                id: r910_2Rect
                //CH91023 anchors.top: parent.top
                anchors.bottom: parent.bottom
                height: 32 //root.m_i_c_control_panel_height - 10
                anchors.left: parent.left
                anchors.right: parent.right
                color: "steelblue" //"brown"

                //ch91029 otsech beg
                opacity: ((//если мышь навели на область то не прозрачный,
                           //иначе- прозрачный
                           //ch91023_3 rootRect_ButtonPane.mouseOnPane
                           mousearea_CommonPanMode.mouseOnPane910 //e
                           && //если еще режим полной панели,  то становится не прзрачным
                           (0 !== root.getCamCommonPanelModeUseSetPanel_Deb(
                                ) //ср91018
                            //еще вариант - маленькая панель
                            || //ch91021 wndControlPanel.width < root.m_i_width_visible_bound3
                            root.isSmallMode()//e
                            ) //ch00121
                           && !(root.common_panel)//e
                           ) ? 0.7 : 0.0)
                // ch91029 otsech end
                RowLayout {
                    id: panel_mode_common_panel
                    height: parent.height
                    width: 6 * (24 * root.isize) + (spacing * 6)
                    layoutDirection: Qt.LeftToRight
                    anchors.right: parent.right
                    spacing: 2

                    Rectangle {
                        id: rect_export_media
                        width: 24 * root.isize
                        height: 24 * root.isize
                        color: "transparent"
                        //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
                        IVImageButton {
                            id: export_media_button
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.fill: rect_export_media
                            size: "normal"
                            txt_tooltip: Language.getTranslate(
                                             "export to AVI, MKV",
                                             "экспорт в AVI, MKV") //"экспорт в AVI, MKV"
                            on_source: 'file:///' + applicationDirPath
                                       + '/images/white/archSave.svg'
                            visible: false
                            onClicked: {
                                export_mediaLoader.create()
                            }

                            Loader {
                                id: export_mediaLoader
                                property var componentExport_avi: null
                                function create() {
                                    if (export_mediaLoader.status !== Loader.Null)
                                        export_mediaLoader.source = ""
                                    var qmlfile = "file:///" + applicationDirPath
                                            + '/qtplugins/iv/viewers/archiveplayer/qmainexport.qml'
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
                                        export_mediaLoader.componentExport_avi
                                                = export_mediaLoader.item
                                        root.m_v_component_main_export
                                                = export_mediaLoader.componentExport_avi

                                        idLog3.warn('<' + root.key2 + '_' + root.key3
                                                    + '>' + 'onBindings 180110')

                                        var s_begin_lv = ''
                                        var s_end_lv = ''
                                        var s_zna_ip_lv = ''

                                        idLog2.warn('onBindings 180110')

                                        if (0 === root.m_uu_i_ms_begin_interval) {
                                            s_begin_lv = univreaderex.intervTime2(
                                                        0)
                                            idLog3.warn('unload_to_avi_ivibt clicked time before '
                                                        + root.end)

                                            if ('' === root.end) {
                                                s_end_lv = univreaderex.addDeltaTime(
                                                            univreaderex.intervTime2(
                                                                0), 120000)
                                                idLog3.warn('<' + root.key2 + '_' + root.key3 + '>' + 'unload_to_avi_ivibt clicked end after ' + s_end_lv)
                                            } else
                                                s_end_lv = root.end
                                        } else {
                                            s_begin_lv = univreaderex.uu64ToHumanEv(
                                                        root.m_uu_i_ms_begin_interval,
                                                        3)
                                            s_end_lv = univreaderex.uu64ToHumanEv(
                                                        root.m_uu_i_ms_end_interval,
                                                        3)
                                        }
                                        root.safeSetProperty(
                                                    export_mediaLoader.componentExport_avi,
                                                    'key2',
                                                    Qt.binding(function () {
                                                        return root.key2
                                                    }))
                                        ////////////mwork begin
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
                                        ;
                                        ////////////////////mwork end
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
                                        //ch00708
                                        if (0 !== root.m_s_start_event_id
                                                && '' !== root.m_s_start_event_id) {
                                            root.safeSetProperty(
                                                        export_mediaLoader.componentExport_avi,
                                                        'evtid',
                                                        Qt.binding(function () {
                                                            return root.m_s_start_event_id
                                                        }))
                                        }
                                        //ch221021
                                        //получим из c++ e
                                        s_zna_ip_lv = univreaderex.getSelectedZnaIp()

                                        idLog3.warn("<select_source> export_mediaLoader onStatusChanged s_zna_ip_lv " + s_zna_ip_lv)
                                        root.safeSetProperty(
                                                    export_mediaLoader.componentExport_avi,
                                                    'selected_zna_ip',
                                                    Qt.binding(function () {
                                                        return s_zna_ip_lv
                                                    }))

                                        idLog3.warn('<unload> onBindings from ' + export_mediaLoader.componentExport_avi.from + ' to ' + export_mediaLoader.componentExport_avi.to + ' evtid ' + root.m_s_start_event_id)

                                        export_mediaLoader.componentExport_avi.parent_arc_obj
                                                = sel_interv
                                    }
                                }
                            }
                        } //im but
                    } //rect

                    Rectangle {
                        id: rect_sound
                        width: 24 * root.isize
                        height: 24 * root.isize
                        color: "transparent"
                        Loader {
                            id: sound_Loader
                            anchors.fill: rect_sound
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
                                if (false === root.isCommonPanel()) {
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
            //e ch91111
            //ch91023 cпрятал под е
            Rectangle {
                id: rootRect
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                color: "transparent" //"darksalmon"
                z: 97

                onWidthChanged: {
                    idLog3.warn('<calendar> onWidthChanged rootRect width = ' + rootRect.width)
                }

                Loader {
                    id: select_intervalLoader
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
                            select_intervalLoader.componentSelect_interval.key2
                                    = root.key2 // просто присвоение свойства
                            select_intervalLoader.componentSelect_interval.begin
                                    = root.m_uu_i_ms_begin_interval
                            select_intervalLoader.componentSelect_interval.end
                                    = root.m_uu_i_ms_end_interval

                            select_intervalLoader.componentSelect_interval.parent_qml
                                    = 'IVArchivePlayer.qml'
                            select_intervalLoader.componentSelect_interval.select_interv
                                    = sel_interv


                            //                            select_intervalLoader.componentSelect_interval.id777 = Qt.binding(function(){
                            //                                return root.m_s_exch_event_id;
                            //                            });
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
                    height: 32
                    width: parent.width
                    z: 85

                    onWidthChanged: {
                        univreaderex.putLog807('onWidthChanged ')

                        idLog3.warn('<calendar> onWidthChanged wndControlPanel width = '
                                    + wndControlPanel.width)

                        if (root.common_panel) {
                            root.commonPanelExtButtonsSetVisible(false)
                        } else if (0 !== root.getCamCommonPanelModeUseSetPanel_Deb(
                                       )) {
                            root.commonPanelExtButtonsSetVisible(false)
                        } else {
                            //ch91021 width < root.m_i_width_visible_bound3
                            if (root.isSmallMode()) {
                                idLog3.warn('onWidthChanged vis false before')
                                //univreaderex.putLog807( 'onWidthChanged vis false' );
                                //iv_arc_slider_control.setLabelsVisible( false, true, true );

                                //e ch91111
                                //ch91024 -wndControlPanel.height;
                                //deb root.m_i_c_control_panel_height;
                                //e
                                //e
                                render_rct.anchors.bottomMargin = 0

                                //ch91021_2
                                section_909_rec_high.anchors.topMargin = 67 //65

                                //wndControlPanel.anchors.bottomMargin = 13;//10
                                left_paging_ivibt.anchors.topMargin = 31 //20
                                //left_paging_ivibt.anchors.leftMargin = 0;
                                right_paging_ivibt.anchors.topMargin = 31 //20
                                //e

                                //ch91202
                                //ch91203_4 mousearea_CommonPanMode.enabled = true;
                                //e
                                idLog3.warn('onWidthChanged vis false after')
                            } else {
                                idLog3.warn('onWidthChanged vis true before')
                                //univreaderex.putLog807(
                                //  'onWidthChanged vis true ' +
                                //  ' width ' + width + ', m_i_width_visible_bound3 ' +
                                //  root.m_i_width_visible_bound3 );
                                //iv_arc_slider_control.setLabelsVisible( true, true, true );
                                //ch91024 0;
                                render_rct.anchors.bottomMargin = root.m_i_c_control_panel_height
                                //ch91021_2
                                section_909_rec_high.anchors.topMargin = 0
                                wndControlPanel.anchors.bottomMargin = 0

                                left_paging_ivibt.anchors.topMargin = c_I_ELEM_VERTIC_OFFSET_909
                                left_paging_ivibt.anchors.leftMargin = 0
                                right_paging_ivibt.anchors.topMargin = c_I_ELEM_VERTIC_OFFSET_909

                                //ch91202
                                //ch91203_2 mousearea_CommonPanMode.enabled = false;
                                //e
                                idLog3.warn('onWidthChanged vis true after')
                            }
                        }
                    }
                    //ch91029 otsech end
                    Rectangle {
                        id: section_909_rec
                        visible: !root.common_panel
                        anchors.left: parent.left
                        height: parent.height
                        width: parent.width
                        color: "steelblue"
                        anchors.verticalCenter: parent.verticalCenter

                        onWidthChanged: {
                            idLog3.warn('<calendar> onWidthChanged section_909_rec width = '
                                        + section_909_rec.width)
                        }

                        IVImageButton {
                            id: left_paging_ivibt
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            size: "normal"
                            txt_tooltip: Language.getTranslate(
                                             "previous period",
                                             "предыдущий период") //"предыдущий период"
                            on_source: 'file:///' + applicationDirPath
                                       + '/images/white/playback.svg'
                            onClicked: {
                                univreaderex.setDelta709(-1)
                                //ch00429 deb
                                //e
                            }
                        }
                        IVImageButton {
                            id: right_paging_ivibt
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.rightMargin: 0
                            size: "normal"
                            txt_tooltip: Language.getTranslate(
                                             "next period",
                                             "последующий период") //"последующий период"
                            on_source: 'file:///' + applicationDirPath + '/images/white/play.svg'
                            onClicked: {
                                univreaderex.setDelta709(1)
                            }
                        }
                        Rectangle {
                            id: section_909_rec_high
                            anchors.left: left_paging_ivibt.right
                            anchors.top: parent.top
                            height: 0
                            //ch91112 34
                            //root.m_i_c_control_panel_high_part_height
                            width: 0 //parent.width
                            //color: "transparent"
                            color: "cadetblue"
                            //ch91111 color: "#666666"
                            //e
                            visible: true

                            //ch91002 перенес в главный Image {
                            //ch91002 перенес в главный id: imageSlider
                            //e
                        } //section_909_rec

                        //ch91029 otsech beg
                        //вставляется в место, где раньше было содержимое компонента.
                        //ch90617
                        IVArcSliderControl {
                            id: iv_arc_slider_control

                            //ch90919 vart anchors.fill: parent
                            //ch90919
                            anchors.left: left_paging_ivibt.right
                            anchors.right: right_paging_ivibt.left
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 0
                            width: parent.width - 12
                            implicitHeight: 32
                            visible: true
                            m_univreaderex_asc: univreaderex
                            m_idLog2_asc: idLog2
                            m_idLog3_asc: idLog3

                            m_root_asc: root
                            m_upload_left_bound_lb_asc: upload_left_bound_lb
                            m_upload_left_bound_2_lb_asc: upload_left_bound_2_lb
                            m_r_width_909: iv_arc_slider_control.width

                            m_imageSlider_asc: imageSlider
                            image: imageSlider_1
                            m_timer_finish_preview: timer_finish_preview

                            m_event_select_rct_hint_asc: event_select_rct_hint
                            m_event_select_rct_hint_text_asc: event_select_rct_hint_text
                            m_popup_scale_intervals: ppUp2

                            //m_event_select_rct_asc: event_select_rct

                            //ch91010_3 m_imageSlider_CONT_asc: imageSlider_CONT
                            onSlidermouseEntered: {
                                if (root.common_panel === true
                                        && root.arc_common_panel === true) {
                                    if (!ppUp.opened) {
                                        if (ppUp.x + ppUp.width < render_rct.width) {
                                            var small_ppUpWidth = root.getSmallSizePanel()
                                            var small_x = (parent.width / 2) - (small_ppUpWidth / 2)
                                            ppUp.closePolicy = Popup.CloseOnEscape
                                                    | Popup.CloseOnPressOutsideParent
                                                    | Popup.CloseOnPressOutside
                                            if (small_x > 0 && !root.is_export_media) {
                                                ppUp.open()
                                            }
                                        }
                                    }
                                } else if (root.common_panel === false
                                           && arc_common_panel === false) {
                                    if (!ppUp.opened) {
                                        if (ppUp.x + ppUp.width < render_rct.width) {
                                            ppUp.closePolicy = Popup.CloseOnEscape
                                                    | Popup.CloseOnPressOutsideParent
                                                    | Popup.CloseOnPressOutside
                                            if (!root.is_export_media)
                                                ppUp.open()
                                        }
                                    }
                                }
                            }
                        }

                        Popup {
                            id: ppUp
                            focus: true
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
                                         | Popup.CloseOnPressOutside
                            x: (parent.width / 2) - (ppUp.width / 2)
                            y: parent.height - (section_909_rec.height + 60 * (root.isize))
                            width: 650
                            height: 40 * root.isize
                            padding: 0

                            onXChanged: {

                                //if (ppUp.x < 0)
                                //{
                                //    ppUp.x = 0;
                                //}
                            }

                            Component.onCompleted: {

                            }

                            background: Rectangle {
                                id: rectPpupBackgr
                                //width:ppUp.width
                                //height:ppUp.height
                                anchors.fill: parent
                                color: "steelblue"
                                opacity: 0.5
                                clip: true
                                radius: 3
                            }

                            RowLayout {
                                id: ppUpRowLayout
                                //spacing: 2
                                //width: rootRect_ButtonPane.width
                                //parent
                                //.width/2
                                height: parent.height
                                width: ppUp.width
                                layoutDirection: Qt.LeftToRight
                                spacing: 2

                                Rectangle {
                                    id: rectCalendarTime
                                    width: calend_time.width
                                    height: calend_time.height
                                    color: "transparent"

                                    CalendarTimeComponents {
                                        id: calend_time
                                        anchors.fill: rectCalendarTime
                                        _height: 24 * root.isize
                                        chosenDate: '05.11.2018'
                                        color: "transparent"
                                        size: "normal"
                                        btn_color: "white"

                                        onDateChanged2: {
                                            if (!root.b_input_time_outside_cahange) {
                                                idLog3.warn('<calendar> onDateChanged bef updateTime811() 2')
                                                //ch00708
                                                univreaderex.fillCalendarCommand(
                                                            start, end)
                                                //e
                                                //ch00709 updateTime811();
                                            }
                                        }
                                        onDateChanged: {
                                            if (!root.b_input_time_outside_cahange) {
                                                idLog3.warn('<calendar> onDateChanged bef updateTime811()')
                                                updateTime811()
                                            }
                                        }
                                        onCalendarOpened: {
                                            idLog3.warn('<calendar> onCalendarOpened start '
                                                        + start + ' end ' + end)
                                            univreaderex.fillCalendarCommand(
                                                        start, end)
                                        }
                                        onMonthChanged: {
                                            idLog3.warn('<calendar> onMonthChanged start '
                                                        + start + ' end ' + end)
                                            univreaderex.fillCalendarCommand(
                                                        start, end)
                                        }
                                        onYearChanged: {
                                            idLog3.warn('<calendar> onYearChanged start '
                                                        + start + ' end ' + end)
                                            univreaderex.fillCalendarCommand(
                                                        start, end)
                                        }

                                        onTimeChanged: {
                                            if (!root.b_input_time_outside_cahange) {
                                                idLog3.warn('<calendar> onTimeChanged bef updateTime811_Causing1()')
                                                updateTime811_Causing1()
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: rectPlay_ivichb
                                    width: 24 * root.isize
                                    height: 24 * root.isize
                                    color: "transparent"

                                    IVImageCheckbox {
                                        id: play_ivichb
                                        anchors.fill: rectPlay_ivichb
                                        size: "normal"
                                        txt_tooltip: Language.getTranslate(
                                                         "Archive playback",
                                                         "Проигрывание архива") //"проигрывание архива"
                                        on_source: 'file:///' + applicationDirPath
                                                   + '/images/white/pause.svg'
                                        off_source: 'file:///' + applicationDirPath
                                                    + '/images/white/play.svg'
                                        onClicked: {

                                            //ch230323 temp deb тест для slider new
                                            /*
                                        idLog3.warn('<slider_new> 2' );
                                        var i_uu_64_delta_lv = 10000000;
                                        var i_uu_64_frame_time_2303_lv =
                                          univreaderex.getFrameTimeUUI64();
                                        if ( i_uu_64_frame_time_2303_lv > 5 * i_uu_64_delta_lv  )
                                        var i_uu_64_beg_2303_lv =
                                          i_uu_64_frame_time_2303_lv - i_uu_64_delta_lv;
                                        var i_uu_64_end_2303_lv =
                                          i_uu_64_frame_time_2303_lv + i_uu_64_delta_lv;
                                        univreaderex.intervalSliderNewRefresh(
                                          i_uu_64_beg_2303_lv, i_uu_64_end_2303_lv );
                                        /**/
                                            //e
                                            idLog3.warn('<cmd> play_ivichb onClicked key2 '
                                                        + root.key2)
                                            idLog3.warn('<cmd> savedSetName ' + root.savedSetName)
                                            idLog3.warn('<cmd> savedSetName 2 ')
                                            root.funcPlayCommand2202()
                                        }
                                    }
                                }

                                Rectangle {
                                    id: rectRevers_ivichb
                                    width: 24 * root.isize
                                    height: 24 * root.isize
                                    color: "transparent"

                                    IVImageCheckbox {
                                        id: revers_ivichb
                                        anchors.fill: rectRevers_ivichb
                                        size: "normal"
                                        txt_tooltip: Language.getTranslate(
                                                         "play back",
                                                         "проигрывать назад") //"проигрывать назад"

                                        property bool visible2: true
                                        property bool visible3: true
                                        visible: visible2 && visible3

                                        on_source: 'file:///' + applicationDirPath
                                                   + '/images/white/reward.svg'
                                        off_source: ''
                                        onClicked: {

                                            //ch230323 temp deb тест для slider new
                                            /*
                                        idLog3.warn('<slider_new> 3' );
                                        var i_uu_64_beg_2303_lv =
                                          univreaderex.uuIMSBeginInterval();
                                        var i_uu_64_end_2303_lv =
                                          univreaderex.uuIMSEndInterval();
                                        root.testGetIntervals(
                                            i_uu_64_beg_2303_lv, i_uu_64_end_2303_lv );
                                        /**/
                                            //e
                                            if (chkd) {
                                                if (play_ivichb.chkd) {
                                                    //ch00505 root.cmd = 'play_backward';
                                                    univreaderex.setCmd005(
                                                                'play_backward')
                                                }
                                                txt_tooltip = Language.getTranslate(
                                                            "play ahead",
                                                            "проигрывать вперед") //"проигрывать вперед"
                                            } else {
                                                if (play_ivichb.chkd) {
                                                    //ch00505 root.cmd = 'play';
                                                    univreaderex.setCmd005(
                                                                'play')
                                                }
                                                txt_tooltip = Language.getTranslate(
                                                            "play back",
                                                            "проигрывать назад") //"проигрывать назад"
                                            }
                                            ;
                                        }
                                    }
                                }

                                Rectangle {
                                    id: speed_ch_box_rec
                                    height: 24 * root.isize
                                    width: 24 * root.isize
                                    color: "transparent"

                                    IVSpeedSlider {
                                        id: iv_speed_slider
                                        speed: 1
                                        //btn_color:
                                        //"red"
                                        //ch90913 rootRect
                                        //section_909_rec_high_phone
                                        //  .color
                                        //'#666666'
                                        //'yellow'
                                        size: "normal"
                                        anchors.verticalCenter: parent.verticalCenter

                                        property bool visible2: true
                                        property bool visible3: true
                                        visible: visible2 && visible3

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
                                } //speed_ch_box_rec

                                Rectangle {
                                    id: rectEvents_skip
                                    width: iv_butt_spb_events_skip.width
                                    height: iv_butt_spb_events_skip.height
                                    color: "transparent"

                                    IVButtonSpinbox {
                                        id: iv_butt_spb_events_skip

                                        size: root.isize <= 1 ? "small" : root.isize > 1
                                                                && root.isize < 2 ? "normal" : "big"
                                        btn_color: "white"
                                        left_tooltip: Language.getTranslate(
                                                          "Go to previous event",
                                                          "Перейти к предыдущему событию") //"Перейти к предыдущему событию"
                                        center_tooltip: Language.getTranslate(
                                                            "Events",
                                                            "События") //"События"
                                        right_tooltip: Language.getTranslate(
                                                           "Go to next event",
                                                           "Перейти к следующему событию") //"Перейти к следующему событию"
                                        left_src: 'arrow_left.svg'
                                        center_src: 'thunder.svg'
                                        right_src: 'arrow_right.svg'
                                        anchors.fill: rectEvents_skip

                                        //z: 0
                                        property bool visible2: true
                                        property bool visible3: true
                                        property bool visible4: true
                                        visible: move_to_event.isAllowed
                                                 && visible2 && visible3
                                                 && visible4
                                        //ch91112 deb
                                        onVisibleChanged: {
                                            idLog3.warn(' iv_butt_spb_events_skip onVisibleChanged isAllowed ' + move_to_event.isAllowed + ' visible2 ' + visible2 + ' visible3 ' + visible3 + ' visible4 ' + visible4 + ' visible ' + visible)
                                        }
                                        //e
                                        onLeftClick: {
                                            var pt_mapped_pos_lv = null
                                            pt_mapped_pos_lv = mapToItem(root,
                                                                         x, y)
                                            idLog3.warn(' onVisibleChanged x ' + x + ' pt_mapped_pos_lv.x ' + pt_mapped_pos_lv.x + ' width ' + width + ' y ' + y + ' pt_mapped_pos_lv.y ' + pt_mapped_pos_lv.y + ' height ' + height)
                                            //ch90917 rootRect_ButtonFullPaneArc
                                            root.moveToEventBySlider_Causing1(
                                                        false, false,
                                                        //ch91112_2 x, y
                                                        pt_mapped_pos_lv.x,
                                                        pt_mapped_pos_lv.y + height)
                                            if (!popUpUpload_left_bound_rect.opened) {
                                                popUpUpload_left_bound_rect.open()
                                            }
                                        }
                                        onCenterClick: {

                                        }
                                        onRightClick: {
                                            var pt_mapped_pos_lv = null
                                            pt_mapped_pos_lv = mapToItem(root,
                                                                         x, y)
                                            idLog3.warn(' onVisibleChanged x ' + x + ' pt_mapped_pos_lv.x ' + pt_mapped_pos_lv.x + ' width ' + width + ' y ' + y + ' pt_mapped_pos_lv.y ' + pt_mapped_pos_lv.y + ' height ' + height)

                                            //ch90918 rootRect_ButtonFullPaneArc
                                            root.moveToEventBySlider_Causing1(
                                                        true, false, //ch00520 x
                                                        pt_mapped_pos_lv.x //e
                                                        + (2 * width / 5),
                                                        //ch00520 y
                                                        pt_mapped_pos_lv.y //e
                                                        + height)
                                            if (!popUpUpload_left_bound_rect.opened) {
                                                popUpUpload_left_bound_rect.open()
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: rectBmark_skip
                                    width: iv_butt_spb_bmark_skip.width
                                    height: iv_butt_spb_bmark_skip.height
                                    color: "transparent"

                                    IVButtonSpinbox {
                                        id: iv_butt_spb_bmark_skip

                                        size: root.isize <= 1 ? "small" : root.isize > 1
                                                                && root.isize < 2 ? "normal" : "big"
                                        btn_color: "white"
                                        left_tooltip: Language.getTranslate(
                                                          "Go to previous mark",
                                                          "Перейти к предыдущей метке") //"Перейти к предыдущей метке"
                                        center_tooltip: Language.getTranslate(
                                                            "Marks",
                                                            "Метки") //"Метки"
                                        right_tooltip: Language.getTranslate(
                                                           "Go to next mark",
                                                           "Перейти к следующей метке") //"Перейти к следующей метке"
                                        left_src: 'arrow_left.svg'
                                        center_src: 'bookmark.svg'
                                        right_src: 'arrow_right.svg'
                                        //ch91112 связано с режимом общ панели
                                        property bool visible2: true
                                        //ch91112 от изменения размера е
                                        property bool visible3: true
                                        //ср91112 от настройки пользователя, показывать ли
                                        property bool visible4: true
                                        anchors.fill: rectBmark_skip
                                        visible: move_to_bmark.isAllowed
                                                 && visible2 && visible3
                                                 && visible4
                                        onLeftClick: {

                                            var pt_mapped_pos_lv = null
                                            pt_mapped_pos_lv = mapToItem(root,
                                                                         x, y)
                                            idLog3.warn(' onVisibleChanged x ' + x + ' pt_mapped_pos_lv.x ' + pt_mapped_pos_lv.x + ' width ' + width + ' y ' + y + ' pt_mapped_pos_lv.y ' + pt_mapped_pos_lv.y + ' height ' + height)

                                            //ch90918 rootRect_ButtonFullPaneArc
                                            root.moveToEventBySlider_Causing1(
                                                        false, true,
                                                        //ср00528 x, y
                                                        pt_mapped_pos_lv.x,
                                                        pt_mapped_pos_lv.y + height)
                                            if (!popUpUpload_left_bound_rect.opened) {
                                                popUpUpload_left_bound_rect.open()
                                            }
                                        }
                                        onCenterClick: {

                                        }
                                        onRightClick: {


                                            //ch00109 deb
                                            //var t1 = 0;
                                            //t1 = rootRect_ButtonPane.getFrameTime();
                                            //idLog3.warn( '<photocam> t1 ' + t1 );
                                            //e
                                            var pt_mapped_pos_lv = null
                                            pt_mapped_pos_lv = mapToItem(root,
                                                                         x, y)
                                            idLog3.warn(' onVisibleChanged x ' + x + ' pt_mapped_pos_lv.x ' + pt_mapped_pos_lv.x + ' width ' + width + ' y ' + y + ' pt_mapped_pos_lv.y ' + pt_mapped_pos_lv.y + ' height ' + height)

                                            //ch90918rootRect_ButtonFullPaneArc
                                            root.moveToEventBySlider_Causing1(
                                                        true, true, //ср00528 x
                                                        pt_mapped_pos_lv.x + (2 * width / 5),
                                                        //ср00528 y
                                                        pt_mapped_pos_lv.y + height)
                                            if (!popUpUpload_left_bound_rect.opened) {
                                                popUpUpload_left_bound_rect.open()
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: rectSelect_interval_ivibt
                                    width: 24 * root.isize
                                    height: 24 * root.isize
                                    visible: can_export_acc.isAllowed
                                    color: "transparent"

                                    IVImageButton {
                                        id: select_interval_ivibt
                                        property bool visible2: true
                                        property bool visible3: true
                                        visible: can_export_acc.isAllowed && visible2 && visible3
                                        size: "normal"
                                        _width: 24
                                        txt_tooltip: root.m_s_tooltip_select_interv_1
                                        anchors.fill: rectSelect_interval_ivibt
                                        on_source: 'file:///' + applicationDirPath
                                                   + '/images/white/flag_left.svg'

                                        Loader {
                                            id: menuLoaderSelInterv
                                            //anchors.fill: parent
                                            asynchronous: false
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
                                                var qmlFile2 = 'file:///' + applicationDirPath + '/qtplugins/iv/ivcontextmenurealtime/IVContextMenuRealtime.qml'
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
                                                    menuLoaderSelInterv.componentMenu
                                                            = menuLoaderSelInterv.item
                                                    //console.error("<<<<<<<<<<<<<<<<<<<<<<<<< menuLoaderSelInterv.componentMenu Loader.Ready");
                                                }
                                                if (menuLoaderSelInterv.status === Loader.Error) {

                                                    //console.error("menuLoaderSelInterv.componentMenu error");
                                                }
                                                if (menuLoaderSelInterv.status === Loader.Null) {

                                                }
                                            }
                                        }

                                        onClicked: {

                                            var i_uu_new_interv_time_lv = 0
                                            if (root.c_I_IS_FIERST_SELECT_INTERV
                                                    === root.m_i_select_interv_state) {
                                                //ch00413
                                                if (0 !== univreaderex.isFrameCounterCorrespondCommand(
                                                            ))
                                                    root.drawStartInterval()
                                                else {
                                                    //ch00608
                                                    //ch00608 univreaderex.setDelaySetStartInterval( 1 );
                                                    root.drawStartIntervalByCommand()
                                                    //e
                                                }
                                                ;
                                            } else if (root.c_I_IS_SECOND_SELECT_INTERV
                                                       === root.m_i_select_interv_state) {

                                                //ch90801 Sm_root_bpa.
                                                //positioningMenu()
                                                //menu_item_change.visible = true;
                                                //menu_item_select_interval_left.visible = false;
                                                //menu_item_select_interval_right.visible = false;
                                                //menu_item_go_to_begin.visible = false;
                                                //menu_item_go_to_end.visible = false;
                                                //menu_item_save_interval.visible = false;
                                                //menu_item_call_unload_window.visible = false;
                                                //menu_item_unload.visible = false;
                                                menuLoaderSelInterv.menu_item_select_interval_right_visible = false
                                                menuLoaderSelInterv.menu_item_select_interval_left_visible = false
                                                menuLoaderSelInterv.menu_item_change_visible = true
                                                menuLoaderSelInterv.menu_item_go_to_begin_visible
                                                        = false
                                                menuLoaderSelInterv.menu_item_go_to_end_visible
                                                        = false
                                                menuLoaderSelInterv.menu_item_save_interval_visible
                                                        = false
                                                menuLoaderSelInterv.menu_item_call_unload_window_visible = false
                                                menuLoaderSelInterv.menu_item_unload_visible = false

                                                //onClicked: menu_interval2.open();
                                                onClicked: {
                                                    menuLoaderSelInterv.componentMenu._clearMenu()

                                                    if (menuLoaderSelInterv.menu_item_select_interval_left_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcSelectInterval_left,
                                                                    Language.getTranslate(
                                                                        "Change left border",
                                                                        "Изменить левую границу"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_select_interval_right_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcSelectInterval_right,
                                                                    Language.getTranslate(
                                                                        "Change right border",
                                                                        "Изменить правую границу"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_change_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcChange,
                                                                    Language.getTranslate(
                                                                        "Change Interval",
                                                                        "Изменить интервал"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_go_to_begin_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcGo_to_begin,
                                                                    Language.getTranslate(
                                                                        "Go to begin",
                                                                        "Перейти к началу"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_go_to_end_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcGo_to_end,
                                                                    Language.getTranslate(
                                                                        "Go to end",
                                                                        "Перейти к концу"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_save_interval_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcSave_interval,
                                                                    Language.getTranslate(
                                                                        "Save interval",
                                                                        "Сохранить интервал"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_call_unload_window_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcCall_Unload_window,
                                                                    Language.getTranslate(
                                                                        "Open export window",
                                                                        "Открыть окно выгрузки"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_unload_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcUnload,
                                                                    Language.getTranslate(
                                                                        "Export",
                                                                        "Выгрузить"),
                                                                    true, "")
                                                    }
                                                    menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                root.funcReset_selection,
                                                                Language.getTranslate(
                                                                    "Reset selection",
                                                                    "Сбросить выделение"),
                                                                true, "")

                                                    positioningMenu()

                                                    //console.info("menuLoaderSelInterv.componentMenu.x = ", menuLoaderSelInterv.componentMenu.x);
                                                    //console.info("menuLoaderSelInterv.componentMenu.y = ", menuLoaderSelInterv.componentMenu.y);

                                                    //menuLoaderSelInterv.componentMenu.x = rl_mouse_x_av;
                                                    //menuLoaderSelInterv.componentMenu.y = rl_mouse_y_av;
                                                    var menuPoint = mapToItem(
                                                                Window.window.contentItem,
                                                                menuLoaderSelInterv.componentMenu.x,
                                                                menuLoaderSelInterv.componentMenu.y)
                                                    if (menuPoint.y + menuLoaderSelInterv.componentMenu.height >= Window.window.height) {
                                                        menuLoaderSelInterv.componentMenu.y -= (menuPoint.y + menuLoaderSelInterv.componentMenu.height - Window.window.height)
                                                    }
                                                    menuLoaderSelInterv.componentMenu.side = 'right'
                                                    if (menuPoint.x + menuLoaderSelInterv.componentMenu.width + menuLoaderSelInterv.componentMenu.width >= Window.window.width) {
                                                        menuLoaderSelInterv.componentMenu.side
                                                                = 'left'
                                                    }

                                                    if (menuPoint.x + menuLoaderSelInterv.componentMenu.width > Window.window.width - 20) {
                                                        menuLoaderSelInterv.componentMenu.x -= (menuPoint.x + menuLoaderSelInterv.componentMenu.width - Window.window.width + 20)
                                                    }
                                                    menuLoaderSelInterv.componentMenu._open()
                                                }
                                                //vart onClicked: menu_interval.popup(mouseX, mouseY)
                                            } else if (root.c_I_IS_CORRECT_INTERV
                                                       === root.m_i_select_interv_state) {

                                                //вызовем меню е
                                                //positioningMenu()
                                                //menu_item_change.visible = false;
                                                //menu_item_select_interval_left.visible = true;
                                                //menu_item_select_interval_right.visible = true;
                                                //menu_item_go_to_begin.visible = true;
                                                //menu_item_go_to_end.visible = true;
                                                //menu_item_save_interval.visible = true;
                                                //menu_item_unload.visible = true;
                                                //menu_item_unload.visible = false;
                                                //menu_item_call_unload_window.visible = true;
                                                menuLoaderSelInterv.menu_item_select_interval_right_visible = true
                                                menuLoaderSelInterv.menu_item_select_interval_left_visible = true
                                                menuLoaderSelInterv.menu_item_change_visible = true
                                                menuLoaderSelInterv.menu_item_go_to_begin_visible
                                                        = true
                                                menuLoaderSelInterv.menu_item_go_to_end_visible
                                                        = true
                                                menuLoaderSelInterv.menu_item_save_interval_visible
                                                        = true
                                                menuLoaderSelInterv.menu_item_call_unload_window_visible = true
                                                menuLoaderSelInterv.menu_item_unload_visible = true

                                                idLog3.warn("<interv> getFrameTimeUUI64 "
                                                            + univreaderex.getFrameTimeUUI64(
                                                                ) + " m_uu_i_ms_begin_interval " + root.m_uu_i_ms_begin_interval + " m_uu_i_ms_end_interval " + root.m_uu_i_ms_end_interval)

                                                //если границы не поменялись то не отобр пункты
                                                //изменения интервала
                                                if (0 !== univreaderex.isFrameCounterCorrespondCommand(
                                                            ))
                                                    i_uu_new_interv_time_lv
                                                            = univreaderex.getFrameTimeUUI64()
                                                else
                                                    i_uu_new_interv_time_lv
                                                            = univreaderex.getCommandTimeUUI64()
                                                if (Math.abs(
                                                            i_uu_new_interv_time_lv
                                                            - root.m_uu_i_ms_begin_interval) < 500
                                                        || Math.abs(
                                                            i_uu_new_interv_time_lv
                                                            - root.m_uu_i_ms_end_interval) < 500) {
                                                    //menu_item_select_interval_left.visible = false;
                                                    //menu_item_select_interval_right.visible = false;
                                                    menuLoaderSelInterv.menu_item_select_interval_left_visible = false
                                                    menuLoaderSelInterv.menu_item_select_interval_right_visible = false
                                                    if (root.m_i_is_interval_corresp_event
                                                            && !(root.m_i_is_interval_corresp_event_bookmark)) {
                                                        //menu_item_save_interval.visible = false;
                                                        menuLoaderSelInterv.menu_item_save_interval_visible = false
                                                    }
                                                }

                                                //e

                                                //onClicked: menu_interval2.open();
                                                onClicked: {
                                                    menuLoaderSelInterv.componentMenu._clearMenu()

                                                    if (menuLoaderSelInterv.menu_item_select_interval_left_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcSelectInterval_left,
                                                                    Language.getTranslate(
                                                                        "Change left border",
                                                                        "Изменить левую границу"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_select_interval_right_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcSelectInterval_right,
                                                                    Language.getTranslate(
                                                                        "Change right border",
                                                                        "Изменить правую границу"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_change_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcChange,
                                                                    Language.getTranslate(
                                                                        "Change Interval",
                                                                        "Изменить интервал"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_go_to_begin_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcGo_to_begin,
                                                                    Language.getTranslate(
                                                                        "Go to begin",
                                                                        "Перейти к началу"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_go_to_end_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcGo_to_end,
                                                                    Language.getTranslate(
                                                                        "Go to end",
                                                                        "Перейти к концу"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_save_interval_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcSave_interval,
                                                                    Language.getTranslate(
                                                                        "Save interval",
                                                                        "Сохранить интервал"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_call_unload_window_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcCall_Unload_window,
                                                                    Language.getTranslate(
                                                                        "Open export window",
                                                                        "Открыть окно выгрузки"),
                                                                    true, "")
                                                    }
                                                    if (menuLoaderSelInterv.menu_item_unload_visible) {
                                                        menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                    root.funcUnload,
                                                                    Language.getTranslate(
                                                                        "Export",
                                                                        "Выгрузить"),
                                                                    true, "")
                                                    }
                                                    menuLoaderSelInterv.componentMenu.createMenuItem(
                                                                root.funcReset_selection,
                                                                Language.getTranslate(
                                                                    "Reset selection",
                                                                    "Сбросить выделение"),
                                                                true, "")

                                                    positioningMenu()

                                                    //menuLoaderSelInterv.componentMenu.x = rl_mouse_x_av;
                                                    //menuLoaderSelInterv.componentMenu.y = rl_mouse_y_av;
                                                    var menuPoint = mapToItem(
                                                                Window.window.contentItem,
                                                                menuLoaderSelInterv.componentMenu.x,
                                                                menuLoaderSelInterv.componentMenu.y)
                                                    if (menuPoint.y + menuLoaderSelInterv.componentMenu.height >= Window.window.height) {
                                                        menuLoaderSelInterv.componentMenu.y -= (menuPoint.y + menuLoaderSelInterv.componentMenu.height - Window.window.height)
                                                    }
                                                    menuLoaderSelInterv.componentMenu.side = 'right'
                                                    if (menuPoint.x + menuLoaderSelInterv.componentMenu.width + menuLoaderSelInterv.componentMenu.width >= Window.window.width) {
                                                        menuLoaderSelInterv.componentMenu.side
                                                                = 'left'
                                                    }

                                                    if (menuPoint.x + menuLoaderSelInterv.componentMenu.width > Window.window.width - 20) {
                                                        menuLoaderSelInterv.componentMenu.x -= (menuPoint.x + menuLoaderSelInterv.componentMenu.width - Window.window.width + 20)
                                                    }
                                                    menuLoaderSelInterv.componentMenu._open()
                                                }
                                            }

                                            if (!popUpUpload_left_bound_rect.opened) {
                                                popUpUpload_left_bound_rect.open()
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: export_aviRect
                                    width: 24 * root.isize
                                    height: 24 * root.isize
                                    color: "transparent"
                                    visible: can_export_acc.isAllowed
                                    //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
                                    IVImageButton {
                                        id: unload_to_avi_ivibt_ButtonPane
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.fill: export_aviRect
                                        size: "normal"
                                        txt_tooltip: Language.getTranslate(
                                                         "export to AVI, MKV",
                                                         "экспорт в AVI, MKV") //"экспорт в AVI, MKV"
                                        on_source: 'file:///' + applicationDirPath
                                                   + '/images/white/archSave.svg'
                                        onClicked: {
                                            //ch90918 устарела root.m_s_unload_begin_interval = univreaderex.intervTime2( 0 );
                                            idLog3.trace('unload_to_avi_ivibt 2 clicked ')
                                            //ch00708 time before '
                                            //ch00708 +
                                            //ch00708 root.end );
                                            //ch90918 устарела root.m_s_unload_end_interval = root.end;
                                            export_aviLoader.create()
                                        }

                                        Loader {
                                            id: export_aviLoader
                                            //anchors.fill: photo_cam_rec_ButtonPane
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
                                                if (export_aviLoader.status === Loader.Ready) {
                                                    export_aviLoader.componentExport_avi
                                                            = export_aviLoader.item
                                                    root.m_v_component_main_export
                                                            = export_aviLoader.componentExport_avi

                                                    idLog3.warn('<' + root.key2 + '_' + root.key3
                                                                + '>' + 'onBindings 180110')

                                                    var s_begin_lv = ''
                                                    var s_end_lv = ''
                                                    //ch221021
                                                    var s_zna_ip_lv = ''

                                                    //e
                                                    idLog2.warn('onBindings 180110')

                                                    if (0 === root.m_uu_i_ms_begin_interval) {
                                                        s_begin_lv = univreaderex.intervTime2(
                                                                    0)
                                                        idLog3.warn('unload_to_avi_ivibt clicked time before ' + root.end)
                                                        if ('' === root.end) {
                                                            /*ch00708
                                                        root.end =
                                                        univreaderex.addDeltaTime(
                                                                    univreaderex.intervTime2( 0 ), 120000 );
                                                        idLog3.warn(
                                                                    '<' + root.key2 + '_' + root.key3 + '>' +
                                                                    'unload_to_avi_ivibt clicked end after ' +
                                                           root.end );
                                                        */
                                                            s_end_lv = univreaderex.addDeltaTime(
                                                                        univreaderex.intervTime2(
                                                                            0),
                                                                        120000)
                                                            idLog3.warn('<' + root.key2 + '_' + root.key3 + '>' + 'unload_to_avi_ivibt clicked end after ' + s_end_lv)
                                                        } else
                                                            s_end_lv = root.end
                                                    } else {
                                                        s_begin_lv = univreaderex.uu64ToHumanEv(
                                                                    root.m_uu_i_ms_begin_interval,
                                                                    3)
                                                        s_end_lv = univreaderex.uu64ToHumanEv(
                                                                    root.m_uu_i_ms_end_interval,
                                                                    3)
                                                    }
                                                    root.safeSetProperty(
                                                                export_aviLoader.componentExport_avi,
                                                                'key2',
                                                                Qt.binding(
                                                                    function () {
                                                                        return root.key2
                                                                    }))
                                                    ////////////mwork begin
                                                    var s1 = s_begin_lv.indexOf(
                                                                '27')
                                                    idLog3.warn('<mwork> s_begin_lv ' + s_begin_lv + ' s_end_lv ' + s_end_lv + ' ' + root.time811 + ' s1 ')

                                                    if (s1 === 0) {
                                                        s_begin_lv = root.time811
                                                        s_end_lv = s_begin_lv
                                                        idLog3.warn('<mwork>corrected ' + s_begin_lv
                                                                    + ' ' + s_end_lv)
                                                    }
                                                    ;
                                                    ////////////////////mwork end
                                                    root.safeSetProperty(
                                                                export_aviLoader.componentExport_avi,
                                                                'from',
                                                                Qt.binding(
                                                                    function () {
                                                                        return s_begin_lv
                                                                    }))

                                                    root.safeSetProperty(
                                                                export_aviLoader.componentExport_avi,
                                                                'to',
                                                                Qt.binding(
                                                                    function () {
                                                                        return s_end_lv
                                                                    }))
                                                    ;
                                                    //ch00708
                                                    if (0 !== root.m_s_start_event_id
                                                            && '' !== root.m_s_start_event_id)

                                                        //e
                                                        root.safeSetProperty(
                                                                    export_aviLoader.componentExport_avi,
                                                                    'evtid',
                                                                    Qt.binding(
                                                                        function () {
                                                                            return root.m_s_start_event_id
                                                                        }))
                                                    //ch221021
                                                    //получим из c++ e
                                                    s_zna_ip_lv = univreaderex.getSelectedZnaIp()

                                                    idLog3.warn("<select_source> export_aviLoader onStatusChanged s_zna_ip_lv " + s_zna_ip_lv)
                                                    root.safeSetProperty(
                                                                export_aviLoader.componentExport_avi,
                                                                'selected_zna_ip',
                                                                Qt.binding(
                                                                    function () {
                                                                        return s_zna_ip_lv
                                                                    }))

                                                    //e

                                                    //export_aviLoader.componentExport_avi.selected_zna_ip = "[\n{\n\"IP\" : \"192.168.40.107\", \n\"port\": 20001\n}\n]";
                                                    idLog3.warn('<unload> onBindings from ' + export_aviLoader.componentExport_avi.from + ' to ' + export_aviLoader.componentExport_avi.to + ' evtid ' + root.m_s_start_event_id)

                                                    export_aviLoader.componentExport_avi.parent_arc_obj = sel_interv
                                                }
                                            }
                                        }
                                    } //im but
                                } //rect

                                Rectangle {
                                    id: sound_rect_rec_ButtonPane
                                    width: 24 * root.isize
                                    height: 24 * root.isize
                                    color: "transparent"
                                    Loader {
                                        id: soundLoader
                                        anchors.fill: sound_rect_rec_ButtonPane
                                        property var componentSound: null
                                        function create() {
                                            var qmlfile = "file:///" + applicationDirPath
                                                    + '/qtplugins/iv/sound/PaneSound.qml'
                                            soundLoader.source = qmlfile
                                        }
                                        function refresh() {
                                            soundLoader.destroy()
                                            soundLoader.create()
                                        }
                                        function destroy() {
                                            if (soundLoader.status !== Loader.Null)
                                                soundLoader.source = ""
                                        }
                                        onStatusChanged: {
                                            if (soundLoader.status === Loader.Ready) {
                                                soundLoader.componentSound = soundLoader.item

                                                idLog3.warn('<sound> onCreated180904 2 '
                                                            + soundLoader.componentSound)
                                                var sound808_lv = soundLoader.componentSound

                                                root.m_pane_sound = soundLoader.componentSound
                                                idLog3.warn('<sound> 200811 50')
                                                //vart soundLoader.componentSound.nessActivateSound.connect( root.nessActivateSoundAP );
                                                //vart root.nessActivateSoundAP.connect( soundLoader.componentSound.nessActivateSound );
                                                root.m_i_is_sound_created = 1
                                                //e
                                                sound808_lv.owneraddress_arch
                                                        = univreaderex.getAddr808()
                                                sound808_lv.funaddress_arch
                                                        = univreaderex.getFunct808()
                                                univreaderex.storeSoundInfo(
                                                            sound808_lv.owneraddress,
                                                            sound808_lv.funaddress)

                                                soundLoader.componentSound.key2 = root.key2
                                                soundLoader.componentSound.key3 = root.key3
                                                soundLoader.componentSound.is_archive = 1

                                                root.safeSetProperty(
                                                            root,
                                                            'm_s_key3_audio_ap',
                                                            Qt.binding(
                                                                function () {
                                                                    return soundLoader.componentSound.key3_audio
                                                                }))

                                                root.safeSetProperty(
                                                            root,
                                                            'm_s_track_source_univ_ap',
                                                            Qt.binding(
                                                                function () {
                                                                    return soundLoader.componentSound.track_source_univ
                                                                }))
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: photo_cam_rec_ButtonPane
                                    width: 24 * root.isize
                                    height: 24 * root.isize
                                    color: "transparent"
                                    Loader {
                                        id: photocamLoader
                                        anchors.fill: photo_cam_rec_ButtonPane
                                        property var componentPhotocam: null
                                        function create() {
                                            var qmlfile = "file:///" + applicationDirPath
                                                    + '/qtplugins/iv/photocam/PanePhotoCam.qml'
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
                                            if (photocamLoader.status === Loader.Ready) {
                                                photocamLoader.componentPhotocam
                                                        = photocamLoader.item

                                                root.safeSetProperty(
                                                            photocamLoader.componentPhotocam,
                                                            'key2', Qt.binding(
                                                                function () {
                                                                    return root.key2
                                                                }))

                                                root.safeSetProperty(
                                                            photocamLoader.componentPhotocam,
                                                            'track', Qt.binding(
                                                                function () {
                                                                    return root.trackFrameAfterSynchrRoot
                                                                }))

                                                root.safeSetProperty(
                                                            photocamLoader.componentPhotocam,
                                                            'parent2',
                                                            Qt.binding(
                                                                function () {
                                                                    return root
                                                                }))
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: rectInterval_mashtab
                                    width: 70 * root.isize
                                    height: 24 * root.isize
                                    color: "transparent"

                                    Button {
                                        id: interval_razmer
                                        width: 70 * root.isize
                                        height: 24 * root.isize

                                        //y: parent.height - (ppUp.height*3)
                                        //x: parent.width - 150
                                        Text {
                                            id: txt_razmer
                                            text: lm_intervals.get(
                                                      root.m_i_curr_scale - 1).name //qsTr("<...>")
                                            color: "white"
                                            font.pixelSize: 14 * root.isize
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.verticalCenter: parent.verticalCenter
                                            leftPadding: 2
                                            onTextChanged: {

                                                //console.info("interval_razmer.text = ", txt_razmer.text)
                                            }
                                        }

                                        background: Rectangle {
                                            implicitWidth: 70 * root.isize
                                            implicitHeight: 20 * root.isize
                                            opacity: enabled ? 1 : 0.3
                                            border.color: interval_razmer.down ? "#FA8072" : "white"
                                            border.width: 1
                                            radius: 4
                                            color: "steelblue" //"darkslateblue"
                                        }

                                        onClicked: {
                                            //if ( root.common_panel === false)
                                            //{
                                            if (!ppUp2.opened) {
                                                ppUp2.open()
                                            }
                                            //}
                                        }
                                    }

                                    Popup {
                                        id: ppUp2
                                        focus: true
                                        closePolicy: Popup.CloseOnEscape
                                                     | Popup.CloseOnPressOutsideParent
                                                     | Popup.CloseOnPressOutside
                                        x: 0 - ((ppUp2.width - rectInterval_mashtab.width) / 2) //(mapToItem(root, ppUp.x, ppUp.y)).x //parent.width - (100*root.isize);
                                        y: 0 - (128 * root.isize)
                                        width: 100 * root.isize
                                        height: 128 * root.isize
                                        padding: 0

                                        Component.onCompleted: {

                                        }

                                        background: Rectangle {
                                            width: ppUp2.width
                                            height: ppUp2.height
                                            color: "steelblue" //"darkslateblue"
                                            opacity: 0.4
                                            clip: true
                                            radius: 3
                                            border.color: "white"
                                            border.width: 1
                                        }

                                        Rectangle {
                                            id: ppUpRect2
                                            z: 2
                                            width: ppUp2.width
                                            height: ppUp2.height
                                            color: "transparent"
                                            radius: 3

                                            ListView {
                                                id: interv_lv
                                                width: ppUp2.width - 2
                                                height: ppUp2.height
                                                highlightFollowsCurrentItem: true
                                                currentIndex: root.m_i_curr_scale - 1
                                                //keyNavigationEnabled: true
                                                focus: true

                                                highlight: Rectangle {
                                                    color: "#343434"
                                                }

                                                model: lm_intervals
                                                delegate: Component {
                                                    Rectangle {
                                                        id: delegateItem
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
                                                                idLog3.warn('<cmd> interv_lv MouseArea onClicked')
                                                                delegateItem.ListView.view.currentIndex = model.index
                                                                //listView.currentItem = bookmarkModel.get(delegateItem.ListView.view.currentIndex);
                                                            }
                                                        }
                                                    }
                                                }
                                                Component.onCompleted: {

                                                }

                                                onCurrentIndexChanged: {
                                                    idLog3.warn('<cmd> interv_lv onCurrentIndexChanged = ' + interv_lv.currentIndex)
                                                    root.m_i_curr_scale = interv_lv.currentIndex + 1
                                                    univreaderex.putLog807(
                                                                'bef setScaleF811 2 m_i_curr_scale '
                                                                + root.m_i_curr_scale)
                                                    idLog3.warn('<cmd> onCurrentIndexChanged root.m_i_max_scale = ' + root.m_i_max_scale)
                                                    idLog3.warn('<cmd> onCurrentIndexChanged root.m_i_max_scale = ' + root.m_i_curr_scale)
                                                    //console.info("onCurrentIndexChanged scale === ", root.m_i_max_scale + 1 - root.m_i_curr_scale)
                                                    if (m_i_curr_scale > 0 && m_i_curr_scale <= lm_intervals.count) {
                                                        txt_razmer.text = lm_intervals.get(m_i_curr_scale - 1).name
                                                    }
                                                    univreaderex.setScaleF811(
                                                                root.m_i_max_scale + 1
                                                                - root.m_i_curr_scale)
                                                }

                                                onCurrentItemChanged: {
                                                    idLog3.warn('<cmd> interv_lv onCurrentItemChanged OOOOO =' + currentItem)
                                                    //interv_lv.highlightFollowsCurrentItem
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: rectSwitchToRealTime_ButtonPane
                                    width: 24 * root.isize
                                    height: 24 * root.isize
                                    color: "transparent"
                                    //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
                                    IVImageButton {
                                        //ch90423 id: archive
                                        id: switchToRealTime_ButtonPane
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width
                                        height: parent.height
                                        txt_tooltip: Language.getTranslate(
                                                         "return to realtime",
                                                         "возврат в реалтайм") //"возврат в реалтайм"
                                        //txt_tooltip: (parentComponent.isFullscreen ? 'Off fullscreen':'On fullscreen')
                                        on_source: 'file:///' + applicationDirPath
                                                   + //ch90423 '/images/white/video_lib.svg'
                                                   //ch10216 '/images/white/camera.svg'
                                                   '/images/white/video_lib_exit.svg'
                                        size: "normal" //(parentComponent.isFullscreen? "normal":"small")
                                        onClicked: {
                                            //ch90425 parentComponent
                                            if (false === root.isCommonPanel(
                                                        )) {
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
                                    id: image_corr_rec_ButtonPane
                                    width: 24 * root.isize
                                    height: 24 * root.isize
                                    color: "transparent"
                                    //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
                                    Loader {
                                        id: image_correctLoader
                                        anchors.fill: image_corr_rec_ButtonPane
                                        property var componentImage_correct: null
                                        function create() {
                                            var qmlfile = "file:///" + applicationDirPath + '/qtplugins/iv/imagecorrector/ImageCorrector.qml'
                                            image_correctLoader.source = qmlfile
                                        }
                                        function refresh() {
                                            image_correctLoader.destroy()
                                            image_correctLoader.create()
                                        }
                                        function destroy() {
                                            if (image_correctLoader.status !== Loader.Null)
                                                image_correctLoader.source = ""
                                        }
                                        onStatusChanged: {
                                            if (image_correctLoader.status === Loader.Ready) {
                                                image_correctLoader.componentImage_correct
                                                        = image_correctLoader.item

                                                //ch91113 входная очередь данного плагина е
                                                image_correctLoader.componentImage_correct.inProfileName = root.//ch91112_3 trackFrameAfterSynchrRoot;
                                                trackFrameAfterStabilizerRoot
                                                //ch91113 выходная очередь данного плагина е
                                                image_correctLoader.componentImage_correct.outProfileName = //ch91112_3 univreaderex.trackFrameAfterSynchr
                                                        root.trackFrameAfterStabilizerRoot
                                                        + "_correct" // просто присвоение свойства
                                                //ch91113 render.trackFrame
                                                root.trackFrameAfterImageCorrectorRoot = image_correctLoader.componentImage_correct.outProfileName

                                                root.safeSetProperty(
                                                            image_correctLoader.item,
                                                            'key2', Qt.binding(
                                                                function () {
                                                                    return root.key2
                                                                }))

                                                image_correctLoader.componentImage_correct._x_position = -image_correctLoader.componentImage_correct.custom_width
                                                image_correctLoader.componentImage_correct._y_position = -image_correctLoader.componentImage_correct.custom_height - 40

                                                //ch91113
                                                root.m_b_image_corrector_created = true
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: fullscreenRect
                                    width: 24 * root.isize
                                    height: 24 * root.isize
                                    color: "transparent"

                                    //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
                                    IVImageButton {
                                        id: fullscreenButton_ButtonPane
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width
                                        height: parent.height
                                        txt_tooltip: (//ch90425 parentComponent
                                                      root.isFullscreen ? Language.getTranslate("Minimize", "Свернуть") : Language.getTranslate("Maximize", "Развернуть"))
                                        on_source: (//ch90425 parentComponent
                                                    root.isFullscreen ? 'file:///' + applicationDirPath + '/images/white/fullscreen_exit.svg' : 'file:///' + applicationDirPath + '/images/white/fullscreen.svg')
                                        size: "normal" //(parentComponent.isFullscreen? "normal":"small")
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

                                Popup {
                                    id: popUpUpload_left_bound_rect
                                    focus: true
                                    closePolicy: Popup.CloseOnEscape
                                                 | Popup.CloseOnPressOutsideParent
                                                 | Popup.CloseOnPressOutside
                                    //x: iv_butt_spb_bmark_skip.x-(popUpUpload_left_bound_rect.width/1.6);
                                    x: rectBmark_skip.x - (popUpUpload_left_bound_rect.width / 1.6)
                                    y: parent.height - (100 * root.isize)
                                    width: 255 * root.isize
                                    height: 30 * root.isize
                                    padding: 0

                                    Component.onCompleted: {

                                    }

                                    background: Rectangle {
                                        width: popUpUpload_left_bound_rect.width
                                        height: popUpUpload_left_bound_rect.height
                                        color: "steelblue"
                                        opacity: 0.5
                                        clip: true
                                    }

                                    Rectangle {
                                        id: upload_left_bound_rect
                                        width: 255 * root.isize
                                        height: 28 * root.isize
                                        color: "transparent"
                                        clip: true

                                        //ch91014 anchors.verticalCenter:
                                        //ch91014 parent
                                        //ch91014 .verticalCenter
                                        Label {
                                            id: upload_left_bound_2_lb
                                            text: Language.getTranslate(
                                                      "Interval selected",
                                                      "Выбран интервал") //'Выбран интервал'
                                            font.pixelSize: 12 * root.isize
                                            anchors.top: parent.top
                                            anchors.left: parent.left

                                            property bool visible2: true
                                            property bool visible3: true
                                            property bool visible4: false
                                            visible: visible2 && visible3
                                                     && visible4
                                            color: 'white'

                                            //vart hoverEnabled: true
                                            ToolTip {
                                                id: tooltip908
                                                delay: 1000
                                                timeout: 5000
                                                //vart visible:
                                                //text: ''
                                                contentItem: Text {
                                                    color: "white"
                                                    text: ''
                                                    font.pixelSize: 12 * root.isize
                                                }
                                                background: Rectangle {
                                                    border.color: "black"
                                                    color: "transparent"
                                                    radius: 5
                                                }
                                                //vart qsTr("This tool tip is shown after hovering the button for a second.")
                                            }
                                            MouseArea {
                                                id: upload_left_bound_2_lb_mouse_area
                                                //ch90813 z: 120
                                                anchors.top: upload_left_bound_2_lb.bottom
                                                anchors.left: parent.left
                                                //anchors.right: parent.right
                                                hoverEnabled: true
                                                onEntered: {
                                                    if (upload_left_bound_2_lb.visible
                                                            && '' !== tooltip908.contentItem.text)
                                                        tooltip908.visible = true
                                                }
                                                onExited: {
                                                    tooltip908.visible = false
                                                }
                                            } //mouse area
                                        }
                                        Label {
                                            id: upload_left_bound_lb
                                            text: ''
                                            font.pixelSize: 12 * root.isize

                                            anchors.top: parent.top
                                            anchors.topMargin: 14 * root.isize
                                            anchors.left: parent.left

                                            property bool visible2: true
                                            property bool visible3: true
                                            property bool visible4: false
                                            visible: visible2 && visible3
                                                     && visible4
                                            color: 'white'
                                        }
                                    }
                                }
                            }
                        }

                        ListModel {
                            id: lm_intervals
                            Component.onCompleted: {
                                append({
                                           name: Language.getTranslate("year",
                                                                       "год")
                                       })
                                append({
                                           name: Language.getTranslate("month",
                                                                       "месяц")
                                       })
                                append({
                                           name: Language.getTranslate("week",
                                                                       "неделя")
                                       })
                                append({
                                           name: Language.getTranslate("day",
                                                                       "день")
                                       })
                                append({
                                           name: Language.getTranslate("hour",
                                                                       "час")
                                       })
                                append({
                                           name: Language.getTranslate(
                                                     "10 minutes", "10 минут")
                                       })
                                append({
                                           name: Language.getTranslate(
                                                     "1 minute", "1 минута")
                                       })
                                txt_razmer.text = lm_intervals.get(
                                            root.m_i_curr_scale - 1).name
                            }
                        }
                    }
                    //e ch90617
                    //ch91029 otsech end
                } //wndControlPanel

                IVUnivReaderex {
                    id: univreaderex
                    //ch90428 key2: root.key2
                    key2: ''
                    time_urx: '' //root.time
                    end: '' //ch91226 root.end
                    repeat: root.repeat
                    //ch00505 cmd: root.cmd
                    //ch00505 speed: root.speed
                    //try ch90625 frame_time: ''
                    time_field_correct: ''
                    slider_value_correct: 100013

                    //ch00618 events_intervales_need_refresh: 0
                    //ch80321 - eto priznak, chto nugno pereschitat e
                    interv_time_left_correct: 0
                    app_path_correct: ''
                    on_frame_profile_urx: ''
                    key3_urx: ''
                    property int m_i_ness_swith_to_realtime_prev: 0

                    //ch90225
                    //значение мыши на прошлом тике е
                    //ch91014 property real m_qr_prev_tick_coord_x: 0.0
                    //ch91014 property real m_qr_prev_tick_coord_y: 0.0
                    //ch91012 property int m_i_timer_counter: 0
                    //ch91012 property int m_i_timer_counter_prev: 0
                    //e
                    property real m_qr_prev_tick_coord_x_2: 0.0
                    property real m_qr_prev_tick_coord_y_2: 0.0

                    property int m_i_events_intervales_need_refresh_mem: 0
                    // ch91029 otsech beg
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
                            ;
                        }
                        ;
                        critSect903(false)
                    }
                    onCommon_panel_visibleChanged: {
                        root.commonPanelSetVisible(
                                    univreaderex.common_panel_visible)
                    }
                    onScale_time_rightChanged: onScaleTimeRightChangedReal()
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

                        //ср91102
                        root.b_input_time_outside_cahange = false
                        //e
                        idLog3.warn('onTimeFieldCorrectChangedReal end ')
                    }

                    onSlider_value_correctChanged: onSliderValueCorrectChangedReal()
                    function onSliderValueCorrectChangedReal() {
                        idLog2.warn('onSliderValueCorrectChangedReal slider_value_correct '
                                    + slider_value_correct)
                        idLog3.warn('onSliderValueCorrectChangedReal slider_value_correct '
                                    + slider_value_correct + ' m_slider_control_asc.value '
                                    + iv_arc_slider_control.m_slider_control_asc.value)
                        //ch00416
                        if (iv_arc_slider_control.m_slider_control_asc.value
                                !== slider_value_correct) {
                            //e
                            root.b_slider_value_outside_change = true
                            iv_arc_slider_control.m_slider_control_asc.value = slider_value_correct
                            idLog3.warn('onSliderValueCorrectChangedReal aft value '
                                        + iv_arc_slider_control.m_slider_control_asc.value
                                        + ' position '
                                        + iv_arc_slider_control.m_slider_control_asc.position
                                        + ' visualPosition '
                                        + iv_arc_slider_control.m_slider_control_asc.visualPosition)
                        }
                        ;
                    }
                    //ch00618
                    //ch00618 onEvents_intervales_need_refreshChanged:
                    //ch00618 onEventsIntervalesNeedRefreshChangedReal()
                    onEventsIntervalesNeedRefresh006: {
                        univreaderex.onEventsIntervalesNeedRefreshChangedReal(
                                    i_events_intervales_need_refresh_av,
                                    i_is_global_refresh_av)
                    }

                    //e
                    onClearPrimitives: {
                        idLog3.warn('<prim> 200714 100 ')
                        if (root.m_primit !== null
                                && 'clearData' in root.m_primit) {
                            idLog3.warn('<prim> 200714 101 ')
                            root.m_primit.clearData()
                            idLog3.warn('<prim> 200714 102 ')
                        }
                        ;
                    }

                    //ch90911 это - рефрешь слайдера е
                    function onEventsIntervalesNeedRefreshChangedReal(i_events_intervales_need_refresh_av, i_is_global_refresh_av) {
                        var b_is_ness_cont_work_lv = true
                        var qr_point_lv = -1.0
                        var qr_point_begin_lv = -1.0
                        var qr_point_end_lv = -1.0
                        var i_view_prior_lv = -1
                        var qs_color_lv = ''
                        var i_is_bmark_lv = 0
                        var qs_event_color_lv = ''

                        var i_scale_dev_num_lv = 0
                        var i_it_lv = 0

                        var qr_point_scale_devision_lv = -1.0
                        var qs_scale_devision_text_lv = ''
                        var i_decemal_lv = 0
                        var i_is_last_events_element_lv = 0

                        //ch00619 var qr_point_begin_corr_lv = 0.0;
                        idLog3.warn('<fill_interv>onEventsIntervalesNeedRefreshChangedReal beg funct ch '
                                    + //ch00618 events_intervales_need_refresh
                                    i_events_intervales_need_refresh_av//e
                                    )
                        idLog3.warn('<refr_task' + key2 + '> ' + root.common_panel
                                    + ' onEventsIntervalesNeedRefreshChangedReal draw interv beg funct ch '
                                    + " events_intervales_need_refresh "
                                    + i_events_intervales_need_refresh_av + //e
                                    ' events_intervales_need_refresh_mem '
                                    + m_i_events_intervales_need_refresh_mem)
                        if (m_i_events_intervales_need_refresh_mem
                                !== //ch00618 events_intervales_need_refresh
                                i_events_intervales_need_refresh_av//e
                                ) {
                            m_i_events_intervales_need_refresh_mem
                                    = //ch00618 events_intervales_need_refresh
                                    i_events_intervales_need_refresh_av
                            //e
                            idLog3.warn('<refr_task' + key2 + '> ' + root.common_panel
                                        + ' onEventsIntervalesNeedRefreshChangedReal  draw interv'
                                        + ' is_global_refresh ' + i_is_global_refresh_av)
                            //ch00618
                            if (0 !== i_is_global_refresh_av) {
                                //e
                                iv_arc_slider_control.m_slider_control_asc.clearFill()
                                iv_arc_slider_control.m_slider_control_asc.createFill(
                                            0.0, 1.0, "lightslategray", 1.0)
                            }
                            ;
                            univreaderex.setFierstIndex908()
                            //ch90827
                            univreaderex.qmlFillIntervalsEnterLeaveCS(1)
                            //e
                            //ch90403 интервалы заполненности
                            while (true) {
                                b_is_ness_cont_work_lv = true
                                if (b_is_ness_cont_work_lv) {
                                    qr_point_begin_lv = univreaderex.getNextFillIntervalBeginValue()
                                    b_is_ness_cont_work_lv = (-1 !== qr_point_begin_lv)
                                }
                                if (b_is_ness_cont_work_lv) {
                                    qr_point_end_lv = univreaderex.getNextFillIntervalEndValue()
                                    b_is_ness_cont_work_lv = (-1 !== qr_point_end_lv)
                                }
                                idLog3.warn('<fill_interv>onEventsIntervalesNeedRefreshChangedReal 90404 6 ness '
                                            + b_is_ness_cont_work_lv + ' beg '
                                            + qr_point_begin_lv + ' end ' + qr_point_end_lv)
                                if (b_is_ness_cont_work_lv) {
                                    i_view_prior_lv
                                            = univreaderex.getNextFillIntervalViewPriorValue()
                                    if (1 === i_view_prior_lv)
                                        qs_color_lv = 'green'
                                    else
                                        qs_color_lv = 'orange'
                                    idLog3.warn('<fill_interv>onEventsIntervalesNeedRefreshChangedReal interv beg ' + qr_point_begin_lv + ' end ' + qr_point_end_lv + ' color ' + qs_color_lv)
                                    idLog3.warn('<fill_interv>onEventsIntervalesNeedRefreshChangedReal arc trace interv beg ' + qr_point_begin_lv + ' end ' + qr_point_end_lv + ' color ' + qs_color_lv)
                                    idLog3.warn('<fill_interv>onEventsIntervalesNeedRefreshChangedReal 2 interv beg ' + qr_point_begin_lv + ' end ' + qr_point_end_lv + ' color ' + qs_color_lv)

                                    /*ch00619 vart
                                qr_point_begin_corr_lv = qr_point_begin_lv;
                                if ( 0 === i_global_refresh_condish_av )
                                {
                                    qr_point_begin_corr_lv =
                                      Math.max( qr_point_begin_corr_lv, qr_frame_begin_av );
                                }
                                if (
                                     qr_point_begin_corr_lv < qr_point_end_lv
                                   )
                                {
                                */
                                    iv_arc_slider_control.m_slider_control_asc.createFill(
                                                //ch00619 qr_point_begin_corr_lv
                                                qr_point_begin_lv,
                                                qr_point_end_lv,
                                                qs_color_lv, 1.0)
                                    //ch00619 };
                                }

                                if (!b_is_ness_cont_work_lv)
                                    break
                            } //while
                            idLog3.warn('<events> onEventsIntervalesNeedRefreshChangedReal 190820 ')
                            //ch91021
                            //ch00628 otobragaem sobitiya e
                            if (!root.isSmallMode()) {
                                while (true) {

                                    qr_point_lv = univreaderex.getNextValue(
                                                i_is_global_refresh_av)
                                    idLog3.warn('<events> onEventsIntervalesNeedRefreshChangedReal 2 qr_point_lv ' + qr_point_lv)
                                    if (-1.0 === qr_point_lv) {

                                        //ch00628 break;
                                    } else {
                                        i_is_bmark_lv = univreaderex.isLastEventBMark()
                                        if (0 === i_is_bmark_lv)
                                            qs_event_color_lv = 'red'
                                        else
                                            qs_event_color_lv = 'cyan'
                                        //ch90820
                                        idLog3.warn('<events> onEventsIntervalesNeedRefreshChangedReal qr_point_lv ' + qr_point_lv)
                                        //e
                                        iv_arc_slider_control.m_slider_control_asc.createFill(
                                                    qr_point_lv,
                                                    qr_point_lv + 0.002,
                                                    qs_event_color_lv, 1.0)
                                    }
                                    i_is_last_events_element_lv = isLastEventsElements()
                                    if (0 !== i_is_last_events_element_lv)
                                        break
                                }
                                ;
                            }
                            ;
                            //ch90827
                            univreaderex.qmlFillIntervalsEnterLeaveCS(0)
                            //e
                            iv_arc_slider_control.m_slider_control_asc.createFill(
                                        0.0, 0.05, "#b0b0b0", 0.7//"black", 0.7
                                        )
                            iv_arc_slider_control.m_slider_control_asc.createFill(
                                        0.95, 1.0, "#b0b0b0", 0.7//"black", 0.7
                                        )
                        }
                        //ch91021
                        //if ( !root.isSmallMode() )
                        //{
                        //e
                        iv_arc_slider_control.m_slider_control_asc.drawSelectedInterval()
                        //ch90903 рисование рисок е
                        if (wndControlPanel.width < root.m_i_width_visible_bound2)
                            i_decemal_lv = 1
                        if (//ch91021 wndControlPanel.width < root.m_i_width_visible_bound3
                                root.isSmallMode())
                            i_decemal_lv = 2

                        //сделаем все невид е
                        iv_arc_slider_control.setLabelsVisible(false,
                                                               true, false)

                        i_scale_dev_num_lv = univreaderex.getScaleDevisionNum()

                        //ch90912 deb
                        //              idLog3.warn('<events> onEventsIntervalesNeedRefreshChangedReal i_scale_dev_num_lv ' +
                        //                          i_scale_dev_num_lv );
                        //              if ( 7 !== i_scale_dev_num_lv )
                        //              {
                        //e
                        idLog3.warn('<events> onEventsIntervalesNeedRefreshChangedReal draw lab ')
                        //var coeff = iv_arc_slider_control.getThinningFactor(i_scale_dev_num_lv);
                        //idLog3.warn('<events> onEventsIntervalesNeedRefreshChangedReal coeff = ', coeff);

                        //for ( i_it_lv = 0; i_it_lv < i_scale_dev_num_lv; coeff ? i_it_lv+=coeff : i_it_lv++ )
                        for (i_it_lv = 0; i_it_lv < i_scale_dev_num_lv; i_it_lv++) {
                            qs_scale_devision_text_lv = univreaderex.getScaleDevisionText(
                                        i_scale_dev_num_lv, i_it_lv,
                                        i_decemal_lv)
                            qr_point_scale_devision_lv = univreaderex.getScaleDevisionPos(
                                        i_scale_dev_num_lv, i_it_lv,
                                        i_decemal_lv)
                            if (0 != i_it_lv && i_scale_dev_num_lv != i_it_lv) {
                                //console.info("\ni_it_lv = ", i_it_lv, "\ni_scale_dev_num_lv = ",i_scale_dev_num_lv,
                                //             "\ni_decemal_lv = ",i_decemal_lv);
                                iv_arc_slider_control.drawLabel(
                                            i_it_lv,
                                            qr_point_scale_devision_lv,
                                            qs_scale_devision_text_lv)
                            }
                            ;
                        }
                        iv_arc_slider_control.getThinningFactor(
                                    i_scale_dev_num_lv)
                        iv_arc_slider_control.setScaleTimeLeftRightVisible()
                        //}
                        //ch90912
                        //              }
                        //e
                    }


                    //ch230321 рефрешь алтернативный - slider_new
                    onInterv_time_left_correctChanged: onIntervTimeLeftCorrectChangedReal()
                    function onIntervTimeLeftCorrectChangedReal() {
                        var b_is_ness_cont_work_lv = true
                        var i_coord_res_lv = 1
                        var x_last_begin_point_lv = 1
                        var x_last_end_point_lv = 1
                        var s_beg_point_lv = ''
                        if (b_is_ness_cont_work_lv) {
                            //vichilim lev coordinatu e
                            i_coord_res_lv = univreaderex.sliderCoordByTime(0)
                            if (-1 == i_coord_res_lv) {
                                b_is_ness_cont_work_lv = false
                                x_last_begin_point_lv = 1
                                x_last_end_point_lv = 1
                            } else if (-2 == i_coord_res_lv) {
                                x_last_begin_point_lv = 1
                            } else {
                                x_last_begin_point_lv = i_coord_res_lv // / 1000;
                            }
                            ;
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
                    //ch90704
                    //                    onQmlRefreshSelectedInterval:
                    //                        function qmlRefreshSelectedIntervalReal(){
                    //                            iv_arc_slider_control.m_slider_control_asc.
                    //                                drawSelectedInterval();
                    //                        }
                    //e
                    onSendToQml910: {

                        //scale_interv_len_lb.text = newValue;
                    }
                    onSetMenuText: {
                        //var menu_item912 = getMenuObjectByIndex( i_menu_index_av );
                        //menu_item912.text = qs_menu_text_av;
                        //menu_item912.visible2 = true;
                        //menu_item912.height = 30;
                        if (0 === i_menu_index_av) {
                            idLog3.warn( "<switch> 230901 2 " +
                                         menuLoaderContext_menu2.menu_source0_text )
                            menuLoaderContext_menu2.menu_source0_text = qs_menu_text_av
                        } else if (1 === i_menu_index_av) {
                            idLog3.warn( "<switch> 230901 3 " +
                                         menuLoaderContext_menu2.menu_source1_text )
                            menuLoaderContext_menu2.menu_source1_text = qs_menu_text_av
                        } else if (2 === i_menu_index_av) {
                            menuLoaderContext_menu2.menu_source2_text = qs_menu_text_av
                        } else if (3 === i_menu_index_av) {
                            menuLoaderContext_menu2.menu_source3_text = qs_menu_text_av
                        } else if (4 === i_menu_index_av) {
                            menuLoaderContext_menu2.menu_source4_text = qs_menu_text_av
                        } else if (5 === i_menu_index_av) {
                            menuLoaderContext_menu2.menu_source5_text = qs_menu_text_av
                        } else if (6 === i_menu_index_av) {
                            menuLoaderContext_menu2.menu_source6_text = qs_menu_text_av
                        }
                        idLog2.warn('<sel_source> onSetMenuText i_menu_index_av ' + i_menu_index_av)
                    }
                    onNessAudioEnable: {
                        //vart3 idLog3.warn( '<sound> 200729 1 ' );
                        //vart3 if (
                        //vart 'change_state_sound_checkbox' in root.m_pane_sound
                        //root.m_pane_sound.change_state_sound_checkbox !== null &&
                        //root.m_pane_sound.change_state_sound_checkbox !== undefined
                        //vart3 true
                        //vart3 )
                        //vart3 {
                        idLog3.warn('<sound> 200729 3 ')
                        //vart root.m_pane_sound.
                        //vart change_state_sound_checkbox( true );
                        //vart root.m_pane_sound.nessActivateSoundAP();
                        root.m_i_ness_activate_sound = 1
                        //vart3 }
                        idLog3.warn('<sound> 200729 2 ')
                    }
                    //ch10714
                    onSttVideoPresent: {
                        idLog3.warn('<sound> 210714 ')
                        root.m_s_is_video_present = "1"
                    }
                    //e
                    onSetControlElements: {
                        root.m_b_no_actions = true
                        if ('pause' === qs_cmd_av)
                            play_ivichb.chkd = false
                        else if ('play' === qs_cmd_av)
                            play_ivichb.chkd = true


                        //iv_speed_slider.external_modif !== undefined
                        //iv_speed_slider.external_modif = 1;
                        if (125 == i_speed_av)
                            iv_speed_slider.speed = 0.125
                        else if (250 == i_speed_av)
                            iv_speed_slider.speed = 0.25
                        else if (500 == i_speed_av)
                            iv_speed_slider.speed = 0.5
                        else if (1000 == i_speed_av)
                            iv_speed_slider.speed = 1
                        else if (2000 == i_speed_av)
                            iv_speed_slider.speed = 2
                        else if (4000 == i_speed_av)
                            iv_speed_slider.speed = 4
                        else if (8000 == i_speed_av)
                            iv_speed_slider.speed = 8
                        else if (16000 == i_speed_av)
                            iv_speed_slider.speed = 16
                        else if (32000 == i_speed_av)
                            iv_speed_slider.speed = 32
                        else if (64000 == i_speed_av)
                            iv_speed_slider.speed = 64
                        else if (128000 == i_speed_av)
                            iv_speed_slider.speed = 128


                        //iv_speed_slider.external_modif !== undefined
                        //iv_speed_slider.external_modif = 0;
                        root.m_b_no_actions = false
                    }

                    //ch00413
                    /*ch00608
                    onNessDrawStartInterval: {
                      var i_lv = getDelaySetStartInterval();
                      idLog3.warn(
                          '<interv> onNessDrawStartInterval getDelaySetStartInterval ' +
                                    i_lv );

                      if ( 0 !== i_lv )
                        ivButtonPane.drawStartInterval();
                    }
                    */
                    /*ch00607
                    onNessCorrectIntervalSelectLeft: {
                      var i_lv = getDelayCorrectIntervalSelectLeft();
                      idLog3.warn(
                          '<interv> onNessDrawStartInterval 2 getDelaySetStartInterval ' +
                                    i_lv );

                      if ( 0 !== i_lv )
                        ivButtonPane.correctIntervalSelectLeft_Causing1();
                    }
                    */
                    /*ch00608
                    onNessCorrectIntervalSelectRight: {
                      var i_lv = setDelayCorrectIntervalSelectRight();
                      idLog3.warn(
                          '<interv> onNessDrawStartInterval 3 getDelaySetStartInterval ' +
                                    i_lv );

                      if ( 0 !== i_lv )
                        ivButtonPane.correctIntervalSelectRight_Causing1();
                    }
                    */
                    /*ch00608
                    onNessCorrectInterval: {
                      var i_lv = getDelayCorrectInterval();
                      idLog3.warn(
                          '<interv> onNessDrawStartInterval 3 getDelaySetStartInterval ' +
                                    i_lv );

                      if ( 0 !== i_lv )
                        ivButtonPane.correctInterval_Causing1();
                    }
                    */
                    //e
                    onDrawPreviewQML: {
                        //ch91016_3 var pt_mapped_pos_lv = null;
                        var qs_provider_param_lv = ''
                        qs_provider_param_lv = qs_paramPreview_av
                        idLog3.warn('<preview> showPreview bef source = ' + qs_provider_param_lv)
                        //ch91017 проверим, что не ушли коорд
                        if (iv_arc_slider_control.isInSliderZone()) {

                            imageSlider_1.source="";
                            //imageSlider_2.source="";
                            imageSlider.visible = false;
                            if (qs_provider_param_lv.length > 0)
                            {
                                //imageSlider.border.color = "transparent"
                                imageSlider.x = root.width / 2 - imageSlider.width
                                        / 2 //qr_mouse_x_av - imageSlider.width / 2;
                                imageSlider.y = qr_mouse_y_av - ((imageSlider.height - 4) * 1.75)

                                //visible
                                //imageSlider.imageVisible_2 = true
                                //console.info("onDrawPreviewQML imageSlider.imageVisible_2 = true")

                                //ch91010 m_imageSlider_asc.source =
                                //ch91010 "image://iv7univ_readerex/" + qs_provider_param_lv;

                                //imageSlider.setSource(
                                //        "image://iv7univ_readerex/" + qs_provider_param_lv);

                                imageSlider_1.source=qs_provider_param_lv;
                                imageSlider_1.visible=true;
                                imageSlider.visible = true;
                            }

                            //e

                            //ch90923 deb
                            //ch90927 m_imageSlider_asc.source = 'file:///' + 'F:/190923_image/IMG00039.jpg'
                            //e ch90927

                            //ch91016_3 pt_mapped_pos_lv = mapToItem
                            //ch91016_3 ( root, qr_mouse_x_av, qr_mouse_y_av );
                            idLog3.warn('showPreview '
                                        + //ch91016_3 'pt_mapped_pos_lv.x ' + pt_mapped_pos_lv.x +
                                        //ch91016_3 'pt_mapped_pos_lv.y' + pt_mapped_pos_lv.y +
                                        ' m_imageSlider_asc.heihgt ' + imageSlider.height
                                        + ' qr_mouse_x_av ' + qr_mouse_x_av
                                        + ' qr_mouse_y_av ' + qr_mouse_y_av)


                            //ch91002 m_imageSlider_asc.anchors.leftMargin = pt_mapped_pos_lv.x
                            //ch91002 - m_imageSlider_asc.width / 2;

                            //e
                            //e
                            if (timer_finish_preview.running) {
                                timer_finish_preview.stop()
                            }
                            timer_finish_preview.start()
                        }
                        //e
                    }
                    //ch221021
                    onSetSelectedZnaIpOutput: {
                        idLog3.warn("<select_source> onSetSelectedZnaIpOutput qs_selected_zna_ip_output_av "
                                    + qs_selected_zna_ip_output_av)
                        m_s_selected_zna_ip_output = qs_selected_zna_ip_output_av
                    }
                    //e
                    //ch91029 otsech end
                    //ch10325
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
                } //rex
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

    function testGetIntervals(i64_uu_i_ms_begin_av, i64_uu_i_ms_end_av) {
        //var b_is_ness_cont_work_lv = true;
        //var qr_point_lv = -1.0;
        var qr_point_begin_lv = -1.0
        var qr_point_end_lv = -1.0
        var i_view_prior_lv = -1
        var qs_color_lv = ''

        //var i_is_bmark_lv = 0;
        //var qs_event_color_lv = '';

        //var i_scale_dev_num_lv = 0;
        //var i_it_lv = 0;

        //var qr_point_scale_devision_lv = -1.0;
        //var qs_scale_devision_text_lv = '';
        //var i_decemal_lv = 0;
        //var i_is_last_events_element_lv = 0;
        idLog3.warn('<slider_new> 10')
        var b_is_ness_cont_work_lv = true
        iv_arc_slider_control.m_slider_control_asc.clearFill()
        idLog3.warn('<slider_new> 22')
        iv_arc_slider_control.m_slider_control_asc.createFill(0.0, 1.0,
                                                              "lightslategray",
                                                              1.0)
        idLog3.warn('<slider_new> 23')
        univreaderex.setFierstIndex908SliderNew()
        idLog3.warn('<slider_new> 25')
        univreaderex.qmlFillIntervalsSliderNewEnterLeaveCS(1)
        //ch90403 интервалы заполненности
        idLog3.warn('<slider_new> 11')
        while (true) {
            idLog3.warn('<slider_new> 12')

            b_is_ness_cont_work_lv = true
            if (b_is_ness_cont_work_lv) {
                idLog3.warn('<slider_new> 13')

                qr_point_begin_lv = univreaderex.getNextFillIntervalSliderNewBeginValue(
                            i64_uu_i_ms_begin_av, i64_uu_i_ms_end_av)
                b_is_ness_cont_work_lv = (-1 !== qr_point_begin_lv)
                idLog3.warn('<slider_new> 14')
            }
            if (b_is_ness_cont_work_lv) {
                idLog3.warn('<slider_new> 15')

                qr_point_end_lv = univreaderex.getNextFillIntervalSliderNewEndValue(
                            i64_uu_i_ms_begin_av, i64_uu_i_ms_end_av)
                b_is_ness_cont_work_lv = (-1 !== qr_point_end_lv)
            }
            idLog3.warn('<fill_interv>onEventsIntervalesNeedRefreshChangedReal 90404 6 ness '
                        + b_is_ness_cont_work_lv + ' beg ' + qr_point_begin_lv
                        + ' end ' + qr_point_end_lv)
            if (b_is_ness_cont_work_lv) {
                i_view_prior_lv = univreaderex.getNextFillIntervalSliderNewViewPriorValue()
                if (1 === i_view_prior_lv)
                    qs_color_lv = 'green'
                else
                    qs_color_lv = 'orange'
                idLog3.warn('<fill_interv>onEventsIntervalesNeedRefreshChangedReal interv beg '
                            + qr_point_begin_lv + ' end ' + qr_point_end_lv
                            + ' color ' + qs_color_lv)
                idLog3.warn('<fill_interv>onEventsIntervalesNeedRefreshChangedReal arc trace interv beg ' + qr_point_begin_lv
                            + ' end ' + qr_point_end_lv + ' color ' + qs_color_lv)
                idLog3.warn('<fill_interv>onEventsIntervalesNeedRefreshChangedReal 2 interv beg '
                            + qr_point_begin_lv + ' end ' + qr_point_end_lv
                            + ' color ' + qs_color_lv)
                iv_arc_slider_control.m_slider_control_asc.createFill(
                            //ch00619 qr_point_begin_corr_lv
                            qr_point_begin_lv, qr_point_end_lv,
                            qs_color_lv, 1.0)
            }

            if (!b_is_ness_cont_work_lv)
                break
        } //while
        univreaderex.qmlFillIntervalsSliderNewEnterLeaveCS(0)
        idLog3.warn('<slider_new> 40')
    }
    //ch220228
    function funcPlayCommand2202() {
        idLog3.warn('220228_700 ')
        idLog3.warn('220228_600 ')
        if (!root.m_b_no_actions) {
            idLog3.warn('220228_601 ')
            if (play_ivichb.chkd) {
                idLog3.warn('220228_602 ')
                if (revers_ivichb.chkd) {
                    idLog3.warn('220228_603 ')
                    //ch00505 root.cmd = 'play_backward';
                    univreaderex.setCmd005('play_backward')
                } else {
                    idLog3.warn('220228_6   ')
                    //ch00505 root.cmd = 'play';
                    univreaderex.setCmd005('play')
                }
                play_ivichb.txt_tooltip = Language.getTranslate(
                            "Pause", "Пауза") //"пауза"
            } else {
                idLog3.warn('220228_601 ')
                univreaderex.setCmd005('pause')
                play_ivichb.txt_tooltip = Language.getTranslate(
                            "Archive playback",
                            "Проигрывание архива") //"проигрывание архива"
            }
            ;
        }
        ;
        idLog3.warn('220228_605 ')
    }
    //e
    function funcCloseCamera() {
        /*if (integration_flag.value === "SDK")
        {
            root.ivComponent.command('WindowsCreator', 'windows:hide',{id:root.Window.window.ivComponent.unique});
        }
        else
        {
            if (root.viewer_command_obj !== null || root.viewer_command_obj !== undefined)
            {
                root.viewer_command_obj.command_to_viewer('sets:area:removecamera2');
            }
        }*/
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

    //e
    function componentCompleted() {
        if (root.key2 === '' || root.key2 === null || root.key2 === undefined) {
            return
        }

        idLog3.warn("<slider_new> 55 root.key2 " + root.key2)
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

        //ch00406 temp deb
        //root.cmd = 'play';
        //e

        //ch91227 temp deb
        //ch91227 temp deb root.time = '2019.12.27-10:10:33';
        //ch91227 temp deb root.end = '2019.12.27-10:13:33';
        //e

        //ch00406
        if ('play' === root.cmd)
            play_ivichb.chkd = true

        //e

        //ch00424 if ( '' !== root.time  )
        //ch00424 univreaderex.setTimeFromParentAccepted( 1 );
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
        //vart var qml = '';

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
                //ch90918 false
                commonPanelSetVisible(0)
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
                    iv_arc_slider_control.visible = false
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
            //ch000122 - построено из окна выгрузки е
            if (root.m_b_is_caused_by_unload) {
                root.complete5()
            }
        }
        idLog3.warn('90704 bef complete901 key2 ' + root.key2 + ' savedSetName '
                    + root.savedSetName)

        //ch90527 , s_controls_lv
        univreaderex.complete901(s_time_iv_lv, root.savedSetName)

        if (0 === root.getCamCommonPanelMode()) {
            //ср90704
            if (false === root.common_panel) {

                //e
                //ch90917 ivButtonPane.complete3();
            }
        }
        idLog3.warn('<prim 3> common_panel ' + root.common_panel)
        //ср90704
        if (false === root.common_panel) {
            //e
            idLog3.warn('<prim 100>')
            complete4()
            //ch00122
            if (0 !== root.getCamCommonPanelModeUseSetPanel_Deb())
                root.m_i_c_control_panel_height = 38
            //e
            idLog3.warn('<start_stop> 241017 001 ')
        }
        //ch90731
        root.complete2()
        //e
        idLog3.warn('<prim 4>')

        if (false === root.common_panel || 0 !== root.getCamCommonPanelMode()) {
            idLog3.warn('<common_pan> 00425 1 key2 '
                        + root.key2 + " common_panel " + common_panel +
                        " getCamCommonPanelMode " + root.getCamCommonPanelMode() )
            timer809.running = true
        }

        mousearea_CommonPanMode.enabled = true
        //ch00121
        if (true === root.common_panel)
            ivButtonTopPanel.visible = false

        m_component_completed_2303 = true
        idLog3.warn("<slider_new> 51 root.key2 " + root.key2)
        root.complete2303()
        //e
        if (is_export_media === 1) {
            root.m_i_is_comleted = 1
        }
        idLog3.warn('<compl end >' + ' key2 ' + root.key2 + ' key3 ' + root.key3)
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


    //ch91029 otsech2 end
    /*function getMenuObjectByIndex( i_menu_index_av )
    {
      var menu_item912 = 0;
      if ( 0 === i_menu_index_av )
      {
          menu_item912 = menu_item_source_0;
          //menu_item_source_0.visible = true;
          //menu_item_source_0.height = 30;
      }
      else if ( 1 === i_menu_index_av )
      {
          menu_item912 = menu_item_source_1;
          //menu_item_source_1.visible = true;
          //menu_item_source_1.height = 50;
      }
      else if ( 2 === i_menu_index_av )
      { menu_item912 = menu_item_source_2;  }
      else if ( 3 === i_menu_index_av )
      { menu_item912 = menu_item_source_3;  }
      else if ( 4 === i_menu_index_av )
      { menu_item912 = menu_item_source_4;  }
      else if ( 5 === i_menu_index_av )
      { menu_item912 = menu_item_source_5;  }
      else if ( 6 === i_menu_index_av )
      { menu_item912 = menu_item_source_6;  }
      return menu_item912;
    }*/
    function isCommonPanel() {
        return root.common_panel
    }
    function isSmallMode() {
        var b_lv = false

        b_lv = (wndControlPanel.width < root.m_i_width_visible_bound3)

        idLog3.warn('<root> isSmallMode wndControlPanel.width '
                    + wndControlPanel.width + ' root.m_i_width_visible_bound3 '
                    + root.m_i_width_visible_bound3 + ' b_lv ' + b_lv)
        return b_lv
        //ch91030 ( wndControlPanel.width < root.m_i_width_visible_bound3 )
        //ch91030 b_lv;
        //true;
    }
    //ch91029 otsech2 beg
    function callContextMenu907(rl_mouse_x_av, rl_mouse_y_av) {

        //context_menu2.x = rl_mouse_x_av;
        //context_menu2.y = rl_mouse_y_av;
        //onClicked: {
        //    context_menu2.open();
        //    if(timer_context_menu2_close.running)
        //    {
        //        timer_context_menu2_close.stop();
        //    }
        //    timer_context_menu2_close.start();
        //}
        onClicked: {
            menuLoaderContext_menu2.componentMenu._clearMenu()

            menuLoaderContext_menu2.componentMenu.createMenuItem(
                        root.funcSwitchToFullScreen,
                        root.isFullscreen ? Language.getTranslate(
                                                "Switch to multiscreen",
                                                "Переключиться в мультиэкран") : Language.getTranslate(
                                                "Switch to full screen",
                                                "Переключиться в полный экран"),
                                            true, "fullscreen.svg")
            menuLoaderContext_menu2.componentMenu.createMenuItem(
                        root.functReturnToRealtime,
                        Language.getTranslate("Return to realtime",
                                              "Возврат в реалтайм"), true,
                        "video_lib_exit.svg")
            if (can_export_acc.isAllowed){
                menuLoaderContext_menu2.componentMenu.createMenuItem(
                            root.funcCall_Unload_window,
                            Language.getTranslate("Open export menu",
                                                  "Открыть меню экспорта"), true,
                            "archSave.svg")
            }
            if (root.fast_edits === true /*|| root.is_set_edit === true
                    || integration_flag.value === "SDK"*/) {
                menuLoaderContext_menu2.componentMenu.createMenuItem(
                            root.funcCloseCamera,
                            Language.getTranslate("Close camera",
                                                  "Закрыть камеру"), true,
                            'clear.svg')
                if(interfaceButtonsCloseSets.value === "true") {
                    menuLoaderContext_menu2.componentMenu.createMenuItem(
                                root.funcCloseSet,
                                Language.getTranslate("Close tab",
                                                      "Закрыть вкладку"), true,
                                'clear.svg')
                }
            } else {
                if(isSetEdit.value === "true" )
                {
                    menuLoaderContext_menu2.componentMenu.createMenuItem(
                                root.funcCloseCamera,
                                Language.getTranslate("Close camera",
                                                      "Закрыть камеру"), true,
                                'clear.svg')
                }
                else
                {
                    if( integration_flag.value === "SDK")
                    {
                        if(!root.viewer_command_obj.myGlobalComponent.ivSetsArea)
                        {
                            menuLoaderContext_menu2.componentMenu.createMenuItem(
                                        root.funcCloseCamera,
                                        Language.getTranslate("Close camera",
                                                              "Закрыть камеру"), true,
                                        'clear.svg')
                        }
                        else
                        {
                            if(interfaceButtonsCloseSets.value === "true")
                            {
                                menuLoaderContext_menu2.componentMenu.createMenuItem(
                                            root.funcCloseSet,
                                            Language.getTranslate("Close tab",
                                                                  "Закрыть вкладку"), true,
                                            'clear.svg')
                            }
                        }
                    }
                    else
                    {
                        if(interfaceButtonsCloseSets.value === "true")
                        {
                            menuLoaderContext_menu2.componentMenu.createMenuItem(
                                        root.funcCloseSet,
                                        Language.getTranslate("Close tab",
                                                              "Закрыть вкладку"), true,
                                        'clear.svg')
                        }
                    }
                }

            }

            idLog3.warn( "<switch> 230901 1 " )
            if (menuLoaderContext_menu2.menu_source0_text !== '') {
                idLog3.warn( "<switch> 230901 5 " + menuLoaderContext_menu2.menu_source0_text )
                menuLoaderContext_menu2.componentMenu.createMenuItem(
                            root.funcSwitchSource0,
                            menuLoaderContext_menu2.menu_source0_text, true, "")
            }
            if (menuLoaderContext_menu2.menu_source1_text !== '') {
                idLog3.warn( "<switch> 230901 6 " + menuLoaderContext_menu2.menu_source1_text )
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
            if (root.is_export_media != true) {
                menuLoaderContext_menu2.componentMenu._open()
            }

            if (timer_context_menu2_close.running) {
                timer_context_menu2_close.stop()
            }
            timer_context_menu2_close.start()
        }
    }
    function setMode904() {
        var i_automatic_lv = 0;
        //root.key2 = '138'
        var i_is_correct_parent_finded_lv = 0
        var i_is_this_common_panel_lv = 0
        if (false === root.common_panel)
            i_is_this_common_panel_lv = 0
        else {
            i_is_this_common_panel_lv = 1
            //ke2 = 'common_panel908';
        }
        ;

        var b_is_ness_cont_work_lv = true
        if (b_is_ness_cont_work_lv) {
            if (root.is_export_media === 1) {
                idLog3.warn(' 200715 30 ')
                root.m_b_is_caused_by_unload = true
            }
            //ch00715
            if (0 !== root.from_export_media) {
                idLog3.warn(' 200715 31 ')
                root.m_b_is_caused_by_unload = true
            }
            //e

            //ch00715
            if (root.m_b_is_caused_by_unload) {
                if ('keepAspectRatioExport' in render)
                    render.keepAspectRatioExport = 1
            }
            //e
            idLog3.warn(//ch00505 '<common_pan> onKey2Changed root.m_b_is_caused_by_unload ' +
                        '<common_pan> setMode904 root.m_b_is_caused_by_unload xx2 '
                        + root.m_b_is_caused_by_unload)
        }
        //console.info("setMode904() iv_vcli_setting_arc.value = ", iv_vcli_setting_arc.value);
        var i_iv_vcli_setting_arc_lv = 0
        if ('true' === iv_vcli_setting_arc.value)
            i_iv_vcli_setting_arc_lv = 1
        else
            i_iv_vcli_setting_arc_lv = 0


        var v_deb_window_1 = null
        var controls = null


        //ch00425 var iii = 8;
        //ch00425 iii = univreaderex.getI00425(  5 );

        //console.info("setMode904() root.Window = ", root.Window);
        //console.info("setMode904() root.Window.window = ", root.Window.window);
        //console.info("setMode904() root.Window.window.ivComponent = ", root.Window.window.ivComponent);
        if (root.Window.window.ivComponent !== null
                && root.Window.window.ivComponent !== undefined) {
            controls = root.Window.window.ivComponent.findByIvType(
                        'IVSETSAREA',
                        true) //viewer_command_obj.myGlobalComponent;
            i_is_correct_parent_finded_lv = 1
        }
        //ch00422 deb 2
        /*
        if ( 0 === i_is_this_common_panel_lv )
        {
            controls = null;
            i_is_correct_parent_finded_lv = 0;
        }
        */
        //e
        //idLog3.warn(
        //        '<common_pan> controls 90429 3 xx ' +
        //        controls +
        //        ' v_deb_window_1 ' +
        //        v_deb_window_1
        //        );
        var s_controls_lv = 'xxx'
        s_controls_lv = controls
        //ch00421
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

        if ((null === s_controls2_lv || '' === s_controls2_lv)
                && (//ch00424 0 === univreaderex.isTimeFromParentAccepted()
                    0 !== univreaderex.getIdCamerasGroup())) {
            idLog3.warn('<common_pan> 00425 10 ')
            s_controls_lv = 'global_set_200421_' + univreaderex.getIdCamerasGroupAsString()
        }

        //e
        idLog3.warn('<common_pan> controls 90429 4 xx ' + s_controls_lv
                    + ' i_is_correct_parent_finded_lv ' + i_is_correct_parent_finded_lv
                    + " getIdCamerasGroup() " + univreaderex.getIdCamerasGroup(
                        ))
        univreaderex.setCommonPanelMode(i_is_this_common_panel_lv,
                                        i_iv_vcli_setting_arc_lv,
                                        i_is_correct_parent_finded_lv,
                                        s_controls_lv)

        idLog3.warn('<prim> 4 ' + text_primit)
        //deb        if ( '' !== text_primit )
        //        {
        //            idLog3.warn('<prim> 3 '  + root.text_primit );
        //            univreaderex.outputPrimitiv_Causing1( root.text_primit );
        //        }



        //ch230901
        i_automatic_lv = 0;
        if ( 'true' === iv_vcli_setting_arc_automatic_source_select.value )
          i_automatic_lv = 1;
        univreaderex.avtomaticSourceSelectSet( i_automatic_lv );
        idLog3.warn("<switch> 230217 416 root.key2 "
                    + root.key2 + " i_automatic_lv " + i_automatic_lv );
        //e
    }

    function correctIntervalSelectLeft() {
        var i_uu_64_frame_time006_lv = univreaderex.getFrameTimeUUI64()
        correctIntervalSelectLeft_Level1(i_uu_64_frame_time006_lv)
    }

    function correctIntervalSelectLeft_ByCommand() {
        var i_uu_64_command_time_lv = univreaderex.getCommandTimeUUI64()
        correctIntervalSelectLeft_Level1(i_uu_64_command_time_lv)
    }

    function correctIntervalSelectLeft_Level1(i_uu_64_new_bound_time_av) {
        var i_uu_64_bound_time_lv = //ch00609 univreaderex.getFrameTimeUUI64();
                i_uu_64_new_bound_time_av

        idLog3.warn('<interv>correctIntervalSelectLeft_Level1 m_uu_i_ms_begin_interval '
                    + root.m_uu_i_ms_begin_interval + ' i_uu_64_bound_time_lv '
                    + i_uu_64_bound_time_lv)

        if (i_uu_64_bound_time_lv < root.m_uu_i_ms_begin_interval //ch00604
                + 5000//e
                ) {

            //ch00604 root.m_uu_i_ms_end_interval = root.m_uu_i_ms_begin_interval;
            //ch00604 root.m_uu_i_ms_begin_interval = i_uu_64_frame_time_lv;
        } else
            root.m_uu_i_ms_end_interval = i_uu_64_bound_time_lv
    }

    function correctIntervalSelectRight() {
        var i_uu_64_frame_time_lv = univreaderex.getFrameTimeUUI64()
        correctIntervalSelectRight_Level1(i_uu_64_frame_time_lv)
    }

    function correctIntervalSelectRight_Level1(i_uu_64_new_bound_time_av) {
        var i_uu_64_bound_time_lv = i_uu_64_new_bound_time_av

        idLog3.warn('<interv>correctIntervalSelectLeft m_uu_i_ms_end_interval '
                    + root.m_uu_i_ms_end_interval + ' i_uu_64_bound_time_lv '
                    + i_uu_64_bound_time_lv)

        if (root.m_uu_i_ms_end_interval //ch00604
                + 5000 //e
                < i_uu_64_bound_time_lv) {

            //ch00604 root.m_uu_i_ms_begin_interval = root.m_uu_i_ms_end_interval;
            //ch00604 root.m_uu_i_ms_end_interval = i_uu_64_frame_time_lv;
        } else
            root.m_uu_i_ms_begin_interval = i_uu_64_bound_time_lv
    }

    function correctIntervalSelectRight_ByCommand() {
        var i_uu_64_command_time_lv = univreaderex.getCommandTimeUUI64()
        correctIntervalSelectRight_Level1(i_uu_64_command_time_lv)
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
        var i_lv = 0

        i_lv = root.getCamCommonPanelMode()
        if (0 !== univreaderex.isGlobalSet200421())
            i_lv = 0

        return i_lv
    }

    function complete4() {
        idLog3.warn('<start_stop> 241017 009 ')
        primitivesLoader.create()
        idLog3.warn('<start_stop> 241017 010 ')
        equalizerLoader.create()
        idLog3.warn('<start_stop> 241017 011 ')
        //e
    }

    //e ch91112_3
    function buttonPanelSetVisible(b_val_av) {
        //ch90918 ivButtonPane
        //ch90918 .height = i_val_lv;
        //ivButtonPane
        //   .visible = b_val_av;
    }

    //ch90918 - это - спрятать или пок-ть общ панель е
    function commonPanelSetVisible(i_val_av) {

        idLog3.warn('<common_pan> 200712 31 ')

        //deb ch91029 otsech
        var i_height_lv = root.height
        var i_height_contr_panel_lv = wndControlPanel.height
        //ch00117
        root.visible = (0 !== i_val_av)
        //e
        if (0 !== i_val_av) {
            root.height = i_height_contr_panel_lv
        } else {
            root.height = 0
        }
        wndControlPanel.visible = (0 !== i_val_av)
        //ch91111
        //wndControlPanel_phone.visible = ( 0 !== i_val_av );
        //e ch91111
        //ch90617
        //old slider_control_rct
        iv_arc_slider_control//e
        .visible = (0 !== i_val_av)
        //ch90918
        buttonPanelSetVisible(0 !== i_val_av)

        if (ppUp.opened && i_val_av === 0) {
            ppUp.close()
        }

        //e
        // ch91029 otsech end
    }
    function updateTime811_Causing1() {
        idLog3.warn('<calendar> updateTime811_Causing1 b_input_time_outside_cahange '
                    + b_input_time_outside_cahange)
        updateTime811()
    }

    function updateTime811() {
        // ch91029 otsech
        idLog3.warn('updateTime811 begin ')
        //ch00203 univreaderex.putLog807( '---updateTime811' );
        //сформируем time811 e
        var s_date_lv = calend_time.chosenDate
        idLog3.warn('<calendar> updateTime811 calend_time.chosenDate ' + calend_time.chosenDate
                    + ' calend_time.chosenTime ' + calend_time.chosenTime + ' s_date_lv '
                    + s_date_lv + ' timeString ' + calend_time.timeString
                    + ' input_time_outside_cahange ' + root.b_input_time_outside_cahange)
        idLog3.warn('calend_time.chosenDate ' + calend_time.chosenDate + ' calend_time.chosenTime '
                    + calend_time.chosenTime + ' s_date_lv ' + s_date_lv)
        root.time811 = univreaderex.timeFromComponents(s_date_lv,
                                                       //ch81107 temp e
                                                       calend_time.chosenTime)
        //deb '17:05:11' );
        idLog3.warn('updateTime811 root.time811' + root.time811
                    + ' b_input_time_outside_cahange ' + root.b_input_time_outside_cahange)
        if (root.time811 == "") {

        } else {
            idLog3.warn('updateTime811 root.time811 301')
            if (!root.b_input_time_outside_cahange) {
                idLog3.warn('updateTime811 302' + ' univreaderex.time '
                            + univreaderex.time_urx + ' root.time811 ' + root.time811)
                //ch00706
                /*
              if ( 0 !== univreaderex.isDateChanged( univreaderex.time, root.time811 ) )
              {
                  idLog3.warn( 'updateTime811 303 ' );
                  univreaderex.fillCalendarCommand2(
                      root.time811 );
              }
              */
                //e
                univreaderex.time_urx = root.time811
                idLog3.warn('updateTime811 root.time811' + root.time811
                            + ' univreaderex.time ' + univreaderex.time_urx)
            }
            ;
        }
        idLog3.warn('updateTime811 root.time811 4')
        root.b_input_time_outside_cahange = false
        // ch91029 otsech end
    }

    function updateSpeedSlider() {
        var i_speed_lv = 1
        // ch91029 otsech beg
        //vart speed2.text == "1000"
        if (false) {

        } else {
            if (0.125 === iv_speed_slider.speed)
                i_speed_lv = 125
            else if (0.25 === iv_speed_slider.speed)
                i_speed_lv = 250
            else if (0.5 === iv_speed_slider.speed)
                i_speed_lv = 500
            else if (1 === iv_speed_slider.speed)
                i_speed_lv = 1000
            else if (2 === iv_speed_slider.speed)
                i_speed_lv = 2000
            else if (4 === iv_speed_slider.speed)
                i_speed_lv = 4000
            else if (8 === iv_speed_slider.speed)
                i_speed_lv = 8000
            else if (16 === iv_speed_slider.speed)
                i_speed_lv = 16000
            else if (32 === iv_speed_slider.speed)
                i_speed_lv = 32000
            else if (64 === iv_speed_slider.speed)
                i_speed_lv = 64000
            else if (128 === iv_speed_slider.speed)
                i_speed_lv = 128000
            //univreaderex.SendCommandQML();
            univreaderex.setSpeed005(i_speed_lv)
        }
        // ch91029 otsech end
    }

    function correctIntervalSelectLeft_Causing1() {
        //ch00608 univreaderex.setDelayCorrectIntervalSelectLeft( 0 );
        //изменим границы интервала е
        root.correctIntervalSelectLeft()
        correctIntervalSelect_CommonPart()
    }

    function correctIntervalSelect_CommonPart() {
        root.m_i_is_interval_corresp_event = 0
        root.m_s_start_event_id = 0
        iv_arc_slider_control.m_slider_control_asc.drawSelectedInterval()
    }
    function correctIntervalSelectLeft_ByCommand_Causing1() {
        //ch00607 univreaderex.setDelayCorrectIntervalSelectLeft( 0 );
        //изменим границы интервала е
        root.correctIntervalSelectLeft_ByCommand()
        correctIntervalSelect_CommonPart()
    }

    function correctIntervalSelectRight_Causing1() {
        idLog3.warn('<interv> correctIntervalSelectRight_Causing1 beg')

        //ch00608 univreaderex.setDelayCorrectIntervalSelectRight( 0 );
        //изменим границы интервала е
        root.correctIntervalSelectRight()
        correctIntervalSelect_CommonPart()
    }

    function correctIntervalSelectRight_ByCommand_Causing1() {
        idLog3.warn('<interv> correctIntervalSelectRight_ByCommand_Causing1 beg')

        //ch00608 univreaderex.setDelayCorrectIntervalSelectRight( 0 );
        //изменим границы интервала е
        root.correctIntervalSelectRight_ByCommand()
        correctIntervalSelect_CommonPart()
    }

    function correctInterval_Causing1(i_uu_64_time_av) {
        //ch0048m_univreaderex_bpa.setDelayCorrectInterval( 0 );
        //дотянем до этой точки е
        correctInterval_Level1(i_uu_64_time_av)

        root.m_i_is_interval_corresp_event = 0
        root.m_s_start_event_id = 0
        //Пересчитаем коорд нач, конца е
        iv_arc_slider_control.m_slider_control_asc.drawSelectedInterval()
        //изменим лейбл интервал e
        root.m_i_select_interv_state = root.c_I_IS_CORRECT_INTERV
        select_interval_ivibt.txt_tooltip = m_s_tooltip_select_interv_2
    }

    function drawStartInterval() {
        drawStartInterval_Level1(univreaderex.getFrameTimeUUI64())
    }

    function drawStartIntervalByCommand() {
        drawStartInterval_Level1(univreaderex.getCommandTimeUUI64())
    }

    function drawStartInterval_Level1(i_uu_64_changed_time_av) {
        //ch00609 univreaderex.setDelaySetStartInterval( 0 );
        //e
        //зададим маленький начальный интервал е
        var i_uu_64_frame_time_lv = 0
        i_uu_64_frame_time_lv = //ch00608 univreaderex.getFrameTimeUUI64();
                i_uu_64_changed_time_av
        idLog3.warn('select_interval_ivichb onClicked bef addDeltaTimeUU64')
        root.m_uu_i_ms_begin_interval = i_uu_64_frame_time_lv
        root.m_uu_i_ms_begin_interval = root.m_uu_i_ms_begin_interval - 5000
        idLog3.warn('<' + root.key2 + '_' + root.key3 + '>'
                    + 'select_interval_ivichb onClicked aft addDeltaTimeUU64 begn '
                    + root.m_uu_i_ms_begin_interval)
        idLog3.warn('select_interval_ivichb onClicked bef addDeltaTimeUU64 2')
        root.m_uu_i_ms_end_interval = i_uu_64_frame_time_lv
        root.m_uu_i_ms_end_interval = root.m_uu_i_ms_end_interval + 5000
        root.m_i_select_interv_state = root.c_I_IS_SECOND_SELECT_INTERV
        idLog3.warn('select_interval_ivichb onClicked aft addDeltaTimeUU64 end '
                    + root.m_uu_i_ms_end_interval)
        idLog3.warn(' ' + ' i_uu_64_frame_time_lv ' + i_uu_64_frame_time_lv)
        //vart if ( root.m_i_width_visible_bound2 < rootRect.width )
        //vart {
        upload_left_bound_lb.visible4 = true
        upload_left_bound_2_lb.visible4 = true

        //vart }
        //Зададим подсказку е
        select_interval_ivibt.txt_tooltip = Language.getTranslate(
                    "select the second boundary of the interval and click",
                    "выберите вторую границу интервала и нажмите")
        //Пересчитаем коорд нач, конца е
        idLog3.warn('select_interval_ivichb onClicked ' + ' i_uu_64_frame_time_lv '
                    + i_uu_64_frame_time_lv + //                                            ' f_left_bound_lv ' + f_left_bound_lv +
                    //                                            ' f_right_bound_lv ' + f_right_bound_lv +
                    ' width_visible_bound2 ' + root.m_i_width_visible_bound2
                    + ' rootRect.width ' // +//ch90918 rootRect_ButtonFullPaneArc
                    //rootRect_ButtonPane
                    //      .width
                    )

        /*deb ch90623*/
        root.m_i_is_interval_corresp_event = 0
        //ch90723 root.m_b_ness_check_present_event = 0;
        root.m_s_start_event_id = 0

        iv_arc_slider_control.m_slider_control_asc.drawSelectedInterval(
                    //                                               f_left_bound_lv, f_right_bound_lv,
                    //                                               1.0
                    )
    }

    function getFrameTime() {
        var i64_time_lv = 0
        i64_time_lv = univreaderex.getFrameTimeUUI64()
        idLog3.warn('<photocam> getFrameTime time ' + i64_time_lv)
        return univreaderex.getFrameTimeUUI64()
    }
    function extComponentsSetVisible(b_is_visible_av) {
        //ch91112 приписал 2 е
        select_interval_ivibt.visible2 = b_is_visible_av
        upload_left_bound_2_lb.visible2 = b_is_visible_av
        upload_left_bound_lb.visible2 = b_is_visible_av
        //menu_interval2.visible = b_is_visible_av;
        //ср91031 force_write_ivibt.visible = b_is_visible_av;
        //ch91112 приписал 2 е
        iv_butt_spb_events_skip.visible2 = b_is_visible_av
        iv_butt_spb_bmark_skip.visible2 = b_is_visible_av
    }

    function complete2() {
        var b_cond_lv = false

        //ch90916 if ( 0 !== root.
        //ch90916 getCamCommonPanelMode()
        //ch90916 )
        //ch90916 {
        //var qml = '/qtplugins/iv/sound/PaneSound.qml';
        //ivCreator808_ButtonPane.asyncCreate('Unique', 'file:///' + applicationDirPath + qml, sound_rect_rec_ButtonPane);

        //qml = '/qtplugins/iv/imagecorrector/ImageCorrector.qml';
        //ivCreator808_3_ButtonPane.asyncCreate('Unique', 'file:///' + applicationDirPath + qml,
        //                         image_corr_rec_ButtonPane);

        //qml = '/qtplugins/iv/photocam/PanePhotoCam.qml';
        //ivCreator808_2_ButtonPane.asyncCreate('Unique', 'file:///' + applicationDirPath + qml,
        //                         photo_cam_rec_ButtonPane);
		
        idLog3.warn('<start_stop> 241017 002 ')
		
        if (root.arc_common_panel === false) {
            idLog3.warn('<start_stop> 241017 003 ')
            soundLoader.create()
            idLog3.warn('<start_stop> 241017 004 ')
            image_correctLoader.create()
            idLog3.warn('<start_stop> 241017 005 ')
            photocamLoader.create()
            idLog3.warn('<start_stop> 241017 006 ')
            fullscreenButton_ButtonPane.visible = true
            unload_to_avi_ivibt_ButtonPane.visible = true
        } else {
            if (root.key2 !== "common_panel") {
                export_media_button.visible = true
                sound_rect_rec_ButtonPane.width = 24 * root.isize
                sound_rect_rec_ButtonPane.visible = true
                sound_Loader.create()
                photocam_Loader.create()
                switch_to_real_time_button.visible = true
                image_correct_Loader.create()
                fullscreen_button.visible = true
            } else {
                fullscreenRect.width = 1
                fullscreenRect.visible = false
                fullscreenButton_ButtonPane.visible = false
                export_aviRect.width = 1
                export_aviRect.visible = false
                unload_to_avi_ivibt_ButtonPane.visible = false
                image_corr_rec_ButtonPane.width = 1
                image_corr_rec_ButtonPane.visible = false
                rectEvents_skip.width = 1
                rectEvents_skip.visible = false
                rectBmark_skip.width = 1
                rectBmark_skip.visible = false
                rectSelect_interval_ivibt.width = 1
                rectSelect_interval_ivibt.visible = false
                select_interval_ivibt._width = 1
                select_interval_ivibt.visible = false
                photo_cam_rec_ButtonPane.visible = false
                photo_cam_rec_ButtonPane.width = 1
                sound_rect_rec_ButtonPane.width = 1
                sound_rect_rec_ButtonPane.visible = false
            }
        }


        //ch91031 deb
        //            if ( false === root.isCommonPanel() )
        //            {
        //                qml = '/qtplugins/iv/archivecomponents/force_write/qforce_write3.qml';
        //                ivCreator910_ButtonPane.asyncCreate('Unique', 'file:///' + applicationDirPath + qml,
        //                                         deb_force_write_rec_ButtonPane);
        //            }
        //e ch91031

        //ch90916 };
        idLog3.warn('<start_stop> 241017 007 ')
        b_cond_lv = (0 === root.getCamCommonPanelModeUseSetPanel())

        idLog3.warn('<root> complete2 getCamCommonPanelModeUseSetPanel ' + b_cond_lv)

        //vart ||
        //vart root.common_panel
        if (0 === root.getCamCommonPanelModeUseSetPanel_Deb()) {

            //cg90918 anchors.bottomMargin = 57;
            //ch90918
            //ch91023_3 rootRect_ButtonPane.mousearea_CommonPanMode.anchors.
            //ch91023_3 bottomMargin = 57;
            //e
            b_cond_lv = root.isSmallMode()

            idLog3.warn('<root> complete2 b_cond_lv ' + b_cond_lv)

            //ch91030
            if (!root.isSmallMode()) //e
            {
                mousearea_CommonPanMode.enabled = false
            }
        } else {
            extComponentsSetVisible(false)
        }
    }

    //ch90917
    function showInterval908(uu_i_ms_begin_interval_av, uu_i_ms_end_interval_av, s_event_text_interval_av) {
        var s_event_text_trunc_lv = ''
        s_event_text_trunc_lv = univreaderex.truncUTF8StrUR(
                    s_event_text_interval_av, 20)

        root.m_uu_i_ms_begin_interval = uu_i_ms_begin_interval_av
        root.m_uu_i_ms_end_interval = uu_i_ms_end_interval_av
        root.m_i_select_interv_state = root.c_I_IS_CORRECT_INTERV

        select_interval_ivibt.txt_tooltip = m_s_tooltip_select_interv_2

        //ch00708 old idLog3.warn('<events>moveToEventBySlider_Causing1 m_uu_i_ms_begin_interval ' +
        idLog3.warn('<' + root.key2 + '_' + root.key3 + '_events>'
                    + ' showInterval908 m_uu_i_ms_begin_interval ' + root.m_uu_i_ms_begin_interval
                    + ' m_uu_i_ms_end_interval ' + root.m_uu_i_ms_end_interval)

        iv_arc_slider_control.m_slider_control_asc.drawSelectedInterval()

        //ch90812
        upload_left_bound_2_lb.text = Language.getTranslate(
                    "Interval selected", "Выбран интервал")
        //console.info("ArchivePlayer s_event_text_interval_av = ", s_event_text_interval_av);
        if ('' !== s_event_text_interval_av) {
            if (s_event_text_interval_av === s_event_text_trunc_lv) {
                upload_left_bound_2_lb.text += ' ' + s_event_text_interval_av
                tooltip908.contentItem.text = ''
            } else {
                upload_left_bound_2_lb.text += ' ' + s_event_text_trunc_lv
                //vart upload_left_bound_2_lb.txt_tooltip
                tooltip908.contentItem.text = s_event_text_interval_av
            }
        }
        //e
        //ch90806
        upload_left_bound_lb.visible4 = true
        upload_left_bound_2_lb.visible4 = true
        //e
    }

    function moveToEventBySlider_Causing1(b_is_right_av, b_is_bookmarks_av, rl_mess_x_av, rl_mess_y_av) {
        var i_res_lv = 0
        var i_curr_time_lv = univreaderex.getCurrTime()

        var s_event_text_lv = ''
        var i_is_already_interval_selected_lv = 0
        var s_warning_pref_lv = ''

        idLog3.warn('<events>moveToEventBySlider_Causing1 bef request '
                    + ' root.m_i_marker_last_request_to_events '
                    + root.m_i_marker_last_request_to_events + ' i_curr_time_lv '
                    + i_curr_time_lv + ' root.m_i_current_timeout_request_to_events '
                    + root.m_i_current_timeout_request_to_events)

        if (root.m_i_current_timeout_request_to_events > 20000
                || root.m_i_marker_last_request_to_events + 40000 < i_curr_time_lv)
            root.m_i_current_timeout_request_to_events = 2000

        if (0 !== root.m_uu_i_ms_begin_interval)
            i_is_already_interval_selected_lv = 1
        i_res_lv = univreaderex.moveToEventBySlider(
                    b_is_right_av, b_is_bookmarks_av,
                    i_is_already_interval_selected_lv,
                    root.m_i_current_timeout_request_to_events)
        //ch90717
        idLog3.warn('<events>moveToEventBySlider_Causing1 i_res_lv ' + i_res_lv
                    + ' rl_mess_x_av ' + rl_mess_x_av + ' rl_mess_y_av '
                    + rl_mess_y_av + ' root.m_i_current_timeout_request_to_events '
                    + root.m_i_current_timeout_request_to_events)
        //ch90725
        if (root.c_I_TIMEOUT_907 === i_res_lv) {
            root.m_i_current_timeout_request_to_events += 2000
            //ch90802 hint = '';
            //ch90731
            //ch90918 rootRect_ButtonFullPaneArc
            root.showNextEventNotFoundMess(
                        root.m_i_current_timeout_request_to_events,
                        rl_mess_x_av, rl_mess_y_av,
                        'событие за ' + root.m_i_current_timeout_request_to_events
                        / 1000 + ' сек не найденно, попробуйте еще раз')
            //e ch90731
        } //e
        //ch90805
        else if (root.c_I_NOT_FOUND_907 === i_res_lv) {
            //ch90918 rootRect_ButtonFullPaneArc
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
    function positioningMenu() {
        //menu_interval2.x =
        menuLoaderSelInterv.componentMenu.x = select_interval_ivibt.x
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
        menuLoaderSelInterv.componentMenu.y = //select_interval_ivichb
                //select_interval_ivibt
                rectSelect_interval_ivibt.y
    }

    function positioningContextMenu() {
        menuLoaderContext_menu2.componentMenu.x = mouseAreaRender.mouseX
        menuLoaderContext_menu2.componentMenu.y = mouseAreaRender.mouseY
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
        //ch91112_2 var pt_mapped_pos_lv = null;
        next_event_not_found_rct_hint.visible = true
        m_i_event_not_found_visible_counter = 7

        //ch90704 next_event_not_found_rct_hint.x = m_mouseX_bpa - 5;
        i_x_lv = rl_x_av
        i_y_lv = rl_y_av
        //ch91112_2 pt_mapped_pos_lv = mapToItem
        //ch91112_2 ( root, i_x_lv, i_y_lv );
        next_event_not_found_rct_hint.x = //ch91112_2 pt_mapped_pos_lv.x;
                i_x_lv
        next_event_not_found_rct_hint.y = //ch91112_2 pt_mapped_pos_lv.y;
                i_y_lv

        next_event_not_found_rct_hint_text.text = //'событие за ' + i_timeout_av / 1000 +
                //' сек не найденно, попробуйте еще раз'
                s_text_av
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
        select_interval_ivibt.visible2 = b_av
        iv_butt_spb_events_skip.visible2 = b_av
        iv_butt_spb_bmark_skip.visible2 = b_av
        photo_cam_rec_ButtonPane.visible = b_av

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
        unload_to_avi_ivibt_ButtonPane.visible = false
        switchToRealTime_ButtonPane.visible = false

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

    function getSmallSizePanel() {
        return rectCalendarTime.width + rectPlay_ivichb.width
                + export_aviRect.width + rectSwitchToRealTime_ButtonPane.width
                + rectInterval_mashtab.width + fullscreenRect.width + 14
    }

    function getNormalSizePanel() {
        return rectCalendarTime.width + rectPlay_ivichb.width + export_aviRect.width
                + rectSwitchToRealTime_ButtonPane.width + rectInterval_mashtab.width
                + fullscreenRect.width + rectRevers_ivichb.width + 33 + rectEvents_skip.width
                + rectBmark_skip.width + rectSelect_interval_ivibt.width
                + sound_rect_rec_ButtonPane.width + photo_cam_rec_ButtonPane.width
                + image_corr_rec_ButtonPane.width + 30
    }

    function getPanelSizeCommonPanelMode() {
        return rectCalendarTime.width + rectPlay_ivichb.width + rectRevers_ivichb.width
                + speed_ch_box_rec.width + rectInterval_mashtab.width
                + rectSwitchToRealTime_ButtonPane.width + 18
    }

    function safeSetProperty(component, prop, func) {
        if (prop in component) {
            component[prop] = func
        }
    }

    function funcSelectInterval_right() {
        if (0 !== univreaderex.isFrameCounterCorrespondCommand()) {
            idLog3.warn("<interv> 107")
            root.correctIntervalSelectLeft_Causing1()
        } else {
            idLog3.warn("<interv> 108")
            //ch00607
            //ch00607 univreaderex.setDelayCorrectIntervalSelectRight( 1 );
            root.correctIntervalSelectLeft_ByCommand_Causing1()
            //e
        }
    }
    function funcSelectInterval_left() {
        idLog3.warn('<interv>	507')
        if (0 !== univreaderex.isFrameCounterCorrespondCommand()) {
            idLog3.warn('<interv>	508')
            root.correctIntervalSelectRight_Causing1()
        } else {
            idLog3.warn('<interv>	509')
            //ch00607
            //ch00607 univreaderex.setDelayCorrectIntervalSelectLeft( 1 );
            root.correctIntervalSelectRight_ByCommand_Causing1()
            //e
        }
    }
    function funcChange() {
        idLog3.warn('<' + root.key2 + '_' + root.key3 + '_interv> 50')
        if (0 !== univreaderex.isFrameCounterCorrespondCommand()) {
            idLog3.warn("<interv> 54")
            root.correctInterval_Causing1(univreaderex.getFrameTimeUUI64())
        } else {
            idLog3.warn("<interv>	57")
            //ch00608
            //ch00608 univreaderex.setDelayCorrectInterval( 1 );
            root.correctInterval_Causing1(univreaderex.getCommandTimeUUI64())
            //e
        }
    }
    function funcGo_to_begin() {
        univreaderex.outsideSetTimeMS(root.m_uu_i_ms_begin_interval)
    }
    function funcGo_to_end() {
        univreaderex.outsideSetTimeMS(root.m_uu_i_ms_end_interval)
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
    function funcCall_Unload_window() {
        export_aviLoader.create()
    }
    function funcUnload() {
        univreaderex.unload007(root.m_uu_i_ms_begin_interval,
                               root.m_uu_i_ms_end_interval)

        var win_count = MExprogress.windows_count
        idLog3.trace('<IVButtonPaneArc.qml> menu_item_unload onTriggered win_count = ' + win_count)
        idLog3.trace('<IVButtonPaneArc.qml> menu_item_unload onTriggered  export_status_window.value = ' + export_status_window.value)
        if (win_count === 0 && export_status_window.value === "true") {
            idarchive_player.createExprogressWindow()
        }
    }
    function funcReset_selection() {
        //print("Action 2")
        //ch90719
        root.m_uu_i_ms_begin_interval = 0
        root.m_uu_i_ms_end_interval = 0

        //e ch90719
        iv_arc_slider_control.m_slider_control_asc.clearFill2()
        upload_left_bound_lb.visible4 = false
        upload_left_bound_2_lb.visible4 = false
        root.m_i_select_interv_state = root.c_I_IS_FIERST_SELECT_INTERV
        select_interval_ivibt.txt_tooltip = root.m_s_tooltip_select_interv_1
    }
    //ch230324
    function complete2303() {
        idLog3.warn("<slider_new> 57 root.key2 " + root.key2
                    + " m_b_ke2_changed_2303 " + m_b_ke2_changed_2303
                    + " m_component_completed_2303 " + m_component_completed_2303
                    + " m_b_complete_2303_fierst_time " + m_b_complete_2303_fierst_time)
        if (m_b_ke2_changed_2303 && m_component_completed_2303) {
            idLog3.warn("<slider_new> 58 root.key2 " + root.key2)
            if (m_b_complete_2303_fierst_time) {
                m_b_complete_2303_fierst_time = false
                //ch230324 здесь все проинициировано e
                idLog3.warn("<slider_new> 60 root.key2 "
                            + root.key2 );
            }
        }
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
    //e
    Shortcut {
        sequence: StandardKey.ZoomIn
        onActivated: {
        }
    }
}

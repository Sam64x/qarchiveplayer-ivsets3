import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

import QtQuick.Templates 2.0 as T

import iv.plugins.loader 1.0
import iv.guicomponents 1.0

import iv.plugins.users 1.0

import iv.photocam 1.0
import iv.calendar 1.0

Rectangle
{
    id: rootRect_ButtonFullPaneArc
    property variant m_univreaderex_bfpa: null
    property variant m_idLog2_bfpa: null
    property variant m_idLog3_bfpa: null
    property variant m_iv_arc_slider_control_bfpa: null
    property variant m_render_bfpa: null
    //ch90804 property variant m_mouseX_bfpa: null



    property variant m_upload_left_bound_lb_bfpa: upload_left_bound_lb
    property variant m_upload_left_bound_2_lb_bfpa: upload_left_bound_2_lb
    property variant m_force_write_ivibt_bfpa: force_write_ivibt

    property variant m_iv_butt_spb_events_skip_bfpa: iv_butt_spb_events_skip

    property variant m_iv_butt_spb_bmark_skip_bfpa: iv_butt_spb_bmark_skip


    //пример того что передается во владельца е
    //prot property variant m_slider_control_asc: slider_control
    //пример того что передается из владельца е
    property variant m_root_bfpa: null
    //пример того что передается из владельца е
    //property variant m_upload_left_bound_lb_asc: null

    property int m_i_event_not_found_visible_counter: 0

    property string m_s_tooltip_select_interv_2:
        'изменить границу интервала и другие операции с интервалом'

    anchors.fill: parent
    anchors.leftMargin: 330
    anchors.rightMargin: 0
    color: "transparent"

    function showInterval908( uu_i_ms_begin_interval_av,
                              uu_i_ms_end_interval_av,
                              s_event_text_interval_av )
    {
        var s_event_text_trunc_lv = '';
        s_event_text_trunc_lv = m_univreaderex_bfpa.truncUTF8StrUR( s_event_text_interval_av, 20 );

        m_root_bfpa.m_uu_i_ms_begin_interval = uu_i_ms_begin_interval_av;
        m_root_bfpa.m_uu_i_ms_end_interval = uu_i_ms_end_interval_av;
        m_root_bfpa.m_i_select_interv_state = m_root_bfpa.c_I_IS_CORRECT_INTERV;

        select_interval_ivibt.txt_tooltip =
                m_s_tooltip_select_interv_2;

        m_idLog3_bfpa.warn('<events>moveToEventBySlider_Causing1 m_uu_i_ms_begin_interval ' +
          m_root_bfpa.m_uu_i_ms_begin_interval +
          ' m_uu_i_ms_end_interval ' +
          m_root_bfpa.m_uu_i_ms_end_interval );


        m_iv_arc_slider_control_bfpa.m_slider_control_asc.
            drawSelectedInterval();

        //ch90812
        upload_left_bound_2_lb.text =
                'Выбран интервал ';
        if ( '' !== s_event_text_interval_av )
        {
            if ( s_event_text_interval_av === s_event_text_trunc_lv )
            {
                upload_left_bound_2_lb.text +=
                        ' ' + s_event_text_interval_av;
                tooltip908.text = '';
            }
            else
            {
                upload_left_bound_2_lb.text +=
                        ' ' + s_event_text_trunc_lv;
                //vart upload_left_bound_2_lb.txt_tooltip
                tooltip908.text
                        =
                        s_event_text_interval_av;

            }
        }
        //e
        //ch90806
        upload_left_bound_lb.visible4 = true;
        upload_left_bound_2_lb.visible4 = true;
        //e
    }


    function moveToEventBySlider_Causing1( b_is_right_av, b_is_bookmarks_av,
                                           rl_mess_x_av, rl_mess_y_av  )
    {
        var i_res_lv = 0;
        var i_curr_time_lv = m_univreaderex_bfpa.getCurrTime();

        var s_event_text_lv = '';

        m_idLog3_bfpa.warn('<events>moveToEventBySlider_Causing1 bef request ' +
          ' m_root_bfpa.m_i_marker_last_request_to_events ' +
          m_root_bfpa.m_i_marker_last_request_to_events +
          ' i_curr_time_lv ' +
          i_curr_time_lv +
          ' m_root_bfpa.m_i_current_timeout_request_to_events ' +
          m_root_bfpa.m_i_current_timeout_request_to_events );

        if ( m_root_bfpa.m_i_current_timeout_request_to_events > 20000 ||
                m_root_bfpa.m_i_marker_last_request_to_events + 40000 < i_curr_time_lv )
          m_root_bfpa.m_i_current_timeout_request_to_events = 2000;


        i_res_lv = m_univreaderex_bfpa.moveToEventBySlider
                         ( b_is_right_av, b_is_bookmarks_av,
                           m_root_bfpa.m_i_current_timeout_request_to_events );
        //ch90717
        m_idLog3_bfpa.warn('<events>moveToEventBySlider_Causing1 i_res_lv ' +
          i_res_lv + ' rl_mess_x_av ' + rl_mess_x_av + ' rl_mess_y_av ' +
          rl_mess_y_av + ' m_root_bfpa.m_i_current_timeout_request_to_events ' +
          m_root_bfpa.m_i_current_timeout_request_to_events );
        //ch90725
        if ( m_root_bfpa.c_I_TIMEOUT_907 === i_res_lv )
        {
          m_root_bfpa.m_i_current_timeout_request_to_events += 2000;
          //ch90802 hint = '';
          //ch90731
          rootRect_ButtonFullPaneArc.showNextEventNotFoundMess(
              m_root_bfpa.m_i_current_timeout_request_to_events, rl_mess_x_av, rl_mess_y_av,
                      'событие за ' + m_root_bfpa.m_i_current_timeout_request_to_events /
                      1000 +
                      ' сек не найденно, попробуйте еще раз' );
          //e ch90731
        }
        //e
        //ch90805
        else if ( m_root_bfpa.c_I_NOT_FOUND_907 === i_res_lv )
        {
            rootRect_ButtonFullPaneArc.showNextEventNotFoundMess(
                m_root_bfpa.m_i_current_timeout_request_to_events, rl_mess_x_av, rl_mess_y_av,
                                'событие для заданного промежутка не существует'
                        );
        }
        //e
        else if ( m_root_bfpa.c_I_SUCCESS_907 === i_res_lv )
        {
            m_root_bfpa.m_i_is_interval_corresp_event = 1;
            //ch90723 m_root_bfpa.m_b_ness_check_present_event = 0;
            m_root_bfpa.m_i_is_interval_corresp_event_bookmark =
                    b_is_bookmarks_av ? 1 : 0;
            m_root_bfpa.m_s_start_event_id = m_univreaderex_bfpa.getLastSelectedEventStartId();

            s_event_text_lv = m_univreaderex_bfpa.getLastSelectedEventText();
            showInterval908(
                        m_univreaderex_bfpa.getLastSelectedEventBegin(),
                        m_univreaderex_bfpa.getLastSelectedEventEnd(),
                        s_event_text_lv
                        );
        }
        //e
        m_root_bfpa.m_i_marker_last_request_to_events = i_curr_time_lv;
    }
    function positioningMenu()
    {
        menu_interval2.x =
                //select_interval_ivichb
                select_interval_ivibt
                .x;
        if ( menu_interval2.width + 10 <
                //select_interval_ivichb
                select_interval_ivibt
                .x )
        {
            menu_interval2.x =
                    //select_interval_ivichb
                    select_interval_ivibt
                    .x
                    + 20;
        };
        menu_interval2.y =
          //select_interval_ivichb
          select_interval_ivibt
          .y;
    }

    function timerActions()
    {
      m_i_event_not_found_visible_counter--;
      if ( 0 === m_i_event_not_found_visible_counter )
      {
          next_event_not_found_rct_hint.visible = false;
      }
    }
    function showNextEventNotFoundMess( i_timeout_av, rl_x_av, rl_y_av, s_text_av )
    {
        var i_x_lv = 10;
        var i_y_lv = 10;
        next_event_not_found_rct_hint.visible = true;
        m_i_event_not_found_visible_counter = 7;

        //ch90704 next_event_not_found_rct_hint.x = m_mouseX_bfpa - 5;
        i_x_lv = rl_x_av;
        i_y_lv = rl_y_av;
        m_idLog3_bfpa.warn( '<events> showNextEventNotFoundMess i_x_lv ' +
                            i_x_lv + ' i_y_lv ' + i_y_lv );

        next_event_not_found_rct_hint.x = i_x_lv;//rl_x_av;
        next_event_not_found_rct_hint.y = i_y_lv;//rl_y_av;

        next_event_not_found_rct_hint_text.text =
                //'событие за ' + i_timeout_av / 1000 +
                //' сек не найденно, попробуйте еще раз'
                s_text_av;
        next_event_not_found_rct_hint.width =
           next_event_not_found_rct_hint_text.contentWidth;
        next_event_not_found_rct_hint.height =
           next_event_not_found_rct_hint_text.contentHeight;
    }
    function commonPanelExtButtonsSetVisible( b_av )
    {
        /*ch90916
        sound_rect_rec.visible = b_av;
        photo_cam_rec.visible = b_av;
        image_corr_rec.visible = b_av;
        ch90916*/
        force_write_ivibt.visible = b_av;
        select_interval_ivibt.visible2 = b_av;
        iv_butt_spb_events_skip.visible2 = b_av;
        iv_butt_spb_bmark_skip.visible2 = b_av;

        //ch90916 unload_to_avi_ivibt.visible = b_av;
    }
    function part1SetVisible( b_av )
    {
        upload_left_bound_2_lb.visible3 = b_av;
        upload_left_bound_lb.visible3 = b_av;
        iv_butt_spb_events_skip.visible3 = b_av;
        iv_butt_spb_bmark_skip.visible3 = b_av;
        select_interval_ivibt.visible3 = b_av;
    }
    function part2SetVisible( b_av )
    {
        /*ch90916
        sound_rect_rec.visible = b_av;
        photo_cam_rec.visible = b_av;
        image_corr_rec.visible = b_av;
        ch90916*/
        force_write_ivibt.visible = b_av &&
          m_root_bfpa.m_b_is_by_events;
        select_interval_ivibt.visible2 = b_av;
        //ch90613 key2_lb.visible = true;

        //ch90916 unload_to_avi_ivibt.visible = b_av && !m_root_bfpa.m_b_is_caused_by_unload;

        iv_butt_spb_events_skip.visible2 = b_av && !m_root_bfpa.m_b_is_caused_by_unload;
        iv_butt_spb_bmark_skip.visible2 = b_av && !m_root_bfpa.m_b_is_caused_by_unload;
    }
    /*ch90916
    function complete3()
    {
        var qml = '/qtplugins/iv/sound/PaneSound.qml';
        ivCreator808.asyncCreate('Unique', 'file:///' + applicationDirPath + qml,
                                 sound_rect_rec);
        qml = '/qtplugins/iv/imagecorrector/ImageCorrector.qml';
        ivCreator808_3.asyncCreate('Unique', 'file:///' + applicationDirPath + qml,
                                 image_corr_rec);
        qml = '/qtplugins/iv/photocam/PanePhotoCam.qml';
        ivCreator808_2.asyncCreate('Unique', 'file:///' + applicationDirPath + qml,
                                 photo_cam_rec);
    }
    ch90916*/
    function complete5()
    {
        m_idLog2_bfpa.warn( 'onCompleted prop present' );

        //ch90916 unload_to_avi_ivibt.visible = false;
        //ch90916 realtime_ivibt.visible = false;

        iv_butt_spb_events_skip.visible2 = false;
        iv_butt_spb_bmark_skip.visible2 = false;
    }
    function correctInterval()
    {
        var i_uu_64_frame_time_lv =
          m_univreaderex_bfpa.getFrameTimeUUI64();
        if ( i_uu_64_frame_time_lv < m_root_bfpa.m_uu_i_ms_begin_interval )
          m_root_bfpa.m_uu_i_ms_begin_interval = i_uu_64_frame_time_lv;
        else if ( m_root_bfpa.m_uu_i_ms_end_interval < i_uu_64_frame_time_lv )
          m_root_bfpa.m_uu_i_ms_end_interval = i_uu_64_frame_time_lv;
    }
    IvAccess {
      id: move_to_event
      access: "{move_to_event}"
    }
    IvAccess {
      id: move_to_bmark
      access: "{move_to_bmark}"
    }

    IVImageButton
    {
        id: select_interval_ivibt
        anchors.top: parent.top
        anchors.topMargin:
            5
        //ch90916 anchors.right: unload_to_avi_ivibt.left
        anchors.rightMargin: 5
        property bool visible2: true
        property bool visible3: true
        visible: visible2 && visible3
        size: "small"
        _width: 18
        txt_tooltip: m_root_bfpa.m_s_tooltip_select_interv_1
        on_source: 'file:///' + applicationDirPath + '/images/white/flag_left.svg'
        onClicked:{
//                            var f_left_bound_lv =  0.0;
//                            var f_right_bound_lv = 0.0;
            if ( m_root_bfpa.c_I_IS_FIERST_SELECT_INTERV === m_root_bfpa.m_i_select_interv_state  )
            {
                //зададим маленький начальный интервал е
                var i_uu_64_frame_time_lv = 0;
                i_uu_64_frame_time_lv =
                  m_univreaderex_bfpa.getFrameTimeUUI64();
                m_idLog3_bfpa.warn('select_interval_ivichb onClicked bef addDeltaTimeUU64' );
                m_root_bfpa.m_uu_i_ms_begin_interval = i_uu_64_frame_time_lv;
                m_root_bfpa.m_uu_i_ms_begin_interval
                      = m_root_bfpa.m_uu_i_ms_begin_interval - 5000;
                m_idLog3_bfpa.warn(
                  'select_interval_ivichb onClicked aft addDeltaTimeUU64 begn ' +
                  m_root_bfpa.m_uu_i_ms_begin_interval );
                m_idLog3_bfpa.warn('select_interval_ivichb onClicked bef addDeltaTimeUU64 2' );
                m_root_bfpa.m_uu_i_ms_end_interval = i_uu_64_frame_time_lv;
                m_root_bfpa.m_uu_i_ms_end_interval
                  = m_root_bfpa.m_uu_i_ms_end_interval + 5000;
                m_root_bfpa.m_i_select_interv_state = m_root_bfpa.c_I_IS_SECOND_SELECT_INTERV;
                m_idLog3_bfpa.warn(
                  'select_interval_ivichb onClicked aft addDeltaTimeUU64 end ' +
                  m_root_bfpa.m_uu_i_ms_end_interval
                            );
                m_idLog3_bfpa.warn(' ' +
                            ' i_uu_64_frame_time_lv ' + i_uu_64_frame_time_lv );
                //vart if ( m_root_bfpa.m_i_width_visible_bound2 < rootRect.width )
                //vart {
                    upload_left_bound_lb.visible4 = true;
                    upload_left_bound_2_lb.visible4 = true;
                //vart }
                //Зададим подсказку е
                txt_tooltip = "выберите вторую границу интервала и нажмите"
                //Пересчитаем коорд нач, конца е
                m_idLog3_bfpa.warn('select_interval_ivichb onClicked ' +
                            ' i_uu_64_frame_time_lv ' + i_uu_64_frame_time_lv +
//                                            ' f_left_bound_lv ' + f_left_bound_lv +
//                                            ' f_right_bound_lv ' + f_right_bound_lv +
                            ' width_visible_bound2 ' +
                            m_root_bfpa.m_i_width_visible_bound2 +
                            ' rootRect.width ' +
                            rootRect_ButtonFullPaneArc.width
                            );

                /*deb ch90623*/
                m_root_bfpa.m_i_is_interval_corresp_event = 0;
                //ch90723 m_root_bfpa.m_b_ness_check_present_event = 0;
                m_root_bfpa.m_s_start_event_id = 0;


                m_iv_arc_slider_control_bfpa.m_slider_control_asc.
                    drawSelectedInterval(
//                                               f_left_bound_lv, f_right_bound_lv,
//                                               1.0
                               );
            }
            else if ( m_root_bfpa.c_I_IS_SECOND_SELECT_INTERV === m_root_bfpa.m_i_select_interv_state  )
            {
                //ch90801 Sm_root_bfpa.
                positioningMenu()
                menu_item_change.visible = true;
                menu_item_select_interval_left.visible = false;
                menu_item_select_interval_right.visible = false;
                menu_item_go_to_begin.visible = false;
                menu_item_go_to_end.visible = false;
                menu_item_save_interval.visible = false;
                menu_item_call_unload_window.visible = false;
                onClicked: menu_interval2.open();
                //vart onClicked: menu_interval.popup(mouseX, mouseY)
            }
            else if ( m_root_bfpa.c_I_IS_CORRECT_INTERV === m_root_bfpa.m_i_select_interv_state  )
            {
                //вызовем меню е
                positioningMenu()
                menu_item_change.visible = false;
                menu_item_select_interval_left.visible = true;
                menu_item_select_interval_right.visible = true;
                menu_item_go_to_begin.visible = true;
                menu_item_go_to_end.visible = true;
                menu_item_save_interval.visible = true;
                menu_item_call_unload_window.visible = true;
                //если границы не поменялись то не отобр пункты
                  //изменения интервала
                if (
                     Math.abs( m_univreaderex_bfpa.getFrameTimeUUI64() -
                          m_root_bfpa.m_uu_i_ms_begin_interval ) < 500
                     ||
                     Math.abs( m_univreaderex_bfpa.getFrameTimeUUI64() -
                          m_root_bfpa.m_uu_i_ms_end_interval ) < 500
                   )
                {
                    menu_item_select_interval_left.visible = false;
                    menu_item_select_interval_right.visible = false;
                    if ( m_root_bfpa.m_i_is_interval_corresp_event &&
                            ! ( m_root_bfpa.m_i_is_interval_corresp_event_bookmark ) )
                      menu_item_save_interval.visible = false;
                }
                //e

                onClicked: menu_interval2.open();
            }
        }
    }
    Label {
        id: upload_left_bound_2_lb
        text: 'Выбран интервал'
        //font.pointSize: 11
        font.pixelSize: 9
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.left: upload_left_bound_lb.left
        anchors.rightMargin: 5
        property bool visible2: true
        property bool visible3: true
        property bool visible4: false
        visible: visible2 && visible3 && visible4
        color:'white'

        //vart hoverEnabled: true
        ToolTip
        {
            id: tooltip908
            delay: 1000
            timeout: 5000
            //vart visible:
            text: ''
                //vart qsTr("This tool tip is shown after hovering the button for a second.")
        }
        MouseArea {
            id: upload_left_bound_2_lb_mouse_area
            //ch90813 z: 120
            anchors.top: parent.top
            //ch90813anchors.topMargin: 20
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            hoverEnabled: true
            onEntered: {
                if (
                        upload_left_bound_2_lb.visible
                        &&
                        '' !== tooltip908.text
                   )
                  tooltip908.visible = true
            }
            onExited: {
                tooltip908.visible = false
            }
            }//mouse area
    }
    Label {
        id: upload_left_bound_lb
        text: ''
        font.pointSize: 11
        font.pixelSize: 9
        anchors.top: parent.top
        anchors.topMargin: 16
        //ch90620 anchors.right: undo_left_bound_ivibt.left
        anchors.right: select_interval_ivibt.left
        anchors.rightMargin: 5
        property bool visible2: true
        property bool visible3: true
        property bool visible4: false
        visible: visible2 && visible3 && visible4
        color:'white'
    }
    Menu {
        id: menu_interval2
        MenuItem {
            id: menu_item_select_interval_left
            height: visible ? implicitHeight : 0
            text: "Изменить интервал и оставить левую границу"
            onTriggered:
            {
                //изменим границы интервала е
                m_root_bfpa.correctIntervalSelectLeft();
                m_root_bfpa.m_i_is_interval_corresp_event = 0;
                //ch90723 m_root_bfpa.m_b_ness_check_present_event = 0;
                m_root_bfpa.m_s_start_event_id = 0;
                m_iv_arc_slider_control_bfpa.m_slider_control_asc.
                  drawSelectedInterval();
            }
        }
        MenuItem {
            id: menu_item_select_interval_right
            height: visible ? implicitHeight : 0
            text: "Изменить интервал и оставить правую границу"
            onTriggered:
            {
                //изменим границы интервала е
                m_root_bfpa.correctIntervalSelectRight();

                m_root_bfpa.m_i_is_interval_corresp_event = 0;
                //ch90723 m_root_bfpa.m_b_ness_check_present_event = 0;
                m_root_bfpa.m_s_start_event_id = 0;

                m_iv_arc_slider_control_bfpa.m_slider_control_asc.
                  drawSelectedInterval();
            }
        }
        MenuItem {
            id: menu_item_change
            height: visible ? implicitHeight : 0
            text: "Изменить интервал"
            onTriggered:
            {
                //print("Action 1")
                //дотянем до этой точки е
                correctInterval();

                m_root_bfpa.m_i_is_interval_corresp_event = 0;
                //ch90723 m_root_bfpa.m_b_ness_check_present_event = 0;
                m_root_bfpa.m_s_start_event_id = 0;

                //Пересчитаем коорд нач, конца е
                m_iv_arc_slider_control_bfpa.m_slider_control_asc.
                    drawSelectedInterval(
//                                               f_left_bound_lv, f_right_bound_lv,
//                                               1.0
                               );
                //изменим лейбл интервал e
                m_root_bfpa.m_i_select_interv_state = m_root_bfpa.c_I_IS_CORRECT_INTERV;
                select_interval_ivibt.txt_tooltip =
                        m_s_tooltip_select_interv_2;
            }
        }
        MenuItem {
            id: menu_item_go_to_begin
            height: visible ? implicitHeight : 0
            text: "Перейти к началу"
            onTriggered:
            {
                m_univreaderex_bfpa.outsideSetTimeMS( m_root_bfpa.m_uu_i_ms_begin_interval );
            }
        }
        MenuItem {
            id: menu_item_go_to_end
            height: visible ? implicitHeight : 0
            text: "Перейти к концу"
            onTriggered:
            {
                m_univreaderex_bfpa.outsideSetTimeMS( m_root_bfpa.m_uu_i_ms_end_interval );
            }
        }
        MenuItem {
            id: menu_item_save_interval
            height: visible ? implicitHeight : 0
            text: "Сохранить интервал"
            onTriggered:
            {
                m_root_bfpa.m_i_is_interval_corresp_event = 1;
                //ch90723 m_root_bfpa.m_b_ness_check_present_event = 1;
                m_root_bfpa.m_b_ness_pass_params = false;
                m_root_bfpa.m_i_is_interval_corresp_event_bookmark = 1;

                var qml = '/qtplugins/iv/archivecomponents/selectinterval/qselectinterval3.qml';
                ivCreator808_5.asyncCreate('', 'file:///' + applicationDirPath + qml,
                                       rootRect_ButtonFullPaneArc);
                m_idLog2_bfpa.warn(
                    //'181031 end time ' +
                            //ch90510 time811
                            //s_frame_time_2_lv
                            //+
                    ' ness_pass_params ' + m_root_bfpa.m_b_ness_pass_params );
            }
        }
        MenuItem {
            id: menu_item_call_unload_window
            height: visible ? implicitHeight : 0
            text: "Открыть окно выгрузки"
            onTriggered:
            {
                /*ch90719
                m_root_bfpa.m_s_unload_begin_interval =
                        univreaderex.uu64ToHumanEv( m_root_bfpa.m_uu_i_ms_begin_interval
                                      );
                m_root_bfpa.m_s_unload_end_interval =
                  univreaderex.uu64ToHumanEv( m_root_bfpa.m_uu_i_ms_end_interval
                                );
                */
                var qml = '/qtplugins/iv/viewers/archiveplayer/qmainexport.qml';
                ivCreator801.asyncCreate('', 'file:///' + applicationDirPath + qml,
                                         rootRect_ButtonFullPaneArc );
            }
        }
        MenuItem {
            text: "Очистить выделение"
            onTriggered:
            {
              //print("Action 2")
              //ch90719
              m_root_bfpa.m_uu_i_ms_begin_interval = 0;
              m_root_bfpa.m_uu_i_ms_end_interval = 0;
              //e ch90719


              m_iv_arc_slider_control_bfpa.m_slider_control_asc.clearFill2();
              upload_left_bound_lb.visible4 = false;
              upload_left_bound_2_lb.visible4 = false;
              m_root_bfpa.m_i_select_interv_state = m_root_bfpa.c_I_IS_FIERST_SELECT_INTERV;
              select_interval_ivibt.txt_tooltip = m_root_bfpa.m_s_tooltip_select_interv_1
            }
        }
        MenuItem {
            text: "Отмена"
            onTriggered:
            {
              //print("Action 3")
            }
        }
    }
    IVImageButton
    {
        id: force_write_ivibt
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.right: iv_butt_spb_bmark_skip.left
        anchors.rightMargin: 5
        size: "small"
        txt_tooltip: "принудительная запись в архив"
        on_source: 'file:///' + applicationDirPath + '/images/white/flag_left.svg'
        onClicked:{
            m_root_bfpa.b_forceRecordCurrState = !m_root_bfpa.b_forceRecordCurrState;
            m_univreaderex_bfpa.commandForceRecord( m_root_bfpa.b_forceRecordCurrState )
        }
    }
    Rectangle {
        id: next_event_not_found_rct_hint
        width: 120
        height: 15
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
    IVButtonSpinbox{
        id: iv_butt_spb_events_skip
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.right: upload_left_bound_2_lb.left
        anchors.rightMargin: 5
        size: "small"
        btn_color:"white"
        left_tooltip: "Перейти к предидущему событию"
        center_tooltip: ""
        right_tooltip: "Перейти к следующему событию"
        left_src: 'arrow_left.svg'
        center_src:  'thunder.svg'
        right_src: 'arrow_right.svg'
        property bool visible2: true
        property bool visible3: true
        property bool visible4: true
        visible: move_to_event.isAllowed && visible2 && visible3 && visible4
        onLeftClick:{
            m_idLog3_bfpa.warn('onLeftClick x ' + x +
                               ' width ' + width + ' y ' + y +
                               ' height ' + height );
            rootRect_ButtonFullPaneArc.moveToEventBySlider_Causing1( false, false,
                                                                    x, y + height )
        }
        onCenterClick:{
        }
        onRightClick:{
            rootRect_ButtonFullPaneArc.moveToEventBySlider_Causing1( true, false,
                                                                    x + ( 2 * width / 5 ), y + height )
        }
    }
    IVButtonSpinbox{
        id: iv_butt_spb_bmark_skip
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.right: iv_butt_spb_events_skip.left
        anchors.rightMargin: 5
        size: "small"
        btn_color:"white"
        left_tooltip: "Перейти к предыдущей метке"
        center_tooltip: ""
        right_tooltip: "Перейти к следующей метке"
        left_src: 'arrow_left.svg'
        center_src:  'bookmark.svg'
        right_src: 'arrow_right.svg'
        property bool visible2: true
        property bool visible3: true
        property bool visible4: true
        visible: move_to_bmark.isAllowed && visible2 && visible3 && visible4
        onLeftClick:{
            rootRect_ButtonFullPaneArc.moveToEventBySlider_Causing1( false,
                                   true, x, y + height );
        }
        onCenterClick:{
        }
        onRightClick:{
            rootRect_ButtonFullPaneArc.moveToEventBySlider_Causing1( true, true,
                                        x + ( 2 * width / 5 ), y + height );
        }
    }

    IVComponentCreator{
        id: ivCreator808_5
        ivComponent: m_root_bfpa.ivComponent // родитель, должен быть равен тому, чему
        //равно свойство ivComponent
        onCreated:{// вызывается, когда компонент удачно создан
            // component - создаваемый компонент
            m_idLog2_bfpa.warn('onCreated180904 808_5 ' + component);
        }
        onBindings: {// вызывается, когда компоненту можно выставить свойства
            //ch90621 var s_i64_frame_time_lv = '';
            // component - создаваемый компонент(можно выставлять ему различные свойства и т.д.)
            m_idLog2_bfpa.warn('onBindings 808_5 ' );
            component.key2 = m_root_bfpa.key2; // просто присвоение свойства
            component.begin = m_root_bfpa.m_uu_i_ms_begin_interval;
            component.end = m_root_bfpa.m_uu_i_ms_end_interval;

//                            component.id777 = Qt.binding(function(){
//                                return m_root_bfpa.m_s_exch_event_id;
//                            });

            m_root_bfpa.m_s_exch_event_id = Qt.binding(function(){
                return component.m_s_exch_event_id_si;
            });


            component.m_b_unload_mode =
              m_root_bfpa.m_b_is_caused_by_unload;
            m_idLog2_bfpa.warn(
                '181031 bind beg ' + component.begin +
                        'end ' + component.end
                        );
        }
        onError: {// вызывается в том случае, когда компонент не может быть создан
        }
    }
}



import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import iv.plugins.loader 1.0
import iv.guicomponents 1.0

//ch90917
import QtQuick.Templates 2.0 as T
import iv.plugins.users 1.0
import iv.photocam 1.0
import iv.calendar 1.0
//e ch90917

import iv.exprogress 1.0

Rectangle
{
    id:rootRect_ButtonPane
    //ch90425
    //то что раньше было в родительской форме е
    //anchors.bottom:
        //ch91024 m_mousearea_CommonPanMode_bpa
    //    parent
    //    .bottom

    z: 95
    width: 368
        //ch91024 m_mousearea_CommonPanMode_bpa
        //parent
        //.width
    height: (m_root_bpa.isFullscreen? 32 : 28)
    property variant m_univreaderex_bpa: null
    property variant m_root_bpa: null
    property variant m_render_bpa: null
    property variant m_speed_ch_box_rec: null
    property variant m_next_event_not_found_rct_hint_bpa: null
    property variant m_next_event_not_found_rct_hint_text_bpa: null
    property variant m_idLog2_bpa: null
    property variant m_mousearea_CommonPanMode_bpa: null
    //ch10929
    property variant m_v_conponent_main_export: null
    //e
    //property variant m_i_210929_1_bpa: null
    color: "transparent"
    //ch91023_4 property bool mouseOnPane: false
    //делаем видимой всю панель кнопок,
    //если непрозрачность === 1 e
    /*ch91023_3
    opacity: (
                 (
                     //мышь навели на панель,
                     //тогда элементы становятся
                     //непрозрачными е
                     //ch91023_3 rootRect_ButtonPane.mouseOnPane
                     m_mousearea_CommonPanMode_bpa.mouseOnPane910
                     //e
                     ||
                     (
                         //если у нас не общий режим, то делаем
                         //непрозрачными
                         0 === m_root_bpa.getCamCommonPanelMode()
                         //и если не маленькое окно е
                         &&
                         //ch91021 wndControlPanel.width >= root.m_i_width_visible_bound3
                         !root.isSmallMode()
                     )
                 )
                 ? 1.0 : 0.0
             )
    */
    //ch90917
    //ch90917 anchors.fill: parent
    //ch90917 anchors.leftMargin: 330
    //ch90917 anchors.rightMargin: 0


    //ch90917 property variant m_univreaderex_bpa: null
    //ch90917 property variant m_idLog2_bpa: null
    property variant m_idLog3_bpa: null
    property variant m_iv_arc_slider_control_bpa: null
    //ch90917 property variant m_render_bpa: null
    property variant m_upload_left_bound_lb_bpa: upload_left_bound_lb
    property variant m_upload_left_bound_2_lb_bpa: upload_left_bound_2_lb
    //ср91031 property variant m_force_write_ivibt_bpa: force_write_ivibt
    property variant m_iv_butt_spb_events_skip_bpa: iv_butt_spb_events_skip
    property variant m_iv_butt_spb_bmark_skip_bpa: iv_butt_spb_bmark_skip
    //пример того что передается во владельца е
    //prot property variant m_slider_control_asc: slider_control
    //пример того что передается из владельца е
    //ch90917 property variant m_root_bpa: null
    //пример того что передается из владельца е
    //property variant m_upload_left_bound_lb_asc: null
    property int m_i_event_not_found_visible_counter: 0

    property string m_s_tooltip_select_interv_2:
        'изменить границу интервала и другие операции с интервалом'

    property variant m_ivCreator801_ButtonPane_bpa: ivCreator801_ButtonPane
    //e ch90917

    IvVcliSetting {
        id: export_status_window
        name: 'qml.export.export_status_window'
    }

    function correctIntervalSelectLeft_Causing1()
    {
        //ch00608 m_univreaderex_bpa.setDelayCorrectIntervalSelectLeft( 0 );
        //изменим границы интервала е
        m_root_bpa.correctIntervalSelectLeft();
        correctIntervalSelect_CommonPart();
    }

    function correctIntervalSelect_CommonPart()
    {
        m_root_bpa.m_i_is_interval_corresp_event = 0;
        m_root_bpa.m_s_start_event_id = 0;
        m_iv_arc_slider_control_bpa.m_slider_control_asc.
          drawSelectedInterval();
    }
    function correctIntervalSelectLeft_ByCommand_Causing1()
    {
        //ch00607 m_univreaderex_bpa.setDelayCorrectIntervalSelectLeft( 0 );
        //изменим границы интервала е
        m_root_bpa.correctIntervalSelectLeft_ByCommand();
        correctIntervalSelect_CommonPart();
    }

    function correctIntervalSelectRight_Causing1()
    {
        m_idLog3_bpa.warn('<interv> correctIntervalSelectRight_Causing1 beg' );

        //ch00608 m_univreaderex_bpa.setDelayCorrectIntervalSelectRight( 0 );
        //изменим границы интервала е
        m_root_bpa.correctIntervalSelectRight();
        correctIntervalSelect_CommonPart();
    }

    function correctIntervalSelectRight_ByCommand_Causing1()
    {
        m_idLog3_bpa.warn('<interv> correctIntervalSelectRight_ByCommand_Causing1 beg' );

        //ch00608 m_univreaderex_bpa.setDelayCorrectIntervalSelectRight( 0 );
        //изменим границы интервала е
        m_root_bpa.correctIntervalSelectRight_ByCommand();
        correctIntervalSelect_CommonPart();
    }

    function correctInterval_Causing1( i_uu_64_time_av )
    {
        //ch0048m_univreaderex_bpa.setDelayCorrectInterval( 0 );
        //дотянем до этой точки е
        correctInterval_Level1( i_uu_64_time_av );

        m_root_bpa.m_i_is_interval_corresp_event = 0;
        m_root_bpa.m_s_start_event_id = 0;
        //Пересчитаем коорд нач, конца е
        m_iv_arc_slider_control_bpa.m_slider_control_asc.
            drawSelectedInterval(
                       );
        //изменим лейбл интервал e
        m_root_bpa.m_i_select_interv_state = m_root_bpa.c_I_IS_CORRECT_INTERV;
        select_interval_ivibt.txt_tooltip =
                m_s_tooltip_select_interv_2;
    }

    function drawStartInterval()
    {
        drawStartInterval_Level1(
            m_univreaderex_bpa.getFrameTimeUUI64() );
    }

    function drawStartIntervalByCommand()
    {
        drawStartInterval_Level1(
            m_univreaderex_bpa.getCommandTimeUUI64() );
    }

    function drawStartInterval_Level1( i_uu_64_changed_time_av )
    {
        //ch00609 m_univreaderex_bpa.setDelaySetStartInterval( 0 );
        //e
        //зададим маленький начальный интервал е
        var i_uu_64_frame_time_lv = 0;
        i_uu_64_frame_time_lv =
          //ch00608 m_univreaderex_bpa.getFrameTimeUUI64();
          i_uu_64_changed_time_av;
        m_idLog3_bpa.warn('select_interval_ivichb onClicked bef addDeltaTimeUU64' );
        m_root_bpa.m_uu_i_ms_begin_interval = i_uu_64_frame_time_lv;
        m_root_bpa.m_uu_i_ms_begin_interval
              = m_root_bpa.m_uu_i_ms_begin_interval - 5000;
        m_idLog3_bpa.warn(
          '<' + m_root_bpa.key2 + '_' + m_root_bpa.key3 + '>' +
          'select_interval_ivichb onClicked aft addDeltaTimeUU64 begn ' +
          m_root_bpa.m_uu_i_ms_begin_interval );
        m_idLog3_bpa.warn('select_interval_ivichb onClicked bef addDeltaTimeUU64 2' );
        m_root_bpa.m_uu_i_ms_end_interval = i_uu_64_frame_time_lv;
        m_root_bpa.m_uu_i_ms_end_interval
          = m_root_bpa.m_uu_i_ms_end_interval + 5000;
        m_root_bpa.m_i_select_interv_state = m_root_bpa.c_I_IS_SECOND_SELECT_INTERV;
        m_idLog3_bpa.warn(
          'select_interval_ivichb onClicked aft addDeltaTimeUU64 end ' +
          m_root_bpa.m_uu_i_ms_end_interval
                    );
        m_idLog3_bpa.warn(' ' +
                    ' i_uu_64_frame_time_lv ' + i_uu_64_frame_time_lv );
        //vart if ( m_root_bpa.m_i_width_visible_bound2 < rootRect.width )
        //vart {
        upload_left_bound_lb.visible4 = true;
        upload_left_bound_2_lb.visible4 = true;
        //vart }
        //Зададим подсказку е

        select_interval_ivibt.txt_tooltip =
          "выберите вторую границу интервала и нажмите"
        //Пересчитаем коорд нач, конца е
        m_idLog3_bpa.warn('select_interval_ivichb onClicked ' +
                    ' i_uu_64_frame_time_lv ' + i_uu_64_frame_time_lv +
//                                            ' f_left_bound_lv ' + f_left_bound_lv +
//                                            ' f_right_bound_lv ' + f_right_bound_lv +
                    ' width_visible_bound2 ' +
                    m_root_bpa.m_i_width_visible_bound2 +
                    ' rootRect.width ' +
                    //ch90918 rootRect_ButtonFullPaneArc
                    rootRect_ButtonPane
                          .width
                    );

        /*deb ch90623*/
        m_root_bpa.m_i_is_interval_corresp_event = 0;
        //ch90723 m_m_root_bpa_bpa.m_b_ness_check_present_event = 0;
        m_root_bpa.m_s_start_event_id = 0;


        m_iv_arc_slider_control_bpa.m_slider_control_asc.
            drawSelectedInterval(
//                                               f_left_bound_lv, f_right_bound_lv,
//                                               1.0
                       );


    }




    function getFrameTime()
    {
        var i64_time_lv = 0;
        i64_time_lv = m_univreaderex_bpa.getFrameTimeUUI64();
        m_idLog3_bpa.warn('<photocam> getFrameTime time ' + i64_time_lv );
        return m_univreaderex_bpa.getFrameTimeUUI64();
    }
    function extComponentsSetVisible( b_is_visible_av )
    {
        //ch91112 приписал 2 е
        select_interval_ivibt.visible2 = b_is_visible_av;
        upload_left_bound_2_lb.visible2 = b_is_visible_av;
        upload_left_bound_lb.visible2 = b_is_visible_av;
        menu_interval2.visible = b_is_visible_av;
        //ср91031 force_write_ivibt.visible = b_is_visible_av;
        //ch91112 приписал 2 е
        iv_butt_spb_events_skip.visible2 = b_is_visible_av;
        iv_butt_spb_bmark_skip.visible2 = b_is_visible_av;
    }

    function complete2()
    {
        var b_cond_lv = false;
        //ch90916 if ( 0 !== m_root_bpa.
                //ch90916 getCamCommonPanelMode()
                //ch90916 )
        //ch90916 {
            var qml = '/qtplugins/iv/sound/PaneSound.qml';
            ivCreator808_ButtonPane.asyncCreate('Unique', 'file:///' + applicationDirPath + qml, sound_rect_rec_ButtonPane);
            qml = '/qtplugins/iv/imagecorrector/ImageCorrector.qml';
            ivCreator808_3_ButtonPane.asyncCreate('Unique', 'file:///' + applicationDirPath + qml,
                                     image_corr_rec_ButtonPane);
            qml = '/qtplugins/iv/photocam/PanePhotoCam.qml';
            ivCreator808_2_ButtonPane.asyncCreate('Unique', 'file:///' + applicationDirPath + qml,
                                     photo_cam_rec_ButtonPane);


            //ch91031 deb
//            if ( false === m_root_bpa.isCommonPanel() )
//            {
//                qml = '/qtplugins/iv/archivecomponents/force_write/qforce_write3.qml';
//                ivCreator910_ButtonPane.asyncCreate('Unique', 'file:///' + applicationDirPath + qml,
//                                         deb_force_write_rec_ButtonPane);
//            }
            //e ch91031

        //ch90916 };

        b_cond_lv = ( 0 === m_root_bpa.getCamCommonPanelModeUseSetPanel() );

        m_idLog3_bpa.warn('<root> complete2 getCamCommonPanelModeUseSetPanel ' +
          b_cond_lv );


        if ( 0 === m_root_bpa.
                getCamCommonPanelModeUseSetPanel_Deb()
             //vart ||
             //vart m_root_bpa.common_panel
                )
        {
            //cg90918 anchors.bottomMargin = 57;
            //ch90918
            //ch91023_3 rootRect_ButtonPane.m_mousearea_CommonPanMode_bpa.anchors.
              //ch91023_3 bottomMargin = 57;
            //e

            b_cond_lv = m_root_bpa.isSmallMode();

            m_idLog3_bpa.warn('<root> complete2 b_cond_lv ' +
              b_cond_lv );

            //ch91030
            if ( !m_root_bpa.isSmallMode() )
            //e
            {
              rootRect_ButtonPane.m_mousearea_CommonPanMode_bpa.enabled = false;
            }
        }
        else
        {
            extComponentsSetVisible( false );
        }
    }

    Component.onCompleted: {
    }

    //ch90917
    function showInterval908( uu_i_ms_begin_interval_av,
                              uu_i_ms_end_interval_av,
                              s_event_text_interval_av )
    {
        var s_event_text_trunc_lv = '';
        s_event_text_trunc_lv = m_univreaderex_bpa.truncUTF8StrUR( s_event_text_interval_av, 20 );

        m_root_bpa.m_uu_i_ms_begin_interval = uu_i_ms_begin_interval_av;
        m_root_bpa.m_uu_i_ms_end_interval = uu_i_ms_end_interval_av;
        m_root_bpa.m_i_select_interv_state = m_root_bpa.c_I_IS_CORRECT_INTERV;

        select_interval_ivibt.txt_tooltip =
                m_s_tooltip_select_interv_2;

        //ch00708 old m_idLog3_bpa.warn('<events>moveToEventBySlider_Causing1 m_uu_i_ms_begin_interval ' +
        m_idLog3_bpa.warn(
                    '<' + m_root_bpa.key2 + '_' + m_root_bpa.key3 + '_events>' +
                    ' showInterval908 m_uu_i_ms_begin_interval ' +
          m_root_bpa.m_uu_i_ms_begin_interval +
          ' m_uu_i_ms_end_interval ' +
          m_root_bpa.m_uu_i_ms_end_interval );


        m_iv_arc_slider_control_bpa.m_slider_control_asc.
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
        var i_curr_time_lv = m_univreaderex_bpa.getCurrTime();

        var s_event_text_lv = '';
        var i_is_already_interval_selected_lv = 0;
        var s_warning_pref_lv = '';


        m_idLog3_bpa.warn('<events>moveToEventBySlider_Causing1 bef request ' +
          ' m_root_bpa.m_i_marker_last_request_to_events ' +
          m_root_bpa.m_i_marker_last_request_to_events +
          ' i_curr_time_lv ' +
          i_curr_time_lv +
          ' m_root_bpa.m_i_current_timeout_request_to_events ' +
          m_root_bpa.m_i_current_timeout_request_to_events );

        if ( m_root_bpa.m_i_current_timeout_request_to_events > 20000 ||
                m_root_bpa.m_i_marker_last_request_to_events + 40000 < i_curr_time_lv )
          m_root_bpa.m_i_current_timeout_request_to_events = 2000;


        if ( 0 !== m_root_bpa.m_uu_i_ms_begin_interval )
          i_is_already_interval_selected_lv = 1;
        i_res_lv = m_univreaderex_bpa.moveToEventBySlider
                         ( b_is_right_av, b_is_bookmarks_av,
                           i_is_already_interval_selected_lv,
                           m_root_bpa.m_i_current_timeout_request_to_events );
        //ch90717
        m_idLog3_bpa.warn('<events>moveToEventBySlider_Causing1 i_res_lv ' +
          i_res_lv + ' rl_mess_x_av ' + rl_mess_x_av + ' rl_mess_y_av ' +
          rl_mess_y_av + ' m_root_bpa.m_i_current_timeout_request_to_events ' +
          m_root_bpa.m_i_current_timeout_request_to_events );
        //ch90725
        if ( m_root_bpa.c_I_TIMEOUT_907 === i_res_lv )
        {
          m_root_bpa.m_i_current_timeout_request_to_events += 2000;
          //ch90802 hint = '';
          //ch90731
          //ch90918 rootRect_ButtonFullPaneArc
          rootRect_ButtonPane
             .showNextEventNotFoundMess(
              m_root_bpa.m_i_current_timeout_request_to_events, rl_mess_x_av, rl_mess_y_av,
                      'событие за ' + m_root_bpa.m_i_current_timeout_request_to_events /
                      1000 +
                      ' сек не найденно, попробуйте еще раз' );
          //e ch90731
        }
        //e
        //ch90805
        else if ( m_root_bpa.c_I_NOT_FOUND_907 === i_res_lv )
        {
            //ch90918 rootRect_ButtonFullPaneArc
            if ( b_is_bookmarks_av )
              s_warning_pref_lv = 'метка';
            else
              s_warning_pref_lv = 'событие';

            rootRect_ButtonPane
              .showNextEventNotFoundMess(
                m_root_bpa.m_i_current_timeout_request_to_events, rl_mess_x_av, rl_mess_y_av,
                                s_warning_pref_lv + ' для заданного промежутка не существует'
                        );
        }
        //e
        else if ( m_root_bpa.c_I_SUCCESS_907 === i_res_lv )
        {
            m_root_bpa.m_i_is_interval_corresp_event = 1;
            //ch90723 m_root_bpa.m_b_ness_check_present_event = 0;
            m_root_bpa.m_i_is_interval_corresp_event_bookmark =
                    b_is_bookmarks_av ? 1 : 0;
            m_root_bpa.m_s_start_event_id = m_univreaderex_bpa.getLastSelectedEventStartId();

            s_event_text_lv = m_univreaderex_bpa.getLastSelectedEventText();
            showInterval908(
                        m_univreaderex_bpa.getLastSelectedEventBegin(),
                        m_univreaderex_bpa.getLastSelectedEventEnd(),
                        s_event_text_lv
                        );
        }
        //e
        m_root_bpa.m_i_marker_last_request_to_events = i_curr_time_lv;
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
          m_next_event_not_found_rct_hint_bpa.visible = false;
      }
    }
    function showNextEventNotFoundMess( i_timeout_av, rl_x_av, rl_y_av, s_text_av )
    {
        var i_x_lv = 10;
        var i_y_lv = 10;
        //ch91112_2 var pt_mapped_pos_lv = null;
        m_next_event_not_found_rct_hint_bpa.visible = true;
        m_i_event_not_found_visible_counter = 7;

        //ch90704 next_event_not_found_rct_hint.x = m_mouseX_bpa - 5;
        i_x_lv = rl_x_av;
        i_y_lv = rl_y_av;
        //ch91112_2 pt_mapped_pos_lv = mapToItem
                //ch91112_2 ( m_root_bpa, i_x_lv, i_y_lv );
        m_next_event_not_found_rct_hint_bpa.x =
                //ch91112_2 pt_mapped_pos_lv.x;
                i_x_lv;
        m_next_event_not_found_rct_hint_bpa.y =
                //ch91112_2 pt_mapped_pos_lv.y;
                i_y_lv;

        m_next_event_not_found_rct_hint_text_bpa.text =
                //'событие за ' + i_timeout_av / 1000 +
                //' сек не найденно, попробуйте еще раз'
                s_text_av;
        m_next_event_not_found_rct_hint_bpa.width =
           m_next_event_not_found_rct_hint_text_bpa.contentWidth;
        m_next_event_not_found_rct_hint_bpa.height =
           m_next_event_not_found_rct_hint_text_bpa.contentHeight;
        m_idLog3_bpa.warn( '<events> showNextEventNotFoundMess i_x_lv ' +
                            i_x_lv + ' i_y_lv ' + i_y_lv +
                            ' m_next_event_not_found_rct_hint_bpa.x ' +
                            m_next_event_not_found_rct_hint_bpa.x +
                            ' m_next_event_not_found_rct_hint_bpa.y ' +
                            m_next_event_not_found_rct_hint_bpa.y +
                            ' m_next_event_not_found_rct_hint_text_bpa.text ' +
                            m_next_event_not_found_rct_hint_text_bpa.text
                          );
    }
    function commonPanelExtButtonsSetVisible( b_av )
    {
        /*ch90916
        sound_rect_rec.visible = b_av;
        photo_cam_rec.visible = b_av;
        image_corr_rec.visible = b_av;
        ch90916*/
        //ср91031 force_write_ivibt.visible = b_av;
        select_interval_ivibt.visible2 = b_av;
        iv_butt_spb_events_skip.visible2 = b_av;
        iv_butt_spb_bmark_skip.visible2 = b_av;

        //ch90916 unload_to_avi_ivibt.visible = b_av;
    }

    function commonPanelElementsSetVisible( b_av )
    {
        sound_rect_rec_ButtonPane.visible = b_av;
        photo_cam_rec_ButtonPane.visible = b_av;
        image_corr_rec_ButtonPane.visible = b_av;
        //ср91031 force_write_ivibt.visible = b_av;
        select_interval_ivibt.visible2 = b_av;
        iv_butt_spb_events_skip.visible2 = b_av;
        iv_butt_spb_bmark_skip.visible2 = b_av;
        unload_to_avi_ivibt_ButtonPane.visible = b_av;
        upload_left_bound_2_lb.visible3 = b_av;
        upload_left_bound_lb.visible3 = b_av;
        fullscreenButton_ButtonPane.visible = b_av;
    }


    function part1SetVisible( b_av )
    {
        //ch10914 upload_left_bound_2_lb.visible3 = b_av;
        //ch10914 upload_left_bound_lb.visible3 = b_av;
        iv_butt_spb_events_skip.visible3 = b_av;
        iv_butt_spb_bmark_skip.visible3 = b_av;
        //ch10914 select_interval_ivibt.visible3 = b_av;
        //ch10914
        if ( b_av )
        {
            //play_btn_rec.anchors.leftMargin = 8;
            play_ivichb.anchors.horizontalCenterOffset = -20;
            revers_ivichb.anchors.horizontalCenterOffset = 20;
            //play_btn_rec.width = 110;
            //speed_ch_box_rec.width = 100;
            //m_speed_ch_box_rec.width = 100;
            //speed_ch_box_rec.leftMargin = 0;
            m_speed_ch_box_rec.anchors.leftMargin = 0;
        }
        else
        {
            //play_btn_rec.anchors.leftMargin = 43;//15
            play_ivichb.anchors.horizontalCenterOffset = -29;
            revers_ivichb.anchors.horizontalCenterOffset = -5;
            //play_btn_rec.width = 60;
            //m_speed_ch_box_rec.width = 20;
            m_speed_ch_box_rec.anchors.leftMargin = -48;
        }
        //e
    }
    function part2SetVisible( b_av )
    {
        /*ch90916
        sound_rect_rec.visible = b_av;
        photo_cam_rec.visible = b_av;
        image_corr_rec.visible = b_av;
        ch90916*/
        //ср91031 force_write_ivibt.visible = b_av &&
          //ср91031 m_root_bpa.m_b_is_by_events;

        select_interval_ivibt.visible2 = b_av;
        //ch90613 key2_lb.visible = true;

        //ch90916 unload_to_avi_ivibt.visible = b_av && !m_root_bpa.m_b_is_caused_by_unload;

        iv_butt_spb_events_skip.visible2 = b_av && !m_root_bpa.m_b_is_caused_by_unload;
        iv_butt_spb_bmark_skip.visible2 = b_av && !m_root_bpa.m_b_is_caused_by_unload;
    }
    function part4SetVisible( b_av )
    {
        /*ch91024_4*/
        photo_cam_rec_ButtonPane.visible = b_av;
        sound_rect_rec_ButtonPane.visible = b_av;
        image_corr_rec_ButtonPane.visible = b_av;
        /**/
    }
    function part5SetVisible( b_av )
    {
        r910_3Rect.visible = b_av;
        r910_4Rect.visible = b_av;
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
        m_idLog2_bpa.warn( 'onCompleted prop present' );

        //ch90916 unload_to_avi_ivibt.visible = false;
        //ch90916 realtime_ivibt.visible = false;

        iv_butt_spb_events_skip.visible2 = false;
        iv_butt_spb_bmark_skip.visible2 = false;
    }

    /*ch00608 vart
    function correctInterval()
    {
        correctInterval_Level1( m_univreaderex_bpa.getFrameTimeUUI64() );
    }

    function correctIntervalByCommand()
    {
        correctInterval_Level1( m_univreaderex_bpa.getCommandTimeUUI64() );
    }
    */

    function correctInterval_Level1( i_uu_64_time_av )
    {
        var i_uu_64_frame_time_lv =
          //ch00608 m_univreaderex_bpa.getFrameTimeUUI64();
          i_uu_64_time_av;
        if ( i_uu_64_frame_time_lv < m_root_bpa.m_uu_i_ms_begin_interval )
          m_root_bpa.m_uu_i_ms_begin_interval = i_uu_64_frame_time_lv;
        else if ( m_root_bpa.m_uu_i_ms_end_interval < i_uu_64_frame_time_lv )
          m_root_bpa.m_uu_i_ms_end_interval = i_uu_64_frame_time_lv;
        //ch00708 e
        m_idLog3_bpa.warn(
                          '<' + root.key2 + '_' + root.key3 + '>' +
                          'correctInterval_Level1 '
                          + ' m_uu_i_ms_begin_interval ' +
                          m_root_bpa.m_uu_i_ms_begin_interval
                          + ' m_uu_i_ms_end_interval ' +
                          m_root_bpa.m_uu_i_ms_end_interval
                          );
    }
    IvAccess {
      id: move_to_event
      access: "{move_to_event}"
    }
    IvAccess {
      id: move_to_bmark
      access: "{move_to_bmark}"
    }
    //e ch90917

    //ch00918
    
    /*#zu666su35*/
    Iv7Test {
        id: test_id_call_archive_menu
        guid: '43_call_archive_menu'
        key2: root.key2
        onCommandReceived: {
            m_idLog3_bpa.warn( value ); //value - json, указанный в ws запросе.
            select_interval_ivibt.clicked(); //- кликнуть кнопку
            test_id_call_archive_menu.result = "{\"result\":\"OK\"}";
        }
    }
    Iv7Test {
        id: test_id_click_change_interval
        guid: '43_click_archive_change_interval'
    key2: root.key2
        onCommandReceived: {
            m_idLog3_bpa.warn( value ); //value - json, указанный в ws запросе.
            menu_item_change.onTriggered();// - кликнуть кнопку
            test_id_click_change_interval.result = "{\"result\":\"OK\"}";
        }
    }
    //ch11110
    Iv7Test {
        id: test_id_click_unload_interval
        guid: '43_click_archive_unload_interval'
    key2: root.key2
        onCommandReceived: {
            m_idLog3_bpa.warn( value ); //value - json, указанный в ws запросе.
            menu_item_unload.onTriggered();// - кликнуть кнопку
            test_id_click_unload_interval.result = "{\"result\":\"OK\"}";
        }
    }
    Iv7Test {
        id: test_id_click_reset_selection_interval
        guid: '43_click_archive_reset_selection_interval'
    key2: root.key2
        onCommandReceived: {
            m_idLog3_bpa.warn( value ); //value - json, указанный в ws запросе.
            menu_item_reset_selection.onTriggered();// - кликнуть кнопку
            test_id_click_reset_selection_interval.result = "{\"result\":\"OK\"}";
        }
    }
    Iv7Test {
        id: test_id_click_cancel111_interval
        guid: '43_click_archive_cancel111_interval'
    key2: root.key2
        onCommandReceived: {
            m_idLog3_bpa.warn( value ); //value - json, указанный в ws запросе.
            menu_item_cancel111.onTriggered();// - кликнуть кнопку
            test_id_click_cancel111_interval.result = "{\"result\":\"OK\"}";
        }
    }
    //e
    Iv7Test {
        id: test_id_click_call_export_window
        guid: '43_click_archive_call_export_window'
        key2: root.key2
        onCommandReceived: {
            m_idLog3_bpa.warn( value ); //value - json, указанный в ws запросе.
            menu_item_call_unload_window.onTriggered(); //- кликнуть кнопку
            test_id_click_call_export_window.result = "{\"result\":\"OK\"}";
        }
    }
    /*#zu666su35*/
    //e
    IVComponentCreator{
        id: ivCreator808_2_ButtonPane
        ivComponent: m_root_bpa.ivComponent // родитель, должен быть равен тому, чему
        //равно свойство ivComponent
        onCreated:{// вызывается, когда компонент удачно создан
            // component - создаваемый компонент
            m_idLog2_bpa.warn('onCreated180904 808_2 ' + component);
        }
        onBindings: {// вызывается, когда компоненту можно выставить свойства
            //ch00109 vart var i64_time_lv = 0;
            // component - создаваемый компонент(можно выставлять ему различные свойства и т.д.)
            m_idLog2_bpa.warn('onBindings 808_2 ' );
            if('key2' in component)
                component.key2 = m_root_bpa.key2; // просто присвоение свойства
            if('track' in component)
                component.track =
                        m_root_bpa.trackFrameAfterSynchrRoot;
            //ch91219
            //ch00109 vart i64_time_lv = m_univreaderex_bpa.getFrameTimeUUI64();
            //ch00109 vart m_idLog3_bpa.warn('<photocam> IVComponentCreator onBindings time ' + i64_time_lv );
            //ch00109 vart component.time = Qt.binding(function(){
                //ch00109 vart return m_univreaderex_bpa.getFrameTimeUUI64()
                //ch00109 vart ;});
            //e
            if('parent2' in component)
                component.parent2 = rootRect_ButtonPane; // просто присвоение свойства
        }
        onError: {// вызывается в том случае, когда компонент не может быть создан
        }
    }
    //ch91031 deb
    /*
    IVComponentCreator{
        id: ivCreator910_ButtonPane
        ivComponent: m_root_bpa.ivComponent // родитель, должен быть равен тому, чему
        //равно свойство ivComponent
        onCreated:{// вызывается, когда компонент удачно создан
            // component - создаваемый компонент
            m_idLog2_bpa.warn('onCreated180904 910 ' + component);
        }
        onBindings: {// вызывается, когда компоненту можно выставить свойства
            // component - создаваемый компонент(можно выставлять ему различные свойства и т.д.)
            m_idLog2_bpa.warn('onBindings 910 ' );
            if('key2' in component)
                component.key2 = m_root_bpa.key2; // просто присвоение свойства
        }
        onError: {// вызывается в том случае, когда компонент не может быть создан
        }
    }
    */
    //e ch91031 deb

    IVComponentCreator{
        id: ivCreator808_3_ButtonPane
        ivComponent: m_root_bpa.ivComponent // родитель, должен быть равен тому, чему
        //равно свойство ivComponent
        onCreated:{// вызывается, когда компонент удачно создан
            // component - создаваемый компонент
            m_idLog2_bpa.warn('onCreated180904 808_3' + component);
        }
        onBindings: {// вызывается, когда компоненту можно выставить свойства
            m_idLog2_bpa.warn('onBindings 808_3 ' );
            // component - создаваемый компонент(можно выставлять ему различные свойства и т.д.)
            m_idLog2_bpa.warn(
                         ' oooo component.inProfileName' +
                         component.inProfileName +
                        ' univreaderex.trackFrame' +
                        m_univreaderex_bpa.trackFrameAfterSynchr
                         );
                //ch91113 входная очередь данного плагина е
                component.inProfileName =
                        m_root_bpa.
                        //ch91112_3 trackFrameAfterSynchrRoot;
                        trackFrameAfterStabilizerRoot;
                //ch91113 выходная очередь данного плагина е
                component.outProfileName =
                        //ch91112_3 m_univreaderex_bpa.trackFrameAfterSynchr
                        m_root_bpa.trackFrameAfterStabilizerRoot
                        + "_correct"; // просто присвоение свойства
            //ch91113 m_render_bpa.trackFrame
            m_root_bpa.trackFrameAfterImageCorrectorRoot
                    = component.outProfileName;

            component._x_position = - component.custom_width;
            component._y_position = - component.custom_height - 40;

            //ch91113
            m_root_bpa.m_b_image_corrector_created = true;
            //e
        }
        onError: {// вызывается в том случае, когда компонент не может быть создан
        }
    }
    IVComponentCreator{
        id: ivCreator808_ButtonPane
        ivComponent: m_root_bpa.ivComponent // родитель, должен быть равен тому, чему
        //равно свойство ivComponent
        onCreated:{// вызывается, когда компонент удачно создан
            // component - создаваемый компонент
            m_idLog3_bpa.warn('<sound> onCreated180904 2 ' + component);
            var sound808_lv = component;

            m_root_bpa.m_pane_sound = component;


            //ch00811
            //vart2 if ( 'nessActivateSound' in component )
            //vart2{
                m_idLog3_bpa.warn( '<sound> 200811 50' );
                //vart component.nessActivateSound.connect( m_root_bpa.nessActivateSoundAP );
                //vart m_root_bpa.nessActivateSoundAP.connect( component.nessActivateSound );
                m_root_bpa.m_i_is_sound_created = 1;
            //vart2 }
            //e
            sound808_lv.owneraddress_arch = m_univreaderex_bpa.getAddr808();
            sound808_lv.funaddress_arch = m_univreaderex_bpa.getFunct808();
            m_univreaderex_bpa.storeSoundInfo( sound808_lv.owneraddress, sound808_lv.funaddress );
            m_idLog3_bpa.warn( '<sound> ivCreator808_ButtonPane onCreated end ' );
        }
        onBindings: {// вызывается, когда компоненту можно выставить свойства
            m_idLog3_bpa.warn('<sound> onBindings 808 ' );
            // component - создаваемый компонент(можно выставлять ему различные свойства и т.д.)
            //old univreaderex.setDelta709( 1 );
            if('key2' in component)
                component.key2 = m_root_bpa.key2; // просто присвоение свойства
            //ch10528
            //chif('key3' in component)
            {
                m_idLog3_bpa.warn('<sound> onBindings 808 m_root_bpa.key3 ' +
                                  m_root_bpa.key3 );
                component.key3 = m_root_bpa.key3; // просто присвоение свойства
            }
            //e

            if('is_archive' in component)
                component.is_archive = '1';
            m_idLog3_bpa.warn(
                '<sound> 180110 onBindings m_root_bpa.key2 ' + m_root_bpa.key2 +
                'component.key2' + component.key2
                        );

            if('key3_audio' in component)
            {
              m_root_bpa.m_s_key3_audio_ap = Qt.binding(
                  function(){
                    return component.key3_audio;
                  });
            }



            if('track_source_univ' in component)
            {
              m_root_bpa.m_s_track_source_univ_ap = Qt.binding(
                  function(){
                    return component.track_source_univ;
                  });
            }

            m_idLog3_bpa.warn('<sound> end onBindings 808 ' );
        }
        onError: {// вызывается в том случае, когда компонент не может быть создан
        }
    }
    IVComponentCreator{
        id: ivCreator801_ButtonPane
        ivComponent: m_root_bpa.ivComponent // родитель, должен быть равен тому, чему
        //равно свойство ivComponent
        onCreated:{// вызывается, когда компонент удачно создан
            // component - создаваемый компонент
            m_idLog3_bpa.warn('onCreated180904 ' + component +
                              ' m_root_bpa.ivComponent ' + m_root_bpa.ivComponent );
            //ch10929
            m_v_conponent_main_export = component;
            //e
        }
        onBindings: {// вызывается, когда компоненту можно выставить свойства
            m_idLog3_bpa.warn(
                              '<' + m_root_bpa.key2 + '_' + m_root_bpa.key3 + '>' +
                              'onBindings 180110' +
                              ' m_root_bpa.ivComponent ' + m_root_bpa.ivComponent );
            var s_begin_lv = '';
            var s_end_lv = '';
            idLog2.warn('onBindings 180110');
            if ( 0 === m_root_bpa.m_uu_i_ms_begin_interval )
            {
                s_begin_lv = univreaderex.intervTime2( 0 );
                m_idLog3_bpa.warn('unload_to_avi_ivibt clicked time before ' +
                   m_root_bpa.end );
                if ( '' === m_root_bpa.end )
                {
                    /*ch00708
                    m_root_bpa.end =
                    univreaderex.addDeltaTime(
                                univreaderex.intervTime2( 0 ), 120000 );
                    idLog3.warn(
                                '<' + m_root_bpa.key2 + '_' + m_root_bpa.key3 + '>' +
                                'unload_to_avi_ivibt clicked end after ' +
                       m_root_bpa.end );
                    */
                    s_end_lv =
                        univreaderex.addDeltaTime(
                                    univreaderex.intervTime2( 0 ), 120000 );
                    idLog3.warn(
                                '<' + m_root_bpa.key2 + '_' + m_root_bpa.key3 + '>' +
                                'unload_to_avi_ivibt clicked end after ' +
                       s_end_lv );
                }
                else
                  s_end_lv = m_root_bpa.end;
            }
            else
            {
                s_begin_lv = univreaderex.uu64ToHumanEv
                        ( m_root_bpa.m_uu_i_ms_begin_interval, 3 );
                s_end_lv = univreaderex.uu64ToHumanEv
                                 ( m_root_bpa.m_uu_i_ms_end_interval, 3 );
            }
            if('key2' in component)
                component.key2 = m_root_bpa.key2; // просто присвоение свойства
////////////mwork begin
						var s1=s_begin_lv.indexOf('27');
						idLog3.warn( '<mwork> s_begin_lv '+s_begin_lv+' s_end_lv '+s_end_lv+' '+m_root_bpa.time811
						+' s1 ' );
						
						if(s1===0)
						{
							s_begin_lv=m_root_bpa.time811;
							s_end_lv=s_begin_lv;
							idLog3.warn( '<mwork>corrected '+s_begin_lv+' '+s_end_lv);
						};
////////////////////mwork end				
            if('from' in component)
                component.from =
                        //ch90719 m_root_bpa.m_s_unload_begin_interval
                        s_begin_lv
                        ;
            if('to' in component)
                component.to =
                        //ch90719 m_root_bpa.m_s_unload_end_interval
                        s_end_lv
                        ;
            if('evtid' in component)
            {
                //ch00708
                if ( 0 !== m_root_bpa.m_s_start_event_id &&
                     '' !== m_root_bpa.m_s_start_event_id )
                //e
                  component.evtid = m_root_bpa.m_s_start_event_id;
            }
            idLog3.warn( '<unload> onBindings from ' +
              component.from + ' to ' + component.to +
                        ' evtid ' + m_root_bpa.m_s_start_event_id );

        }
        onError: {// вызывается в том случае, когда компонент не может быть создан
            // error - текст ошибки
        }
    }
    IVComponentCreator{
      id: ivExprogressCreator
      ivComponent: m_root_bpa.ivComponent
      onCreated: {
        m_idLog3_bpa.trace('<IVButtonPaneArc.qml> ivExprogressCreator onCreated {');
        m_idLog3_bpa.trace('<<IVButtonPaneArc.qml> ivExprogressCreator onCreated }');
      }
      onBindings: {
          m_idLog3_bpa.trace('<<IVButtonPaneArc.qml> ivExprogressCreator onBindings {');
          component.height = 440;
          component.width = 600;
          m_idLog3_bpa.trace('<<IVButtonPaneArc.qml> ivExprogressCreator onBindings }');
      }
      onError: {
        m_idLog3_bpa.trace(error);
      }
    }
    //затеняет область с кнопками е
    /*ch91023_3
    Rectangle
    {
        id:videoButtonRect_ButtonPane
        anchors.fill: rootRect_ButtonPane
        color: "black"
        opacity: (
                     (
                         //если мышь навели на область то не прозрачный,
                         //иначе- прозрачный
                         //ch91023_3 rootRect_ButtonPane.mouseOnPane
                         m_mousearea_CommonPanMode_bpa.mouseOnPane910
                         //e
                         &&
                         //если еще режим полной панели,  то становится не прзрачным
                         (
                             0 !== m_root_bpa.getCamCommonPanelMode()
                             //ср91018
                             //еще вариант - маленькая панель
                             ||
                             //ch91021 wndControlPanel.width < root.m_i_width_visible_bound3
                             root.isSmallMode()
                             //e
                         )
                     )
                     ? 0.4 : 0.0)
    }
    */
    RowLayout
    {
        id:buttonRightRowLayout_ButtonPane
        spacing: 2
        width: rootRect_ButtonPane.width
            //parent
            //.width/2
        height: parent.height
        anchors.right:  rootRect_ButtonPane.right
        anchors.bottom: parent.bottom
        layoutDirection:Qt.RightToLeft

        //z: 0
        Rectangle
        {
            width:  33
            height: 33
            color: "transparent"
            id: r910_4Rect
            //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
            IVImageButton
            {
                id: fullscreenButton_ButtonPane
                anchors.verticalCenter: parent.verticalCenter
                txt_tooltip: (
                                 //ch90425 parentComponent
                                 m_root_bpa
                                 .isFullscreen ? 'Off fullscreen':'On fullscreen')
                on_source: (
                               //ch90425 parentComponent
                               m_root_bpa
                               .isFullscreen ? 'file:///' + applicationDirPath + '/images/white/fullscreen_exit.svg' : 'file:///' + applicationDirPath + '/images/white/fullscreen.svg')
                size: "normal"//(parentComponent.isFullscreen? "normal":"small")
                onClicked:
                {
                    //ch90425 parentComponent
                    m_root_bpa
                    .ivComponent.commandToParent('viewers:fullscreen', {});
                }
                Component.onCompleted:
                {
                }
            }
        }
        Rectangle
        {
            //ch90423 id:imageCorrector
            id:image_corr_rec_ButtonPane
            width:  24
            height: 24
            color: "transparent"
            //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle
        {
            id: rectSwitchToRealTime_ButtonPane
            width:  33
            height: 33
            color: "transparent"
            //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
            IVImageButton
            {
                //ch90423 id: archive
                id: switchToRealTime_ButtonPane
                anchors.verticalCenter:
                    parent.verticalCenter
                txt_tooltip: "возврат в реалтайм"
                //txt_tooltip: (parentComponent.isFullscreen ? 'Off fullscreen':'On fullscreen')
                on_source:  'file:///' + applicationDirPath +
                            //ch90423 '/images/white/video_lib.svg'
                            //ch10216 '/images/white/camera.svg'
                            '/images/white/video_lib_exit.svg'
                size: "normal"//(parentComponent.isFullscreen? "normal":"small")
                onClicked:
                {
                    //ch90425 parentComponent
                    if ( false === m_root_bpa.common_panel )
                    {
                        m_idLog3_bpa.trace( '<210927> unload_to_avi_ivibt 2 clicked bef act ' );
                        m_root_bpa
                          .ivComponent.commandToParent('viewers:switch', {});
                        m_idLog3_bpa.trace( '<210927> unload_to_avi_ivibt 2 clicked aft act ' );
                    }
                    else
                    {
                        m_univreaderex_bpa.allArcPlayersSwitchToRealtime();
                    }
                }
            }
        }
        /*ch90917
        Item
        {
            Layout.fillWidth: true
        }
    }
    RowLayout
    {
        id:buttonLeftRowLayout_ButtonPane
        spacing: 2
        height:
            parent
            .height
        width:
            parent
           .width/2
        anchors.left:
            parent
              .left
        anchors.bottom:
            parent
              .bottom
        ch90917*/
        Rectangle
        {
            id:photo_cam_rec_ButtonPane
            width: 33
            height: 33
            color: "transparent"
            //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
        }

        //ch91031 deb
        /*
        Rectangle
        {
            id:deb_force_write_rec_ButtonPane
            width: 24
            height: 24
            color: "transparent"
        }
        */
        //e ch91031 deb

        Rectangle
        {
            id:sound_rect_rec_ButtonPane
            width: 33//(parentComponent.isFullscreen? 32 : 24)
            height: 33//(parentComponent.isFullscreen? 32 : 24)
            color: "transparent"
            //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle
        {
            id: r910_3Rect
            width:  33
            height: 33
            color: "transparent"
            //ch90930 temp deb anchors.verticalCenter: parent.verticalCenter
            IVImageButton
            {
                id: unload_to_avi_ivibt_ButtonPane
                anchors.verticalCenter: parent.verticalCenter
                size: "normal"
                txt_tooltip: "экспорт в AVI, MKV"
                on_source: 'file:///' + applicationDirPath +
                           '/images/white/archSave.svg'
                onClicked:{
                        //ch90918 устарела m_root_bpa.m_s_unload_begin_interval = m_univreaderex_bpa.intervTime2( 0 );
                        m_idLog3_bpa.trace( 'unload_to_avi_ivibt 2 clicked ' );
                           //ch00708 time before '
                           //ch00708 +
                           //ch00708 m_root_bpa.end );
                        /*ch00708
                        if ( '' === m_root_bpa.end )
                        {
                            m_root_bpa.end =
                            m_univreaderex_bpa.addDeltaTime(
                                        m_univreaderex_bpa.intervTime2( 0 ), 120000 );
                            //ch00709 old unload_to_avi_ivibt clicked end after
                            m_idLog3_bpa.warn( 'unload_to_avi_ivibt 2 clicked end after ' +
                               m_root_bpa.end );
                        }
                        */
                        //ch90918 устарела m_root_bpa.m_s_unload_end_interval = m_root_bpa.end;
                        var qml = '/qtplugins/iv/viewers/archiveplayer/qmainexport.qml';
                        ivCreator801_ButtonPane.asyncCreate('', 'file:///' + applicationDirPath + qml,
                                                 rootRect_ButtonPane);
                }
            }//im but
        }//rect
        //ch90917
        IVImageButton
        {
            id: select_interval_ivibt
            property bool visible2: true
            property bool visible3: true
            visible: visible2 && visible3
            size: "normal"
            _width: 24
            txt_tooltip: m_root_bpa.m_s_tooltip_select_interv_1
            on_source: 'file:///' + applicationDirPath + '/images/white/flag_left.svg'
            onClicked:{

                var i_uu_new_interv_time_lv = 0;
                if ( m_root_bpa.c_I_IS_FIERST_SELECT_INTERV === m_root_bpa.m_i_select_interv_state  )
                {
                    //ch00413
                    if ( 0 !== m_univreaderex_bpa.isFrameCounterCorrespondCommand() )
                        rootRect_ButtonPane.drawStartInterval();
                    else
                    {
                      //ch00608
                      //ch00608 m_univreaderex_bpa.setDelaySetStartInterval( 1 );
                      rootRect_ButtonPane.drawStartIntervalByCommand();
                      //e
                    };
                }
                else if ( m_root_bpa.c_I_IS_SECOND_SELECT_INTERV === m_root_bpa.m_i_select_interv_state  )
                {
                    //ch90801 Sm_root_bpa.
                    positioningMenu()
                    menu_item_change.visible = true;
                    menu_item_select_interval_left.visible = false;
                    menu_item_select_interval_right.visible = false;
                    menu_item_go_to_begin.visible = false;
                    menu_item_go_to_end.visible = false;
                    menu_item_save_interval.visible = false;
                    menu_item_call_unload_window.visible = false;
                    menu_item_unload.visible = false;
                    onClicked: menu_interval2.open();
                    //vart onClicked: menu_interval.popup(mouseX, mouseY)
                }
                else if ( m_root_bpa.c_I_IS_CORRECT_INTERV === m_root_bpa.m_i_select_interv_state  )
                {
                    //вызовем меню е
                    positioningMenu()
                    menu_item_change.visible = false;
                    menu_item_select_interval_left.visible = true;
                    menu_item_select_interval_right.visible = true;
                    menu_item_go_to_begin.visible = true;
                    menu_item_go_to_end.visible = true;
                    menu_item_save_interval.visible = true;

                    menu_item_unload.visible = true;
                    //menu_item_unload.visible = false;


                    menu_item_call_unload_window.visible = true;

                    m_idLog3_bpa.warn( "<interv> getFrameTimeUUI64 " +
                                       m_univreaderex_bpa.getFrameTimeUUI64() +
                                      " m_uu_i_ms_begin_interval " +
                                      m_root_bpa.m_uu_i_ms_begin_interval +
                                      " m_uu_i_ms_end_interval " +
                                      m_root_bpa.m_uu_i_ms_end_interval
                                      );

                    //если границы не поменялись то не отобр пункты
                      //изменения интервала
                    if ( 0 !== m_univreaderex_bpa.isFrameCounterCorrespondCommand() )
                        i_uu_new_interv_time_lv = m_univreaderex_bpa.getFrameTimeUUI64();
                    else
                      i_uu_new_interv_time_lv = m_univreaderex_bpa.getCommandTimeUUI64();
                    if (
                         Math.abs( i_uu_new_interv_time_lv -
                              m_root_bpa.m_uu_i_ms_begin_interval ) < 500
                         ||
                         Math.abs( i_uu_new_interv_time_lv -
                              m_root_bpa.m_uu_i_ms_end_interval ) < 500
                       )
                    {
                        menu_item_select_interval_left.visible = false;
                        menu_item_select_interval_right.visible = false;
                        if ( m_root_bpa.m_i_is_interval_corresp_event &&
                                ! ( m_root_bpa.m_i_is_interval_corresp_event_bookmark ) )
                          menu_item_save_interval.visible = false;
                    }
                    //e

                    onClicked: menu_interval2.open();
                }

                if(!popUpUpload_left_bound_rect.opened)
                {
                    popUpUpload_left_bound_rect.open();
                }
            }
        }
        Popup
        {
            id:popUpUpload_left_bound_rect
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent | Popup.CloseOnPressOutside
            x: iv_butt_spb_bmark_skip.x-(popUpUpload_left_bound_rect.width/1.6);
            y: parent.height - (100);
            width: 255;
            height: 30;
            padding: 0

            Component.onCompleted:
            {
                //console.info("###### 222 Component.onCompleted #####");
            }

            background: Rectangle
            {
                width:popUpUpload_left_bound_rect.width
                height:popUpUpload_left_bound_rect.height
                color:"steelblue"
                opacity:0.5
                clip: true
            }

            Rectangle
            {
                id:upload_left_bound_rect
                width: 255
                height: 28
                color: "transparent"
                clip: true
                //ch91014 anchors.verticalCenter:
                    //ch91014 parent
                     //ch91014 .verticalCenter

                Label {
                    id: upload_left_bound_2_lb
                    text: 'Выбран интервал'
                    font.pixelSize: 12
                    anchors.top: parent.top
                    anchors.left: parent.left

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
                        anchors.top: upload_left_bound_2_lb.bottom
                        anchors.left: parent.left
                        //anchors.right: parent.right
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
                    font.pixelSize: 12

                    anchors.top: parent.top
                    anchors.topMargin: 14
                    anchors.left: parent.left

                    property bool visible2: true
                    property bool visible3: true
                    property bool visible4: false
                    visible: visible2 && visible3 && visible4
                    color:'white'
                }
            }
        }

        Menu {
            id: menu_interval2
            //vart width: 265
            MenuItem {
                id: menu_item_select_interval_right
                height: visible ? implicitHeight : 0
                //ch00604 text: "Изменить интервал и оставить правую границу"
                text: "Изменить левую границу"
                onTriggered:
                {
                    if ( 0 !== m_univreaderex_bpa.isFrameCounterCorrespondCommand() )
                    {
                        m_idLog3_bpa.warn( "<interv> 107" );
                        rootRect_ButtonPane.correctIntervalSelectRight_Causing1();
                    }
                    else
                    {
                      m_idLog3_bpa.warn( "<interv> 108" );
                      //ch00607
                      //ch00607 m_univreaderex_bpa.setDelayCorrectIntervalSelectRight( 1 );
                      rootRect_ButtonPane.correctIntervalSelectRight_ByCommand_Causing1();
                      //e
                    }
                }
            }
            MenuItem {
                id: menu_item_select_interval_left
                height: visible ? implicitHeight : 0
                //ch00604 text: "Изменить интервал и оставить левую границу"
                text: "Изменить правую границу"
                onTriggered:
                {
                    m_idLog3_bpa.warn( '<interv>	507' );
                    if ( 0 !== m_univreaderex_bpa.isFrameCounterCorrespondCommand() )
                    {
                        m_idLog3_bpa.warn( '<interv>	508' );
                        rootRect_ButtonPane.correctIntervalSelectLeft_Causing1();
                    }
                    else
                    {
                      m_idLog3_bpa.warn( '<interv>	509' );
                      //ch00607
                      //ch00607 m_univreaderex_bpa.setDelayCorrectIntervalSelectLeft( 1 );
                      rootRect_ButtonPane.correctIntervalSelectLeft_ByCommand_Causing1();
                      //e
                    }
                }
            }
            MenuItem {
                id: menu_item_change
                height: visible ? implicitHeight : 0
                text: "Изменить интервал"
                onTriggered:
                {
                    m_idLog3_bpa.warn(
                                '<' + m_root_bpa.key2 + '_' + m_root_bpa.key3 + '_interv> 50' );
                    if ( 0 !== m_univreaderex_bpa.isFrameCounterCorrespondCommand() )
                    {
                        m_idLog3_bpa.warn( "<interv> 54" );
                        rootRect_ButtonPane.correctInterval_Causing1(
                                    m_univreaderex_bpa.getFrameTimeUUI64()
                                    );
                    }
                    else
                    {
                      m_idLog3_bpa.warn( "<interv>	57" );
                      //ch00608
                      //ch00608 m_univreaderex_bpa.setDelayCorrectInterval( 1 );
                      rootRect_ButtonPane.correctInterval_Causing1(
                          m_univreaderex_bpa.getCommandTimeUUI64()
                          );
                      //e
                    }
                }
            }
            MenuItem {
                id: menu_item_go_to_begin
                height: visible ? implicitHeight : 0
                text: "Перейти к началу"
                onTriggered:
                {
                    m_univreaderex_bpa.outsideSetTimeMS( m_root_bpa.m_uu_i_ms_begin_interval );
                }
            }
            MenuItem {
                id: menu_item_go_to_end
                height: visible ? implicitHeight : 0
                text: "Перейти к концу"
                onTriggered:
                {
                    m_univreaderex_bpa.outsideSetTimeMS( m_root_bpa.m_uu_i_ms_end_interval );
                }
            }
            MenuItem {
                id: menu_item_save_interval
                height: visible ? implicitHeight : 0
                text: "Сохранить интервал"
                onTriggered:
                {
                    m_root_bpa.m_i_is_interval_corresp_event = 1;
                    //ch90723 m_root_bpa.m_b_ness_check_present_event = 1;
                    m_root_bpa.m_b_ness_pass_params = false;
                    m_root_bpa.m_i_is_interval_corresp_event_bookmark = 1;

                    var qml = '/qtplugins/iv/archivecomponents/selectinterval/qselectinterval3.qml';
                    ivCreator808_5.asyncCreate('', 'file:///' + applicationDirPath + qml,
                                           //ch90918 rootRect_ButtonFullPaneArc
                                           rootRect_ButtonPane
                                               );
                    m_idLog2_bpa.warn(
                        //'181031 end time ' +
                                //ch90510 time811
                                //s_frame_time_2_lv
                                //+
                        ' ness_pass_params ' + m_root_bpa.m_b_ness_pass_params );
                }
            }
            MenuItem {
                id: menu_item_call_unload_window
                height: visible ? implicitHeight : 0
                text: "Открыть окно выгрузки"
                onTriggered:
                {
                    /*ch90719
                    m_root_bpa.m_s_unload_begin_interval =
                            univreaderex.uu64ToHumanEv( m_root_bpa.m_uu_i_ms_begin_interval
                                          );
                    m_root_bpa.m_s_unload_end_interval =
                      univreaderex.uu64ToHumanEv( m_root_bpa.m_uu_i_ms_end_interval
                                    );
                    */
                    var qml = '/qtplugins/iv/viewers/archiveplayer/qmainexport.qml';
                    ivCreator801_ButtonPane.asyncCreate('', 'file:///' + applicationDirPath + qml,
                                             //ch90918 rootRect_ButtonFullPaneArc
                                             rootRect_ButtonPane
                                             );
                }
            }
            MenuItem {
                id: menu_item_unload
                height: visible ? implicitHeight : 0
                text: "Выгрузить"
                onTriggered:
                {
                  m_univreaderex_bpa.unload007(
                      m_root_bpa.m_uu_i_ms_begin_interval,
                      m_root_bpa.m_uu_i_ms_end_interval
                      );

                    var win_count = MExprogress.windows_count;
                    m_idLog3_bpa.trace('<IVButtonPaneArc.qml> menu_item_unload onTriggered win_count = '+win_count);
                    m_idLog3_bpa.trace('<IVButtonPaneArc.qml> menu_item_unload onTriggered  export_status_window.value = '+export_status_window.value);
                    if (win_count === 0 && export_status_window.value === "true")
                    {
                        ivExprogressCreator.ivComponent.command('WindowsCreator', 'windows:add', {
                                                                    'qml':'/qtplugins/iv/exprogress/Exprogress.qml',
                                                                    'unique': 'exprogress.window.',
                                                                    'isSimpleClosing':true
                                                                });
                    }
                }
            }
            MenuItem {
                text: "Сбросить выделение"
                id: menu_item_reset_selection
                onTriggered:
                {
                  //print("Action 2")
                  //ch90719
                  m_root_bpa.m_uu_i_ms_begin_interval = 0;
                  m_root_bpa.m_uu_i_ms_end_interval = 0;
                  //e ch90719


                  m_iv_arc_slider_control_bpa.m_slider_control_asc.clearFill2();
                  upload_left_bound_lb.visible4 = false;
                  upload_left_bound_2_lb.visible4 = false;
                  m_root_bpa.m_i_select_interv_state = m_root_bpa.c_I_IS_FIERST_SELECT_INTERV;
                  select_interval_ivibt.txt_tooltip = m_root_bpa.m_s_tooltip_select_interv_1
                }
            }
            MenuItem {
                text: "Отмена"
                id: menu_item_cancel111
                onTriggered:
                {
                  //print("Action 3")
                }
            }
        }
        /*ch91031 перенес
        IVImageButton
        {
            id: force_write_ivibt
            //ch90917 anchors.top: parent.top
            //ch90917 anchors.topMargin: 5
            //ch90917 anchors.right: iv_butt_spb_bmark_skip.left
            //ch90917 anchors.rightMargin: 5
            //ch90917
            //canchors.verticalCenter: parent.verticalCenter
            //e
            size: "small"
            txt_tooltip: "принудительная запись в архив"
            on_source: 'file:///' + applicationDirPath + '/images/white/flag_left.svg'
            onClicked:{
                m_root_bpa.b_forceRecordCurrState = !m_root_bpa.b_forceRecordCurrState;
                m_univreaderex_bpa.commandForceRecord( m_root_bpa.b_forceRecordCurrState )
            }
        }
        ch91031 */
        IVButtonSpinbox{
            id: iv_butt_spb_events_skip

            size: "normal"
            btn_color:"white"
            left_tooltip: "Перейти к предидущему событию"
            center_tooltip: ""
            right_tooltip: "Перейти к следующему событию"
            left_src: 'arrow_left.svg'
            center_src:  'thunder.svg'
            right_src: 'arrow_right.svg'

            //z: 0
            property bool visible2: true
            property bool visible3: true
            property bool visible4: true
            visible: move_to_event.isAllowed && visible2 && visible3 && visible4
            //ch91112 deb
            onVisibleChanged:
            {
                m_idLog3_bpa.warn(
                  ' iv_butt_spb_events_skip onVisibleChanged isAllowed '
                  + move_to_event.isAllowed +
                  ' visible2 ' + visible2 + ' visible3 ' + visible3 +
                  ' visible4 ' + visible4 + ' visible ' + visible );
            }
            //e
            onLeftClick:{
                var pt_mapped_pos_lv = null;
                pt_mapped_pos_lv = mapToItem
                        ( m_root_bpa, x, y );
                m_idLog3_bpa.warn( ' onVisibleChanged x ' + x +
                                   ' pt_mapped_pos_lv.x ' +
                                   pt_mapped_pos_lv.x +
                                   ' width ' + width + ' y ' + y +
                                   ' pt_mapped_pos_lv.y ' +
                                   pt_mapped_pos_lv.y +
                                   ' height ' + height );
                //ch90917 rootRect_ButtonFullPaneArc
                rootRect_ButtonPane
                  .moveToEventBySlider_Causing1( false, false,
                                             //ch91112_2 x, y
                                             pt_mapped_pos_lv.x,
                                             pt_mapped_pos_lv.y
                                             + height )
                if(!popUpUpload_left_bound_rect.opened)
                {
                    popUpUpload_left_bound_rect.open();
                }
            }
            onCenterClick:{
            }
            onRightClick:{
                var pt_mapped_pos_lv = null;
                pt_mapped_pos_lv = mapToItem
                        ( m_root_bpa, x, y );
                m_idLog3_bpa.warn( ' onVisibleChanged x ' + x +
                                   ' pt_mapped_pos_lv.x ' +
                                   pt_mapped_pos_lv.x +
                                   ' width ' + width + ' y ' + y +
                                   ' pt_mapped_pos_lv.y ' +
                                   pt_mapped_pos_lv.y +
                                   ' height ' + height );

                //ch90918 rootRect_ButtonFullPaneArc
                rootRect_ButtonPane
                  .moveToEventBySlider_Causing1( true, false,
                                                //ch00520 x
                                                pt_mapped_pos_lv.x
                                                //e
                                                + ( 2 * width / 5 )
                                                ,
                                                //ch00520 y
                                                pt_mapped_pos_lv.y
                                                //e
                                                + height
                                                )
                if(!popUpUpload_left_bound_rect.opened)
                {
                    popUpUpload_left_bound_rect.open();
                }
            }
        }
        IVButtonSpinbox{
            id: iv_butt_spb_bmark_skip

            size: "normal"
            btn_color:"white"
            left_tooltip: "Перейти к предыдущей метке"
            center_tooltip: ""
            right_tooltip: "Перейти к следующей метке"
            left_src: 'arrow_left.svg'
            center_src:  'bookmark.svg'
            right_src: 'arrow_right.svg'
            //ch91112 связано с режимом общ панели
            property bool visible2: true
            //ch91112 от изменения размера е
            property bool visible3: true
            //ср91112 от настройки пользователя, показывать ли
            property bool visible4: true
            visible: move_to_bmark.isAllowed && visible2 && visible3 && visible4
            onLeftClick:{

                var pt_mapped_pos_lv = null;
                pt_mapped_pos_lv = mapToItem
                        ( m_root_bpa, x, y );
                m_idLog3_bpa.warn( ' onVisibleChanged x ' + x +
                                   ' pt_mapped_pos_lv.x ' +
                                   pt_mapped_pos_lv.x +
                                   ' width ' + width + ' y ' + y +
                                   ' pt_mapped_pos_lv.y ' +
                                   pt_mapped_pos_lv.y +
                                   ' height ' + height );


                //ch90918 rootRect_ButtonFullPaneArc
                rootRect_ButtonPane
                   .moveToEventBySlider_Causing1( false,
                                       true,
                                       //ср00528 x, y
                                       pt_mapped_pos_lv.x,
                                       pt_mapped_pos_lv.y
                                       + height );
                if(!popUpUpload_left_bound_rect.opened)
                {
                    popUpUpload_left_bound_rect.open();
                }
            }
            onCenterClick:{
            }
            onRightClick:{

                //ch00109 deb
                //var t1 = 0;
                //t1 = rootRect_ButtonPane.getFrameTime();
                //m_idLog3_bpa.warn( '<photocam> t1 ' + t1 );
                //e


                var pt_mapped_pos_lv = null;
                pt_mapped_pos_lv = mapToItem
                        ( m_root_bpa, x, y );
                m_idLog3_bpa.warn( ' onVisibleChanged x ' + x +
                                   ' pt_mapped_pos_lv.x ' +
                                   pt_mapped_pos_lv.x +
                                   ' width ' + width + ' y ' + y +
                                   ' pt_mapped_pos_lv.y ' +
                                   pt_mapped_pos_lv.y +
                                   ' height ' + height );



                //ch90918rootRect_ButtonFullPaneArc
                rootRect_ButtonPane
                  .moveToEventBySlider_Causing1( true, true,
                                            //ср00528 x
                                            pt_mapped_pos_lv.x
                                            + ( 2 * width / 5 ),
                                            //ср00528 y
                                            pt_mapped_pos_lv.y
                                            + height );
                if(!popUpUpload_left_bound_rect.opened)
                {
                    popUpUpload_left_bound_rect.open();
                }
            }
        }

        IVComponentCreator{
            id: ivCreator808_5
            ivComponent: m_root_bpa.ivComponent // родитель, должен быть равен тому, чему
            //равно свойство ivComponent
            onCreated:{// вызывается, когда компонент удачно создан
                // component - создаваемый компонент
                m_idLog2_bpa.warn('onCreated180904 808_5 ' + component);
            }
            onBindings: {// вызывается, когда компоненту можно выставить свойства
                //ch90621 var s_i64_frame_time_lv = '';
                // component - создаваемый компонент(можно выставлять ему различные свойства и т.д.)

                var point_00525_fr_lv = mapFromGlobal( 0, 0 );
                var point_00525_to_lv = mapToGlobal( 0, 0 );
                var point_00525_to_r_lv = m_root_bpa.mapToGlobal( 0, 0 );

                m_idLog3_bpa.warn( 'onBindings 808_5 fr_gl x ' +
                                  point_00525_fr_lv.x +
                                  ' y ' +
                                  point_00525_fr_lv.y +
                                  ' to_gl x ' +
                                  point_00525_to_lv.x +
                                  ' y ' +
                                  point_00525_to_lv.y +
                                  ' to_r_gl x ' +
                                  point_00525_to_r_lv.x +
                                  ' y ' +
                                  point_00525_to_r_lv.y +
                                  ' m_root_bpa.width ' +
                                  m_root_bpa.width +
                                  ' m_root_bpa.height ' +
                                  m_root_bpa.height +
                                  ' component.width ' +
                                  component.width +
                                  ' component.height ' +
                                  component.height
                                  );
                component.key2 = m_root_bpa.key2; // просто присвоение свойства
                component.begin = m_root_bpa.m_uu_i_ms_begin_interval;
                component.end = m_root_bpa.m_uu_i_ms_end_interval;

    //                            component.id777 = Qt.binding(function(){
    //                                return m_root_bpa.m_s_exch_event_id;
    //                            });

                m_root_bpa.m_s_exch_event_id = Qt.binding(function(){
                    return component.m_s_exch_event_id_si;
                });


                component.m_b_unload_mode =
                  m_root_bpa.m_b_is_caused_by_unload;
                m_idLog2_bpa.warn(
                    '181031 bind beg ' + component.begin +
                            'end ' + component.end
                            );

                component.x = point_00525_to_r_lv.x +
                        m_root_bpa.width / 2 - component.width / 2 ;
                component.y = point_00525_to_r_lv.y +
                        m_root_bpa.height / 2 - component.height / 2 ;

            }
            onError: {// вызывается в том случае, когда компонент не может быть создан
            }
        }
        //e ch90917


        Item
        {
                Layout.fillWidth: true
        }
    }

}

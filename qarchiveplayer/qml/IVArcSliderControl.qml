import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

import QtQuick.Templates 2.0 as T

import iv.plugins.loader 1.0
import iv.guicomponents 1.0
import iv.viewers.archiveplayer 1.0

Rectangle
{
    //ch90617 Rectangle {
        id: rootRect_ArcSliderControl   //old slider_control_rct

        property variant m_univreaderex_asc: null
        property variant m_idLog2_asc: null
        property variant m_idLog3_asc: null
        property variant m_slider_control_asc: slider_control
        property variant m_root_asc: null
        property variant m_upload_left_bound_lb_asc: null
        property variant m_upload_left_bound_2_lb_asc: null
        property real m_i_slider_height_koef: 1.0
        property var m_popup_scale_intervals: null
        property var image: null
        property var m_timer_finish_preview: null


        property variant m_r_width_909: null
        signal slidermouseEntered

        color: //"saddlebrown"
            "transparent"
            //ch90905 deb 'yellow'
            //e
        property real c_I_BOUND_WIDTH: 0.0025
        property int c_I_SCALE_DEVISION_MAX_NUM: 12


        property variant m_imageSlider_asc: null

        property variant m_event_select_rct_hint_asc: null
        //property variant m_event_select_rct_asc: null

        property variant m_event_select_rct_hint_text_asc: null

        property variant c_I64_HINT_STATE_DELTA_TIMEOUT:
            //ch91016 1000
            500
        property variant m_i64_marker_mouse_move_actions_delta_timeout: 0

        property bool m_b_is_ness_mouse_move_actions: false

        onWidthChanged: {
            m_idLog3_asc.warn( '<preview> arc_slider width changed before');

            /*if (scale_time_right_lb_rec.x < scale_time_left_lb_rec.width)
            {
                scale_time_left_lb_rec.visible = false;
                scale_time_right_lb_rec.visible = false;
            }
            else
            {
                m_univreaderex_asc.refreshEventsOnBar();
            }*/

            timerUpdate.stop();
            timerUpdate.start();

            m_idLog3_asc.warn( '<preview> arc_slider width changed after');
        }

        Component.onCompleted: {
            if (m_root_asc.debug_mode === true)
            {
                IVCompCounter.addComponent(rootRect_ArcSliderControl);
            }
        }
        Component.onDestruction: {
            if (m_root_asc.debug_mode === true)
            {
                IVCompCounter.removeComponent(rootRect_ArcSliderControl);
            }
        }

        Timer
        {
            id: timerUpdate
            interval:500;
            running: false;
            repeat: false
            onTriggered:
            {
                //console.info("TTTTTTTTTTTTTTTTTTTTTTTTTT onTriggered begin TTTTTTTTTTTTTTTTTTTTTTTTTT");
                if (scale_time_right_lb_rec.x < scale_time_left_lb_rec.width)
                {
                    scale_time_left_lb_rec.visible = false;
                    scale_time_right_lb_rec.visible = false;
                }
                m_univreaderex_asc.refreshEventsOnBar();
                //console.info("TTTTTTTTTTTTTTTTTTTTTTTTTT onTriggered end TTTTTTTTTTTTTTTTTTTTTTTTTT");
            }
        }

        ArchivePlayer {
            id: idarchive_player

            onDrawPreviewQML: {
                console.info("onDrawPreviewQML {");
                var pt_mapped_pos_lv = null;

                if (rootRect_ArcSliderControl.isInSliderZone()) {

                    image.source="";
                    m_imageSlider_asc.visible = false;
                    if (qs_provider_param_lv.length > 0)
                    {
                        m_imageSlider_asc.x = m_root_asc.width / 2 - m_imageSlider_asc.width / 2;
                        m_imageSlider_asc.y = qr_mouse_y_av - ((m_imageSlider_asc.height - 4) * 1.75);

                        console.info("onDrawPreviewQML qs_provider_param_lv=",qs_provider_param_lv);
                        console.info("onDrawPreviewQML m_imageSlider_asc.x=",m_imageSlider_asc.x);
                        console.info("onDrawPreviewQML m_imageSlider_asc.y=",m_imageSlider_asc.y);

                        image.source=qs_provider_param_lv;
                        image.visible=true;
                        m_imageSlider_asc.visible = true;
                    }

                    if (m_timer_finish_preview.running) {
                        m_timer_finish_preview.stop()
                    }
                    m_timer_finish_preview.start()
                }
                console.info("onDrawPreviewQML }")
            }

            Component.onCompleted: {
                //if (root.debug_mode === true) {
                //    IVCompCounter.addComponent(idarchive_player)
                //}
                //update_time_now_interval.start()
                //idLog.trace('###### idarchive_player onCompleted = ######')
            }
            Component.onDestruction: {
                //if (root.debug_mode) {
                //    IVCompCounter.removeComponent(idarchive_player)
                //}
                //idLog.trace('###### idarchive_player onDestruction = ######')
            }
        }

        //ch91010_3 property variant m_imageSlider_CONT_asc: null
        /*ch90618
        Rectangle
        {
            id: rect_90618
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            color: "transparent"
        */
    function isInSliderZone(
        //ch91017 rl_mouse_x_av,  rl_mouse_y_av
        )
    {
        var rl_mouse_x_lv = 0.0;
        var rl_mouse_y_lv = 0.0;
        //ch91017
        rl_mouse_x_lv = slider_control_rct_mouse.mouseX;
        rl_mouse_y_lv = slider_control_rct_mouse.mouseY;
        //e


        /*ch91014 vart
        return
              (
                rl_mouse_y_av <==
                   slider_control.background.y + slider_control.background.height
                &&
                slider_control.background.y <== rl_mouse_y_av
                &&
                rl_mouse_x_av <== sliderBackGroundX() + sliderBackGroundWidth()
                &&
                sliderBackGroundX() <== rl_mouse_x_av
               );
        */
      //m_idLog3_asc.warn( '<preview> 191014 3' )
      var b_1_lv =
          (
            rl_mouse_y_lv <= slider_control.background.y +
                    slider_control.background.height
            &&
            slider_control.background.y <= rl_mouse_y_lv
           );
      m_idLog3_asc.warn( '<preview> 191014 3 b_1_lv ' + b_1_lv )
      var b_2_lv =
          (
          rl_mouse_x_lv <= sliderBackGroundX() + sliderBackGroundWidth()
          &&
          sliderBackGroundX() <= rl_mouse_x_lv
          );
        m_idLog3_asc.warn( '<preview> 191014 3 b_2_lv ' + b_2_lv )
        return ( b_1_lv && b_2_lv );
    }


    function timerActionsSC()
    {
        var b_is_ness_cont_work_lv = false;
        //m_idLog3_asc.warn( '<preview> 191014 1' );
        //console.info("timerActionsSC()");
        if ( m_b_is_ness_mouse_move_actions )
        {
            //ch91014 m_univreaderex_asc.m_qr_prev_tick_coord_x = mouseX;
            //ch91014 m_univreaderex_asc.m_qr_prev_tick_coord_y = mouseY;
            //m_idLog3_asc.warn( '<preview> 191014 5' );
            b_is_ness_cont_work_lv =
                    //ch91017 slider_control_rct_mouse.
                      rootRect_ArcSliderControl.isInSliderZone(
                        //ch91017 slider_control_rct_mouse.mouseX,
                        //ch91017 slider_control_rct_mouse.mouseY
                          );
            m_idLog3_asc.warn( '<preview> 191014 6 b_is_ness_cont_work_lv ' + b_is_ness_cont_work_lv );
            if ( b_is_ness_cont_work_lv )
              slider_control_rct_mouse.sliderMouseMoveActions();
            //ch91018
            else
            {
              m_b_is_ness_mouse_move_actions = false;
              //делаем невидимыми е
              if ( m_imageSlider_asc.imageVisible_2 )
              {
                  m_imageSlider_asc.imageVisible_2 = false;
              }

              if ( event_select_rct.visible )
                  event_select_rct.visible = false;

              if ( m_event_select_rct_hint_asc.visible )
                    m_event_select_rct_hint_asc.visible = false;
            }
            //e
        };
    }
    function sliderBackGroundX()
    {
      return slider_control.background.x + slider_control.handle.radius;
    }
    //function sliderBackGroundY()
    //{
      //return slider_control.background.y - slider_control.handle.radius;
    //}
    function sliderBackGroundWidth()
    {
      return slider_control.background.width - 2 * slider_control.handle.radius;
    }
    function setLabelsVisible( b_is_visible, b_with_mark, b_by_window_size )
    {
        var i_it_lv = 0;
        var marker_lv = null;

        m_idLog3_asc.warn('<events> setLabelsVisible b_is_visible ' + b_is_visible +
                    ' b_with_mark ' + b_with_mark +
                    ' b_by_window_size ' + b_by_window_size);

        for ( i_it_lv = 0; i_it_lv < rootRect_ArcSliderControl.c_I_SCALE_DEVISION_MAX_NUM; i_it_lv++ )
        {
            var label_lv = iv_arc_slider_control.getLabelByInd( i_it_lv );
            m_idLog3_asc.warn('<events> setLabelsVisible before label_lv.visible3 ' + label_lv.visible3 +
                        ' label_lv.visible2 ' + label_lv.visible2);
            if ( b_by_window_size )
            {
                if (label_lv.visible3 !== b_is_visible)
                {
                    label_lv.visible3 = b_is_visible;
                }
            }
            else
            {
                if (label_lv.visible2 !== b_is_visible)
                {
                    label_lv.visible2 = b_is_visible;
                }
            }
            //m_idLog3_asc.warn('<events> setLabelsVisible after label_lv.visible3 ' + label_lv.visible3 +
            //            ' label_lv.visible2 ' + label_lv.visible2);
            if ( b_with_mark )
            {
                marker_lv = iv_arc_slider_control.getRectMarkByInd( i_it_lv );
                if (marker_lv.visible !== b_is_visible)
                {
                    marker_lv.visible = b_is_visible;
                }
                m_idLog3_asc.warn('<events> setLabelsVisible i_it_lv ' + i_it_lv +
                            ' marker_lv.id ' + marker_lv.id
                                  );
            }
            m_idLog3_asc.warn('<events> setLabelsVisible i_it_lv ' + i_it_lv +
                        ' label_lv.id ' + label_lv.id +
                        ' label_lv.visible ' + label_lv.visible2
                              );
        }
    }

    function setScaleTimeLeftRightVisible()
    {
        var time_left_cross = false;
        var time_rigth_cross = false;

        scale_time_left_lb_rec.visible = true;
        scale_time_right_lb_rec.visible = true;

        var i_it_lv = 0;

        //console.info("!!!!!!!!!!!!!!!!!!!!!!!!!!! = ", rootRect_ArcSliderControl.c_I_SCALE_DEVISION_MAX_NUM);

        for ( i_it_lv = 0; i_it_lv < rootRect_ArcSliderControl.c_I_SCALE_DEVISION_MAX_NUM; i_it_lv++ )
        {
            var label_lv = iv_arc_slider_control.getLabelByInd( i_it_lv );
            //console.info("----------------------------- label_lv = ", label_lv);
            //console.info("----------------------------- label_lv.visible = ", label_lv.visible);

            if (label_lv.visible)
            {
                //console.info("scale_time_left_lb_rec.width = ", scale_time_left_lb_rec.width);
                //console.info("label_lv.x = ", label_lv.x);
                if (scale_time_left_lb_rec.width > label_lv.x)
                {
                    time_left_cross = true;
                }

                if (label_lv.x+label_lv.contentWidth > scale_time_right_lb_rec.x)
                {
                    time_rigth_cross = true;
                }
            }
        }

        //console.info("!!!!!!!!!!!!!!!!!!!!!!!!!!! -----------------------------------------------------------");

        if (time_left_cross === true)
        {
            scale_time_left_lb_rec.visible = false;
            //console.info("setScaleTimeLeftRightVisible 1 scale_time_left_lb_rec.visible = ",scale_time_left_lb_rec.visible);
        }
        else
        {
            scale_time_left_lb_rec.visible = true;
            //console.info("setScaleTimeLeftRightVisible 2 scale_time_left_lb_rec.visible = ",scale_time_left_lb_rec.visible);
        }

        if (time_rigth_cross === true)
        {
            scale_time_right_lb_rec.visible = false;
            //console.info("setScaleTimeLeftRightVisible 3 scale_time_right_lb_rec.visible = ",scale_time_right_lb_rec.visible);
        }
        else
        {
            scale_time_right_lb_rec.visible = true;
            //console.info("setScaleTimeLeftRightVisible 4 scale_time_right_lb_rec.visible = ",scale_time_right_lb_rec.visible);
        }
    }

    function getThinningFactor(dev_num_lv )
    {
        //console.info("getThinningFactor {");
        var i_it_lv = 0;
        var labels_width = 0;
        var max_content_width = 0;
        var thin_fact=0;

        //console.info(" <<<<<<<<<<<<<<< getThinningFactor dev_num_lv  = ",dev_num_lv);

        for ( i_it_lv = 0; i_it_lv < dev_num_lv; i_it_lv++ )
        {
            var label_lv = rootRect_ArcSliderControl.getLabelByInd( i_it_lv );
            if (max_content_width < label_lv.contentWidth && label_lv.visible)
            {
                max_content_width = label_lv.contentWidth;
            }

            //console.info(" <<<<<<<<<<<<<<< getThinningFactor label_lv.contentWidth  = ",label_lv.contentWidth);
            //console.info(" <<<<<<<<<<<<<<< getThinningFactor label_lv.visible  = ",label_lv.visible);
        }

        //for ( i_it_lv = 0; i_it_lv < dev_num_lv; i_it_lv++ )
        //{
        //    var label_lv = rootRect_ArcSliderControl.getLabelByInd( i_it_lv );
        //    labels_width += label_lv.contentWidth;
        //    console.info(" <<<<<<<<<<<<<<< getThinningFactor label_lv.contentWidth  = ",label_lv.contentWidth);
        //}

        //console.info(" <<<<<<<<<<<<<<< getThinningFactor labels_width before  = ",labels_width);

        labels_width = max_content_width * dev_num_lv;

        labels_width += scale_time_left_lb_rec.width;
        labels_width += scale_time_right_lb_rec.width;

        //console.info(" <<<<<<<<<<<<<<< getThinningFactor labels_width = ",labels_width);
        //console.info(" <<<<<<<<<<<<<<< getThinningFactor rootRect_ArcSliderControl.width = ",rootRect_ArcSliderControl.width);

        if (labels_width > rootRect_ArcSliderControl.width)
        {
            if (labels_width/2 < rootRect_ArcSliderControl.width)
            {
                //console.info("getThinningFactor return 2");
                //console.info("getThinningFactor return 0");
                //return 2;
                thin_fact=2;
            }
            else if (labels_width/3 < rootRect_ArcSliderControl.width)
            {
                //console.info("getThinningFactor return 3");
                //console.info("getThinningFactor return 0");
                //return 3;
                thin_fact=3;
            }
            else if (labels_width/4 < rootRect_ArcSliderControl.width)
            {
                //console.info("getThinningFactor return 4");
                //return 4;
                thin_fact=4;
            }
            else
            {
                //console.info("getThinningFactor return ",rootRect_ArcSliderControl.c_I_SCALE_DEVISION_MAX_NUM);
                //console.info("getThinningFactor return 0");
                //return rootRect_ArcSliderControl.c_I_SCALE_DEVISION_MAX_NUM;
            }
        }

        for ( i_it_lv = 0; thin_fact !== 0 && i_it_lv < dev_num_lv; i_it_lv+= thin_fact+1 )
        {
            for (var j = i_it_lv; j <i_it_lv+thin_fact; j++)
            {
                var label_lv1 = rootRect_ArcSliderControl.getLabelByInd( j );
                if (label_lv1.visible)
                {
                    label_lv1.visible2 = false;
                }

                //console.info(" <<<<<<<<<<<<<<< getThinningFactor label_lv.contentWidth  = ",label_lv1.contentWidth);
                //console.info(" <<<<<<<<<<<<<<< getThinningFactor label_lv.visible  = ",label_lv1.visible);
            }
        }
        //console.info("getThinningFactor return 0");
        //console.info("getThinningFactor }");
        return 0;
    }
    function getRectMarkByInd( i_it_av )
    {
        var label_lv = scale_devision_point_0_rect;
        switch( i_it_av )
        {
        case 0:
        {
          label_lv = scale_devision_point_0_rect;
          break;
        }
        case 1:
        {
          label_lv = scale_devision_point_1_rect;
          break;
        }
        case 2:
        {
          label_lv = scale_devision_point_2_rect;
          break;
        }
        case 3:
        {
          label_lv = scale_devision_point_3_rect;
          break;
        }
        case 4:
        {
          label_lv = scale_devision_point_4_rect;
          break;
        }
        case 5:
        {
          label_lv = scale_devision_point_5_rect;
          break;
        }
        case 6:
        {
          label_lv = scale_devision_point_6_rect;
          break;
        }
        case 7:
        {
          label_lv = scale_devision_point_7_rect;
          break;
        }
        case 8:
        {
          label_lv = scale_devision_point_8_rect;
          break;
        }
        case 9:
        {
          label_lv = scale_devision_point_9_rect;
          break;
        }
        case 10:
        {
          label_lv = scale_devision_point_10_rect;
          break;
        }
        case 11:
        {
          label_lv = scale_devision_point_11_rect;
          break;
        }
        }
        return label_lv;
    }
    function getLabelByInd( i_it_av )
    {
        var label_lv = scale_devision_time_0_lb;
        switch( i_it_av )
        {
        case 0:
        {
          label_lv = scale_devision_time_0_lb;
          break;
        }
        case 1:
        {
          label_lv = scale_devision_time_1_lb;
          break;
        }
        case 2:
        {
          label_lv = scale_devision_time_2_lb;
          break;
        }
        case 3:
        {
          label_lv = scale_devision_time_3_lb;
          break;
        }
        case 4:
        {
          label_lv = scale_devision_time_4_lb;
          break;
        }
        case 5:
        {
          label_lv = scale_devision_time_5_lb;
          break;
        }
        case 6:
        {
          label_lv = scale_devision_time_6_lb;
          break;
        }
        case 7:
        {
          label_lv = scale_devision_time_7_lb;
          break;
        }
        case 8:
        {
          label_lv = scale_devision_time_8_lb;
          break;
        }
        case 9:
        {
          label_lv = scale_devision_time_9_lb;
          break;
        }
        case 10:
        {
          label_lv = scale_devision_time_10_lb;
          break;
        }
        case 11:
        {
          label_lv = scale_devision_time_11_lb;
          break;
        }
        }
        return label_lv;
    }
    function changeHeidthIfNess( mouseX, mouseY )
    {
        var b_is_ness_active_lv = false;
        var b_is_ness_cont_work_lv = true;
        var i_i_slider_height_koef_lv = 0.0;

        var i_counter006_lv = 0;

        //если коорд слайдера поменялась е
        if ( b_is_ness_cont_work_lv )
        {
          m_idLog2_asc.warn('onPositionChanged ' +
                         //ch91012 'm_i_timer_counter ' +
                         //ch91012 m_univreaderex_asc.m_i_timer_counter +
                         'mouseX ' +
                         mouseX +
                         'm_qr_prev_tick_coord_x_2 ' +
                         m_univreaderex_asc.m_qr_prev_tick_coord_x_2
                         );
          b_is_ness_cont_work_lv =
            (
              m_univreaderex_asc.m_qr_prev_tick_coord_x_2 !== mouseX
              ||
              m_univreaderex_asc.m_qr_prev_tick_coord_y_2 !== mouseY
             );
        }
        if ( b_is_ness_cont_work_lv )
        {
            m_idLog3_asc.warn('changeHeidthIfNess ' +
                           'mouseX ' +
                           mouseX +
                           'mouseY ' +
                           mouseY +
                           'background.x ' +
                           slider_control.background.x +
                           'background.y ' +
                           slider_control.background.y +
                           'background.width ' +
                           slider_control.background.width +
                           'background.height ' +
                           slider_control.background.height
                           );
            m_univreaderex_asc.m_qr_prev_tick_coord_x_2 = mouseX;
            m_univreaderex_asc.m_qr_prev_tick_coord_y_2 = mouseY;
            b_is_ness_active_lv =
              ( mouseY <= slider_control.background.y +
                          slider_control.background.height &&
                slider_control.background.y <= mouseY &&
                mouseX <=
                 sliderBackGroundX() + sliderBackGroundWidth()
                 &&
                 sliderBackGroundX()
                   <= mouseX );
            i_i_slider_height_koef_lv = b_is_ness_active_lv ? 1.5 : 1.0;
            m_idLog3_asc.warn('changeHeidthIfNess ' +
                           'b_is_ness_active_lv ' +
                           b_is_ness_active_lv +
                           ' i_i_slider_height_koef_lv ' +
                           i_i_slider_height_koef_lv +
                           ' m_i_slider_height_koef ' +
                           rootRect_ArcSliderControl.m_i_slider_height_koef
                              );
          //ch90911 утолщение полоски слайдера e
          if ( i_i_slider_height_koef_lv !== rootRect_ArcSliderControl.
                    m_i_slider_height_koef )
          {
                rootRect_ArcSliderControl.
                  m_i_slider_height_koef = i_i_slider_height_koef_lv;
                /*ch00622
                i_counter006_lv = m_univreaderex_asc.getCounter006();
                m_univreaderex_asc.onEventsIntervalesNeedRefreshChangedReal(
                    i_counter006_lv, 1 );
                */
          };
          //e
        };
    }
    function drawLabel( i_it_av, qr_point_scale_devision_av,
                        qs_scale_devision_text_av )
    {
       //ch90920 var rl_pos_lv = 0;
       //ch90920 var rl_pos_mark_lv = 0;
       m_idLog3_asc.warn( '<slider> drawLabel i_it_av ' +
                          i_it_av +
                          ' qr_point_scale_devision_av ' + qr_point_scale_devision_av +
                         ' qs_scale_devision_text_av ' + qs_scale_devision_text_av
                          );
       var label_lv = getLabelByInd( i_it_av );
       label_lv.text = qs_scale_devision_text_av;

       label_lv.visible2 = true;
       //ch90920 rl_pos_mark_lv =
         //ch90920 slider_control.x + qr_point_scale_devision_av * slider_control.width;
       //ch90920 rl_pos_lv = rl_pos_mark_lv - label_lv.contentWidth / 2;
       //ch90920 deb label_lv.anchors.leftMargin = rl_pos_lv;
       //ch90920
       label_lv.m_r_sd_offset =  qr_point_scale_devision_av;
       label_lv.m_r_sd_contentWidth = label_lv.contentWidth;
       //e
       m_idLog3_asc.warn( '<slider> drawLabel slider_control.x ' +
                          slider_control.x +
                         ' slider_control.width ' + slider_control.width +
                         ' rootRect_ArcSliderControl.width ' + rootRect_ArcSliderControl.width +
                         ' label_lv.x ' + label_lv.x +
                         ' label_lv.y ' + label_lv.y +
                         ' label_lv ' + label_lv +
                         //ch90920 ' rl_pos_lv ' + rl_pos_lv +
                         ' label_lv.contentWidth ' +
                         label_lv.contentWidth +
                         ' m_r_width_909 ' + rootRect_ArcSliderControl.m_r_width_909
                          );
       m_idLog3_asc.warn( '<slider> drawLabel after assign ' );

       //ch90906 deb if ( 2 === i_it_av )
         //ch90906 deb scale_devision_time_2_lb.
           //ch90906 deb anchors.leftMargin = rl_pos_lv;

       //рисочки е
       var rect_mark_lv = getRectMarkByInd( i_it_av );
       //ch90920 rect_mark_lv.anchors.leftMargin = rl_pos_mark_lv;
       rect_mark_lv.visible = true;
       rect_mark_lv.m_r_sd_offset = qr_point_scale_devision_av;
    }

    T.Slider {
        id: slider_control
        objectName: 'slider_90622'
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        to:
            100000.0
        z:2
        handle: Rectangle {
            x: slider_control.visualPosition * (slider_control.width - width)
            y: (slider_control.height - height) / 2
            width: 5//8.0 * rootRect_ArcSliderControl.m_i_slider_height_koef
            height: parent.height+20//8.0 * rootRect_ArcSliderControl.m_i_slider_height_koef
            radius: 4.0 * rootRect_ArcSliderControl.m_i_slider_height_koef
            z: 2
            color: "#0000cd"//slider_control.pressed ? "#f0f0f0" : "#f6f6f6"
        }
        background: Rectangle {
            y: (slider_control.height - height) / 2
            height: parent.height//4.0 * rootRect_ArcSliderControl.m_i_slider_height_koef
            radius: 1.0 * rootRect_ArcSliderControl.m_i_slider_height_koef
            //color: "orangered"
        }


        onValueChanged:
        {
            m_idLog3_asc.warn( '<slider> onValueChanged b_slider_value_outside_change ' +
                              m_root_asc.b_slider_value_outside_change + " SLIDER VALUE = " + slider_control.value );
            if ( !m_root_asc.b_slider_value_outside_change )
            {
              m_idLog3_asc.warn( '<slider> onValueChanged 1 b_slider_value_outside_change ' +
                              m_root_asc.b_slider_value_outside_change );
              m_univreaderex_asc.setSliderValue709( value );
              m_idLog3_asc.warn( '<slider> onValueChanged 2 ' );
            }
            m_root_asc.b_slider_value_outside_change = false;
        }
        Component.onCompleted: {
            var i9 = 0;
            createFill(0.0, 0.05,
                       "#b0b0b0",
                       0.7
                       );
            createFill(0.95, 1.0,
                       "#b0b0b0"
                       , 0.7
                       );
        }
        function createFill(x0, x1, color, opacity ){
            m_idLog3_asc.warn( '<slider> createFill {');
            m_idLog3_asc.warn( '<slider> createFill x0 = '+x0+" x1 = "+x1+" color = "+color+" opacity = "+opacity);
            var component = Qt.createComponent("FillRect.qml");
            var object = component.createObject(slider_control.background);
            object.anchors.left = Qt.binding(function(){
                return slider_control.background.left;
            });

            object.anchors.right = Qt.binding(function(){
                return slider_control.background.right
            });

            m_idLog3_asc.warn( '<slider> createFill slider_control.handle.radius = '+slider_control.handle.radius);
            m_idLog3_asc.warn( '<slider> createFill slider_control.background.width = '+slider_control.background.width);

            object.anchors.leftMargin = Qt.binding(function(){
                return (
                         x0 !== 0 ? (slider_control.handle.radius +
                           ( slider_control.background.width -
                             2 * slider_control.handle.radius )
                             * x0):0
                       );
                //e ch90627
            });

            object.anchors.rightMargin = Qt.binding(function(){
                //ch90627
                //old return slider_control.background.width * (1-x1)
                return (
                         x1 !== 1 ? (slider_control.handle.radius +
                           ( slider_control.background.width -
                             2 * slider_control.handle.radius ) *
                             ( 1 - x1 )) : 0
                       )
                //e ch90627
            });

            object.color = color
            object.opacity = opacity
            m_idLog3_asc.warn( '<slider> createFill }');
        }

        function createFill3( x0, color, opacity ){
            //m_idLog3_asc.warn( '<slider> createFill3 slider_control.width ' +
              //                  slider_control.width );
            createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH * 2,
              //ch90913 0
              1.0
                -
                ( rootRect_ArcSliderControl.
                  m_i_slider_height_koef - 1 ) * 2
              , color, opacity, 2 );
            if ( ( rootRect_ArcSliderControl.
              m_i_slider_height_koef - 1.0 ) * 2.0 > 0 )
            {
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 2, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 4, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 6, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 8, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 10, color, opacity, 2 );
            }
            else
            {
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 3, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 5, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 7, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 9, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 11, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 13, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 15, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 17, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 19, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 21, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 23, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 25, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 27, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 29, color, opacity, 2 );
            }
            createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH * 2,
              //ch90913 10
              30.0
                +
                ( rootRect_ArcSliderControl.
                  m_i_slider_height_koef - 1 ) * 2
              , color, opacity, 2 );
        }
        function createFill4( x0, color, opacity ){
            //m_idLog3_asc.warn( '<slider> createFill4 slider_control.width ' +
              //                  slider_control.width );
            createFill5_90920_2( x0 - c_I_BOUND_WIDTH * 2, x0 + c_I_BOUND_WIDTH,
                        //ch90913 0
                        1.0
                        -
                        ( rootRect_ArcSliderControl.
                          m_i_slider_height_koef - 1 ) * 2
                        , color, opacity, 2 );
            if ( ( rootRect_ArcSliderControl.
              m_i_slider_height_koef - 1.0 ) * 2.0 > 0 )
            {
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 2, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 4, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 6, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 8, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 10, color, opacity, 2 );
            }
            else
            {
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 3, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 5, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 7, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 9, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 11, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 13, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 15, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 17, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 19, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 21, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 23, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 25, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 27, color, opacity, 2 );
                createFill5_90920_2( x0 - c_I_BOUND_WIDTH, x0 + c_I_BOUND_WIDTH, 29, color, opacity, 2 );
            }

            createFill5_90920_2( x0 - c_I_BOUND_WIDTH * 2, x0 + c_I_BOUND_WIDTH,
                        //ch90913 10
                        30.0
                        +
                        ( rootRect_ArcSliderControl.
                          m_i_slider_height_koef - 1 ) * 2
                        , color, opacity, 2 );
        }
        function createFill2(x0, x1, y, color, opacity ){
            //m_idLog3_asc.warn( '<slider> createFill2 slider_control.width ' +
              //                  slider_control.width );
            m_idLog3_asc.warn("<slider> createFill2 x0= "+x0+" x1= "+x1+" y= "+y+" color= "+color+" opacity= "+opacity);
            createFill5_90920_2(x0, x1, y, color, opacity, 2 );
        }
        function createFill5_90920_2(x0, x1, y, color, opacity, z_av ){
            m_idLog3_asc.warn("createFill5_90920_2 {");
            var component = Qt.createComponent("FillRect2.qml");
            m_idLog3_asc.warn("createFill5_90920_2 component = "+component)
            var object = component.createObject(
                        rootRect_ArcSliderControl
                        );
            m_idLog3_asc.warn("createFill5_90920_2 object = "+object);
            object.anchors.left = Qt.binding(function(){
                return slider_control.left;
            });
            object.z = z_av
            object.anchors.right = Qt.binding(function(){
                return slider_control.right
            });
            m_idLog3_asc.warn("createFill5_90920_2 z_av = "+z_av);
            m_idLog3_asc.warn("createFill5_90920_2 slider_control.handle.radius = "+slider_control.handle.radius);
            m_idLog3_asc.warn("createFill5_90920_2 slider_control.width = "+slider_control.width);
            object.anchors.leftMargin = Qt.binding(function(){

                //m_idLog3_asc.warn( '<slider> createFill5_90920_1 slider_control.width ' +
                  //                  slider_control.width );


                return (
                         slider_control.handle.radius +
                           ( slider_control.width -
                             2 * slider_control.handle.radius )
                             * x0
                       );
            });
            m_idLog3_asc.warn("createFill5_90920_2 object.anchors.leftMargin = "+object.anchors.leftMargin);
            object.anchors.rightMargin = Qt.binding(function(){
                return (
                         slider_control.handle.radius +
                           ( slider_control.width -
                             2 * slider_control.handle.radius ) *
                             ( 1 - x1 )
                       )
            });
            m_idLog3_asc.warn("createFill5_90920_2 object.anchors.rightMargin = "+object.anchors.rightMargin);
            /*
            m_idLog3_asc.warn( '<slider> old left offset ' +
                              ( ( slider_control.width )* x0 ) +
                              ' new left offset ' +
                              (
                                  slider_control.handle.radius +
                                        ( slider_control.width -
                                          2 * slider_control.handle.radius )
                                          * x0
                              )
                              +
                              'old right offset ' +
                                      ( ( slider_control.width )* x0 ) +
                                      ' new left offset ' +
                                      (
                                          slider_control.handle.radius +
                                                    ( slider_control.width -
                                                      2 * slider_control.handle.radius )
                                                      * ( 1 - x1 )
                                      )
            );
            */
            object.anchors.top = Qt.binding(function(){
                return slider_control
                //.background
                .top
            });
            object.anchors.topMargin = y;

            object.color = color
            object.opacity = opacity
            m_idLog3_asc.warn("createFill5_90920_2 }");
        }
        function drawSelectedInterval()
        {
            var f_left_bound_lv =  0.0;
            var f_right_bound_lv = 0.0;
            var i_is_out_of_bounds_left_lv = 0;
            var i_is_out_of_bounds_right_lv = 0;
            //ch00708 e
            m_idLog3_asc.warn(
                                '<' + m_root_asc.key2 + '_' + m_root_asc.key3 + '>' +
                                ' drawSelectedInterval slider_control.width ' +
                                slider_control.width +
                                ' m_uu_i_ms_begin_interval ' +
                                m_root_asc.m_uu_i_ms_begin_interval +
                                ' m_uu_i_ms_end_interval ' +
                                m_root_asc.m_uu_i_ms_end_interval
                              );
            m_upload_left_bound_lb_asc.text =
                    '[' +
                     m_univreaderex_asc.uu64ToHumanEv(
                        m_root_asc.m_uu_i_ms_begin_interval, 2
                        ) +
                    ', ' + m_univreaderex_asc.uu64ToHumanEv
                    ( m_root_asc.m_uu_i_ms_end_interval, 2  ) + ']';

            i_is_out_of_bounds_left_lv = m_univreaderex_asc.
              isOutOfBounds( m_root_asc.m_uu_i_ms_begin_interval )
            i_is_out_of_bounds_right_lv = m_univreaderex_asc.
              isOutOfBounds( m_root_asc.m_uu_i_ms_end_interval )
            f_left_bound_lv = m_univreaderex_asc.getReducedValue
              ( m_root_asc.m_uu_i_ms_begin_interval );
            f_right_bound_lv = m_univreaderex_asc.getReducedValue
              ( m_root_asc.m_uu_i_ms_end_interval );
            clearFill2();
            if (
                    /*
                    0.0 !== f_left_bound_lv
                    &&
                    1.0 !== f_left_bound_lv
                    ||
                    0.0 !== f_right_bound_lv
                    &&
                    1.0 !== f_right_bound_lv
                    */
                    //ch90703 vart f_left_bound_lv != f_right_bound_lv
                    (
                        0 === i_is_out_of_bounds_left_lv
                        ||
                        0 === i_is_out_of_bounds_right_lv
                        ||
                        ( 0 !== m_univreaderex_asc.isOverBounds(
                             m_root_asc.m_uu_i_ms_begin_interval,
                             m_root_asc.m_uu_i_ms_end_interval
                            ) )
                    )
                    &&
                    root.m_i_select_interv_state !== c_I_IS_FIERST_SELECT_INTERV
                )
            {
                m_idLog3_asc.warn("******************zdfbnzdfbnzdfnztfgtnxtfgnf");
                createFill2(f_left_bound_lv, f_right_bound_lv,3.0-(rootRect_ArcSliderControl.m_i_slider_height_koef-1)*2,'magenta',1.0);

                createFill2(f_left_bound_lv, f_right_bound_lv, 28.0+(rootRect_ArcSliderControl.m_i_slider_height_koef-1)*2,'magenta',1.0);

                m_idLog3_asc.warn("******************obvodka");
                if ( 0 === i_is_out_of_bounds_left_lv )
                  createFill3( f_left_bound_lv, 'mediumblue', 1.0 );
                if ( 0 === i_is_out_of_bounds_right_lv )
                  createFill4( f_right_bound_lv, 'mediumblue', 1.0 );
            }
        }

        function clearFill(){
            for(var i = 0; i < slider_control.background.children.length; ++i){
                slider_control.background.children[i].destroy()
            }
        }
        function clearFill2(){
            var s_objectName_lv = '';
            for(var i = 0; i < rootRect_ArcSliderControl.children.length; ++i){
                s_objectName_lv = rootRect_ArcSliderControl.children[i].objectName;
                m_idLog3_asc.warn(
                                  '<' + m_root_asc.key2 + '_' + m_root_asc.key3 + '>' +
                                  ' clearFill2 objectName ' +
                                  rootRect_ArcSliderControl.children[i].objectName +
                                  ' s_objectName_lv ' + s_objectName_lv
                                  );
                if ( rootRect_ArcSliderControl.children[i].objectName === 'fillRect2_90622' )
                {
                  m_idLog3_asc.warn( '<slider> destroy ' );
                  rootRect_ArcSliderControl.children[i].destroy()
                }
            }
        }


        /*ch90704
        function createTestPreviewFrame(){
            m_idLog2_asc.warn( 'createTestPreviewFrame begin' );
            var qml = '/qtplugins/iv/archivecomponents/cam_preview/qcam_preview3.qml';
            ivCreator812.asyncCreate('', 'file:///' + applicationDirPath + qml,
                                     rightSectionRec_Low);
        }
        */
    }
    //ch90906

    Rectangle{
        id: scale_time_left_lb_rec
        anchors.left: parent.left
        height: parent.height
        color: "transparent"
        //color: "blueviolet"
        width: 100
        z:122
        Label {
            id: scale_time_left_lb
            text: m_univreaderex_asc.scale_time_left
            font.pixelSize: 12
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color:'white'
        }
        Label {
            id: scale_date_left_lb
            text: m_univreaderex_asc.scale_date_left
            font.pixelSize: 12
            anchors.left: scale_time_left_lb.right
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            color:"white"
        }
    }
    Rectangle{
        id: scale_devision_point_0_rect
        anchors.left: parent.left
        anchors.leftMargin:
          slider_control.x + m_r_sd_offset * slider_control.width;
        anchors.top: parent.top

        height: 10
        width: 1
        color: "#f6f6f6"

        visible: false
        property real m_r_sd_offset: 0.0
    }
    Label {
        id: scale_devision_time_0_lb
        text: 'd1'
        font.pixelSize: 14
        anchors.top: scale_devision_point_0_rect.bottom
        anchors.left: parent.left
        anchors.leftMargin:
        //ch90920 25
        slider_control.x + m_r_sd_offset * slider_control.width -
            m_r_sd_contentWidth / 2.0;
        color:'white'
        property bool visible2: false
        property bool visible3: true
        visible: visible2 && visible3
        property real m_r_sd_offset: 0.0
        property real m_r_sd_contentWidth: 0.0
    }
    Rectangle{
        id: scale_devision_point_1_rect
        anchors.left: parent.left
        anchors.leftMargin:
          slider_control.x + m_r_sd_offset * slider_control.width;
        anchors.top: parent.top
        //anchors.topMargin: 31
         height: 10
        z:122
        width: 1
        color: "#f6f6f6"
        visible: false
        property real m_r_sd_offset: 0.0

        onVisibleChanged: {
            m_idLog3_asc.warn( '<slider> onVisibleChanged x = '+scale_devision_point_1_rect.x+' y = '+scale_devision_point_1_rect.y);
            m_idLog3_asc.warn( '<slider> onVisibleChanged scale_devision_point_1_rect visible = '+scale_devision_point_1_rect.visible );
        }
    }
    Label {
        id: scale_devision_time_1_lb
        text: 'd1'
        font.pixelSize: 14
        anchors.top: scale_devision_point_1_rect.bottom
        anchors.left: parent.left
        anchors.leftMargin:
            //ch90920 25
            //ch90920 slider_control.width / 3
            slider_control.x + m_r_sd_offset * slider_control.width -
                m_r_sd_contentWidth / 2.0;
        color:'white'
        property bool visible2: false
        property bool visible3: true
        visible: visible2 && visible3
        property real m_r_sd_offset: 0.0
        property real m_r_sd_contentWidth: 0.0
        z:122
    }
    Rectangle{
        id: scale_devision_point_2_rect
        anchors.left: parent.left
        anchors.leftMargin:
          slider_control.x + m_r_sd_offset * slider_control.width;
        anchors.top: parent.top
        height: 10
        width: 1
        color: "#f6f6f6"
        visible: false
        property real m_r_sd_offset: 0.0
        z:122

        onVisibleChanged: {
            m_idLog3_asc.warn( '<slider> onVisibleChanged x = '+scale_devision_point_2_rect.x+' y = '+scale_devision_point_2_rect.y);
            m_idLog3_asc.warn( '<slider> onVisibleChanged scale_devision_point_2_rect visible = '+scale_devision_point_2_rect.visible );
        }
    }
    Label {
        id: scale_devision_time_2_lb
        text: 'd1'
        font.pixelSize: 14
        z:122
        anchors.top: scale_devision_point_2_rect.bottom
        anchors.left: parent.left
        anchors.leftMargin:
        //ch90920 25
          slider_control.x + m_r_sd_offset * slider_control.width -
            m_r_sd_contentWidth / 2.0;
        color:'white'
        property bool visible2: false
        property bool visible3: true
        visible: visible2 && visible3
        property real m_r_sd_offset: 0.0
        property real m_r_sd_contentWidth: 0.0
    }
    Rectangle{
        id: scale_devision_point_3_rect
        anchors.left: parent.left
        anchors.leftMargin:
          slider_control.x + m_r_sd_offset * slider_control.width;
        anchors.top: parent.top
        height: 10
        width: 1
        color: "#f6f6f6"
        visible: false
        property real m_r_sd_offset: 0.0
        z:122

        onVisibleChanged: {
            m_idLog3_asc.warn( '<slider> onVisibleChanged x = '+scale_devision_point_3_rect.x+' y = '+scale_devision_point_3_rect.y);
            m_idLog3_asc.warn( '<slider> onVisibleChanged scale_devision_point_3_rect visible = '+scale_devision_point_3_rect.visible );
        }
    }
    Label {
        id: scale_devision_time_3_lb
        text: 'd1'
        font.pixelSize: 14
        anchors.top: scale_devision_point_3_rect.bottom
        anchors.left: parent.left
        anchors.leftMargin:
        //ch90920 25
          slider_control.x + m_r_sd_offset * slider_control.width -
            m_r_sd_contentWidth / 2.0;
        color:'white'
        property bool visible2: false
        property bool visible3: true
        visible: visible2 && visible3
        property real m_r_sd_offset: 0.0
        property real m_r_sd_contentWidth: 0.0
        z:122
    }
    Rectangle{
        id: scale_devision_point_4_rect
        anchors.left: parent.left
        anchors.leftMargin:
          slider_control.x + m_r_sd_offset * slider_control.width;
        anchors.top: parent.top
        height: 10
        width: 1
        color: "#f6f6f6"
        visible: false
        property real m_r_sd_offset: 0.0
        z:122

        onVisibleChanged: {
            m_idLog3_asc.warn( '<slider> onVisibleChanged x = '+scale_devision_point_4_rect.x+' y = '+scale_devision_point_4_rect.y);
            m_idLog3_asc.warn( '<slider> onVisibleChanged scale_devision_point_4_rect visible = '+scale_devision_point_4_rect.visible );
        }
    }
    Label {
        id: scale_devision_time_4_lb
        text: 'd1'
        font.pixelSize: 14
        anchors.top: scale_devision_point_4_rect.bottom
        anchors.left: parent.left
        anchors.leftMargin:
          //ch90920 25
          slider_control.x + m_r_sd_offset * slider_control.width -
            m_r_sd_contentWidth / 2.0;
        color:'white'
        property bool visible2: false
        property bool visible3: true
        visible: visible2 && visible3
        property real m_r_sd_offset: 0.0
        property real m_r_sd_contentWidth: 0.0
        z:122
    }
    Rectangle{
        id: scale_devision_point_5_rect
        anchors.left: parent.left
        anchors.leftMargin:
          slider_control.x + m_r_sd_offset * slider_control.width;
        anchors.top: parent.top
        height: 10
        width: 1
        color: "#f6f6f6"
        visible: false
        property real m_r_sd_offset: 0.0
        z:122

        onVisibleChanged: {
            m_idLog3_asc.warn( '<slider> onVisibleChanged x = '+scale_devision_point_5_rect.x+' y = '+scale_devision_point_5_rect.y);
            m_idLog3_asc.warn( '<slider> onVisibleChanged scale_devision_point_5_rect visible = '+scale_devision_point_5_rect.visible );
        }
    }
    Label {
        id: scale_devision_time_5_lb
        text: 'd1'
        font.pixelSize: 14
        anchors.top: scale_devision_point_5_rect.bottom
        anchors.left: parent.left
        anchors.leftMargin:
        //ch90920 25
        slider_control.x + m_r_sd_offset * slider_control.width -
          m_r_sd_contentWidth / 2.0;
        color:'white'
        property bool visible2: false
        property bool visible3: true
        visible: visible2 && visible3
        property real m_r_sd_offset: 0.0
        property real m_r_sd_contentWidth: 0.0
        z:122
    }
    Rectangle{
        id: scale_devision_point_6_rect
        anchors.left: parent.left
        anchors.leftMargin:
          slider_control.x + m_r_sd_offset * slider_control.width;
        anchors.top: parent.top
        height: 10
        width: 1
        color: "#f6f6f6"
        visible: false
        property real m_r_sd_offset: 0.0
        z:122

        onVisibleChanged: {
            m_idLog3_asc.warn( '<slider> onVisibleChanged x = '+scale_devision_point_6_rect.x+' y = '+scale_devision_point_6_rect.y);
            m_idLog3_asc.warn( '<slider> onVisibleChanged scale_devision_point_6_rect visible = '+scale_devision_point_6_rect.visible );
        }
    }
    Label {
        id: scale_devision_time_6_lb
        text: 'd1'
        font.pixelSize: 14
        anchors.top: scale_devision_point_6_rect.bottom
        anchors.left: parent.left
        anchors.leftMargin:
        //ch90920 25
        slider_control.x + m_r_sd_offset * slider_control.width -
          m_r_sd_contentWidth / 2.0;
        color:'white'
        property bool visible2: false
        property bool visible3: true
        visible: visible2 && visible3
        property real m_r_sd_offset: 0.0
        property real m_r_sd_contentWidth: 0.0
        z:122
    }
    Rectangle{
        id: scale_devision_point_7_rect
        anchors.left: parent.left
        anchors.leftMargin:
          slider_control.x + m_r_sd_offset * slider_control.width;
        anchors.top: parent.top
        height: 10
        width: 1
        color: "#f6f6f6"
        visible: false
        property real m_r_sd_offset: 0.0
        z:122

        onVisibleChanged: {
            m_idLog3_asc.warn( '<slider> onVisibleChanged x = '+scale_devision_point_7_rect.x+' y = '+scale_devision_point_7_rect.y);
            m_idLog3_asc.warn( '<slider> onVisibleChanged scale_devision_point_7_rect visible = '+scale_devision_point_7_rect.visible );
        }
    }
    Label {
        id: scale_devision_time_7_lb
        text: 'd1'
        font.pixelSize: 14
        anchors.top: scale_devision_point_7_rect.bottom
        anchors.left: parent.left
        anchors.leftMargin:
        //ch90920 25
        slider_control.x + m_r_sd_offset * slider_control.width -
          m_r_sd_contentWidth / 2.0;
        color:'white'
        property bool visible2: false
        property bool visible3: true
        visible: visible2 && visible3
        property real m_r_sd_offset: 0.0
        property real m_r_sd_contentWidth: 0.0
        z:122
    }
    Rectangle{
        id: scale_devision_point_8_rect
        anchors.left: parent.left
        anchors.leftMargin:
          slider_control.x + m_r_sd_offset * slider_control.width;
        anchors.top: parent.top
        height: 10
        width: 1
        color: "#f6f6f6"
        visible: false
        property real m_r_sd_offset: 0.0
        z:122

        onVisibleChanged: {
            m_idLog3_asc.warn( '<slider> onVisibleChanged x = '+scale_devision_point_8_rect.x+' y = '+scale_devision_point_8_rect.y);
            m_idLog3_asc.warn( '<slider> onVisibleChanged scale_devision_point_8_rect visible = '+scale_devision_point_8_rect.visible );
        }
    }
    Label {
        id: scale_devision_time_8_lb
        text: 'd1'
        font.pixelSize: 14
        anchors.top: scale_devision_point_8_rect.bottom
        anchors.left: parent.left
        anchors.leftMargin:
        //ch90920 25
        slider_control.x + m_r_sd_offset * slider_control.width -
          m_r_sd_contentWidth / 2.0;
        color:'white'
        property bool visible2: false
        property bool visible3: true
        visible: visible2 && visible3
        property real m_r_sd_offset: 0.0
        property real m_r_sd_contentWidth: 0.0
        z:122
    }
    Rectangle{
        id: scale_devision_point_9_rect
        anchors.left: parent.left
        anchors.leftMargin:
          slider_control.x + m_r_sd_offset * slider_control.width;
        anchors.top: parent.top
        height: 10
        width: 1
        color: "#f6f6f6"
        visible: false
        property real m_r_sd_offset: 0.0
        z:122

        onVisibleChanged: {
            m_idLog3_asc.warn( '<slider> onVisibleChanged x = '+scale_devision_point_9_rect.x+' y = '+scale_devision_point_9_rect.y);
            m_idLog3_asc.warn( '<slider> onVisibleChanged scale_devision_point_9_rect visible = '+scale_devision_point_9_rect.visible );
        }
    }
    Label {
        id: scale_devision_time_9_lb
        text: 'd1'
        font.pixelSize: 14
        anchors.top: scale_devision_point_9_rect.bottom
        anchors.left: parent.left
        anchors.leftMargin:
        //ch90920 25
        slider_control.x + m_r_sd_offset * slider_control.width -
          m_r_sd_contentWidth / 2.0;
        color:'white'
        property bool visible2: false
        property bool visible3: true
        visible: visible2 && visible3
        property real m_r_sd_offset: 0.0
        property real m_r_sd_contentWidth: 0.0
        z:122
    }
    Rectangle{
        id: scale_devision_point_10_rect
        anchors.left: parent.left
        anchors.leftMargin:
          slider_control.x + m_r_sd_offset * slider_control.width;
        anchors.top: parent.top
        height: 10
        width: 1
        color: "#f6f6f6"
        visible: false
        property real m_r_sd_offset: 0.0
        z:122

        onVisibleChanged: {
            m_idLog3_asc.warn( '<slider> onVisibleChanged x = '+scale_devision_point_10_rect.x+' y = '+scale_devision_point_10_rect.y);
            m_idLog3_asc.warn( '<slider> onVisibleChanged scale_devision_point_10_rect visible = '+scale_devision_point_10_rect.visible );
        }
    }
    Label {
        id: scale_devision_time_10_lb
        text: 'd1'
        font.pixelSize: 14
        anchors.top: scale_devision_point_10_rect.bottom
        anchors.left: parent.left
        anchors.leftMargin:
        //ch90920 25
        slider_control.x + m_r_sd_offset * slider_control.width -
          m_r_sd_contentWidth / 2.0;
        color:'white'
        property bool visible2: false
        property bool visible3: true
        visible: visible2 && visible3
        property real m_r_sd_offset: 0.0
        property real m_r_sd_contentWidth: 0.0
        z:122
    }
    Rectangle{
        id: scale_devision_point_11_rect
        anchors.left: parent.left
        anchors.leftMargin:
          slider_control.x + m_r_sd_offset * slider_control.width;
        anchors.top: parent.top
        height: 10
        width: 1
        color: "#f6f6f6"
        visible: false
        property real m_r_sd_offset: 0.0
        z:122

        onVisibleChanged: {
            m_idLog3_asc.warn( '<slider> onVisibleChanged x = '+scale_devision_point_11_rect.x+' y = '+scale_devision_point_11_rect.y);
            m_idLog3_asc.warn( '<slider> onVisibleChanged scale_devision_point_11_rect visible = '+scale_devision_point_11_rect.visible );
        }
    }
    Label {
        id: scale_devision_time_11_lb
        text: 'd1'
        font.pixelSize: 14
        anchors.top: scale_devision_point_11_rect.bottom
        anchors.left: parent.left
        anchors.leftMargin:
        //ch90920 25
        slider_control.x + m_r_sd_offset * slider_control.width -
          m_r_sd_contentWidth / 2.0;
        color:'white'
        property bool visible2: false
        property bool visible3: true
        visible: visible2 && visible3
        property real m_r_sd_offset: 0.0
        property real m_r_sd_contentWidth: 0.0
        z:122
    }

    Rectangle{
        id: scale_time_right_lb_rec
        anchors.right: parent.right
        height: parent.height
        color: "transparent"
        //color: "blueviolet"
        width: 100
        z:122
        Label {
            id: scale_time_right_lb
            text: m_univreaderex_asc.scale_time_right
            font.pixelSize: 12
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color:'white'
        }
        Label {
            id: scale_date_right_lb
            text: m_univreaderex_asc.scale_date_right
            font.pixelSize: 12
            anchors.left: scale_time_right_lb.right
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            color:"white"
        }
    }
    //e ch90906
    MouseArea {
        id: slider_control_rct_mouse
        z: 120
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: mouse.accepted = false;
        //onPressed: mouse.accepted = false;
        //onReleased: mouse.accepted = false;
        onDoubleClicked: mouse.accepted = false;
        onPressAndHold: mouse.accepted = false;
        acceptedButtons: Qt.RightButton
        property var shift: 0
        property var to_left: false
        property var to_right: false
        onPressed: {
            shift = slider_control_rct_mouse.mouseX
        }
        onMouseXChanged: {
            if (pressed){
                if (shift > slider_control_rct_mouse.mouseX)
                {
                    //console.info("onMouseXChanged right");
                    to_left = false;
                    to_right = true;
                }
                else
                {
                    //console.info("onMouseXChanged left");
                    to_left = true;
                    to_right = false;
                }
            }
        }
        onReleased: {
            if (to_right)
            {
                m_univreaderex_asc.setDelta709( 1 );
            }

            if (to_left)
            {
                m_univreaderex_asc.setDelta709( -1 );
            }
            to_left = false;
            to_right = false;
        }
        onExited: {
            var i_counter006_lv = 0;
            m_idLog3_asc.warn('<preview> onExited beg m_i_slider_height_koef ' + rootRect_ArcSliderControl.m_i_slider_height_koef );

            var i_i_slider_height_koef_lv = 0.0;
            event_select_rct.visible = false;
            m_event_select_rct_hint_asc.visible = false;
                    //ch91017 deb sht true;

            m_imageSlider_asc.imageVisible_2 = false;

            //ср90911
            i_i_slider_height_koef_lv = 1.0;
            if ( i_i_slider_height_koef_lv !== rootRect_ArcSliderControl.m_i_slider_height_koef )
            {
                rootRect_ArcSliderControl.m_i_slider_height_koef = i_i_slider_height_koef_lv;
                /*ch00622
                i_counter006_lv = m_univreaderex_asc.getCounter006();
                m_univreaderex_asc.onEventsIntervalesNeedRefreshChangedReal(
                    i_counter006_lv, 1
                    );
                */
            };
            //e


            m_idLog3_asc.warn('<preview> onExited end m_i_slider_height_koef ' +
                rootRect_ArcSliderControl.
                  m_i_slider_height_koef );


        }
        onEntered: {

            if (m_popup_scale_intervals !== null || m_popup_scale_intervals !== undefined)
            {
                if (m_popup_scale_intervals.opened === true)
                {
                    m_popup_scale_intervals.close();
                }
            }

            rootRect_ArcSliderControl.slidermouseEntered();
        }

        function
          hintStateChange()
        {
            m_idLog3_asc.warn( 'hintStateChange beg' );
            var i_is_last_pozitioning_event_bmark_lv = 0;
            var qs_event_text_lv = '';
            var qr_slider_coord_lv = 0.0;
            var b_is_event_finded_lv = false;
            var i_is_event_finded_2_lv = 0;
            qr_slider_coord_lv =
              ( mouseX -
                  sliderBackGroundX()
                  ) /
                sliderBackGroundWidth()
                ;
            //ch91014 похоже, это уже не актуально
            //qs_time = dvp
            //e
            qs_event_text_lv = m_univreaderex_asc.
                getEventBySlider( qr_slider_coord_lv )
            m_idLog3_asc.warn(
                        "<preview> hintStateChange mouseX " + mouseX +
                        " sliderBackGroundX " + sliderBackGroundX() +
                        " sliderBackGroundWidth " + sliderBackGroundWidth() +
                        " qr_slider_coord_lv " + qr_slider_coord_lv +
                        " qs_event_text_lv " + qs_event_text_lv
                        );
            b_is_event_finded_lv =
                ( '' !== qs_event_text_lv );
            i_is_event_finded_2_lv = m_univreaderex_asc.isEventFinded();
            i_is_last_pozitioning_event_bmark_lv = m_univreaderex_asc.
              isLastPositioningEventBMark();
            if ( 0 === i_is_last_pozitioning_event_bmark_lv )
              event_select_rct.color = 'red';
            else
                event_select_rct.color = 'cyan';

            m_event_select_rct_hint_text_asc.text = qs_event_text_lv;
            m_event_select_rct_hint_asc.width =
                m_event_select_rct_hint_text_asc.contentWidth;
            m_event_select_rct_hint_asc.height =
                m_event_select_rct_hint_text_asc.contentHeight;
            event_select_rct.visible = ( 0 !== i_is_event_finded_2_lv );
            m_event_select_rct_hint_asc.visible =
                    b_is_event_finded_lv;
                    //ch91017 deb sht true;
        }
        function sliderMouseMoveActions()
        {
          m_idLog3_asc.warn('<preview> sliderMouseMoveActions beg ');
          var i_ms_lv = m_univreaderex_asc.getFrameTimeUUI64();
          m_idLog3_asc.warn( 'sliderMouseMoveActions i_ms_lv ' + i_ms_lv );
          var i_curr_time_lv = m_univreaderex_asc.getCurrTime();
          if ( rootRect_ArcSliderControl.m_i64_marker_mouse_move_actions_delta_timeout +
                  rootRect_ArcSliderControl.c_I64_HINT_STATE_DELTA_TIMEOUT <
                  i_curr_time_lv
                  //ch00319
                  &&
                  0 !== i_ms_lv
                  //e
                  )
          {
            m_b_is_ness_mouse_move_actions = false;
            rootRect_ArcSliderControl.m_i64_marker_mouse_move_actions_delta_timeout =
              i_curr_time_lv
              //ch91016 + rootRect_ArcSliderControl.c_I64_HINT_STATE_DELTA_TIMEOUT
              ;
            sliderMouseMoveActions_Level1();
          }
          else
            m_b_is_ness_mouse_move_actions = true;
        }
        function sliderMouseMoveActions_Level1()
        {
            /*ch91018 vart
            var b_is_ness_active_lv = false;
            b_is_ness_active_lv =
              ( mouseY <= slider_control.background.y +
                          slider_control.background.height &&
                slider_control.background.y <= mouseY &&
                mouseX <=
                 sliderBackGroundX() + sliderBackGroundWidth()
                 &&
                 sliderBackGroundX()
                   <= mouseX );
            rootRect_ArcSliderControl.m_idLog3_asc.warn(
               '<preview> sliderMouseMoveActions_Level1 b_is_ness_active_lv ' +
                        b_is_ness_active_lv +
                        ' mouseY ' +
                        mouseY +
                        ' slider_control.background.y ' +
                        slider_control.background.y +
                        ' slider_control.background.height ' +
                        slider_control.background.height +
                        ' mouseX ' +
                        mouseX +
                        ' sliderBackGroundX() ' +
                        sliderBackGroundX() +
                        ' sliderBackGroundWidth() ' +
                        sliderBackGroundWidth()
                        );
            if ( b_is_ness_active_lv )
            {
            ch91018 vart*/
                hintStateChange();
                if (m_root_asc.is_export_media != true)
                {
                    showPreview();
                }
            /*ch91018 vart
            }
            else
            {
                m_imageSlider_asc.imageVisible_2 = false;
                event_select_rct.visible = false;
                m_event_select_rct_hint_asc.visible =
                        false;
            }
            ch91018 vart*/
        }
        function showPreview()
        {

            m_idLog3_asc.warn('<preview> showPreview ');

            //ch91002 temp deb
            //return;
            //e


            //ch91215 var pt_mapped_pos_lv = null;

            //ch91015 var qs_provider_param_lv = '';
            var qr_slider_coord_lv = 0.0;
            qr_slider_coord_lv = ( mouseX - sliderBackGroundX()) / sliderBackGroundWidth();
            //запомним исходные данные для получения и размещения картинки е
            var pt_mapped_pos_lv = null;
            //ch mouseY
            pt_mapped_pos_lv = mapToItem( m_root_asc, mouseX,6);
            idarchive_player.stop_thread();
            //var time = m_univreaderex_asc.getFrameTimeUUI64();
            var beg = m_univreaderex_asc.uuIMSBeginInterval();
            var end = m_univreaderex_asc.uuIMSEndInterval();
            var delta_time = end - beg;
            var seconds_in_pixels = delta_time / sliderBackGroundWidth();
            var time = beg + (mouseX * seconds_in_pixels);

            console.info("showPreview delta_time=",delta_time);
            console.info("showPreview sliderBackGroundWidth()=",sliderBackGroundWidth());
            console.info("showPreview time=",time);
            console.info("showPreview qr_slider_coord_lv=",qr_slider_coord_lv);
            if (!m_root_asc.is_multiscreen && m_root_asc.key2 != "common_panel") {
                if (m_root_asc.display_camera_previews === true)
                {
                    idarchive_player.start_thread2(m_root_asc.key2, time, pt_mapped_pos_lv.x, pt_mapped_pos_lv.y);
                }
            }
            //m_univreaderex_asc.memPreviewParams( pt_mapped_pos_lv.x, pt_mapped_pos_lv.y, qr_slider_coord_lv );
        }
        onPositionChanged: {
            m_idLog3_asc.warn('onPositionChanged 1 ' )
            event_select_rct.x = mouseX - 5;
            var pt_mapped_pos_2_lv = null;
            pt_mapped_pos_2_lv = mapToItem
                    ( m_root_asc, mouseX - 52, 0 );
            m_event_select_rct_hint_asc.x = pt_mapped_pos_2_lv.x;
            m_event_select_rct_hint_asc.y = m_root_asc.height - (rootRect_ArcSliderControl.height+m_event_select_rct_hint_asc.height);//pt_mapped_pos_2_lv.y-10 - m_imageSlider_asc.height - m_event_select_rct_hint_asc.height + 2;
            //ch00121
            if ( true === m_root_asc.common_panel )
                m_event_select_rct_hint_asc.y = m_event_select_rct_hint_asc.height*(-1);//+= (50*m_root_asc.isize);
            //e
            m_idLog3_asc.warn('<events>' +
                              ' m_event_select_rct_hint_asc.x ' +
                              m_event_select_rct_hint_asc.x +
                              ' m_event_select_rct_hint_asc.y ' +
                              m_event_select_rct_hint_asc.y
                             );

            var b_is_ness_cont_work_lv = true;
            //ch90924 var b_is_ness_cont_work2_lv = true;
            var qs_event_text_lv = '';
            var qr_slider_coord_lv = 0.0;

            var i_is_last_pozitioning_event_bmark_lv = 0;

            var i_i_slider_height_koef_lv = 0.0;

            var b_is_small_mode_lv = false;
            /*ch91014
            //если коорд слайдера поменялась е
            if ( b_is_ness_cont_work_lv )
            {
              m_idLog3_asc.warn('onPositionChanged ' +
                             //ch91012 'm_i_timer_counter ' +
                             //ch91012 m_univreaderex_asc.m_i_timer_counter +
                             'mouseX ' +
                             mouseX +
                             'm_qr_prev_tick_coord_x ' +
                             m_univreaderex_asc.m_qr_prev_tick_coord_x
                             );
              b_is_ness_cont_work_lv =
              (
                  m_univreaderex_asc.m_qr_prev_tick_coord_x !== mouseX
                  ||
                  m_univreaderex_asc.m_qr_prev_tick_coord_y !== mouseY
              );
            }
            ch91014*/
            //ch91021
            if ( b_is_ness_cont_work_lv )
            {
              b_is_small_mode_lv = m_root_asc.isSmallMode();
              m_univreaderex_asc.smallModeToCPP(
                  b_is_small_mode_lv ? 1 : 0 );
              b_is_ness_cont_work_lv = !b_is_small_mode_lv;
            }
            //e
            //ch90924 b_is_ness_cont_work2_lv = b_is_ness_cont_work_lv;
            if ( b_is_ness_cont_work_lv )
            {
                m_idLog3_asc.warn('onPositionChanged ' +
                               'mouseY ' +
                               mouseY +
                               'background.x ' +
                               slider_control.background.x +
                               'background.y ' +
                               slider_control.background.y +
                               'background.width ' +
                               slider_control.background.width +
                               'background.height ' +
                               slider_control.background.height
                               );
                //ch91014 m_univreaderex_asc.m_qr_prev_tick_coord_x = mouseX;
                //ch91014 m_univreaderex_asc.m_qr_prev_tick_coord_y = mouseY;
                b_is_ness_cont_work_lv =
                        rootRect_ArcSliderControl.isInSliderZone(
                            //ch91017 mouseX,
                            //ch91017 mouseY
                            );
            }
            changeHeidthIfNess( mouseX, mouseY );

            /*ch91012 вместо этого вызов в таймере е
            if ( b_is_ness_cont_work_lv )
            {
              b_is_ness_cont_work_lv =
                ( m_univreaderex_asc.m_i_timer_counter !==
                  m_univreaderex_asc.m_i_timer_counter_prev );
            }
            */
            if ( b_is_ness_cont_work_lv )
            {
              /*ch91012 вместо этого вызов в таймере е
              m_univreaderex_asc.m_i_timer_counter_prev =
                m_univreaderex_asc.m_i_timer_counter;
              */




              //найдем коорд на слайдере как доля 1 e
              qr_slider_coord_lv =
                ( mouseX -
                    //ch90627 slider_control.background.x
                    sliderBackGroundX()
                    ) /
                  //ch90627 slider_control.background.width
                  sliderBackGroundWidth()
                  ;
              m_idLog3_asc.warn('onPositionChanged ' +
                               'qr_slider_coord_lv ' +
                               qr_slider_coord_lv +
                               'slider_control.background.x ' +
                               slider_control.background.x +
                               'slider_control.background.width ' +
                               slider_control.background.width
                               );
              slider_control_rct_mouse.sliderMouseMoveActions();
            }//nesscont
            //ch91018
            else
            {
                if ( m_imageSlider_asc.imageVisible_2 )
                {
                  m_imageSlider_asc.imageVisible_2 = false;
                }
                if ( event_select_rct.visible )
                  event_select_rct.visible = false;
                if ( m_event_select_rct_hint_asc.visible )
                    m_event_select_rct_hint_asc.visible = false;
            }
            //e
        }//funct
    }//mouse area
    Rectangle {
        id: event_select_rct
        //ch90627
        z: 2
        //e
        objectName: 'event_select_rct_90622'
        width: 8 * rootRect_ArcSliderControl.m_i_slider_height_koef
        height: 8 * rootRect_ArcSliderControl.m_i_slider_height_koef
        radius:
                4.0
                * rootRect_ArcSliderControl.m_i_slider_height_koef
        color: "red"
        visible: false
        anchors.verticalCenter: slider_control.verticalCenter
    }

    //ch90618 }
    //ch90617 }
}



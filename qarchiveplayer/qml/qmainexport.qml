import QtQuick 2.6
import QtQuick.Window 2.2
import QtQuick.Controls 2.1
import iv.plugins.loader 1.0
//ch81101 import iv.viewers.archiveplayer 1.0

ApplicationWindow {
    id: wnd
    property string ivUnique: 'WND' // идентификатор, передаваемый во вспомогательный компонент
    property string key2: '' // пример свойства компонента для наглядности
    property string from: ''
    property string to: ''
    property string evtid_me: ''
    property string filter_events_me: ''
    property int is_bookmark_me: 0
    property var parent_arc_obj: null
    property string unique: "export_avi_window"
    //ch221021
    property string selected_zna_ip: ''
    //e

    onClosing:
    {
        //ch10927
        idLog3.warn( "<210927> mainRect.comp " + mainRect.comp );
        //ch10929

        /*if ( 'm_i_210929' in wnd.ivComponent.parentComponent.qml )
        {
          idLog3.warn( "<210927> 156 " );
          wnd.ivComponent.parentComponent.qml.m_i_210929 = 17;
          idLog3.warn( "<210927> 157 " );
        }*/
        /*
        if ( 'm_i_210929_1' in wnd.ivComponent.parentComponent.qml )
        {
          idLog3.warn( "<210927> 160 " );
          wnd.ivComponent.parentComponent.qml.m_i_210929_1 = 1;
          idLog3.warn( "<210927> 161 " );
        }
        */


        //if ( 'm_i_210929_deb' in wnd.ivComponent.parentComponent.qml )
        //{
          //wnd.ivComponent.parentComponent.qml.m_i_210929_deb = 77797;
          if (parent_arc_obj !== null || parent_arc_obj !== undefined)
          {
              idLog3.warn( "<210927> 200 " );
              parent_arc_obj.set_m_i_210929_deb(77797);
              idLog3.warn( "<210927> 201 " );
          }
        //}

        //if ( 'm_v_conponent_main_export_ap' in wnd.ivComponent.parentComponent.qml )
        //{
          //idLog3.warn( "<210927> onClosing bef m_v_conponent_main_export_ap.remove " );
          //wnd.ivComponent.parentComponent.qml.ivButtonPane.m_v_conponent_main_export.remove();
          //wnd.ivComponent.parentComponent.qml.ivButtonPane.m_v_conponent_main_export = null;
          //idLog3.warn( "<210927> onClosing aft m_v_conponent_main_export_ap.remove " );
        //}
        //e
        if ( mainRect.comp !== null )
        {
          idLog3.warn( "<210927> mainRect.comp.close " );
          //mainRect.comp.close();
        }
        //e
        //mainRect.comp.ivComponent.remove();
        //mainRect.comp=null;
        export_mediaLoader.destroy();
    }

    // необходимо только для корневого окна(для ваших qml компонентов не нужно так делать, нужно
    // делать так:
    // property IVComponent2 ivComponent: null

    visible: true
    width:
        //ch90902 640
        990
    height:
        //ch90902 480
        600
    title: qsTr("Экспорт в AVI, MKV")
    //vart modality: Qt.WindowModal
    //ch00703 modality: Qt.ApplicationModal
    //ch00703
    flags:  Qt.Window
            | Qt.WindowSystemMenuHint
            | Qt.WindowTitleHint
            | Qt.WindowCloseButtonHint
            | Qt.WindowStaysOnTopHint
    //e


    Iv7Test {
        id: test_id_click_close_export_window
        guid: '43_click_archive_close_export_window'
        key2: wnd.key2
        onCommandReceived: {
            idLog3.warn( "<210927> 43_click_archive_close_export_window onCommandReceived" );
            idLog3.warn( value ); //value - json, указанный в ws запросе.
            wnd.close();
            test_id_click_close_export_window.result = "{\"result\":\"OK\"}";
        }
    }

    Iv7Log{
        id: idLog3
        name: 'arc.tracedecim'
    }
    //flags: Qt.Dialog
    Rectangle{
        id: mainRect
        property var comp : null
        //anchors.left: button.right
        /*
        anchors.leftMargin: 20
        color: "Blue"
        */
        width: parent.width// - button.width
        height: parent.height
        /* vart
        anchors.fill: parent

        MouseArea { // for blocking all underlayers
             anchors.fill: parent
        }
        */

        Component.onCompleted: {
            export_mediaLoader.create();
        }

        Loader {
            id: export_mediaLoader
            anchors.fill: mainRect

            property var componentExportMedia: null
            function create()
            {
                var qmlfile = "file:///"+applicationDirPath + '/qtplugins/iv/export/Settings.qml';
                export_mediaLoader.source = qmlfile;
            }
            function refresh()
            {
                export_mediaLoader.destroy();
                export_mediaLoader.create();
            }
            function destroy()
            {
                if(export_mediaLoader.status !== Loader.Null)
                    export_mediaLoader.source = "";
            }
            onStatusChanged:
            {
                if (export_mediaLoader.status === Loader.Ready)
                {
                    var s_event_id_lv = '';
                    export_mediaLoader.componentExportMedia = export_mediaLoader.item;
                    mainRect.comp = export_mediaLoader.componentExportMedia;

                    mainRect.safeSetProperty(export_mediaLoader.componentExportMedia, 'key2',
                                             Qt.binding(function(){return wnd.key2;}));

                    mainRect.safeSetProperty(export_mediaLoader.componentExportMedia, 'from',
                                             Qt.binding(function(){return wnd.from;}));

                    mainRect.safeSetProperty(export_mediaLoader.componentExportMedia, 'to',
                                             Qt.binding(function(){return wnd.to;}));

                    mainRect.safeSetProperty(export_mediaLoader.componentExportMedia, 'filter_events',
                                             Qt.binding(function(){return wnd.filter_events_me;}));

                    idLog3.warn( "<select_source> export_mediaLoader onStatusChanged selected_zna_ip " +
                                wnd.selected_zna_ip );

                    mainRect.safeSetProperty(export_mediaLoader.componentExportMedia, 'selected_zna_ip',
                                             Qt.binding(function(){return wnd.selected_zna_ip;}));

                    s_event_id_lv = wnd.evtid_me;
                    if ( '' !== s_event_id_lv )
                    {
                        if('evtid' in export_mediaLoader.componentExportMedia)
                            export_mediaLoader.componentExportMedia.evtid = s_event_id_lv; // просто присвоение свойства
                        if('is_bookmark' in export_mediaLoader.componentExportMedia)
                            export_mediaLoader.componentExportMedia.is_bookmark = wnd.is_bookmark_me;
                    };

                    idLog3.warn( '<unload> key2 ' +
                                 export_mediaLoader.componentExportMedia.key2 +
                                 ' from ' +
                                 export_mediaLoader.componentExportMedia.from +
                                 ' to ' +
                                 export_mediaLoader.componentExportMedia.to +
                                 ' filter_events ' +
                                 export_mediaLoader.filter_events +
                                 ' evtid ' +
                                 export_mediaLoader.componentExportMedia.evtid +
                                 ' is_bookmark ' +
                                 export_mediaLoader.componentExportMedia.is_bookmark +
                                 ' wnd.filter_events_me ' +
                                 wnd.filter_events_me +
                                 ' selected_zna_ip ' +
                                 wnd.selected_zna_ip
                                );

                }
                if(export_mediaLoader.status === Loader.Error)
                {
                }
                if(export_mediaLoader.status === Loader.Null)
                {
                }
            }
        }
        function safeSetProperty(component, prop, func) {
            if(prop in component) {
                component[prop] = func;
            }
        }
    }

}

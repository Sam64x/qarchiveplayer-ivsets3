import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.ptz.isptzcamera 1.0
import iv.sets.sets3 1.0
import QtQuick.Dialogs 1.1
Rectangle {
    //property bool isCurrentItem: ListView.listView.currentIndex === index
    property var globSignalsObject: null
    //height: 150
    color: "white"
    //border.color: "blue"
    //border.width: 1
   // width: parent.width
    property string key2: ""
    property string type: ""
    property string qmlPath: ""
    property var params: ""
    id:root
    Component.onCompleted:
    {
        camPreviewLoader.create1();
    }
    CheckPTZ
    {
        id:ptzCheck
        onAnswerReady: {
            //idLog.warn('<IVRealtimePlayer>'+"root.isCreationInterrupted = "+root.isParentCreationInterrupted+" root.isParentCreationInterrupted = "+root.isParentCreationInterrupted+' answer key2 ='+key2+" root.key2 ="+root.key2+' isPtz = ' +isPtz +" isZoom = "+ isZoom +" isBrush = "+ isBrush +" isLight = "+ isLight +" isQuery = "+ isQuery);
            if(root.isCreationInterrupted || root.isParentCreationInterrupted) {
               // idLog.warn('<IVRealtimePlayer> onAnswerReady return root.isCreationInterrupted || root.isParentCreationInterrupted');
              return;
            }
          if(root.key2 !== key2) {
             // idLog.warn('<IVRealtimePlayer> onAnswerReady return root.key2 !== key2');
            return;
          }
          //idLog.warn('<IVRealtimePlayer>CAMERA isPtz = ' +isPtz +" isZoom = "+ isZoom +" isBrush = "+ isBrush +" isLight = "+ isLight +" isQuery = "+ isQuery);
          root.isPTZ = isPtz | isZoom | isBrush | isLight | isQuery;
          //root.isPanTilt = isPtz;
         // root.isZoom = isZoom;
         // root.isBrush = isBrush;
         // root.isLight = isLight;
         // root.isQuery = isQuery;
         // if (!root.isZoom && !root.isPanTilt)
              //root.isControl = false;
         // else
              //root.isControl = true;

          if(!root.isPTZ) {
            return;
          }
         // ptzLoader.create();
          //ivCreator.createComponent();
        }
    }
    Loader
    {
        id:camPreviewLoader
        anchors.fill: parent
        anchors.bottomMargin: 20
        asynchronous: false
        property var componentCamPreview: null
        function create1()
        {
            var qmlFile2 = 'file:///' + applicationDirPath +  '/qtplugins/iv/archivecomponents/cam_preview/qcam_preview3.qml';
            camPreviewLoader.source = qmlFile2;
        }
        function refresh1()
        {
            camPreviewLoader.destroy1();
            camPreviewLoader.create1();
        }
        function destroy1()
        {
            if(camPreviewLoader.status !== Loader.Null)
                camPreviewLoader.source = "";
        }
        onStatusChanged:
        {
            if (camPreviewLoader.status === Loader.Ready)
            {
                camPreviewLoader.componentCamPreview = camPreviewLoader.item;
                camPreviewLoader.componentCamPreview.anchors.fill = camPreviewLoader;
                camPreviewLoader.componentCamPreview.key2 = root.key2;
            }
            if(camPreviewLoader.status === Loader.Error)
            {
            }
            if(camPreviewLoader.status === Loader.Null)
            {

            }
        }
    }
    Text
    {
        anchors.bottom: parent.bottom
        height: 20
        width: parent.width
        color: "black"
        text: root.key2
        horizontalAlignment: Qt.AlignHCenter
        onTextChanged:
        {
            ptzCheck.checkIsPtz(root.key2);
        }
    }
    MouseArea
    {
        id:mMouse
        anchors.fill: parent
        hoverEnabled: true
        //propagateComposedEvents: true
        onDoubleClicked:
        {
            var autoCamMode = root.globSignalsObject.getCamsAutoModeStatus();
            if(autoCamMode)
            {
                var _zoneObj = {};
                _zoneObj["x"] = 1;
                _zoneObj["y"] = 1;
                _zoneObj["dx"] = 8;
                _zoneObj["dy"] = 8;
                _zoneObj["type"] = root.type;
                _zoneObj["params"] = root.params;
                _zoneObj["qml_path"] = root.qmlPath;
               // var _zz_ = JSON.stringify(_zoneObj);
                root.globSignalsObject.addCamToSlot(_zoneObj);
            }
            else
            {
                var _zoneObj = {};
                _zoneObj["x"] = 1;
                _zoneObj["y"] = 1;
                _zoneObj["dx"] = 8;
                _zoneObj["dy"] = 8;
                _zoneObj["type"] = root.type;
                _zoneObj["params"] = root.params;
                _zoneObj["qml_path"] = root.qmlPath;
                root.globSignalsObject.addCamToPreview(_zoneObj);
            }

            mouse.accepted = true;
        }
    }
}

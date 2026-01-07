import QtQuick 2.11
import QtQml 2.3
import iv.ptz.isptzcamera 1.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.sets.sets3 1.0
import QtQuick.Dialogs 1.1
Rectangle {
   // property bool isCurrentItem: ListView.listView.currentIndex === index
    property var globSignalsObject: null
    //height: 30
    color: "#d9d9d9"
    border.color: "gray"
    border.width: 1
    //width: parent.width
    property bool isPTZ:false
    property string key2: ""
    property string type: ""
    property string qmlPath: ""
    property var params: ""
    id:root
    CheckPTZ
    {
        id:ptzCheck
        onAnswerReady: {
            //idLog.warn('<IVRealtimePlayer>'+"root.isCreationInterrupted = "+root.isParentCreationInterrupted+" root.isParentCreationInterrupted = "+root.isParentCreationInterrupted+' answer key2 ='+key2+" root.key2 ="+root.key2+' isPtz = ' +isPtz +" isZoom = "+ isZoom +" isBrush = "+ isBrush +" isLight = "+ isLight +" isQuery = "+ isQuery);
            if(root.isCreationInterrupted || root.isParentCreationInterrupted) {
                idLog.warn('<IVRealtimePlayer> onAnswerReady return root.isCreationInterrupted || root.isParentCreationInterrupted');
              return;
            }
          if(root.key2 !== key2) {
              //idLog.warn('<IVRealtimePlayer> onAnswerReady return root.key2 !== key2');
            return;
          }
          //idLog.warn('<IVRealtimePlayer>CAMERA isPtz = ' +isPtz +" isZoom = "+ isZoom +" isBrush = "+ isBrush +" isLight = "+ isLight +" isQuery = "+ isQuery);
          root.isPTZ = isPtz | isZoom | isBrush | isLight | isQuery;
          //root.isPanTilt = isPtz;
         // root.isZoom = isZoom;
         // root.isBrush = isBrush;
         // root.isLight = isLight;
         // root.isQuery = isQuery;
          //console.error("CAMERA is PTZ = ",root.isPTZ)
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
    Image {
        width: 16
        height: 16
        id: tpzImahe
        source: "file:///"+applicationDirPath + "/images/left_pan_butons/d_dome.svg"
        visible: isPTZ
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        ToolTip.text: "PTZ камера"
        ToolTip.delay: 500
        ToolTip.visible:  mar6.containsMouse
        MouseArea
        {
            anchors.fill: parent
            id:mar6
            hoverEnabled: true
        }
    }
    Image {
        width: 16
        height: 16
        id: mapindicator
        source: "file:///"+applicationDirPath + "/images/black/window.svg"
        visible: root.type === "MapViewer"
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        ToolTip.text: "План "+ root.key2
        ToolTip.delay: 500
        ToolTip.visible:  mar7.containsMouse
        MouseArea
        {
            anchors.fill: parent
            id:mar7
            hoverEnabled: true
        }
    }

    Text
    {
        anchors.centerIn: parent
        color: "black"
        text: root.key2==="client_settings"?"Настройки клиента":root.key2
        id:textKey2
        font.pixelSize: 16
        onTextChanged:
        {
            ptzCheck.checkIsPtz(root.key2);
        }
    }
    MouseArea
    {
        id:mMouse
        anchors.fill: parent
        hoverEnabled: false
        propagateComposedEvents: true
        onDoubleClicked:
        {
            var isEditor = root.globSignalsObject.getEditorStatus();
            if(isEditor)
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
                    //console.error("CAMS TO SLOT =====================================",JSON.stringify(_zoneObj))
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
                    //console.error("CAMS TO PREVIEW =====================================",JSON.stringify(_zoneObj))
                    root.globSignalsObject.addCamToPreview(_zoneObj);
                }
            }
            else
            {
               // console.error("vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv - root.globSignalsObject.tabAddedOnceCam");
                root.globSignalsObject.tabAddedOnceCam(root.key2,0,root.type,root.params,root.qmlPath);
            }
            mouse.accepted = true;
        }
    }
}

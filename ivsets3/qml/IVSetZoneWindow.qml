import QtQuick 2.11
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.plugins.loader 1.0
import iv.sets.sets3 1.0

ApplicationWindow
{
    id: root
    color: "transparent"
    //anchors.fill: parent
    width: 0
    height: 0
    visible: true
  //flags: Qt.FramelessWindowHint
    property string unique: root
    property string setName: ""
    property string camName: ""
    property int winIndex: -1
    property string outProperties:""
    property int aT: 0
    property point clickPos: Qt.point(1, 1)
    property bool isEditor: false
    property string asNewSet: ""
    property string strZones: ""
    function getZones( param1 )
    {
        var sZones = "";
        try
        {
            root.strZones = JSON.stringify( setZone.myZones);

            return root.strZones;
        }
        catch(exception)
        {
            return exception;
        }


    }
    function updateParams(params)
    {
        var res = setZone.updateParams(params);
        return res;
    }
    function setColsRows(cols,rows)
    {
        setZone.cols = cols;
        setZone.rows = rows;
        return "";
    }

    IvVcliSetting
    {
      id: integration_opac
      name: 'sdk.opacity'
      onValueChanged:
      {
          if(integration_flag.value === "SDK")
          {
            var opac = integration_opac.value;
            if(opac === "" || opac === undefined)
            {
                opac = 1;
                return;
            }
            var doblOpac = parseFloat(opac);
            root.opacity = doblOpac;
          }
      }
    }
    IvVcliSetting
    {
      id: integration_flag
      name: 'cmd_args.mode'
    }
    Component.onCompleted:
    {
        if(integration_flag.value === "SDK")
        {
          var opac = integration_opac.value;
          if(opac === "" || opac === undefined)
          {
              opac = 1;
              return;
          }
          var doblOpac = parseFloat(opac);
          root.opacity = doblOpac;
        }
    }

    onAsNewSetChanged:
    {
        setZone.asNewSet = root.asNewSet;
    }
    onIsEditorChanged:
    {
        setZone.isEditor = root.isEditor;
    }
    property string tvIrMode: "tvDay"
    onTvIrModeChanged:
    {
        setZone.tvIrMode = root.tvIrMode;
    }
    MouseArea
    {
        id:www
        anchors.fill: parent
        propagateComposedEvents: true
        hoverEnabled: false

        onPressed:
        {
            root.clickPos = Qt.point(mouseX,mouseY);

        }
        onPositionChanged: {

//            if (pressedButtons == Qt.LeftButton)
//            {
//               var dx = mouseX - root.clickPos.x;
//               var dy = mouseY - root.clickPos.y;
//                root.x = root.x + dx;
//                root.y = root.y + dy;
//            }

        }
        onReleased:
        {
        }

        z:5
    }
    QtObject
    {
        id:tempObj
         property string tabUniqId:""
    }

    IVClientSetsZone
    {
        id:setZone
        anchors.fill: parent
        z:3
        tvIrMode:"tvDay"
        isEditor:false
        isSets:false
        globSignalsObject:root.tempObj
    }
    onOutPropertiesChanged:
    {
        try
        {
            var settingsObj = JSON.parse(root.outProperties);
            var x__ = settingsObj["x"];
            var y__ = settingsObj["y"];
            var width__ = settingsObj["width"];
            var height__ = settingsObj["height"];
            var topmost_ = settingsObj["topmost"];
           // var _isUsed = settingsObj["isUsed"];
           // var _cusVis = settingsObj["custom_visible"];
            var _setName = settingsObj["setName"];
            var _isEd = settingsObj["isEditor"];
            var aT = settingsObj["aT"];
            //if(_isUsed !== undefined)
            //{
                //root.isUsed = _isUsed;
           // }
           // if(_cusVis !== undefined)
           // {
            //    root.custom_visible = _cusVis;
            //}
            if(_setName !== undefined)
            {
                root.setName = _setName;
            }
            if(_isEd !== undefined)
            {
                root.isEditor = _isEd;
            }

            if(aT !== undefined)
            {
                root.aT = aT;
            }
            if(topmost_)
            {
               root.flags = Qt.WindowStaysOnTopHint| Qt.FramelessWindowHint; //| Qt.Window;//
            }
            else
            {
              root.flags = Qt.Window;
            }
            root.width = width__;
            root.height = height__;
            if(aT>0)
            {
                xAnim.stop();
                xAnim.to = x__;
                xAnim.start();
                yAnim.stop();
                yAnim.to = y__;
                yAnim.start();
            }
            else
            {
                root.x = x__;
                root.y = y__;
            }
        }
        catch(exeption)
        {
        }


    }
    NumberAnimation
    {
        id:xAnim
        target: root
        property: "x"
        from: root.x

        duration: root.aT
       // onStopped: root.start()
    }
    NumberAnimation
    {
        id:yAnim
        target: root
        property: "y"
        from: root.y
        duration: root.aT
       // onStopped: root.start()
    }
    onSetNameChanged:
    {
        setZone.setName = root.setName;
    }
    onCamNameChanged:
    {
        setZone.camName = root.camName;
    }
}

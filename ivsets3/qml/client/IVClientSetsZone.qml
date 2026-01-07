import QtQml 2.3
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import iv.plugins.loader 1.0
//import iv.guicomponents 1.0
//import iv.components.windows 1.0
import iv.sets.sets3 1.0
import iv.colors 1.0
import iv.controls 1.0
import iv.mapviewer 1.0
Rectangle
{
  id: root
  anchors.fill: parent
  color: "transparent"//"#d9d9d9"
  smooth: true

  //dev op root.isPrintDebugLogs
  property bool isPrintDebugLogs: false

  IvVcliSetting
  {
    id: integration_flag
    name: 'cmd_args.mode'
  }

  property string key2ForMap: ""
  property bool isEditor: false
  property bool isRealtime: true
  property string setName: ""
  property string setId: ""
  property int isLocal: 1
  property string asNewSet: ""
  property string innerType: ""
  property var zones: []
  property var myZones: []
  property int cols: 32
  property int rows: 32
  property int ratioX: 16
  property int ratioY: 9
  property var globSignalsObject: null
  property bool isSetChanged: false
  property int currentPresset: -1
  property bool isFullscreen: false
  property bool running: true
  property bool isSets: true
  property string tvIrMode: "tvDay"
  property var mainColor: IVColors.get("Colors/Background new/BgFormPrimaryThemed")
  property var separatorColor: IVColors.get("Colors/Stroke new/StSeparatorThemed")
  property bool isPresetChanged: false
  property int maximumCams: 64
  property int presetNumber: -1
  property bool fastEdit: fastEdits.value ==="true"?true:false

  IvVcliSetting
  {
      id: fastEdits
      name: 'sets.fastEdits'
  }
  IvVcliSetting {
      id: eventsMaps
      name: 'settings.openMapFromEvents'
  }
  function qmltypeof(obj, className) {
    var str = obj.objectName;
      //console.error("objectName OF COMPONENT = ", str);
    return str.indexOf(className) !== -1;
  }
  function swapElements(array, index1, index2) {
      let temp = array[index1];
      array[index1] = array[index2];
      array[index2] = temp;
  }
  Component.onCompleted:
  {
      root.m_resize();
      //cellCanvas.requestPaint("Component.onCompleted");
  }
  onIsSetsChanged:
  {
      //if(root.isPrintDebugLogs)
      //console.error("onIsSetsChanged = " , root.isSetChanged)
      root.globSignalsObject.setChanged(root.setName);
  }
Timer
{
    id:resizeTimer
    running: false
    interval: 100
    repeat: false
    triggeredOnStart: false
    onTriggered:
    {
        if(root.ratioX === 0 | root.ratioY === 0)
        {
            gridRect.width = middleRect.width;
            gridRect.height = middleRect.height;
        }
        else
        {
            var _rect = root.gridPositionToRect3(middleRect.width,middleRect.height,0,1,root.ratioX,root.ratioY);
            gridRect.width = _rect.width;
            gridRect.height = _rect.height;
        }
        root.m_resize("onHeightChanged");
        cellCanvas.requestPaint();
    }
}
  onWidthChanged:
  {
      if(root.ratioX === 0 | root.ratioY === 0)
      {
          gridRect.width = middleRect.width;
          gridRect.height = middleRect.height;
      }
      else
      {
          var _rect = root.gridPositionToRect3(middleRect.width,middleRect.height,0,1,root.ratioX,root.ratioY);
          gridRect.width = _rect.width;
          gridRect.height = _rect.height;
      }
      root.m_resize("onWidthChanged");
      cellCanvas.requestPaint();

    //  resizeTimer.stop();
    //  resizeTimer.start();
  }
  onHeightChanged:
  {
      if(root.ratioX === 0 | root.ratioY === 0)
      {
          gridRect.width = middleRect.width;
          gridRect.height = middleRect.height;
      }
      else
      {
          var _rect = root.gridPositionToRect3(middleRect.width,middleRect.height,0,1,root.ratioX,root.ratioY);
          gridRect.width = _rect.width;
          gridRect.height = _rect.height;
      }
      root.m_resize("onHeightChanged");
      cellCanvas.requestPaint();
      //resizeTimer.stop();
      //resizeTimer.start();
  }
  onIsEditorChanged:
  {
      console.log("onIsEditorChanged", isEditor)
      cellCanvas.requestPaint();
      root.forceActiveFocus();
  }
  onAsNewSetChanged:
  {
      root.myZones = JSON.parse(root.asNewSet);
      //if(root.isPrintDebugLogs)
      {
          //console.error("onAsNewSetChanged 555 = ",root.myZones)
          console.error("onAsNewSetChanged 555222 = ",root.asNewSet)
      }
      root.cols = root.myZones["cols"];
      root.rows = root.myZones["rows"];
      if(root.myZones["ratioX"] === null || root.myZones["ratioX"] === undefined)
      {
          root.ratioX = 0;
      }
      else
      {
          root.ratioX = root.myZones["ratioX"];
      }
      if(root.myZones["ratioY"] === null || root.myZones["ratioY"] === undefined)
      {
          root.ratioY = 0;
      }
      else
      {
          root.ratioY = root.myZones["ratioY"];
      }
      var _zzones = root.myZones["zones"];
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      for(var i = 0;i<_zzones.length;i++)
      {
          var _zone  = selectionComponent.createObject(pluginsGrid, {compIndex:i});

          _zone.z = 10;
          _zone.params=_zzones[i].params;
          //if(root.isPrintDebugLogs)
          console.error("create zone 3",JSON.stringify(_zzones[i].params));
          //_zone.innerIndex = i;
          _zone.y = (_zzones[i].y-1)*_height;
          _zone.x = (_zzones[i].x-1)*_width;
          _zone.type = _zzones[i].type;
          _zone.qml_path = _zzones[i].qml_path;
          var ddx = _zzones[i].dx;
          var ddy = _zzones[i].dy;
          _zone.width = _width * ddx ;
          _zone.height = _height * ddy;

          _zone.guid=_zzones[i].guid;
          //if(_zone.type === "detailcamera")
          //{
          //console.error("DETAL W = ",_zone.width , _width)
          //console.error("DETAL H = ",_zone.height , _height)
          // }
          //root.globSignalsObject.zonesAddedFromSetName(root.setName,_zzones[i]);
          root.zones.push(_zone);
      }
  }
  onGlobSignalsObjectChanged:
  {
      if(root.globSignalsObject !== null & root.globSignalsObject !== undefined)
      {
          myGlobConnect.target = Qt.binding(function() {return root.globSignalsObject;});
          root.globSignalsObject.setsCompleted();
      }
  }
  onTvIrModeChanged:
  {
//      console.error("onTvIrModeChanged 1 ",root.tvIrMode)
//      for(var i=0;i<root.zones.length;i++)
//      {
//          console.error("onTvIrModeChanged 3 ",root.tvIrMode)
//          if(root.zones[i].type === "panorama")
//          {
//              console.error("onTvIrModeChanged 4 ",root.tvIrMode, root.zones[i].zoneObject)
//              if(root.tvIrMode === "tvDay")
//              {
//                  root.zones[i].zoneObject.changeCurrentViewMode(1);
//                  console.error("ACTIVATE tvDay = " );

//              }
//              if(root.tvIrMode === "irNight")
//              {
//                  root.zones[i].zoneObject.changeCurrentViewMode(2)
//                  console.error("ACTIVATE irNight = ");
//              }
//              if(root.tvIrMode === "tvIRAuto")
//              {
//                  //root.zones[i].zoneObject.changeCurrentViewMode()
//              }
//              if(root.tvIrMode === "tvIRCombined")
//              {
//                  root.zones[i].zoneObject.changeCurrentViewMode(3);
//                  console.error("ACTIVATE tvIRCombined");
//              }
//          }
//      }
  }


  /*
1) починить растягиваниие и перемещение ok
2) вписать в отдельное приложение
3) сделать вс методы для добавления зон и наборов
4) сохранение в файл нового набора.ok
*/

  Connections
  {
      id:myGlobConnect

      onTabUniqIdChanged:
      {
          console.error(" 250602 009 tabUniqId ", root.globSignalsObject.tabUniqId );
          if( root.globSignalsObject.tabUniqId !== "" )
          {
              console.error(" 250602 010 tabUniqId ", root.globSignalsObject.tabUniqId );
              mainLoader.refresh();
          }
          else
          {
              console.error(" 250602 011 ");
              mainLoader.destroy1();
          }
      }

      // target:root.globSignalsObject
      onSetAdded:
      {
          //if(root.isPrintDebugLogs)
          //console.error("ivsezone onSetAdded setname = ",setname);
          root.setName = setname;
      }
      onSetToArchive:
      {
          //if(root.isPrintDebugLogs)
          //console.error("SET TO ARCH");
        root.isRealtime = false;
      }
      onSetToRealtime:
      {
          //if(root.isPrintDebugLogs)
          //console.error("SET TO REAL");
        root.isRealtime = true;
      }

//      onSetSelected:
//      {
//          root.setName = setname;
//      }
      onSetRefreshed:
      {
          root.setName = "";
          root.setName = setname;
      }
      onSetColsRowsChanged:
      {
          root.cols = cols;
          root.rows = rows;
      }
      onRatioChanged:
      {
          root.ratioX = ratioX;
          root.ratioY = ratioY;
          if(root.ratioX === 0 | root.ratioY === 0)
          {
              gridRect.width = middleRect.width;
              gridRect.height = middleRect.height;
          }
          else
          {
              var _rect = root.gridPositionToRect3(middleRect.width,middleRect.height,0,1,root.ratioX,root.ratioY);
              gridRect.width = _rect.width;
              gridRect.height = _rect.height;
          }



      }

      onSwitch_fullscreen:
      {
          //        console.error("ON SWITCH!!!!! = ", index)
          //        root.zones[index].x = 0;
          //        root.zones[index].y = 0;
          //        root.zones[index].width = gridRect.width;
          //        root.zones[index].height = gridRect.height;
      }

      onSetSaved:
      {
          //if(root.isPrintDebugLogs)
          //console.error("ivsezone onSetSaved setname = ",setname , "old set name = ",root.setName);
          if(setname === "")
          {
              root.saveSet(root.setName);
          }
          else
          {
              var oldName = root.setName
              root.saveSet(setname);
              root.globSignalsObject.setNameChanged(oldName,setname);
              root.setName = setname;
          }
          root.isSetChanged = false;
          root.globSignalsObject.setChanged("");
      }
      onSetCopy:
      {
          var setStr = JSON.stringify(root.myZones);
          var _nsetName = root.setName+"_копия";
          customSets.saveSet(_nsetName,_nsetName,setStr);
          root.globSignalsObject.setNameChanged(root.setName,_nsetName);
          //root.setName = _nsetName;
      }
      onZonesAdded:
      {
          //if(root.isPrintDebugLogs)
          //console.error("onZonesAdded 1 " , zone)
          root.addZone(zone);
          root.isSetChanged = true;
          root.globSignalsObject.setChanged(root.setName);
          //console.error("onZonesAdded 1 ", root.isSetChanged);
      }
      onZoneChanged:
      {
          root.zoneChanged2(index,zoneparams);
      }
      onZoneSelected:
      {
          //if(root.isPrintDebugLogs)
          //console.error("bbbbb zone selected",index,zoneparams);
          root.zoneChanged(index);
      }
      onZoneRemoved:
      {
          root.deleteZone(index);
          root.isSetChanged = true;
          root.globSignalsObject.setChanged(root.setName);
      }
    onClearView:
    {
        root.setName = "";
        root.clearZones();
        if(root.myZones["zones"])
        {
            for(var ii = 0;ii <root.myZones["zones"].length;ii++)
            {
                root.deleteZone(ii)
            }
        }
    }

    onTabSelected5:
    {
        //if(root.isPrintDebugLogs)
        var _isRealtime = (viewType==="realtime")
        console.error("FFFFFFFFFFFFFFF onTabSelected3 = ",tabname,type,id,viewType,_isRealtime);
//        if(tabname===root.setName && id=== root.setId && root.isRealtime == _isRealtime )
//        {
//            console.error("FFFFFFFFFFFFFFF onTabSelected5 return ");
//            return;
//        }
        root.setName = "";
        root.isRealtime = true;
        root.clearZones();
        if(root.myZones["zones"])
        {
            for(var ii = 0;ii <root.myZones["zones"].length;ii++)
            {
                root.deleteZone(ii)
            }
        }
        if(root.myZones["zones"])
        {
            for(var ii = 0;ii <root.myZones["zones"].length;ii++)
            {
                root.deleteZone(ii)
            }
        }
        if(type === "set")
        {
            root.setName = "";
            root.isRealtime = _isRealtime;
            //if(root.isPrintDebugLogs)
            //console.error("TAB SELECTED SET", tabname,id)
            root.setId = id;
            root.innerType = type;
            //root.startCreateObj(root.setName,root.setId)
            //if(root.isPrintDebugLogs)
            console.error("FFFFFFFFFFFFFFF onTabSelected5 = ",tabname,root.setId,viewType);
            root.setName = tabname;

        }
        else if(type === "camera")
        {
            root.setName ="";
            var item = customSets.getTypePreset(type, "key2", "string", tabname);
            root.isRealtime = _isRealtime;
            root.setName = tabname;
            root.cols = 32;
            root.rows = 32;
            root.ratioX = 16;
            root.ratioY = 9;
            root.innerType = type
            var zoneObj = {};
            zoneObj["x"] = 1;
            zoneObj["y"] = 1;
            zoneObj["dx"] = 32;
            zoneObj["dy"] = 32;
            zoneObj["type"] = type;
            zoneObj["qml_path"] = item.qml_path;
            zoneObj["params"] = item.params;
            root.addZone(JSON.stringify(zoneObj));
        }
        else if(type==="client_settings")
        {
            root.setName ="";
            var item = customSets.getTypePreset(type, "", "string", "");
            root.setName = tabname;
            root.innerType = type
            root.cols = 32;
            root.rows = 32;
            var zoneObj = {};
            zoneObj["x"] = 1;
            zoneObj["y"] = 1;
            zoneObj["dx"] = 32;
            zoneObj["dy"] = 32;
            zoneObj["type"] = type;
            zoneObj["qml_path"] = item.qml_path;
            zoneObj["params"] = item.params;

            root.addZone(JSON.stringify(zoneObj));
        }
        else if(type==="map")
        {
            root.setName ="";
            var item = customSets.getTypePreset(type, "jsonDataFileName", "string", tabname);
            root.setName = tabname;
            root.innerType = type
            root.cols = 32;
            root.rows = 32;
            var zoneObj = {};
            //if(root.isPrintDebugLogs)
            //console.error(JSON.stringify(item) , "aAAAAAAAAAAAAAAAAAAAAAAA")
            zoneObj["x"] = 1;
            zoneObj["y"] = 1;
            zoneObj["dx"] = 32;
            zoneObj["dy"] = 32;
            zoneObj["type"] = type;
            zoneObj["qml_path"] = item.qml_path;
            zoneObj["params"] = item.params;
            var sparams = JSON.stringify(zoneObj);
            //if(root.isPrintDebugLogs)
            //console.error("nnnnnnnnnnnnnnn = ",sparams);
            root.addZone(JSON.stringify(zoneObj));
        }
        else
        {
            //if(root.isPrintDebugLogs)
            //console.error("ADD ZONE TYPE ERROR = ",type );
        }
    }
    onTabSelected4:
    {
        //if(root.isPrintDebugLogs)
        //console.error("FFFFFFFFFFFFFFF onTabSelected4 = ",tabname,type,id,key2);
        if(tabname===root.setName && id=== root.setId)
        {
            return;
        }
        root.setName = "";
        root.clearZones();
        if(root.myZones["zones"])
        {
            for(var ii = 0;ii <root.myZones["zones"].length;ii++)
            {
                root.deleteZone(ii)
            }
        }
        if(type === "set")
        {
            root.setName = "";
            //if(root.isPrintDebugLogs)
            //console.error("TAB SELECTED SET", tabname,id)
            root.setId = id;
            root.innerType = type;
            //root.startCreateObj(root.setName,root.setId)
            //if(root.isPrintDebugLogs)
            //console.error("FFFFFFFFFFFFFFF onTabSelected = ",tabname,root.setId);
            root.setName = tabname;
        }
        else if(type === "camera")
        {
            root.setName ="";
            var item = customSets.getTypePreset(type, "key2", "string", tabname);
            root.setName = tabname;
            root.cols = 32;
            root.rows = 32;
            root.ratioX = 16;
            root.ratioY = 9;
            root.innerType = type
            console.error("OPEN CAMERA type = ",type , root.innerType)
            var zoneObj = {};
            zoneObj["x"] = 1;
            zoneObj["y"] = 1;
            zoneObj["dx"] = 32;
            zoneObj["dy"] = 32;
            zoneObj["type"] = type;
            zoneObj["params"] = item.params;
            zoneObj["qml_path"] = item.qml_path;
            root.addZone(JSON.stringify(zoneObj));
        }
        else if(type==="client_settings")
        {
            root.setName ="";
            var item = customSets.getTypePreset(type, "", "string", "");
            root.setName = tabname;
            root.innerType = type;
            root.cols = 32;
            root.rows = 32;
            var zoneObj = {};
            zoneObj["x"] = 1;
            zoneObj["y"] = 1;
            zoneObj["dx"] = 32;
            zoneObj["dy"] = 32;
            zoneObj["type"] = type;
            zoneObj["qml_path"] = item.qml_path;
            zoneObj["params"] = item.params;

            root.addZone(JSON.stringify(zoneObj));
        }
        else if(type==="map")
        {
            root.setName ="";
            var item = customSets.getTypePreset(type, "jsonDataFileName", "string", tabname);
            root.setName = tabname;
            root.key2ForMap = key2;
            root.innerType = type
            root.cols = 32;
            root.rows = 32;
            var zoneObj = {};
            //if(root.isPrintDebugLogs)
            //console.error(JSON.stringify(item) , "aAAAAAAAAAAAAAAAAAAAAAAA")
            zoneObj["x"] = 1;
            zoneObj["y"] = 1;
            zoneObj["dx"] = 32;
            zoneObj["dy"] = 32;
            zoneObj["type"] = type;
            zoneObj["qml_path"] = item.qml_path;
            zoneObj["params"] = item.params;

            var sparams = JSON.stringify(zoneObj);
            //if(root.isPrintDebugLogs)
            //console.error("nnnnnnnnnnnnnnn = ",sparams);
            root.addZone(JSON.stringify(zoneObj));
        }
        else
        {
            //if(root.isPrintDebugLogs)
            //console.error("ADD ZONE TYPE ERROR = ",type );
        }
    }

      onTabEditedOn:
      {
          root.isEditor = true;
          cellCanvas.requestPaint();
      }
      onTabEditedOff:
      {
          root.isEditor = false;
          cellCanvas.requestPaint();
      }
      onGetZonesFromSet:
      {
          var _zzones = root.myZones["zones"];
          //console.error("zzzzzzzzzzzzzzzzzzzzzzzzzzzz = ",JSON.stringify(_zzones));
          // for(var i = 0;i<_zzones.length;i++)
          {
              root.globSignalsObject.zonesAddedFromSetName(root.setName,_zzones);
          }
      }


    onSetPreset:
    {
        ///console.error("SET PRESSET ", presetNumber);
        root.setPreset(presetNumber);
    }
    onSetPreset1:
    {
        //console.error("SET PRESSET 1");
        root.setPresset1();
    }
    onSetPreset2:
    {
        root.setPresset2();
    }
    onSetPreset3:
    {
        root.setPresset3();
    }
    onSlotsChanged:
    {
        //(var slotsModel,int pressetNumber)
        var slots = JSON.parse(slotsModel);
        //console.error("onSlotChanged = ",slotsModel, pressetNumber);
        if(pressetNumber === 1)
        {
            root.setPresset1();
        }
    }
      ///Поддержка старых сигралов
      onCommand1:
      {
          if(command==="viewers:fullscreen")
          {
              root.isFullscreen = !root.isFullscreen;
              var ind = root.getCurrIndex2Comp(sender);
              var _viewer = root.zones[ind];
              if(root.isFullscreen && _viewer)
              {
                  root.running = false;
                  if( _viewer.zoneObject.running !== undefined)
                  {
                      _viewer.zoneObject.running = true;

                  }
                  _viewer.zoneObject.visible = true;
                  _viewer.z = 11;
                  _viewer.anchors.fill = pluginsGrid;
              }
              else
              {
                  root.running = true;
                  var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
                  var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
                  _viewer.z = 10;
                  if( _viewer.zoneObject.running !== undefined)
                  {
                      _viewer.zoneObject.running = Qt.binding(function(){ return root.running});

                  }
                  _viewer.zoneObject.visible = Qt.binding(function(){ return root.running});
                  _viewer.anchors.fill = undefined;
                  _viewer.y = (root.myZones["zones"][ind].y-1)*_height;
                  _viewer.x = (root.myZones["zones"][ind].x-1)*_width;
                  var ddx = root.myZones["zones"][ind].dx;
                  var ddy = root.myZones["zones"][ind].dy;
                  _viewer.width = _width * ddx ;
                  _viewer.height = _height * ddy;
              }

          }
      }


  }
  IVCustomSets {
      id: customSets
      Component.onCompleted: customSets.initWs()
  }

  function setPreset(presetNumber)
  {

      //console.error("SET PRESET NUMBER = ",presetNumber );

      if(presetNumber === 3)
      {
          root.isPresetChanged = true;
          root.maximumCams = 10;
          root.presetNumber = presetNumber;
          root.setPresset3();
          root.setPresset3();
      }
      if(presetNumber === 4)
      {
          root.isPresetChanged = true;
          root.maximumCams = 8;
          root.presetNumber = presetNumber;
          root.setPresset4();
          root.setPresset4();
      }
      if(presetNumber === 5)
      {
          root.isPresetChanged = true;
          root.maximumCams = 13;
          root.presetNumber = presetNumber;
          root.setPresset5();
          root.setPresset5();
      }
      if(presetNumber === 6)
      {
          root.isPresetChanged = true;
          root.maximumCams = 16;
          root.presetNumber = presetNumber;
          root.setPresset6();
          root.setPresset6();
      }
    }

  function setPresset1()
  {
      root.cols = 60;
      root.rows = 60;
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1))) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1))) ;//- pluginsGrid.rowSpacing;


      var ii1 = 0;
      var yy1 = 0;
      if(root.zones.length === 0)
      {
          for(var i = 0;i<7;i++)
          {
              var _zone  = selectionComponent.createObject(pluginsGrid, {compIndex:i+1});
              _zone.params={};
              //_zone.z = 10;
              // console.error("create zone ",JSON.stringify(_zzones[i].params));
              //_zone.innerIndex = i;
              //_zone.y = (_zzones[i].y-1)*_height;
              //_zone.x = (_zzones[i].x-1)*_width;
              _zone.type = "empty";
              //_zone.qml_path = _zzones[i].qml_path;
              //            var ddx = _zzones[i].dx;
              //            var ddy = _zzones[i].dy;
              //            _zone.width = _width * ddx ;
              //            _zone.height = _height * ddy;
              // root.globSignalsObject.zonesAddedFromSetName(root.setName,_zone_);
              root.zones.push(_zone);
              root.myZones["zones"].push("{\"type\":\"empty\",\"qml_path\":\"\",\"params\":{}}")
          }
      }
      var zonesSize = root.zones.length;
      if(zonesSize>7)
      {

      }
      else if(zonesSize<=7 && zonesSize>0)
      {
          root.zones[0].x = 0;
          root.zones[0].y = 0;
          root.zones[0].width = _width*30;
          root.zones[0].height = _height*30;
          root.newPosotions(root.zones[0]);
          if(zonesSize>1)
          {
              root.zones[1].x = _width*30;
              root.zones[1].y = 0;
              root.zones[1].width = _width*30;
              root.zones[1].height = _height*30;
              root.newPosotions(root.zones[1]);
          }
          if(zonesSize>2)
          {
              root.zones[2].x = 0;
              root.zones[2].y = _height*30;
              root.zones[2].width = _width*30;
              root.zones[2].height = _height*30;
              root.newPosotions(root.zones[2]);
          }
          if(zonesSize>3)
          {
              root.zones[3].x = _width*30;
              root.zones[3].y = _height*30;
              root.zones[3].width = _width*15;
              root.zones[3].height = _height*15;
              root.newPosotions(root.zones[3]);
          }
          if(zonesSize>4)
          {
              root.zones[4].x = _width*45;
              root.zones[4].y = _height*30;
              root.zones[4].width = _width*15;
              root.zones[4].height = _height*15;
              root.newPosotions(root.zones[4]);
          }
          if(zonesSize>5)
          {
              root.zones[5].x = _width*30;
              root.zones[5].y = _height*45;
              root.zones[5].width = _width*15;
              root.zones[5].height = _height*15;
              root.newPosotions(root.zones[5]);
          }
          if(zonesSize>6)
          {
              root.zones[6].x = _width*45;
              root.zones[6].y = _height*45;
              root.zones[6].width = _width*15;
              root.zones[6].height = _height*15;
              root.newPosotions(root.zones[6]);
          }
      }
      else if(zonesSize===0)
      {

      }



      return;
      //    for(var i=0;i<zonesSize;i++)
      //    {
      //        if(i<3)
      //        {
      //            root.zones[i].x = ii1*(_width*30);
      //            root.zones[i].y = yy1*(_height*30);
      //            ii1++;
      //            if(ii1>2)
      //            {
      //                ii1 = 0;
      //                yy1++;
      //            }
      //        }
      //        else if(i>=3 && i<8)
      //        {
      //            root.zones[i].x = ii1*(_width*8);
      //            root.zones[i].y = yy1*(_height*8);
      //            ii1++;
      //            if(ii1>3)
      //            {
      //               ii1=0;
      //               yy1++;
      //            }

      //        }
      //        else if(i>7 && i<12)
      //        {
      //            root.zones[i].x = ii1*(_width*8);
      //            root.zones[i].y = yy1*(_height*8);
      //            ii1++;
      //            if(ii1>3)
      //            {
      //               ii1=0;
      //               yy1++;
      //            }
      //        }
      //        else if(i>11 && i<16)
      //        {
      //            root.zones[i].x = ii1*(_width*8);
      //            root.zones[i].y = yy1*(_height*8);
      //            ii1++;
      //            if(ii1>3)
      //            {
      //               ii1=0;
      //               yy1++;
      //            }
      //        }
      //        else
      //        {
      //            root.zones[i].x = 0;
      //            root.zones[i].y = 0;
      //        }
      //        root.zones[i].width = _width*8;
      //        root.zones[i].height = _height*8;
      //        root.newPosotions(root.zones[i]);
      //    }
  }
  function setPresset2()
  {
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      var zonesSize = root.zones.length;
      var ii1 = 0;
      var yy1 = 0;
      for(var i=0;i<zonesSize;i++)
      {
          if(i<2)
          {
              root.zones[i].x = ii1*(_width*32);
              root.zones[i].y = yy1*(_height*8);
              //ii1++;
              yy1++;
              root.zones[i].width = _width*32;
              root.zones[i].height = _height*8;
              root.newPosotions(root.zones[i]);
          }
          else if(i>=2 && i<=5)
          {
              root.zones[i].x = ii1*(_width*8);
              root.zones[i].y = yy1*(_height*8);
              ii1++;
              if(ii1>3)
              {
                  ii1=0;
                  yy1++;
              }
              root.zones[i].width = _width*8;
              root.zones[i].height = _height*8;
              root.newPosotions(root.zones[i]);
          }
          else if(i>=6 && i<=9)
          {
              root.zones[i].x = ii1*(_width*8);
              root.zones[i].y = yy1*(_height*8);
              ii1++;
              if(ii1>3)
              {
                  ii1=0;
                  yy1++;
              }
              root.zones[i].width = _width*8;
              root.zones[i].height = _height*8;
              root.newPosotions(root.zones[i]);

          }
          else
          {
              root.zones[i].x = 0;
              root.zones[i].y = 0;
              root.zones[i].width = _width*8;
              root.zones[i].height = _height*8;
              root.newPosotions(root.zones[i]);
          }
      }
  }
  function setPresset3()
  {
      root.cols = 32;
      root.rows = 32;
      var presert3 = "[{\"x\":1,\"y\":1,\"dx\":16,\"dy\":16},
     {\"x\":17,\"y\":1,\"dx\":16,\"dy\":16},
     {\"x\":1,\"y\":17,\"dx\":8,\"dy\":8},
     {\"x\":9,\"y\":17,\"dx\":8,\"dy\":8},
     {\"x\":17,\"y\":17,\"dx\":8,\"dy\":8},
     {\"x\":25,\"y\":17,\"dx\":8,\"dy\":8},
     {\"x\":1,\"y\":25,\"dx\":8,\"dy\":8},
     {\"x\":9,\"y\":25,\"dx\":8,\"dy\":8},
     {\"x\":17,\"y\":25,\"dx\":8,\"dy\":8},
     {\"x\":25,\"y\":25,\"dx\":8,\"dy\":8}]";
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      var presert3Array = JSON.parse(presert3);
      var zonesCount = presert3Array.length;
      var i1=0;
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      //console.error("setPresset3 = ", zonesCount , JSON.stringify(presert3Array));
//      if(root.presetNumber === 3)
//      {
//           console.error("setPresset3 root.presetNumber === 3 ", zonesCount , JSON.stringify(presert3Array));
//          return;
//      }
        if(root.zones.length>0)
        {
             //console.error("setPresset3 root.zones.length>0", zonesCount , root.zones.length);
            for(i1; i1<root.zones.length;i1++)
            {
                var _zone_ = {};
                if(root.zones.length>zonesCount)
                {
                    root.deleteZone(root.zones.length-1);
                    i1 = 0;
                    continue;
                }
                root.myZones["zones"][i1].x = presert3Array[i1].x;
                root.myZones["zones"][i1].y = presert3Array[i1].y;
                root.myZones["zones"][i1].dx = presert3Array[i1].dx;
                root.myZones["zones"][i1].dy = presert3Array[i1].dy;
                root.zones[i1].x = (presert3Array[i1].x-1)*_width;
                root.zones[i1].y = (presert3Array[i1].y-1)*_height;
                var ddx = presert3Array[i1].dx;
                var ddy = presert3Array[i1].dy;
                root.zones[i1].width = _width * ddx ;
                root.zones[i1].height = _height * ddy;
            }
        }
      for(i1; i1<zonesCount;i1++)
      {
          var _zone_ = {};
          _zone_.x = presert3Array[i1].x;
          _zone_.y = presert3Array[i1].y;
          _zone_.dx = presert3Array[i1].dx;
          _zone_.dy = presert3Array[i1].dy;
          _zone_.type = "camera";
          _zone_.qml_path = "";
          root.addZoneEmpty(JSON.stringify(_zone_));
      }
  }
  function setPresset4()
  {
      root.cols = 32;
      root.rows = 32;
      var presert4 = "[{\"x\":1,\"y\":1,\"dx\":24,\"dy\":24},
     {\"x\":1,\"y\":25,\"dx\":8,\"dy\":8},
     {\"x\":9,\"y\":25,\"dx\":8,\"dy\":8},
     {\"x\":17,\"y\":25,\"dx\":8,\"dy\":8},
     {\"x\":25,\"y\":25,\"dx\":8,\"dy\":8},
     {\"x\":25,\"y\":1,\"dx\":8,\"dy\":8},
     {\"x\":25,\"y\":9,\"dx\":8,\"dy\":8},
     {\"x\":25,\"y\":17,\"dx\":8,\"dy\":8}]";
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      var presert3Array = JSON.parse(presert4);
      var zonesCount = presert3Array.length;
      var i1=0;
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      //console.error("setPresset4 = ", zonesCount , JSON.stringify(presert3Array));
//      if(root.presetNumber === 3)
//      {
//           console.error("setPresset3 root.presetNumber === 4 ", zonesCount , JSON.stringify(presert3Array));
//          return;
//      }
        if(root.zones.length>0)
        {
             //console.error("setPresset4 root.zones.length>0", zonesCount , root.zones.length);
            for(i1; i1<root.zones.length;i1++)
            {
                var _zone_ = {};
                if(root.zones.length>zonesCount)
                {
                    root.deleteZone(root.zones.length-1);
                    i1 = 0;
                    continue;
                }
                root.myZones["zones"][i1].x = presert3Array[i1].x;
                root.myZones["zones"][i1].y = presert3Array[i1].y;
                root.myZones["zones"][i1].dx = presert3Array[i1].dx;
                root.myZones["zones"][i1].dy = presert3Array[i1].dy;
                root.zones[i1].x = (presert3Array[i1].x-1)*_width;
                root.zones[i1].y = (presert3Array[i1].y-1)*_height;
                var ddx = presert3Array[i1].dx;
                var ddy = presert3Array[i1].dy;
                root.zones[i1].width = _width * ddx ;
                root.zones[i1].height = _height * ddy;
            }
        }
      for(i1; i1<zonesCount;i1++)
      {
          var _zone_ = {};
          _zone_.x = presert3Array[i1].x;
          _zone_.y = presert3Array[i1].y;
          _zone_.dx = presert3Array[i1].dx;
          _zone_.dy = presert3Array[i1].dy;
          _zone_.type = "camera";
          _zone_.qml_path = "";
          root.addZoneEmpty(JSON.stringify(_zone_));
      }
  }
  function setPresset5()
  {
      root.cols = 32;
      root.rows = 32;
      var presert5 = "[{\"x\":9,\"y\":9,\"dx\":16,\"dy\":16},
     {\"x\":1,\"y\":1,\"dx\":8,\"dy\":8},
     {\"x\":9,\"y\":1,\"dx\":8,\"dy\":8},
     {\"x\":17,\"y\":1,\"dx\":8,\"dy\":8},
     {\"x\":25,\"y\":1,\"dx\":8,\"dy\":8},
     {\"x\":1,\"y\":9,\"dx\":8,\"dy\":8},
     {\"x\":25,\"y\":9,\"dx\":8,\"dy\":8},
     {\"x\":1,\"y\":17,\"dx\":8,\"dy\":8},
     {\"x\":25,\"y\":17,\"dx\":8,\"dy\":8},
     {\"x\":1,\"y\":25,\"dx\":8,\"dy\":8},
     {\"x\":9,\"y\":25,\"dx\":8,\"dy\":8},
     {\"x\":17,\"y\":25,\"dx\":8,\"dy\":8},
     {\"x\":25,\"y\":25,\"dx\":8,\"dy\":8}]";
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      var presert3Array = JSON.parse(presert5);
      var zonesCount = presert3Array.length;
      var i1=0;
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      //console.error("setPresset4 = ", zonesCount , JSON.stringify(presert3Array));
//      if(root.presetNumber === 3)
//      {
//           console.error("setPresset3 root.presetNumber === 4 ", zonesCount , JSON.stringify(presert3Array));
//          return;
//      }
        if(root.zones.length>0)
        {
             //console.error("setPresset4 root.zones.length>0", zonesCount , root.zones.length);
            for(i1; i1<root.zones.length;i1++)
            {
                var _zone_ = {};
                if(root.zones.length>zonesCount)
                {
                    root.deleteZone(root.zones.length-1);
                    i1 = 0;
                    continue;
                }
                root.myZones["zones"][i1].x = presert3Array[i1].x;
                root.myZones["zones"][i1].y = presert3Array[i1].y;
                root.myZones["zones"][i1].dx = presert3Array[i1].dx;
                root.myZones["zones"][i1].dy = presert3Array[i1].dy;
                root.zones[i1].x = (presert3Array[i1].x-1)*_width;
                root.zones[i1].y = (presert3Array[i1].y-1)*_height;
                var ddx = presert3Array[i1].dx;
                var ddy = presert3Array[i1].dy;
                root.zones[i1].width = _width * ddx ;
                root.zones[i1].height = _height * ddy;
            }
        }
      for(i1; i1<zonesCount;i1++)
      {
          var _zone_ = {};
          _zone_.x = presert3Array[i1].x;
          _zone_.y = presert3Array[i1].y;
          _zone_.dx = presert3Array[i1].dx;
          _zone_.dy = presert3Array[i1].dy;
          _zone_.type = "camera";
          _zone_.qml_path = "";
          root.addZoneEmpty(JSON.stringify(_zone_));
      }
  }
  function setPresset6()
  {
      root.cols = 32;
      root.rows = 32;
      var presert6 = "[{\"x\":1,\"y\":1,\"dx\":8,\"dy\":8},
                       {\"x\":9,\"y\":1,\"dx\":8,\"dy\":8},
                       {\"x\":17,\"y\":1,\"dx\":8,\"dy\":8},
                       {\"x\":25,\"y\":1,\"dx\":8,\"dy\":8},
                       {\"x\":1,\"y\":9,\"dx\":8,\"dy\":8},
                       {\"x\":9,\"y\":9,\"dx\":8,\"dy\":8},
                       {\"x\":17,\"y\":9,\"dx\":8,\"dy\":8},
                       {\"x\":25,\"y\":9,\"dx\":8,\"dy\":8},
                       {\"x\":1,\"y\":17,\"dx\":8,\"dy\":8},
                       {\"x\":9,\"y\":17,\"dx\":8,\"dy\":8},
                       {\"x\":17,\"y\":17,\"dx\":8,\"dy\":8},
                       {\"x\":25,\"y\":17,\"dx\":8,\"dy\":8},
                       {\"x\":1,\"y\":25,\"dx\":8,\"dy\":8},
                       {\"x\":9,\"y\":25,\"dx\":8,\"dy\":8},
                       {\"x\":17,\"y\":25,\"dx\":8,\"dy\":8},
                       {\"x\":25,\"y\":25,\"dx\":8,\"dy\":8}]";
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      var presert3Array = JSON.parse(presert6);
      var zonesCount = presert3Array.length;
      var i1=0;
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      console.error("setPresset6 = ", zonesCount , JSON.stringify(presert3Array));
//      if(root.presetNumber === 3)
//      {
//           console.error("setPresset3 root.presetNumber === 4 ", zonesCount , JSON.stringify(presert3Array));
//          return;
//      }
        if(root.zones.length>0)
        {
             //console.error("setPresset6 root.zones.length>0", zonesCount , root.zones.length);
            for(i1; i1<root.zones.length;i1++)
            {
                var _zone_ = {};
                if(root.zones.length>zonesCount)
                {
                    root.deleteZone(root.zones.length-1);
                    i1 = 0;
                    continue;
                }
                root.myZones["zones"][i1].x = presert3Array[i1].x;
                root.myZones["zones"][i1].y = presert3Array[i1].y;
                root.myZones["zones"][i1].dx = presert3Array[i1].dx;
                root.myZones["zones"][i1].dy = presert3Array[i1].dy;
                root.zones[i1].x = (presert3Array[i1].x-1)*_width;
                root.zones[i1].y = (presert3Array[i1].y-1)*_height;
                var ddx = presert3Array[i1].dx;
                var ddy = presert3Array[i1].dy;
                root.zones[i1].width = _width * ddx ;
                root.zones[i1].height = _height * ddy;
            }
        }
      for(i1; i1<zonesCount;i1++)
      {
          var _zone_ = {};
          _zone_.x = presert3Array[i1].x;
          _zone_.y = presert3Array[i1].y;
          _zone_.dx = presert3Array[i1].dx;
          _zone_.dy = presert3Array[i1].dy;
          _zone_.type = "camera";
          _zone_.qml_path = "";
          root.addZoneEmpty(JSON.stringify(_zone_));
      }
  }
  onRatioXChanged:
  {
      if(root.ratioX === 0 | root.ratioY === 0)
      {
          gridRect.width = middleRect.width;
          gridRect.height = middleRect.height;
      }
      else
      {
          var _rect = root.gridPositionToRect3(middleRect.width,middleRect.height,0,1,root.ratioX,root.ratioY);
          gridRect.width = _rect.width;
          gridRect.height = _rect.height;
      }
      root.globSignalsObject.ratioXChanged(root.ratioX);
      root.myZones["ratioX"] = root.ratioX;
  }
  onRatioYChanged:
  {
      if(root.ratioX === 0 | root.ratioY === 0)
      {
          gridRect.width = middleRect.width;
          gridRect.height = middleRect.height;
      }
      else
      {
          var _rect = root.gridPositionToRect3(middleRect.width,middleRect.height,0,1,root.ratioX,root.ratioY);
          gridRect.width = _rect.width;
          gridRect.height = _rect.height;
      }
      root.globSignalsObject.ratioYChanged(root.ratioY);
      root.myZones["ratioY"] = root.ratioY;
  }

  onColsChanged:
  {
      root.myZones["cols"] = root.cols;

      root.m_resize("onColsChanged");
      cellCanvas.requestPaint();
      root.globSignalsObject.setColsChanged(root.cols);
  }
  onRowsChanged:
  {
      root.myZones["rows"] = root.rows;

      root.m_resize("onRowsChanged");
      cellCanvas.requestPaint();
      root.globSignalsObject.setRowsChanged(root.rows);
  }

  function deinit()
  {
      for(var i = root.zones.length;i===0;)
      {
          root.zones[i].deinit();
          var elem = root.zones.pop();
          elem.destroy();
      }
  }

    function saveSet(newSetName)
    {
        //saveSet2(QString setName, QString setId, QString newSetName, QString setJson)
        if(root.myZones)
        {
            root.myZones["setName"] = newSetName;

            if(root.myZones["isuser"] ===0)
            {
                root.myZones["isuser"] = 1;
                root.myZones["setId"] = "";

            }
            else
            {
                root.myZones["setId"] = root.setId;
            }
        }
        var setStr =JSON.stringify(root.myZones);
        console.error("1111111111 = ",root.setName,newSetName,setStr);
        customSets.saveSet2(root.setName,root.setId,newSetName,setStr);
    }
  function deleteSet(setName)
  {
      var setStr = JSON.stringify(root.myZones);
      //console.error(root.setName);
      if(root.setName !=="")
          customSets.deleteSet(root.setName);
      if(setName)
      {
          customSets.deleteSet(setName);
      }
  }
  function updateParams(params)
  {
      // var paramObj = JSON.parse(params)
      if(params)
      {
          //console.error("PARAMS TO UPDATE = ",params , root.zones.length);
          params = JSON.parse(params);
          for(var i = 0;i<params.length;i++)
          {
              var onceObj = params[i];
              //console.error("onceObj = ",JSON.stringify(onceObj));
              for(var j = 0; j<root.zones.length;j++)
              {
                  //console.error("1 = ",root.zones[j].guid , " 2 = ",onceObj.guid);
                  if(root.zones[j].guid === onceObj.guid)
                  {
                      if(onceObj.qml_path !== root.zones[j].qml_path)
                      {
                          //console.error("qml_path = ",onceObj.qml_path , " 2 = ",root.zones[j].qml_path);
                          root.zones[j].params =  onceObj.params;
                          root.zones[j].qml_path = onceObj.qml_path;
                          //console.error("refresh2 2 return");
                          return onceObj;
                      }
                      else
                      {
                          root.zones[j].refresh2(onceObj.params);
                          return params;
                      }
                  }
              }
          }
      }
      return 1;

  }
  function updateCells()
  {
      cellCanvas.requestPaint();
  }
  function addZoneEmpty(zoneObj)
  {
      //console.error("ADD ZONES addZoneEmpty",zoneObj);
      //root.isSetChanged = true;
      var _zone_ = {};
      if(zoneObj)
      {
          _zone_ = JSON.parse(zoneObj);
      }
      var date = Qt.formatDate(new Date(),"dd.MM.yyyy")
      var time = Qt.formatTime(new Date(),"hh:mm:ss")
      var md5awd = date+time;
      var md5str = "";
      md5str = Qt.md5(md5awd);
      _zone_.guid = md5str;
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;

      var _zone  = selectionComponent.createObject(pluginsGrid, {compIndex:root.zones.length+1});
      _zone_.isEmpty = _zone_.qml_path === ""?true:false;
      _zone_.params = {};
      _zone_.qml_path = "";
      _zone_.innerIndex = root.zones.length+1;
      _zone.z = 10;
      _zone.type = _zone_.type;
      _zone.isEmpty = _zone_;
      _zone.innerIndex = root.zones.length+1;
      _zone.params = {};
      _zone.qml_path = "";
      root.myZones["zones"].push(_zone_);
      if(_zone_.x>pluginsGrid.columns)
      {
          _zone_.x = 1;
      }
      if(_zone_.y>pluginsGrid.rows)
      {
          _zone_.y = 1;
      }
      if(( _zone_.dx)>pluginsGrid.columns)
      {
          _zone_.dx = pluginsGrid.columns;
      }
      if(( _zone_.dy)>pluginsGrid.rows)
      {
          _zone_.dy = pluginsGrid.rows;
      }
      _zone.y = (_zone_.y-1)*_height;
      _zone.x = (_zone_.x-1)*_width;
      _zone.col = _zone_.x;
        _zone.row = _zone_.y;
        _zone.dx = _zone_.dx;
        _zone.dy = _zone_.dy;
      var ddx = _zone_.dx;
      var ddy = _zone_.dy;
      _zone.width = _width * ddx ;
      _zone.height = _height * ddy;
      // root.globSignalsObject.zonesAddedFromSetName(root.setName,_zone_);
      root.zones.push(_zone);
  }

  function addZone(zoneObj)
  {
      //console.error("ADD ZONES FROM BUTTON",zoneObj);
      if(root.innerType === "client_settings" && root.myZones["zones"].length >0)
      {
          console.error("error added in settings tab");
          return;
      }
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      //console.error("root.innerType = " , root.innerType );
//      if(root.innerType === "camera" && root.myZones["zones"].length >0)
//      {
//          console.error("IN TYPE CAMERA");
//          root.cols = 2;
//          root.rows = 1;
//          root.ratioX = 32;
//          root.myZones["zones"][0].x=1;
//          root.myZones["zones"][0].y=1;
//          root.myZones["zones"][0].dx=1;
//          root.myZones["zones"][0].dy=1;
//          root.zones[0].y = 0;
//          root.zones[0].x = 0;
//          var ddx = root.myZones["zones"][0].dx;
//          var ddy = root.myZones["zones"][0].dy;
//          root.zones[0].width = _width/2;
//          root.zones[0].height = _height/2;
//          var _zone2_ = {};
//          _zone2_.x = 2;
//          _zone2_.y = 1;
//          _zone2_.dx = 1;
//          _zone2_.dy = 1;
//          _zone2_.type = "camera";
//          _zone2_.qml_path = "";
//          root.addZoneEmpty(JSON.stringify(_zone2_));
//          root.innerType = "set";
//          root.globSignalsObject.tabTypeChanged(root.innerType);
//      }
      if(root.myZones.length ===0)
      {
          //console.error("addZone root.myZones.length ===0")
          root.cols = 32;
          root.rows = 32;
          root.myZones= {};
          root.myZones["rows"] = root.rows;
          root.myZones["cols"] = root.cols;
          root.myZones["ratioX"] = root.ratioX;
          root.myZones["ratioY"] = root.ratioY;
          //root.myZones["grid_type"] = root.currentPresset;
          root.myZones["setName"] = root.setName;
          //root.myZones["setId"] = root.setId;
          root.myZones["zones"] = [];
          console.error("addZone2 " , JSON.stringify(root.myZones));
      }

      //console.error("addZone root.isSetChanged = ", root.isSetChanged);
      var _zone_ = {};


      if(zoneObj)
      {
          _zone_ = JSON.parse(zoneObj);
      }
      var date = Qt.formatDate(new Date(),"dd.MM.yyyy")
      var time = Qt.formatTime(new Date(),"hh:mm:ss")
      var md5awd = date+time;
      var md5str = "";
      md5str = Qt.md5(md5awd);
      _zone_.guid = md5str;

      //      var _zoneObj = {};
      //      _zoneObj["x"] = zoneObj.x
      //      _zoneObj["y"] = zoneObj.y
      //      _zoneObj["dx"] = zoneObj.dx
      //      _zoneObj["dy"] = zoneObj.dy
      //      _zoneObj["type"] = zoneObj.type
      //      _zoneObj["key2"] = zoneObj.key2
      //      _zoneObj["qml_path"] = zoneObj.qml_path;

      for(var i2=0;i2<root.myZones["zones"].length;i2++)
      {
          var elemZone = root.myZones["zones"][i2];
          if(elemZone.isEmpty)
          {
              //console.error("EMPTY ZONE FOUND");
//              root.myZones["zones"][i2].x = elemZone.x;
//              root.myZones["zones"][i2].y = elemZone.y;
//              root.myZones["zones"][i2].dx = elemZone.dx;
//              root.myZones["zones"][i2].dy = elemZone.dy;
              root.myZones["zones"][i2].params = _zone_.params;
              root.myZones["zones"][i2].isEmpty = false;
              root.myZones["zones"][i2].qml_path = _zone_.qml_path;
              root.zones[i2].innerIndex = root.zones.length+1;
              root.zones[i2].z = 10;
              root.zones[i2].params=root.myZones["zones"][i2].params;
              root.zones[i2].type = root.myZones["zones"][i2].type;

              root.zones[i2].y = (root.myZones["zones"][i2].y-1)*_height;
              root.zones[i2].x = (root.myZones["zones"][i2].x-1)*_width;
              var ddx = root.myZones["zones"][i2].dx;
              var ddy = root.myZones["zones"][i2].dy;
              root.zones[i2].width = _width * ddx ;
              root.zones[i2].height = _height * ddy;
              root.zones[i2].qml_path = root.myZones["zones"][i2].qml_path;
              return;
          }
      }
      if(root.isPresetChanged)
      {
          if(root.zones.length+1> root.maximumCams)
          {
              return;
          }
      }
      var _zone  = selectionComponent.createObject(pluginsGrid, {compIndex:root.zones.length+1});
      //console.error("TYPE OF COMPONENTS = ",root.qmltypeof(_zone,"custom_zone_object"));
      _zone_.isEmpty = _zone_.qml_path === ""?true:false;
      _zone_.innerIndex = root.zones.length+1;
      _zone.z = 10;

      _zone.params=_zone_.params;
      _zone.type = _zone_.type;
      _zone.qml_path = _zone_.qml_path;
      root.myZones["zones"].push(_zone_);

      if(_zone_.x>pluginsGrid.columns)
      {
          _zone_.x = 1;
      }
      if(_zone_.y>pluginsGrid.rows)
      {
          _zone_.y = 1;
      }
      if(( _zone_.dx)>pluginsGrid.columns)
      {
          _zone_.dx = pluginsGrid.columns;
      }
      if(( _zone_.dy)>pluginsGrid.rows)
      {
          _zone_.dy = pluginsGrid.rows;
      }
      _zone.col = _zone_.x;
    _zone.row = _zone_.y;
    _zone.dx = _zone_.dx;
    _zone.dy = _zone_.dy;
      _zone.y = (_zone_.y-1)*_height;
      _zone.x = (_zone_.x-1)*_width;
      var ddx = _zone_.dx;
      var ddy = _zone_.dy;
      _zone.width = _width * ddx ;
      _zone.height = _height * ddy;
      root.zones.push(_zone);
      update();
      //console.error("MY ZONES = " , JSON.stringify(root.myZones));
  }
  function deleteZone(index)
  {
      //root.isSetChanged = true;
      //console.error("delete index = ",index);
      //console.error("root.myZones.length = ",root.myZones["zones"].length);
      //console.error("root.zones.length = ", root.zones.length);
      if(index>=0 && index <root.myZones["zones"].length)
      {
          for( var i = 0; i < root.myZones["zones"].length; i++)
          {
              if ( i === index)
              {
                  console.error("index found",index);
                  if(root.zones.length >0)
                  {
                      root.zones[i].destroy();
                      root.zones.splice(i, 1);
                  }
                  root.myZones["zones"].splice(i, 1);
              }
          }
      }
  }
  function deleteZone2(comp)
  {
      root.isSetChanged = true;
      console.error("delete comp = ",comp);
      console.error("root.myZones.length = ",root.myZones["zones"].length);
      console.error("root.zones.length = ", root.zones.length);

      for( var i = 0; i < root.myZones["zones"].length; i++)
      {
          if ( comp === root.zones[i])
          {
              console.error("comp found",i);
              root.zones[i].destroy();
              root.zones.splice(i, 1);
              root.myZones["zones"].splice(i, 1);
          }
      }
  }
  function getCurrIndex(comp)
  {
      var index = -1;
      for( var i = 0; i < root.myZones["zones"].length; i++)
      {
          if ( comp === root.zones[i])
          {
              console.error("comp found",i);
              index = i;
          }
      }
      return index;
  }
  function getCurrIndex2Comp(comp)
  {
      var index = -1;
      for( var i = 0; i < root.myZones["zones"].length; i++)
      {
          if ( comp === root.zones[i].zoneObject)
          {
              console.error("comp found",i);
              index = i;
          }
      }
      return index;
  }
  function zoneChanged(index)
  {
      //root.isSetChanged = true;
      //console.error("delete comp = ",comp);
      console.error("root.myZones.length = ",root.myZones["zones"].length);
      console.error("root.zones.length = ", root.zones.length);
      for( var i = 0; i < root.zones.length; i++)
      {
          if ( index === i)
          {
              root.zones[i].forceActiveFocus();
          }
      }
  }
  function zoneChanged2(index,params)
  {
      //root.isSetChanged = true;
      //console.error("delete comp = ",comp);
      console.error("root.myZones.length = ",root.myZones["zones"].length);
      console.error("root.zones.length = ", root.zones.length);
      for( var i = 0; i < root.myZones["zones"].length; i++)
      {
          if ( index === i)
          {
              var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
              var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
              console.error("compAAAAAAAAAAAAAAAAAAAA found zoneChanged2",JSON.stringify(params));
              if(params !== null)
              {
                  root.zones[i].type = params.type;
                  root.myZones["zones"][i].type = params.type;
                  root.zones[i].params = params.params;
                  root.myZones["zones"][i].params = params.params;
                  root.zones[i].qml_path = params.qml_path;
                  root.myZones["zones"][i].qml_path = params.qml_path;

                  root.zones[i].type = params.type;
                  if(params.x>pluginsGrid.columns)
                  {
                      params.x = 1;
                  }
                  if(params.y>pluginsGrid.rows)
                  {
                      params.y = 1;
                  }
                  if((params.x + params.dx)>pluginsGrid.columns)
                  {
                      params.dx = pluginsGrid.columns;
                  }
                  if((params.y + params.dy)>pluginsGrid.rows)
                  {
                      params.dy = pluginsGrid.rows;
                  }

                  root.zones[i].y = (params.y-1)*_height;
                  root.zones[i].x = (params.x-1)*_width;
                  root.myZones["zones"][i].y = params.y;
                  root.myZones["zones"][i].x = params.x;
                  root.myZones["zones"][i].dy = params.dy;
                  root.myZones["zones"][i].dx = params.dx;
                  var ddx = params.dx;
                  var ddy = params.dy;

                  root.zones[i].width = _width * ddx ;
                  root.zones[i].height = _height * ddy;

              }
              ttRefr2.ind = i
              ttRefr2.param = params.params;
              //ttRefr2.start();
              root.zones[i].refresh2(params.params);

              // root.zones.splice(i, 1);
              // root.myZones["zones"].splice(i, 1);
          }
      }
  }

  Timer
  {
      id:ttRefr2
      interval: 100
      triggeredOnStart: false
      repeat: false
      property int ind: -1
      property var param: null
      onTriggered:
      {
          root.zones[ind].refresh2(param);
      }
  }

  function clearZones()
  {
      for(var y = 0;y<root.zones.length;y++)
      {
          //root.zones[y].qml_path = "";
          root.zones[y].destroy();
      }
      root.zones = [];
      root.ratioX = 16;
      root.ratioY = 9;
      //root.myZones["zones"] = [];
  }


  function gridPositionToRect3(rect_width,rect_height,index,count,nw,nh)
  {
      if(nh==0 || nw==0)
      {
          nh=9;
          nw=16;
      };
      var calculated_rectangle = {};
      if((count<1)||(count>65))
      {
          calculated_rectangle["x"] = 1;
          calculated_rectangle["y"] = 1;
          calculated_rectangle["width"] = rect_width;
          calculated_rectangle["height"] = rect_height;
          return calculated_rectangle;
      }
      if(index>=count)
          index=0;
      var cROW=1,cCOL=1;
      while(cROW*cCOL<count)
      {
          var cH1=parseFloat(rect_height/(cROW+1));
          var cW1=parseFloat(rect_width/(cCOL+1));
          if(cH1*nw/nh<=cW1)
          {
              cCOL++;
          }
          else
          {
              cROW++;
          };
      }
      var cH=parseInt(rect_height/cROW);
      var cW=parseInt(rect_width/cCOL);
      if(parseFloat(cH*nw/nh)>cW)
      {
          cH=parseInt(cW*nh/nw);
      }
      else
      {
          cW=parseInt(cH*nw/nh);
      }
      var _row=parseInt(index/cCOL);
      var _col=parseFloat(index%cCOL);

      calculated_rectangle["width"] = cW;
      calculated_rectangle["height"] = cH;
      calculated_rectangle["row"] = _row;
      calculated_rectangle["col"] = _col;

      return calculated_rectangle;
  }

  function newPosotions(comp)
  {
      //root.isSetChanged = true;
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      var _zzones2 = root.myZones["zones"];
      var i1=-1;
      for(i1=0;i1<root.zones.length;i1++)
      {
          if(comp === root.zones[i1])
          {
              console.error("comp FOUND")
              break;
          }
      }
      if(i1>=0)
      {
          var _newX = Math.round(comp.x/_width);
          var _newY = Math.round(comp.y/_height);
          var _newDx = Math.round(comp.width/_width);
          var _newDy = Math.round(comp.height/_height);
          root.myZones["zones"][i1].x = _newX+1;
          root.myZones["zones"][i1].y = _newY+1;
          root.myZones["zones"][i1].dx = _newDx;
          root.myZones["zones"][i1].dy = _newDy;
          comp.x = _newX*_width;
          comp.y = _newY*_height;
          comp.width = _newDx*_width;
          comp.height = _newDy*_height;
          //root.globSignalsObject.zoneChangedFromMouse(i1, root.myZones["zones"][i1]);
      }

  }
  function newPosotions2(comp)
  {
      //root.isSetChanged = true;
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      var _zzones2 = root.myZones["zones"];
      var i1=-1;
      for(i1=0;i1<root.zones.length;i1++)
      {
          if(comp === root.zones[i1])
          {
              console.error("comp FOUND")
              break;
          }
      }
      if(i1>=0)
      {
          comp.x = (root.myZones["zones"][i1].x-1)*_width;
          comp.y = (root.myZones["zones"][i1].y-1)*_height;
          comp.width = root.myZones["zones"][i1].dx*_width;
          comp.height = root.myZones["zones"][i1].dy*_height;
          comp.col = root.myZones["zones"][i1].x;
          comp.row = root.myZones["zones"][i1].y;
          comp.dx = root.myZones["zones"][i1].dx;
          comp.dy = root.myZones["zones"][i1].dy;

          //root.globSignalsObject.zoneChangedFromMouse(i1, root.myZones["zones"][i1]);
      }

  }

  function m_resize(who)
  {
      var _zzones = root.zones;
      var _zzones2 = root.myZones["zones"];

      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      //console.error("m_resize = ",pluginsGrid.columns , pluginsGrid.rows , who)
      for(var i = 0;i<_zzones.length;i++)
      {
          _zzones[i].y = (_zzones2[i].y-1)*_height;
          _zzones[i].x = (_zzones2[i].x-1)*_width;

          var ddx = _zzones2[i].dx;
          var ddy = _zzones2[i].dy;
          _zzones[i].width = _width * ddx ;
          _zzones[i].height = _height * ddy;
      }
  }
  function startCreateObj(setName,setId)
  {

  }

  onSetNameChanged:
  {
      console.error("onSetNameChanged = ",root.setName,root.setId);

          root.clearZones();
          var _zones = customSets.getZone2(root.setName,root.setId);
          var zonesObject = [];
          console.error("123123123 _zones ", _zones, setName);
          try
          {
              zonesObject = JSON.parse(_zones);
              root.myZones = zonesObject;
          }
          catch(exception)
          {
              root.cols = 32;
              root.rows = 32;
              root.myZones["rows"] = root.rows;
              root.myZones["cols"] = root.cols;
              root.myZones["rows"] = root.rows;
              root.myZones["ratioX"] = root.ratioX;
              root.myZones["ratioY"] = root.ratioY;
              root.myZones["grid_type"] = root.currentPresset;
              root.myZones["setName"] = root.setName;
              root.myZones["setId"] = root.setId;
              root.myZones["zones"] = [];
              console.error("parse zones error ",exception,root.setName, _zones);
          }
          root.myZones["setName"] = root.setName;
          root.myZones["setId"] = root.setId;
          root.cols = root.myZones["cols"];
          root.rows = root.myZones["rows"];
          console.error("onSetNameChanged root.myZones[cols] = ", root.myZones["cols"]);
          console.error("onSetNameChanged root.myZones[rows] = ", root.myZones["rows"]);
          if(root.myZones["ratioX"] === null || root.myZones["ratioX"] === undefined)
          {
              root.ratioX = 16;
              console.error("onSetNameChanged root.myZones[rows] root.ratioX = 16")
          }
          else
          {
              root.ratioX = root.myZones["ratioX"];
              console.error("onSetNameChanged else root.myZones[rows] root.ratioX = ",root.ratioX)
          }
          if(root.myZones["ratioY"] === null || root.myZones["ratioY"] === undefined)
          {
              root.ratioY = 9;
              console.error("onSetNameChanged else root.myZones[rows] root.ratioY = 9")
          }
          else
          {
              root.ratioY = root.myZones["ratioY"];
              console.error("onSetNameChanged else root.myZones[rows] root.ratioY = ", root.ratioY)
          }
          console.error("var _zzones = root.myZones 1")
          var _zzones = root.myZones["zones"];
          console.error("var _zzones = root.myZones 2")
          var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
          var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
          console.error("var _zzones = root.myZones 3")
          for(var i = 0;i<_zzones.length;i++)
          {
              console.error("var _zzones = root.myZones 4")
              var _zone  = selectionComponent.createObject(pluginsGrid, {compIndex:i+1});
              if( _zone.status !== Component.Ready )
              {
                  if( _zone.status === Component.Error )
                  {
                      console.error("Error ddddddddddd:"+ _zone.errorString() );
                        return; // or maybe throw
                  }
              }
              console.error("var _zzones = root.myZones 5")
              _zzones[i].isEmpty = _zzones[i].qml_path === "" ?true:false;
              console.error("var _zzones = root.myZones 6")
               console.error("_zzones[i].isEmpty = "+ _zzones[i].isEmpty );
              _zzones[i].innerIndex = root.zones.length+1;
              _zone.innerIndex = _zzones[i].innerIndex;
              if(!_zzones[i].isEmpty)
              {
                _zone.params=_zzones[i].params;
              }
              else
              {
                  _zone.params = {};
                  _zzones[i].qml_path = "";
                  _zzones[i].type = "";
              }

              _zone.z = 10;
              _zone.col = _zzones[i].x;
              _zone.row = _zzones[i].y;
              _zone.dx = _zzones[i].dx;
              _zone.dy = _zzones[i].dy;


              console.error("create zone 1 ",JSON.stringify(_zzones[i]),JSON.stringify(_zzones[i].params),_zzones[i].type);
              //_zone.innerIndex = i;
              _zone.y = (_zzones[i].y-1)*_height;
              _zone.x = (_zzones[i].x-1)*_width;
              _zone.type = _zzones[i].type;

              var ddx = _zzones[i].dx;
              var ddy = _zzones[i].dy;

              _zone.width = _width * ddx ;
              _zone.height = _height * ddy;
              if(_zzones[i].guid)
              {
                _zone.guid=_zzones[i].guid;
              }
              else
              {
                  var date = Qt.formatDate(new Date(),"dd.MM.yyyy")
                  var time = Qt.formatTime(new Date(),"hh:mm:ss")
                  var md5awd = date+time;
                  var md5str = "";
                  md5str = Qt.md5(md5awd);
                  _zzones[i].guid = md5str
                  _zone.guid = _zzones[i].guid;
              }

              _zone.qml_path = _zzones[i].qml_path;
              _zone.isEmpty = _zzones[i].isEmpty;
              console.error("onSetNameChanged create zone 1  = ",_zone.width , _zone.height , _zone.guid , _zone.qml_path , _zone.isEmpty);

              if(_zone.type === "detailcamera")
              {
                  console.error("DETAL W = ",_zone.width)
                  console.error("DETAL H = ",_zone.height)
              }
              console.error("create zone 1 push zone to array");
              root.zones.push(_zone);

        }
      update();
  }
 Timer
 {
     id:testTimer
     triggeredOnStart: false
     interval: 500
     onTriggered:
     {
        root.width--;
        root.width++;
     }
     running: true
     repeat: false
 }
  onZonesChanged:
  {
  }
  Component
  {
     id: selectionComponent
     Rectangle
     {
         id: selComp
         //anchors.fill: parent
         color: selComp.type === "empty"? "transparent":"transparent"
         border {
             width:2
             color: "black"
         }
         objectName: "custom_zone_object"
         z:3
         property string guid:""
         property bool isMultiEnabled: false
         property int compIndex: -1
         property var params: null
         property bool isEmpty: true
         property int rulersSize: 10
         property var zoneObject : null
         property int innerIndex: -1
         property string qml_path: ""
         property string type: ""
         property string editColor: "white"//"#355DEC"
         property int col: -1
         property int row: -1
         property int dx: -1
         property int dy: -1
         property string isKey2Exist: ""
         property var bindinCameras: []
         property int currentBindingIndex: -1
         onBindinCamerasChanged:
         {
             checkMulti();
         }
         function checkMulti()
         {
             if(selComp.bindinCameras.length>0)
             {
                 selComp.isMultiEnabled = true;
                 if(selComp.currentBindingIndex >=0)
                 {
                    leftArrowImage.opacity = 0.7;
                 }
                 else
                 {
                     leftArrowImage.opacity = 0;
                 }
                 if(selComp.currentBindingIndex === selComp.bindinCameras.length-1)
                 {
                     rightArrowImage.opacity = 0;
                 }
                 else
                 {
                     rightArrowImage.opacity = 0.7;
                 }
             }
         }

         function nextCamera()
         {
             if(selComp.currentBindingIndex===selComp.bindinCameras.length-1)
                 return;
             selComp.currentBindingIndex++;
             checkMulti();
             selComp.zoneObject["key2"] = selComp.bindinCameras[selComp.currentBindingIndex]
         }
         function prevCamera()
         {
                 selComp.currentBindingIndex--;
                 checkMulti();
                 if(selComp.currentBindingIndex<0)
                 {
                      selComp.zoneObject["key2"] = selComp.isKey2Exist;
                     return;
                 }
                 selComp.zoneObject["key2"] = selComp.bindinCameras[selComp.currentBindingIndex]
         }


         onQml_pathChanged:
         {
             if(qml_path !=="")
             {
                 innerComponentLoader.source ="";
                 innerComponentLoader.source =  'file:///' +applicationDirPath+"/"+qml_path;
             }
             else
             {
                 innerComponentLoader.source ="";
             }
         }
         onFocusChanged:
         {
             if(selComp.focus === true)
             {
                 //selComp.border.color = "red";
                 selComp.z = 10;
                 selComp.editColor = "#355DEC";
                 for(var i = 0;i<root.zones.length;i++)
                 {
                     if(root.zones[i] === selComp)
                     {
                         console.error("focused comp found");
                         // root.myZones["zones"][i]["focused"] = true;
                     }
                     else
                     {
                         // root.myZones["zones"][i]["focused"] = false;
                     }
                 }

             }
             else
             {
                 selComp.editColor = "white";
                 selComp.z = 1;
             }
         }



         Image
         {
             id:leftArrowImage
             width: 32
             height: 32
             z:20
             anchors.left: parent.left
            // anchors.top: parent.top
             y:selComp.height/2 - 16
             source:"file:///"+applicationDirPath + "/images/white/arrow_left.svg"
             visible: selComp.isMultiEnabled
            opacity: 0.7
            MouseArea
            {
                anchors.fill: parent
                onClicked:
                {
                    selComp.prevCamera();

                }
            }
         }
         Image
         {
             id:rightArrowImage
             width: 32
             height: 32
             z:20
             anchors.right:  parent.right
             y:selComp.height/2 - 16
             //anchors.top: parent.top
             source:"file:///"+applicationDirPath + "/images/white/arrow_right.svg"
             visible: selComp.isMultiEnabled
             opacity: 0.7
             MouseArea
             {
                 anchors.fill: parent
                 onClicked:
                 {
                    selComp.nextCamera()
                 }
             }
         }
         Image
         {
             id:emptyImage
             //width: 32
             //height: 32
             anchors.fill: parent
             visible: selComp.type === "empty"?true:false
             source:"file:///"+applicationDirPath + "/images/logo_nrm.svg"
             MouseArea
             {
                 anchors.fill: parent
                 onClicked:
                 {

                 }
             }
         }
         Image
         {
             id:delImage
             width: 28
             height: 28
             anchors.top: parent.top
             anchors.topMargin: 5
             anchors.right: parent.right
             anchors.rightMargin: 5
             z:20
             visible: root.isEditor?true:false
             source: "file:///"+applicationDirPath + "/images/white/clear.svg"
             MouseArea
             {
                 id:delCompMouseArea
                 anchors.fill: parent
                 onClicked:
                 {
                     //selectionComponent.deleteLater();
                     var index = root.getCurrIndex(selComp);
                     root.globSignalsObject.zoneRemoved(index);
                     root.deleteZone2(selComp);
                 }
             }
         }
         MouseArea {
             anchors.fill: root.isEditor?parent:undefined
             visible: root.isEditor
             hoverEnabled: true
             propagateComposedEvents: true
             z:2
             drag{
                 target: parent
                 minimumX: 0
                 minimumY: 0
                 maximumX: parent.parent.width - parent.width
                 maximumY: parent.parent.height - parent.height
                 smoothed: true
             }
             onClicked:
             {
                 selComp.forceActiveFocus();
                 //mouse.accepted = false;
                 var camsParams = {};
                 camsParams["qml_path"] = selComp.qml_path;
                 camsParams["type"] = selComp.type;
                 camsParams["params"] = selComp.params;
                 var pString = JSON.stringify(camsParams);
                 var index = root.getCurrIndex(selComp);
                 root.globSignalsObject.zoneSelected(index,pString);
                 console.error("CLICKED ",index,pString);
                 console.error("CLICKED ",JSON.stringify(root.myZones));






                // var setStr =JSON.stringify(root.myZones);
                //console.error("1111111111 = ",root.setName,setStr);

                 mouse.accepted = false;
             }
             onDoubleClicked:
             {
                 //  parent.destroy();
             }
             onReleased:
             {

                 root.newPosotions(selComp);
                 selComp.forceActiveFocus();
                 mouse.accepted = false;
             }
         }
         Loader
         {
             id:innerComponentLoader
             anchors.fill: parent
             z:1
             function refresh1()
             {
                 innerComponentLoader.source = "";
                 if(selComp.qml_path !=="")
                 {
                     innerComponentLoader.source =  'file:///' +applicationDirPath+"/"+qml_path;
                 }
                 else
                 {
                     innerComponentLoader.source ="";
                 }
             }
//             QMapViewer {
//                     id: qMapViewer
//                     z: 1000
//                     jsonDataFileName: "777.json"

//                 }
             onStatusChanged:
             {
                 if(innerComponentLoader.status == Loader.Ready)
                 {
                     selComp.zoneObject = innerComponentLoader.item;
                     console.error(" 250602 005 ");
                     if(integration_flag.value !== "SDK")
                     {

                         if ( selComp.zoneObject.tab_id !== undefined && root.globSignalsObject.tabUniqId !== undefined)
                         {
                           selComp.zoneObject.tab_id = root.globSignalsObject.tabUniqId;
                           console.error(" 250602 006 tab_id " + selComp.zoneObject.tab_id );
                         }
                     }
                     console.error(" 250602 007 ");

                     selComp.zoneObject.width = selComp.width;
                     selComp.zoneObject.height =selComp.height;

                     if(selComp.zoneObject.compIndex !== undefined)
                         selComp.zoneObject.compIndex = selComp.compIndex;

                     console.error("SET GLOBAL COMPONENT2222 qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",selComp.type);
                     //selComp.zoneObject.globalComponent = root.globSignalsObject;
                     if(selComp.zoneObject.globSignalsObject)
                     {
                        // console.error("SET GLOBAL COMPONENT2333333333 qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq",selComp.zoneObject.globSignalsObject , root.globSignalsObject);
                        selComp.zoneObject.globSignalsObject = Qt.binding(function(){ return root.globSignalsObject});
                     }

                     if(selComp.zoneObject.hasOwnProperty("globalComponentObject"))
                     {
                          selComp.zoneObject.globalComponentObject = Qt.binding(function(){ return root.globSignalsObject});
                         //console.error("MAP FOUND");
                     }
                     if(selComp.zoneObject.hasOwnProperty("isRealtime"))
                     {
                          selComp.zoneObject.isRealtime = Qt.binding(function(){ return root.isRealtime});
                         //console.error("MAP FOUND");
                     }

                     if(selComp.params)
                     {
                         for (var propertyName in selComp.params)
                         {

                             var prop1 = selComp.params[propertyName];
                             if(prop1.type === "var")
                             {
                                 if(propertyName === "key2")
                                 {

                                    selComp.isKey2Exist = prop1.value[0];
                                        selComp.bindinCameras= customSets.getBindingCameras(prop1.value[0]);
                                     console.error("LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL = ",JSON.stringify(selComp.bindinCameras))
                                         if(selComp.bindinCameras.length >0)
                                         {
                                             selComp.isMultiEnabled = true;
                                             console.error("LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL = " , selComp.bindinCameras.length)
//                                             for(var i1= 0;i1<selComp.bindinCameras.length;i1++)
//                                             {
//                                                 console.error("LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL = " , selComp.bindinCameras[i1])
//                                                 if(selComp.bindinCameras[i1]===prop1.value[0])
//                                                 {
//                                                     console.error("LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL = 22222")
//                                                    leftArrowImage.opacity=0;
//                                                 }
//                                             }
                                         }

                                         console.error("params2222 type of = ",typeof selComp.zoneObject.hasOwnProperty(propertyName) , propertyName,prop1.value[0]);
                                         selComp.zoneObject[propertyName] = prop1.value[0];
                                 }
                                 else
                                {

                                     if(prop1.value.length >1)
                                     {
                                         console.error("params1111 type of = ",typeof selComp.zoneObject.hasOwnProperty(propertyName) , propertyName,prop1.value[0]);
                                         selComp.zoneObject[propertyName] = prop1.value;
                                     }
                                     else
                                     {
                                         console.error("params2222 type of = ",typeof selComp.zoneObject.hasOwnProperty(propertyName) , propertyName,prop1.value[0]);
                                         selComp.zoneObject[propertyName] = prop1.value[0];
                                     }
                                 }
                             }
                             if(selComp.zoneObject.isFullscreen !== null && selComp.zoneObject.isFullscreen !== undefined )
                             {
                                 if(root.innerType === "camera")
                                 {
                                     selComp.zoneObject.isFullscreen = true;
                                 }
                             }

                             if(prop1.type === "function")
                             {
                                 console.error("params type function  = ",typeof selComp.zoneObject.hasOwnProperty(propertyName) , propertyName,prop1.value.length);
                                 var argsCount = prop1.value.length;
                                 if(argsCount === 0)
                                 {
                                     selComp.zoneObject[propertyName]();
                                 }
                                 else if(argsCount === 1)
                                 {
                                     selComp.zoneObject[propertyName](prop1.value[0]);
                                 }
                                 else if(argsCount === 2)
                                 {
                                     selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1]);
                                 }
                                 else if(argsCount === 3)
                                 {
                                     selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2]);
                                 }
                                 else if(argsCount === 4)
                                 {
                                     selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3]);
                                 }
                                 else if(argsCount === 5)
                                 {
                                     selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3],prop1.value[4]);
                                 }
                                 else if(argsCount === 6)
                                 {
                                     selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3],prop1.value[4],prop1.value[5]);
                                 }
                                 else if(argsCount === 7)
                                 {
                                     selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3],prop1.value[4],prop1.value[5],prop1.value[6]);
                                 }
                                 else if(argsCount === 8)
                                 {
                                     selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3],prop1.value[4],prop1.value[5],prop1.value[6],prop1.value[7]);
                                 }
                                 else if(argsCount === 9)
                                 {
                                     selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3],prop1.value[4],prop1.value[5],prop1.value[6],prop1.value[7],prop1.value[8]);
                                 }
                                 else if(argsCount === 10)
                                 {
                                     selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3],prop1.value[4],prop1.value[5],prop1.value[6],prop1.value[7],prop1.value[8],prop1.value[9]);
                                 }
                             }
                         }


                     }
                     innerComponentLoader.item.z=10;
                     if(selComp.type === "map")
                     {
                         if(eventsMaps.value === "true")
                         {
                            selComp.zoneObject.showCameraWindow(-1,-1,-1,-1,root.key2ForMap);
                         }
                     }
                 }
             }
         }
         function deinit()
         {
             innerComponentLoader.source = "";
         }
         function refresh2(params)
         {
             if(params)
             {
                 console.error("refresh2 1");
                 for (var propertyName in params)
                 {
                     console.error("refresh2 3");
                     var prop1 = params[propertyName];
                     if(prop1.type === "var")
                     {


                         if(propertyName === "key2")
                         {

                            selComp.isKey2Exist = prop1.value[0];
                                selComp.bindinCameras= customSets.getBindingCameras(prop1.value[0]);
                             console.error("LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL = ",JSON.stringify(selComp.bindinCameras))
                                 if(selComp.bindinCameras.length >0)
                                 {
                                     selComp.isMultiEnabled = true;
                                     console.error("LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL = " , selComp.bindinCameras.length)
//                                             for(var i1= 0;i1<selComp.bindinCameras.length;i1++)
//                                             {
//                                                 console.error("LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL = " , selComp.bindinCameras[i1])
//                                                 if(selComp.bindinCameras[i1]===prop1.value[0])
//                                                 {
//                                                     console.error("LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL = 22222")
//                                                    leftArrowImage.opacity=0;
//                                                 }
//                                             }
                                 }

                                 console.error("params2222 type of = ",typeof selComp.zoneObject.hasOwnProperty(propertyName) , propertyName,prop1.value[0]);
                                 selComp.zoneObject[propertyName] = prop1.value[0];
                         }
                         else
                        {

                             if(prop1.value.length >1)
                             {
                                 console.error("params1111 type of = ",typeof selComp.zoneObject.hasOwnProperty(propertyName) , propertyName,prop1.value[0]);
                                 selComp.zoneObject[propertyName] = prop1.value;
                             }
                             else
                             {
                                 console.error("params2222 type of = ",typeof selComp.zoneObject.hasOwnProperty(propertyName) , propertyName,prop1.value[0]);
                                 selComp.zoneObject[propertyName] = prop1.value[0];
                             }
                         }



                     }
                     if(selComp.zoneObject.isFullscreen !== null && selComp.zoneObject.isFullscreen !== undefined )
                     {
                         if(root.innerType === "camera")
                         {
                             selComp.zoneObject.isFullscreen = true;
                         }
                     }
                     if(prop1.type === "function")
                     {
                         console.error("params type of = ",typeof selComp.zoneObject.hasOwnProperty(propertyName) , propertyName,prop1.value.length);
                         var argsCount = prop1.value.length;
                         if(argsCount === 0)
                         {
                             selComp.zoneObject[propertyName]();
                         }
                         else if(argsCount === 1)
                         {
                             selComp.zoneObject[propertyName](prop1.value[0]);
                         }
                         else if(argsCount === 2)
                         {
                             selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1]);
                         }
                         else if(argsCount === 3)
                         {
                             selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2]);
                         }
                         else if(argsCount === 4)
                         {
                             selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3]);
                         }
                         else if(argsCount === 5)
                         {
                             selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3],prop1.value[4]);
                         }
                         else if(argsCount === 6)
                         {
                             selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3],prop1.value[4],prop1.value[5]);
                         }
                         else if(argsCount === 7)
                         {
                             selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3],prop1.value[4],prop1.value[5],prop1.value[6]);
                         }
                         else if(argsCount === 8)
                         {
                             selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3],prop1.value[4],prop1.value[5],prop1.value[6],prop1.value[7]);
                         }
                         else if(argsCount === 9)
                         {
                             selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3],prop1.value[4],prop1.value[5],prop1.value[6],prop1.value[7],prop1.value[8]);
                         }
                         else if(argsCount === 10)
                         {
                             selComp.zoneObject[propertyName](prop1.value[0],prop1.value[1],prop1.value[2],prop1.value[3],prop1.value[4],prop1.value[5],prop1.value[6],prop1.value[7],prop1.value[8],prop1.value[9]);
                         }
                     }

                 }
                 if(selComp.type === "map")
                 {
                     if(eventsMaps.value === "true")
                     {
                        selComp.zoneObject.showCameraWindow(-1,-1,-1,-1,root.key2ForMap);
                     }
                 }


             }
             root.update();
             console.error("refresh2 qmlpath= ",innerComponentLoader.source);
         }

         Rectangle
         {
             width: 5
             height: parent.height
             visible: root.isEditor
             color: selComp.editColor
             z:15
             anchors.left: parent.left
             anchors.verticalCenter: parent.verticalCenter
             MouseArea {
                 anchors.fill: parent
                 hoverEnabled: true
                 drag{ target: parent; axis: Drag.XAxis }
                 cursorShape: Qt.SizeHorCursor

                 onMouseXChanged: {
                     if(drag.active ){

                         if(selComp.x>0)
                         {
                             selComp.width = selComp.width - mouseX
                             console.error("selComp.width = ",selComp.width,mouseX,selComp.x)
                             if(selComp.width < 50)
                             {
                                 selComp.width = 50
                                 return;
                             }
                             selComp.x = selComp.x + mouseX;

                             selComp.forceActiveFocus();
                         }
                         else
                         {
                             if(mouseX>0)
                             {
                                 selComp.width = selComp.width - mouseX
                                 //console.error("selComp.width = ",selComp.width,mouseX,selComp.x)
                                 selComp.x = selComp.x + mouseX;
                                 if(selComp.width < 50)
                                     selComp.width = 50;
                                 selComp.forceActiveFocus();
                             }
                         }
                     }
                 }
                 onReleased:
                 {
                     console.error("onReleased left")
                     root.newPosotions(selComp);
                     selComp.forceActiveFocus();
                 }
             }
         }
         Rectangle
         {
             width: 5
             height: parent.height
             visible: root.isEditor
             color: selComp.editColor
             anchors.right: parent.right
             anchors.verticalCenter: parent.verticalCenter
             z:15
             MouseArea {
                 anchors.fill: parent
                 drag{ target: parent; axis: Drag.XAxis }
                 cursorShape: Qt.SizeHorCursor
                 onMouseXChanged: {
                     if(drag.active)
                     {
                         if(pluginsGrid.width>selComp.x+selComp.width)
                         {
                             selComp.width = selComp.width + mouseX
                             console.error("selComp.width = ",selComp.width,mouseX,selComp.x)
                             if(selComp.width < 50)
                                 selComp.width = 50
                             selComp.forceActiveFocus();
                         }
                         else
                         {
                             if(mouseX < selComp.x+selComp.width)
                             {
                                 selComp.width = selComp.width + mouseX
                                 console.error("selComp.width = ",selComp.width,mouseX,selComp.x)
                                 if(selComp.width < 50)
                                     selComp.width = 50
                                 selComp.forceActiveFocus();
                             }
                         }
                     }
                 }
                 onReleased:
                 {
                     console.error("onReleased right")
                     root.newPosotions(selComp);
                     selComp.forceActiveFocus();
                 }
             }
         }
         Rectangle
         {
             width: parent.width
             height: 5
             visible: root.isEditor
             color: selComp.editColor
             anchors.horizontalCenter: parent.horizontalCenter
             anchors.top: parent.top
             z:15
             MouseArea {
                 anchors.fill: parent
                 drag{ target: parent; axis: Drag.YAxis }
                 cursorShape: Qt.SizeVerCursor
                 onMouseYChanged: {
                     if(drag.active){
                         if(selComp.y>=0)
                         {
                             selComp.height = selComp.height - mouseY
                             selComp.y = selComp.y + mouseY
                             if(selComp.height < 50)
                                 selComp.height = 50
                             selComp.forceActiveFocus();
                         }
                         else
                         {
                             // selComp.y=0;
                         }
                     }
                 }
                 onReleased:
                 {
                     console.error("onReleased top")
                     root.newPosotions(selComp);
                     selComp.forceActiveFocus();
                 }
             }
         }
         Rectangle
         {
             width: parent.width
             height: 5
             visible: root.isEditor
             color: selComp.editColor
             z:15
             anchors.horizontalCenter: parent.horizontalCenter
             anchors.bottom: parent.bottom
             MouseArea
             {
                 anchors.fill: parent
                 drag{ target: parent; axis: Drag.YAxis }
                 cursorShape: Qt.SizeVerCursor
                 onMouseYChanged:
                 {
                     if(drag.active){
                         if(pluginsGrid.height >= selComp.y+selComp.height)
                         {
                             pluginsGrid.height=selComp.y+selComp.height;
                             selComp.height = selComp.height + mouseY;
                             if(selComp.height < 50)
                                 selComp.height = 50
                             selComp.forceActiveFocus();
                         }
                     }
                 }
                 onReleased:
                 {
                     console.error("onReleased bottom")
                     root.newPosotions(selComp);
                     selComp.forceActiveFocus();
                 }
             }
         }
         Rectangle
         {
             width: 5
             height: 5
             visible: root.isEditor
             color: selComp.editColor
             z:20
             //anchors.horizontalCenter: parent.horizontalCenter
             anchors.bottom: parent.bottom
             anchors.left: parent.left
             MouseArea
             {
                 anchors.fill: parent
                 drag{ target: parent; axis: Drag.XandYAxis }
                 cursorShape: Qt.SizeBDiagCursor
                 onMouseYChanged:
                 {
                     if(drag.active){
                         if(pluginsGrid.height >= selComp.y+selComp.height)
                         {
                             pluginsGrid.height=selComp.y+selComp.height;
                             selComp.height = selComp.height + mouseY;
                             if(selComp.height < 50)
                                 selComp.height = 50
                             selComp.forceActiveFocus();
                         }
                         if(selComp.x>0)
                         {
                             selComp.width = selComp.width - mouseX
                             console.error("selComp.width = ",selComp.width,mouseX,selComp.x)
                             if(selComp.width < 50)
                             {
                                 selComp.width = 50
                                 return;
                             }
                             selComp.x = selComp.x + mouseX;

                             selComp.forceActiveFocus();
                         }
                         else
                         {
                             if(mouseX>0)
                             {
                                 selComp.width = selComp.width - mouseX
                                 //console.error("selComp.width = ",selComp.width,mouseX,selComp.x)
                                 selComp.x = selComp.x + mouseX;
                                 if(selComp.width < 50)
                                     selComp.width = 50;
                                 selComp.forceActiveFocus();
                             }
                         }
                     }
                 }
                 onReleased:
                 {
                     console.error("onReleased bottom")
                     root.newPosotions(selComp);
                     selComp.forceActiveFocus();
                 }
             }
         }
         Rectangle
         {
             width: 5
             height: 5
             visible: root.isEditor
             color: selComp.editColor
             z:20
             //anchors.horizontalCenter: parent.horizontalCenter
             anchors.top: parent.top
             anchors.left: parent.left
             MouseArea
             {
                 anchors.fill: parent
                 drag{ target: parent; axis: Drag.XandYAxis }
                 cursorShape: Qt.SizeFDiagCursor
                 onMouseYChanged:
                 {
                     if(drag.active){

                         if(selComp.y>=0)
                         {
                             selComp.height = selComp.height - mouseY
                             selComp.y = selComp.y + mouseY
                             if(selComp.height < 50)
                                 selComp.height = 50
                             selComp.forceActiveFocus();
                         }
                         else
                         {

                         }
                         if(selComp.x>0)
                         {
                             selComp.width = selComp.width - mouseX
                             console.error("selComp.width = ",selComp.width,mouseX,selComp.x)
                             if(selComp.width < 50)
                             {
                                 selComp.width = 50
                                 return;
                             }
                             selComp.x = selComp.x + mouseX;

                             selComp.forceActiveFocus();
                         }
                         else
                         {
                             if(mouseX>0)
                             {
                                 selComp.width = selComp.width - mouseX
                                 //console.error("selComp.width = ",selComp.width,mouseX,selComp.x)
                                 selComp.x = selComp.x + mouseX;
                                 if(selComp.width < 50)
                                     selComp.width = 50;
                                 selComp.forceActiveFocus();
                             }
                         }
                     }
                 }
                 onReleased:
                 {
                     console.error("onReleased bottom")
                     root.newPosotions(selComp);
                     selComp.forceActiveFocus();
                 }
             }
         }
         Rectangle
         {
             width: 5
             height: 5
             visible: root.isEditor
             color: selComp.editColor
             z:20
             //anchors.horizontalCenter: parent.horizontalCenter
             anchors.top: parent.top
             anchors.right:  parent.right
             MouseArea
             {
                 anchors.fill: parent
                 drag{ target: parent; axis: Drag.XandYAxis }
                 cursorShape: Qt.SizeBDiagCursor
                 onMouseYChanged:
                 {
                     if(drag.active){

                         if(selComp.y>=0)
                         {
                             selComp.height = selComp.height - mouseY
                             selComp.y = selComp.y + mouseY
                             if(selComp.height < 50)
                                 selComp.height = 50
                             selComp.forceActiveFocus();
                         }
                         else
                         {

                         }
                         if(pluginsGrid.width>selComp.x+selComp.width)
                         {
                             selComp.width = selComp.width + mouseX
                             console.error("selComp.width = ",selComp.width,mouseX,selComp.x)
                             if(selComp.width < 50)
                                 selComp.width = 50
                             selComp.forceActiveFocus();
                         }
                         else
                         {
                             if(mouseX < selComp.x+selComp.width)
                             {
                                 selComp.width = selComp.width + mouseX
                                 console.error("selComp.width = ",selComp.width,mouseX,selComp.x)
                                 if(selComp.width < 50)
                                     selComp.width = 50
                                 selComp.forceActiveFocus();
                             }
                         }



                     }
                 }
                 onReleased:
                 {
                     console.error("onReleased bottom")
                     root.newPosotions(selComp);
                     selComp.forceActiveFocus();
                 }
             }
         }
         Rectangle
         {
             width: 5
             height: 5
             visible: root.isEditor
             color: selComp.editColor
             z:20
             //anchors.horizontalCenter: parent.horizontalCenter
             anchors.bottom: parent.bottom
             anchors.right:  parent.right
             MouseArea
             {
                 anchors.fill: parent
                 drag{ target: parent; axis: Drag.XandYAxis }
                 cursorShape: Qt.SizeFDiagCursor
                 onMouseYChanged:
                 {
                     if(drag.active){


                         if(pluginsGrid.width>selComp.x+selComp.width)
                         {
                             selComp.width = selComp.width + mouseX
                             console.error("selComp.width = ",selComp.width,mouseX,selComp.x)
                             if(selComp.width < 50)
                                 selComp.width = 50
                             selComp.forceActiveFocus();
                         }
                         else
                         {
                             if(mouseX < selComp.x+selComp.width)
                             {
                                 selComp.width = selComp.width + mouseX
                                 console.error("selComp.width = ",selComp.width,mouseX,selComp.x)
                                 if(selComp.width < 50)
                                     selComp.width = 50
                                 selComp.forceActiveFocus();
                             }
                         }
                         if(pluginsGrid.height >= selComp.y+selComp.height)
                         {
                             pluginsGrid.height=selComp.y+selComp.height;
                             selComp.height = selComp.height + mouseY;
                             if(selComp.height < 50)
                                 selComp.height = 50
                             selComp.forceActiveFocus();
                         }



                     }
                 }
                 onReleased:
                 {
                     console.error("onReleased bottom")
                     root.newPosotions(selComp);
                     selComp.forceActiveFocus();
                 }
             }
         }
     }
}
  Rectangle
  {
        id:middleRect
        color: "transparent"
        //color: root.isSets?"lightgray":"black"
        //anchors.fill: parent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: mainLoader.top
        anchors.bottomMargin: mainLoader.componentMain.height>0?60:0

        //anchors.bottomMargin: 150
        Canvas
        {
            id:cellCanvas
            z:1
            //anchors.fill: parent
            anchors.centerIn: parent
            width: gridRect.width
            height: gridRect.height
            onPaint: {
                //return;
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, cellCanvas.width, cellCanvas.height);
                ctx.fillStyle = root.isEditor ? root.separatorColor : "transparent";
                //ctx.fillStyle = root.isSets?IVColors.get("Colors/Stroke new/StSeparatorThemed"):"transparent";
                ctx.fillRect(0,0,cellCanvas.width ,cellCanvas.height);
                if(root.isEditor)
                {
                    ctx.lineWidth = 1;
                    //ctx.fillStyle = "green";
                   // ctx.fillRect(0,0,cellCanvas.width ,cellCanvas.height);
                    var cols = root.cols;
                    var rows = root.rows;
                    var _width =(pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ;//- pluginsGrid.columnSpacing;
                    var _height = (pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1))  ;//- pluginsGrid.rowSpacing;
                    ctx.lineWidth = 1;
                    ctx.fillStyle =root.mainColor//"#4d4d4d";
                    console.error("_height = ",_height);
                    for(var x = 0;x<cols;x++)
                    {
                        for(var y =0;y<rows;y++)
                        {
                            ctx.fillRect(x*_width,y*_height,_width-1 ,_height-1);
                        }
                    }
                }
                if (cellCanvas.fill)
                   ctx.fill();
                if (cellCanvas.stroke)
                    ctx.stroke();
            }
        }
        Rectangle
        {
          id:gridRect
          //anchors.fill: parent
          anchors.centerIn: parent
          width: parent.width
          height: parent.height
          color: "transparent"
          z:2

          Rectangle
          {
              id:pluginsGrid
              anchors.fill:  parent
              color:"transparent"
              property int rows: root.rows
              property int columns: root.cols
//              border.color: "red"
//              border.width: 4

              Component.onCompleted: {
                cellCanvas.requestPaint();
              }

              MouseArea
              {
                  id:dragMA
                  anchors.fill: root.fastEdit && !root.isEditor?parent:undefined
                  hoverEnabled: false
                  visible: root.fastEdit && !root.isEditor

                  readonly property var intValdiator: IntValidator {}
                  property int minimumWidth: intValdiator.top
                  property int minimumHeight: intValdiator.top

                  property var dragableCam: null
                  property var underDragablecCam: null
                  propagateComposedEvents: true
                  z:30
                  property int oldX: 0
                  property int oldY: 0
                  property int newX: 0
                  property int newY: 0
                  property int oldCamX: 0
                  property int oldCamY: 0

                  property int drCamRow :0
                  property int drCamCol :0
                  property int drCamRS :0
                  property int drCamCS :0

                  property int underCamRow :0
                  property int underCamCol :0
                  property int underCamRS :0
                  property int underCamCS :0
                  property bool ctrlPressed: false



                  onClicked:
                  {
                     // if (mouse.button === Qt.LeftButton && mouse.modifier === 67108864)
                      //{
                        //
                     // }
                      mouse.accepted = false;
                  }

                  onPositionChanged: {
                      console.error("onPositionChanged = = " , mouse.modifiers , Qt.ControlModifier, mouse.button , Qt.LeftButton);
                      //if (mouse.modifiers === 67108864)
                      //{
                          console.error("onPositionChanged = = " );

                          if(pluginsGrid.children.length  <2 || root.isFullscreen)
                          {
                              return;
                          }
                          var isUnderFound = false;
                          for (var i = 0; i < pluginsGrid.children.length; i++)
                          {
                              var isViewer2222 = root.qmltypeof(pluginsGrid.children[i],"custom_zone_object") ;

                              var posx = pluginsGrid.children[i].x;
                              var posy = pluginsGrid.children[i].y;

                              var posx2 = posx + pluginsGrid.children[i].width;
                              var posy2 = posy+ pluginsGrid.children[i].height;

                              if( (mouseX>posx) && (mouseX <posx2) && (mouseY>posy) && (mouseY <posy2) && isViewer2222 )
                              {
                                  if(pluginsGrid.children[i] !== dragableCam || pluginsGrid.children[i].isEmpty === true)
                                  {
                                      underDragablecCam = pluginsGrid.children[i];
                                      isUnderFound = true;

                                      underCamRow = underDragablecCam.row;
                                      underCamCol = underDragablecCam.col;
                                      underCamRS = underDragablecCam.dx;
                                      underCamCS = underDragablecCam.dy;

                                  }
                              }
                          }
                          if(!isUnderFound)
                          {
                              underDragablecCam = null;
                          }

                          if(underDragablecCam !== null)
                          {
                              console.error("under= ",underDragablecCam,underDragablecCam.col,underDragablecCam.row,underDragablecCam.dx,underDragablecCam.dy);
                          }
                          else
                          {
                              console.error("under else= ");
                          }

                          if(dragableCam !== null && dragableCam !== undefined)
                          {

                              dragableCam.x = oldCamX + (mouseX - newX);
                              dragableCam.y = oldCamY + (mouseY - newY);
                          }
                          //mouse.accepted = false;
                      //}
                      //else
                      //{
                      //    mouse.accepted = false;
                      //}
                  }


                  onPressAndHold:
                  {
                     // console.error("MOUSE onPressAndHold")
                     mouse.accepted = false;
                      //isNeedHold = true;
                  }
                  onPressed:
                  {
                      console.error("onPRESSED = = " , mouse.modifiers , Qt.ControlModifier, mouse.button , Qt.LeftButton);
                     // mouse.accepted = false;
                      if(mouse.button === Qt.LeftButton && mouse.modifiers === 67108864)
                      {
                          console.error("onPRESSED222 = = " , mouse.modifiers);
                          if(pluginsGrid.children.length  <2 || root.isFullscreen)
                          {
                              mouse.accepted = false;
                              return;
                          }

                          oldX = mouseX;
                          oldY = mouseY;
                          newX = mouseX;
                          newY = mouseY;
                          for (var i = 0; i < pluginsGrid.children.length; i++)
                          {
                              var isViewer2222 = qmltypeof(pluginsGrid.children[i],"custom_zone_object")
                              var posx = pluginsGrid.children[i].x;
                              var posy = pluginsGrid.children[i].y;
                              var posx2 = posx + pluginsGrid.children[i].width;
                              var posy2 = posy+ pluginsGrid.children[i].height;

                              if( (mouseX>posx) && (mouseX <posx2) && (mouseY>posy) && (mouseY <posy2) && isViewer2222 )
                              {
                                  //console.error("children is ptz enable = ",pluginsGrid.children[i].zoneObject.isPTZ);
                                  //if(pluginsGrid.children[i].zoneObject.isRealtime === false ||pluginsGrid.children[i].zoneObject.isPTZ )
                                  //{
                                  //    mouse.accepted = false;
                                  //    return;
                                  //}
                                  dragableCam = pluginsGrid.children[i];
                                  dragableCam.z=20;
                                  oldCamX = dragableCam.x;
                                  oldCamY = dragableCam.y;
                                 // console.error("oldCam =",dragableCam ,dragableCam.col,dragableCam.row,dragableCam.dx,dragableCam.dy );

                                  drCamRow = dragableCam.row;
                                  drCamCol = dragableCam.col;
                                  drCamRS = dragableCam.dy;
                                  drCamCS = dragableCam.dx;
                                  //mouse.accepted = true;
                              }
                          }
                      }
                      else
                      {
                          mouse.accepted = false;
                      }

                        //
                  }
                  onReleased:
                  {
                      console.error("onReleased = = " , mouse.modifiers , Qt.ControlModifier, mouse.button , Qt.LeftButton);
                     //if (mouse.button == Qt.LeftButton && mouse.modifiers === 67108864)
                     // {


                          if(dragableCam!=null && underDragablecCam !=null )
                          {
                              dragableCam.z=10;
                              underDragablecCam.z=10;
                          }
                          if(pluginsGrid.children.length  <2 || root.isFullscreen)
                          {
                              mouse.accepted = false;
                              return;
                          }
                          if(dragableCam!==null && underDragablecCam !==null )
                          {
                              dragableCam.z=10;
                              underDragablecCam.z=10;
                              //if(dragableCam.zoneObject.isRealtime === false)
                              //{
                              //    mouse.accepted = false;
                              //    return;
                             // }
                              var pos = root.myZones["zones"]
                              var dragPos = 0;
                              var underPos = 0;
                              for(var i=0;i<pos.length;i++)
                              {
                                  var posX = pos[i].x;
                                  var posY = pos[i].y;
                                  var posDx = pos[i].dx;
                                  var posDy = pos[i].dy;
                                  //console.error(i,posX,posY,posDx,posDy)
                                  if( (posX === drCamCol) && (posY === drCamRow) && (posDx === drCamCS) && (posDy === drCamRS))
                                  {
                                      dragPos = i;
                                      //console.error("DRAG POS FOUND = ", dragPos)
                                  }
                                  if( (posX === underCamCol) && (posY === underCamRow) && (posDx === underCamCS) && (posDy === underCamRS))
                                  {
                                      underPos = i;
                                      //console.error("UNDER DRAG POS FOUND = ", underPos);
                                  }
                              }

                               console.error("тут 5" , dragPos, underPos)
                              var undPosX = pos[underPos].x
                              var undPosY = pos[underPos].y
                              var undPosDx = pos[underPos].dx;
                              var undPosDy = pos[underPos].dy;


                              var drgPosX = pos[dragPos].x
                              var drgPosY = pos[dragPos].y
                              var drgPosDx = pos[dragPos].dx;
                              var drgPosDy = pos[dragPos].dy;
       //console.error("тут 6")
                              pos[dragPos].x = undPosX
                              pos[dragPos].y = undPosY
                              pos[dragPos].dx = undPosDx
                              pos[dragPos].dy = undPosDy

                              pos[underPos].x = drgPosX
                              pos[underPos].y = drgPosY
                              pos[underPos].dx = drgPosDx
                              pos[underPos].dy = drgPosDy

                              var dragPosObject = pos[dragPos];
                              var underDragPosObject = pos[underPos];
                              pos[dragPos] = underDragPosObject;
                              pos[underPos] = dragPosObject;
    //                          var zoneObjectDrag = root.zones[dragPos];
    //                          var zoneObjectUnder = root.zones[underPos];

                              root.swapElements(root.zones,dragPos,underPos);
    //                          root.zones[dragPos] = zoneObjectUnder;
    //                          root.zones[underPos] = zoneObjectDrag;

                              root.myZones["zones"] = pos;
                              //console.error(JSON.stringify(root.myZones["zones"]));
               // console.error("тут 7")

                              drCamRow =0;
                              drCamCol =0;
                              drCamRS =0;
                              drCamCS =0;

                              underCamRow =0;
                              underCamCol =0;
                              underCamRS =0;
                              underCamCS =0;
                              root.newPosotions2(dragableCam);
                              root.newPosotions2(dragableCam);
                              root.newPosotions2(underDragablecCam);
                              root.newPosotions2(underDragablecCam);
                              //console.error("тут 8")
                              root.globSignalsObject.setSaved("");


                          }
                          else
                          {
                              //if(dragableCam)
                              //{
                                  dragableCam.row = drCamRow;
                                  dragableCam.col = drCamCol;
                                  dragableCam.dy = drCamRS;
                                  dragableCam.dx = drCamCS;
                                  dragableCam.x = oldCamX;
                                  dragableCam.y = oldCamY;
                              //}
                          }

                          dragableCam = null;
                          underDragablecCam = null;
                      //}
                      //else
                      //{

                      //    mouse.accepted = false;
                      //}

                    //console.error("isNeedHold = ",isNeedHold)

                  }
                  onEntered:{
                      //console.error("MOUSE onEntered")
                  }
              }
          }
        }
    }
  Loader {
      id:mainLoader
      width: parent.width
      height: mainLoader.componentMain.height>0?mainLoader.componentMain.height:0
      onHeightChanged:
      {
          resizeTimer.start();
          console.error("HEIGHT CHANGED = ",mainLoader.height , mainLoader.componentMain.height)
      }

      anchors.bottom: parent.bottom
      asynchronous: false
      property var componentMain: null
      function create1()
      {
          var qmlFile2 = 'file:///' + applicationDirPath +  "/qtplugins/iv/viewers/archiveplayer/IVArchivePlayer.qml";
          mainLoader.source = qmlFile2;
      }
      function refresh()
      {
          mainLoader.destroy1();
          mainLoader.create1();
      }
      function destroy1()
      {
          if(mainLoader.status !== Loader.Null)
              mainLoader.source = "";
      }
      onStatusChanged:
      {
          //archive.value = "true";
          if (mainLoader.status === Loader.Ready)
          {
              console.error("START ARCHIVE COMMON")
              mainLoader.componentMain = mainLoader.item;
              //ch250529 mainLoader.componentMain.arc_vers = 1;
              mainLoader.componentMain.arc_vers = 2;
              //e
              mainLoader.componentMain.common_panel = true;
              mainLoader.componentMain.key2 = "common_panel";
              mainLoader.componentMain.tab_id = root.globSignalsObject.tabUniqId;

              console.error("250530 002 tabUniqId ", root.globSignalsObject.tabUniqId );
              mainLoader.componentMain.startPlugin();
              console.error("END ARCHIVE COMMON")
          }
          if(mainLoader.status === Loader.Error)
          {
              console.error("mainLoader error");
          }
          if(mainLoader.status === Loader.Null)
          {

          }
      }
      Component.onCompleted:
      {
      }
  }
}

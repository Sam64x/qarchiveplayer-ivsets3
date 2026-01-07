import QtQml 2.3
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
//import iv.plugins.loader 1.0
//import iv.guicomponents 1.0
//import iv.components.windows 1.0
import iv.sets.sets3 1.0

Rectangle{
  id: root  
  anchors.fill: parent
  property bool isEditor: false
  property string setName: ""
  property string camName: ""
  property var zones: []
  property var myZones: []
  property int cols: 32
  property int rows: 32
  property var globSignalsObject: null
  property bool isSetChanged: false
  smooth: true
  onIsEditorChanged:
  {
      cellCanvas.requestPaint();
  }

  onGlobSignalsObjectChanged:
  {
      if(root.globSignalsObject !== null & root.globSignalsObject !== undefined)
      {
        myGlobConnect.target = Qt.binding(function() {return root.globSignalsObject;});
      }
  }

  color: "black"

/*
1) починить растягиваниие и перемещение ok
2) вписать в отдельное приложение
3) сделать вс методы для добавления зон и наборов
4) сохранение в файл нового набора.ok
*/

Connections
{
    id:myGlobConnect
   // target:root.globSignalsObject
    onSetAdded:
    {
        //console.error("ivsezone onSetAdded setname = ",setname);
        root.setName = setname;
    }
    onSetSelected:
    {
        root.setName = setname;
    }
    onSetSaved:
    {
        //console.error("ivsezone onSetSaved setname = ",setname , "old set name = ",root.setName);
        if(setname === "")
        {
            root.saveSet(root.setName)
        }
        else
        {
            root.saveSet(setname);
            root.setName = setname;
            root.globSignalsObject.setNameChanged(root.setName,setname)
        }
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

        root.addZone(zone);
    }
    onZoneChanged:
    {
//        var pars = newparams;
//        var _index = index;
//        if(pars)
//        {
//            console.error("onZoneChanged = ", JSON.stringify(pars));
//            root.zoneChanged2(_index,pars);

//        }
    }
    onTabSelected:
    {
        root.setName = tabname;
    }



    onSetPresset1:
    {
        root.setPresset1();
    }
    onSetPresset2:
    {
        root.setPresset2();
    }
    onSetPresset3:
    {
        root.setPresset3();
    }
}
IVCustomSets
{
    id:customSets
}

QtObject
{
    id:globalComponent
    signal command(string cmd)
    onCommand: function(cmd)
    {
        if(cmd)
        {
            switch(cmd)
            {
                case 'viewers:fullscreen':
                {

                    break;
                }
            }
        }
    }
}

function setPresset1()
{
    var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
    var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
    var zonesSize = root.zones.length;
    var ii1 = 0;
    var yy1 = 0;
    for(var i=0;i<zonesSize;i++)
    {
        if(i<4)
        {
            root.zones[i].x = ii1*(_width*8);
            root.zones[i].y = yy1*(_height*8);
            ii1++;
            if(ii1>3)
            {
                ii1 = 0;
                yy1++;
            }
        }
        else if(i>=4 && i<8)
        {
            root.zones[i].x = ii1*(_width*8);
            root.zones[i].y = yy1*(_height*8);
            ii1++;
            if(ii1>3)
            {
               ii1=0;
               yy1++;
            }

        }
        else if(i>7 && i<12)
        {
            root.zones[i].x = ii1*(_width*8);
            root.zones[i].y = yy1*(_height*8);
            ii1++;
            if(ii1>3)
            {
               ii1=0;
               yy1++;
            }
        }
        else if(i>11 && i<16)
        {
            root.zones[i].x = ii1*(_width*8);
            root.zones[i].y = yy1*(_height*8);
            ii1++;
            if(ii1>3)
            {
               ii1=0;
               yy1++;
            }
        }
        else
        {
            root.zones[i].x = 0;
            root.zones[i].y = 0;
        }
        root.zones[i].width = _width*8;
        root.zones[i].height = _height*8;
        root.newPosotions(root.zones[i]);
    }
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
    var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
    var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
    var zonesSize = root.zones.length;
    var ii1 = 0;
    var yy1 = 0;
    for(var i=0;i<zonesSize;i++)
    {
        if(i<1)
        {
            root.zones[i].x = ii1*(_width*32);
            root.zones[i].y = yy1*(_height*8);
            //ii1++;
            yy1++;
            root.zones[i].width = _width*32;
            root.zones[i].height = _height*8;
            root.newPosotions(root.zones[i]);
        }
        else if(i>=1 && i<=4)
        {
            root.zones[i].x = ii1*(_width*8);
            root.zones[i].y = yy1*(_height*8);
            ii1++;
            if(ii1>4)
            {
               ii1=0;
               yy1++;
            }
            root.zones[i].width = _width*8;
            root.zones[i].height = _height*8;
            root.newPosotions(root.zones[i]);
        }
        else if(i>=5 && i<=8)
        {
            root.zones[i].x = ii1*(_width*8);
            root.zones[i].y = yy1*(_height*8);
            ii1++;
            if(ii1>8)
            {
               ii1=0;
               yy1++;
            }
            root.zones[i].width = _width*8;
            root.zones[i].height = _height*8;
            root.newPosotions(root.zones[i]);

        }
        else if(i>=9 && i<=12)
        {
            root.zones[i].x = ii1*(_width*8);
            root.zones[i].y = yy1*(_height*8);
            ii1++;
            if(ii1>12)
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


onColsChanged:
{
    root.myZones["cols"] = root.cols;
   // var _rect = gridPositionToRect3(root.width,root.height,0,1,root.x_ratio,root.y_ratio)
   // gridRect.width = _rect.width;
  // gridRect.height= _rect.height;
    root.m_resize();
    cellCanvas.requestPaint();
}
onRowsChanged:
{
    root.myZones["rows"] = root.rows;
   // var _rect = gridPositionToRect3(root.width,root.height,0,1,root.x_ratio,root.y_ratio)
  //  gridRect.width = _rect.width;
   // gridRect.height= _rect.height;
    root.m_resize();
    cellCanvas.requestPaint();
}



 function saveSet(newSetName)
 {
     var setStr = JSON.stringify(root.myZones);
     //console.error("1111111111 = ",root.setName,newSetName,setStr);

     customSets.saveSet(root.setName,newSetName,setStr);
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

  function updateCells()
  {
      cellCanvas.requestPaint();
  }
  function addZone(zoneObj)
  {
      root.isSetChanged = true;
      var _zone_ = {};
      if(zoneObj)
      {
          _zone_ = JSON.parse(zoneObj);
      }

//      var _zoneObj = {};
//      _zoneObj["x"] = zoneObj.x
//      _zoneObj["y"] = zoneObj.y
//      _zoneObj["dx"] = zoneObj.dx
//      _zoneObj["dy"] = zoneObj.dy
//      _zoneObj["type"] = zoneObj.type
//      _zoneObj["key2"] = zoneObj.key2
//      _zoneObj["qml_path"] = zoneObj.qml_path;
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      root.myZones["zones"].push(_zone_);
      var _zone  = selectionComponent.createObject(pluginsGrid, {});
      _zone.z = 10;
      _zone.params=_zone_.params;
      _zone.qml_path = _zone_.qml_path;
      _zone.y = (_zone_.y)*_height;
      _zone.x = (_zone_.x)*_width;
      _zone.type = _zone_.type;
      var ddx = _zone_.dx;
      var ddy = _zone_.dy;
      _zone.width = _width * ddx -1;
      _zone.height = _height * ddy-1;
     root.zones.push(_zone);
  }
function deleteZone(index)
{
    root.isSetChanged = true;
    //console.error("delete index = ",index);
    //console.error("root.myZones.length = ",root.myZones["zones"].length);
    //console.error("root.zones.length = ", root.zones.length);
    if(index>=0 && index <root.myZones["zones"].length)
    {
        for( var i = 0; i < root.myZones["zones"].length; i++)
        {
            if ( i === index)
            {
                //console.error("index found",index);
                root.zones[i].destroy();
                root.zones.splice(i, 1);
                root.myZones["zones"].splice(i, 1);
            }
        }
    }
}
  function deleteZone2(comp)
  {
    root.isSetChanged = true;
    //console.error("delete comp = ",comp);
    //console.error("root.myZones.length = ",root.myZones["zones"].length);
    //console.error("root.zones.length = ", root.zones.length);

    for( var i = 0; i < root.myZones["zones"].length; i++)
    {
        if ( comp === root.zones[i])
        {
            //console.error("comp found",i);
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
            //console.error("comp found",i);
            index = i;
        }
    }
    return index;
}
  function zoneChanged2(index,params)
  {
      root.isSetChanged = true;
      //console.error("delete comp = ",comp);
      //console.error("root.myZones.length = ",root.myZones["zones"].length);
      //console.error("root.zones.length = ", root.zones.length);

        for( var i = 0; i < root.myZones["zones"].length; i++)
        {
            if ( index === i)
            {

                  //console.error("comp found",i);
                  root.zones[i].params = params;
                  root.myZones["zones"][i].params = params;
                  root.zones[i].refresh2(params);

                 // root.zones.splice(i, 1);
                 // root.myZones["zones"].splice(i, 1);
            }
        }

  }

  Component.onCompleted:
  {
      root.m_resize();
      cellCanvas.requestPaint();
  }
  onWidthChanged:
  {
      root.m_resize();
      cellCanvas.requestPaint();
  }
  onHeightChanged:
  {

      root.m_resize();
      cellCanvas.requestPaint();
  }
  function clearZones()
  {
      for(var y = 0;y<root.zones.length;y++)
      {
          //root.zones[y].qml_path = "";
          root.zones[y].destroy();
      }
      root.zones = [];
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
      return calculated_rectangle;
  }

  function newPosotions(comp)
  {
      root.isSetChanged = true;
      var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
      var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
      var _zzones2 = root.myZones["zones"];
      var i1=-1;
      for(i1=0;i1<root.zones.length;i1++)
      {
          if(comp === root.zones[i1])
          {
              //console.error("comp FOUND")
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
          //console.error("comp new x",_newX);
          //console.error("comp new y",_newY);
          //console.error("comp new dx",_newDx ,comp.width,_width);
          //console.error("comp new dy",_newDy);
          comp.x = _newX*_width;
          comp.y = _newY*_height;
          comp.width = _newDx*_width;
          comp.height = _newDy*_height;
      }

  }

function m_resize()
{
    var _zzones = root.zones;
    var _zzones2 = root.myZones["zones"];
    var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
    var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
    //console.error("_width = ",_width)
    for(var i = 0;i<_zzones.length;i++)
    {
        _zzones[i].y = (_zzones2[i].y-1)*_height;
        _zzones[i].x = (_zzones2[i].x-1)*_width;
        if(_zzones2[i].dx>pluginsGrid.columns)
        {
            _zzones2[i].dx = pluginsGrid.columns;
        }
        if(_zzones2[i].dy>pluginsGrid.rows)
        {
            _zzones2[i].dy = pluginsGrid.rows;
        }

        var ddx = _zzones2[i].dx;
        var ddy = _zzones2[i].dy;
        _zzones[i].width = _width * ddx ;
        _zzones[i].height = _height * ddy;
    }
}
Timer
{
    id:isNotEditorTime
    triggeredOnStart: false
    interval: 200
    repeat: false
    onTriggered:
    {
        root.clearZones();
        var _zones = customSets.getZone(root.setName);
        var zonesObject = [];
        try
        {
          zonesObject = JSON.parse(_zones);
          myZones = zonesObject;
        }
        catch(exception)
        {
            root.myZones["cols"] = root.cols;
            root.myZones["rows"] = root.rows;
            root.myZones["zones"] = [];
            console.error("parse zones error ",exception);
        }
        root.cols = root.myZones["cols"];
        root.rows = root.myZones["rows"];
        var _zzones = root.myZones["zones"];
        var _width =((pluginsGrid.width / (pluginsGrid.columns?pluginsGrid.columns:1)) ) ;//- pluginsGrid.columnSpacing;
        var _height = ((pluginsGrid.height / (pluginsGrid.rows?pluginsGrid.rows:1)) ) ;//- pluginsGrid.rowSpacing;
        for(var i = 0;i<_zzones.length;i++)
        {
            var _zone  = selectionComponent.createObject(pluginsGrid, {});
            _zone.params=_zzones[i].params;
            _zone.z = 10;
            //console.error("create zone ",JSON.stringify(_zzones[i].params));
            //_zone.innerIndex = i;
            _zone.y = (_zzones[i].y-1)*_height;
            _zone.x = (_zzones[i].x-1)*_width;
            _zone.type = _zzones[i].type;
            _zone.qml_path = _zzones[i].qml_path;
            var ddx = _zzones[i].dx;
            var ddy = _zzones[i].dy;
            _zone.width = _width * ddx ;
            _zone.height = _height * ddy;
            root.zones.push(_zone);
        }
    }
}
  onSetNameChanged:
  {
    console.error("onSetNameChanged = ",root.setName);
    isNotEditorTime.start();
  }
  onCamNameChanged:
  {

      root.cols = 1
      root.rows = 1
      var _zone  = selectionComponent.createObject(pluginsGrid, {});
      _zone.params={"key2":root.camName,"quality":"#000_FULLSCREEN"};
      _zone.z = 10;
     // console.error("create zone ",JSON.stringify(_zzones[i].params));
      //_zone.innerIndex = i;
      _zone.y = 0;
      _zone.x = 0;
      _zone.type = "camera"
      _zone.qml_path = "qtplugins/iv/viewers/viewer/IVViewer.qml";
      var ddx = 1;
      var ddy = 1;
      _zone.width = pluginsGrid.width;
      _zone.height =pluginsGrid.height;
      root.zones.push(_zone);
  }
  onZonesChanged:
  {
  }
  Rectangle
  {
      id:gridRect
      anchors.fill: parent
      color: "black"
      Rectangle
      {
          id:pluginsGrid
          anchors.fill:  parent
          color:"transparent"
          property int rows: root.rows
          property int columns: root.cols
          z:2
          Component.onCompleted:
          {
            cellCanvas.requestPaint();
          }
      }
      Canvas
      {
          id:cellCanvas
          z:1
          anchors.fill: gridRect
          onPaint:
          {

              var ctx = getContext("2d");
              ctx.clearRect(0, 0, cellCanvas.width, cellCanvas.height);
              ctx.fillStyle = root.isEditor?"#14a3b3":"black";
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
                  ctx.fillStyle = "white";
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
      Component
      {
         id: selectionComponent

         Rectangle {
             id: selComp
//             border {
//                 width: 2
//                 color: root.isEditor?"white":"black"

//             }
             function refresh2(params)
             {

                 if(selComp.params)
                 {
                     for (var propertyName in params)
                     {
                         console.error("ttt ",propertyName ,selComp.params[propertyName] );
                        innerComponentLoader.item[propertyName] = Qt.binding(function(){ return selComp.params[propertyName]});
                     }
                 }
                console.error("refresh2 qmlpath= ",innerComponentLoader.source);
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
                         root.deleteZone2(selComp);
                     }
                 }
             }
             property int innerIndex: -1
             property string qml_path: ""
             property string type: ""
             z:3
             onQml_pathChanged:
             {
                 if(qml_path !=="")
                 {
                     innerComponentLoader.source ="";
                      console.error("AAAAAAAAAAAAAAAAAA ", 'file:///' +applicationDirPath+"/"+qml_path);
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
                     selComp.border.color = "transparent";
                     selComp.z = 10;
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
                     selComp.border.color = "white";
                     selComp.z = 1;
                 }
             }

             property var params: null
             color: "black"
             property int rulersSize: 10

            MouseArea {
                 anchors.fill: parent
                 visible: root.isEditor
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
                     selComp.forceActiveFocus()
                     mouse.accepted = false;
                     var camsParams = {};
                     camsParams["qml_path"] = selComp.qml_path;
                     camsParams["type"] = selComp.type;
                     camsParams["params"] = selComp.params;
                     var pString = JSON.stringify(camsParams);
                     var index = root.getCurrIndex(selComp);
                     root.globSignalsObject.zoneSelected(index,pString);
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
                     //source: 'file:///' +applicationDirPath+"/"+qml_path
                     anchors.fill: parent
//                     anchors.leftMargin: 2
//                     anchors.rightMargin: 2
//                     anchors.topMargin: 2
//                     anchors.bottomMargin: 2
                     z:1


                     onStatusChanged:
                     {
                         if(innerComponentLoader.status == Loader.Ready)
                         {
                             innerComponentLoader.item.width = Qt.binding(function(){ return selectionComponent.width;});
                             innerComponentLoader.item.height = Qt.binding(function(){ return selectionComponent.height;});
                             if(selComp.params)
                             {
                                 for (var propertyName in selComp.params)
                                 {
                                     console.error("ttt ",propertyName ,selComp.params[propertyName] );
                                    innerComponentLoader.item[propertyName] = Qt.binding(function(){ return selComp.params[propertyName]});
                                 }
                             }
                             innerComponentLoader.item.z=10;
                             if(innerComponentLoader.item["running"] !== undefined )
                             {
                                 innerComponentLoader.item["running"] = true;
                             }


/*
                             innerComponentLoader.item.key2 = Qt.binding(function(){ return selComp.key2});
                             innerComponentLoader.item.running = true;
                             innerComponentLoader.item.z=3;

                             //innerComponentLoader.itemanchors.fill = Qt.binding(function(){return viewerLoader;});
                             //innerComponentLoader.item.key2 = Qt.binding(function(){return root.key2;});
                             innerComponentLoader.item.video = '#000_MULTISCREEN';
                             //innerComponentLoader.item.trackIn = innerComponentLoader.item.trackFrame;
//                             root.safeSetProperty(viewerLoader.componentViewer, 'video', Qt.binding(function()
//                             {
//                               return '#000_MULTISCREEN';
//                             }));
//                             root.safeSetProperty(viewerLoader.componentViewer, 'running', Qt.binding(function(){
//                               return true;
//                             }));
//                             root.safeSetProperty(viewerLoader.componentViewer, 'viewer_command_obj', Qt.binding(function(){
//                               return root.viewer_command_obj;
//                             }));
                            //root.safeSetProperty(viewerLoader.componentViewer, 'trackIn', Qt.binding(function(){
                             //  return ivButtonPane.trackOut}));
                            // root.safeSetProperty(viewerLoader.componentViewer, 'isParentCreationInterrupted', Qt.binding(function() {
                            //   return root.isCreationInterrupted;
                            // }));
                            */
                         }
                     }
                 }

             Rectangle {
                 width: 5
                 height: 25
                 visible: root.isEditor
                 //radius: rulersSize
                 color: "red"
                 z:15
                 //anchors.horizontalCenter: parent.left
                 anchors.left: parent.left
                 anchors.leftMargin: 5
                 anchors.verticalCenter: parent.verticalCenter
                 MouseArea {
                     anchors.fill: parent
                     drag{ target: parent; axis: Drag.XAxis }
                     onMouseXChanged: {
                         if(drag.active){

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
             Rectangle {
                 width: 5
                 height: 25
                 visible: root.isEditor
                // radius: rulersSize
                 color: "red"
                 //anchors.horizontalCenter: parent.right
                 anchors.right: parent.right
                 anchors.rightMargin: 5
                 anchors.verticalCenter: parent.verticalCenter
                 z:15
                 MouseArea {
                     anchors.fill: parent
                     drag{ target: parent; axis: Drag.XAxis }
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
             Rectangle {
                 width: 25
                 height: 5
                 visible: root.isEditor
                // radius: rulersSize
                 x: parent.x / 2
                // y: 0
                 color: "red"
                 anchors.horizontalCenter: parent.horizontalCenter
                // anchors.verticalCenter: parent.top
                 anchors.top: parent.top
                 anchors.topMargin: 5
                 z:15
                 MouseArea {
                     anchors.fill: parent
                     drag{ target: parent; axis: Drag.YAxis }
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
             Rectangle {
                 width: 25
                 height: 5
                 visible: root.isEditor
                 //radius: rulersSize
                 x: parent.x / 2
                 y: parent.y
                 color: "red"
                 z:15
                 anchors.horizontalCenter: parent.horizontalCenter
                 //anchors.verticalCenter: parent.bottom
                 anchors.bottom: parent.bottom
                 anchors.bottomMargin: 5
                 MouseArea {
                     anchors.fill: parent
                     drag{ target: parent; axis: Drag.YAxis }
                     onMouseYChanged: {
                         if(drag.active){
                             if(pluginsGrid.height=selComp.y+selComp.height)
                             {
                                selComp.height = selComp.height + mouseY
                                if(selComp.height < 50)
                                    selComp.height = 50
                                selComp.forceActiveFocus();
                             }
                             else
                             {
                                 //selComp.height = pluginsGrid.height-selComp.y-1;
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
  }
}

import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import QtQuick.Dialogs 1.1
import iv.sets.sets3 1.0
Rectangle
{
    /*
    1) Сделать прессеты из свг - не работают
    2) Сделать слоты в прессетах + свободное редактирование
    3) Сделать виртуальный набор с просмотром одиночной камеры + добавление камер в этот набор
    4) Не обосраться на совещании - работает
    */

    id:root
   // anchors.fill: parent
    color: "transparent"
    property var globSignalsObject: null
    property string setName: ""
    property int currentPresset: -1
    property int currentPressetLimit: -1
    property bool isAutoMode:false
    property var slotsArray: []
   function getZonesFromSETS()
    {
        zonesmodel.clear();
        root.globSignalsObject.getZonesFromSet();

        //getZonesFromSETS

    }

    onVisibleChanged:
    {
        zonesmodel.clear();
        if(root.visible === true)
        {
            slotsModel.clear();
            root.globSignalsObject.getZonesFromSet();
        }
        else
        {
            slotsModel.clear();
        }
    }

    function autoSetAll()
    {
        for(var i = 0;i<zonesmodel.count;)
        {
            var zItem = zonesmodel.get(i);
            var isEmptyFound = false;
            for(var j=0;j<slotsModel.count;j++)
            {
                var sItem = slotsModel.get(j);
                if(sItem.isEmpty)
                {
                    var newParams = {};
                    newParams.isEmpty=false;
                    newParams.key2=zItem.key2;
                    newParams.x=sItem.x;
                    newParams.y=sItem.y;
                    newParams.dx=sItem.dx;
                    newParams.dy=sItem.dy;
                    newParams.type=zItem.type;
                    newParams.params=zItem.params;
                    newParams.qml_path=zItem.qml_path;
                    slotsModel.set(j,newParams);
                    root.globSignalsObject.zoneChanged(j,newParams);
                    isEmptyFound = true;
                    zonesmodel.remove(i);
                    break;
                }
                else
                {
                    continue;
                }
            }
            if(zonesmodel.count !== 0 && root.isAutoMode === true)
            {
                root.addEmptySlot();
                var newParams = {};
                newParams.isEmpty=false;
                newParams.key2=zItem.key2;
                newParams.x=zItem.x;
                newParams.y=zItem.y;
                newParams.dx=zItem.dx;
                newParams.dy=zItem.dy;
                newParams.type=zItem.type;
                newParams.params=zItem.params;
                newParams.qml_path=zItem.qml_path;
                root.addEmptySlot();
                root.addCameraEmptySlot(newParams);
               // root.globSignalsObject.zoneChanged(j,newParams);
                zonesmodel.remove(i);
            }
//            else
//            {
//                break;
//            }
        }

//        var zoneItem = zonesmodel.get(index);
//        for(var i = 0;i<slotsModel.count;i++)
//        {
//            var slotItem = slotsModel.get(i);
//            if(slotItem.isEmpty)
//            {
//                slotsModel.setProperty(i,"isEmpty",false);
//                slotsModel.setProperty(i,"key2",zoneItem.key2);
//                slotsModel.setProperty(i,"type",zoneItem.type);
//                zonesmodel.remove(index);
//                break;
//            }
//        }
    }
    function getStrFromModel(model)
    {
        root.slotsArray = [];

        for(var i =0;i<model.count;i++)
        {
            var modelItem = model.get(i);
            if(modelItem.isEmpty)
            {
                //{\"slotIndex\":1,\"x\":1,\"y\":1,\"dx\":32,\"dy\":32,\"type\":\"empty\",\"qml_path\":\"\",\"params\":{}}
                var strItem ={};// "{\"slotIndex\":"+i+",\"type\":\"empty\",\"qml_path\":\"\",\"params\":{}}}"
                strItem.slotIndex = i+1;
                strItem.type = "empty";
                strItem.qml_path = "";
                strItem.params = {};
                root.slotsArray.push(strItem);
            }
            else
            {
                //{\"type\":\"camera\",\"qml_path\":\"qtplugins/iv/viewers/realtimeviewer/IVRealtimeViewer.qml\",\"params\":{\"key2\":\"\",\"running\":true,\"video\":\"#000_MULTISCREEN\"}
                var strItem ={};// "{\"slotIndex\":"+i+",\"type\":\"empty\",\"qml_path\":\"\",\"params\":{}}}"
                strItem.slotIndex = i+1;
                strItem.type = "empty";
                strItem.qml_path = "qtplugins/iv/viewers/realtimeviewer/IVRealtimeViewer.qml";
                strItem.params = {};
                strItem.params.key2 = modelItem.key2;
                strItem.params.video = "#000_MULTISCREEN";
                strItem.params.running = true;
                root.slotsArray.push(strItem);
            }
        }
        var str1 = JSON.stringify(root.slotsArray);
        //root.globSignalsObject.slotsChanged(str1,root.currentPresset);
    }
    function setPresset(index)
    {
        if(root.currentPresset === 1)
        {
            var itemObj = {};
             var i2 = 0;
             var i3 = 0;
             var i4 = 0;
             var i5 = 0;

            for(var i1 = 0; i1<16;i1++)
            {
                if(i1<4)
                {
                    if(slotsModel.count>i1)
                    {
                        var slotItem = slotsModel.get(i1);
                        //if(slotItem.isEmpty === false)
                       // {
                            slotItem.x=i2*8 +1;
                            slotItem.y=1;
                            slotItem.dx=8;
                            slotItem.dy=8;
                            slotsModel.setProperty(i1,"x",i2*8 +1);
                            slotsModel.setProperty(i1,"y",1);
                            slotsModel.setProperty(i1,"dx",8);
                            slotsModel.setProperty(i1,"dy",8);
                            var newParams2 = {};
                           newParams2.isEmpty=false;
                           newParams2.key2=slotItem.key2;
                           newParams2.x=i2*8 +1;
                           newParams2.y=1;
                           newParams2.dx=8;
                           newParams2.dy=8;
                           newParams2.type=slotItem.type;
                           newParams2.params=slotItem.params;
                           newParams2.qml_path=slotItem.qml_path;
                           //zonesmodel.append(newParams);
                           slotsModel.set(index,newParams2);
                           root.globSignalsObject.zoneChanged(i1,newParams2);

                            i2++;
                            continue;
                        //}
                    }
                    else
                    {
                        itemObj.isEmpty = true;
                        itemObj.key2 = "Свободное место";
                        itemObj.x=i2*8 +1;
                        itemObj.y=1;
                        itemObj.dx=8;
                        itemObj.dy=8;
                        itemObj.type="empty";
                        itemObj.params={};
                        itemObj.qml_path ="";
                        root.addEmptySlotWithParams(itemObj);
                        //root.addCameraEmptySlot(itemObj);
                        i2++;
                    }
                }
                else if(i1>3 && i1 <8)
                {
                    if(slotsModel.count>i1)
                    {
                        var slotItem = slotsModel.get(i1);
                        //if(slotItem.isEmpty === false)
                        //{
                            slotItem.x=i3*8 +1;
                            slotItem.y=9;
                            slotItem.dx=8;
                            slotItem.dy=8;
                            slotsModel.setProperty(i1,"x",i3*8 +1);
                            slotsModel.setProperty(i1,"y",9);
                            slotsModel.setProperty(i1,"dx",8);
                            slotsModel.setProperty(i1,"dy",8);
                            var newParams2 = {};
                            newParams2.isEmpty=false;
                           newParams2.key2=slotItem.key2;
                           newParams2.x=i3*8 +1;
                           newParams2.y=9;
                           newParams2.dx=8;
                           newParams2.dy=8;
                           newParams2.type=slotItem.type;
                           newParams2.params=slotItem.params;
                           newParams2.qml_path=slotItem.qml_path;
                          // zonesmodel.append(newParams);
                           slotsModel.set(index,newParams2);
                           root.globSignalsObject.zoneChanged(i1,newParams2);
                           i3++;
                           continue;
                       // }
                    }
                    else
                    {
                        itemObj.isEmpty = true;
                        itemObj.key2 = "Свободное место";
                        itemObj.x=i3*8 +1;
                        itemObj.y=9;
                        itemObj.dx=8;
                        itemObj.dy=8;
                        itemObj.type="empty";
                        itemObj.params={};
                        itemObj.qml_path ="";
                        root.addEmptySlotWithParams(itemObj);
                       // root.addCameraEmptySlot(itemObj);
                        i3++;
                    }
                }
                else if(i1>7 && i1 <12)
                {
                    if(slotsModel.count>i1)
                    {
                        var slotItem = slotsModel.get(i1);
                       // if(slotItem.isEmpty === false)
                        //{
                            slotItem.x=i4*8 +1;
                            slotItem.y=17;
                            slotItem.dx=8;
                            slotItem.dy=8;
                            slotsModel.setProperty(i1,"x",i4*8 +1);
                            slotsModel.setProperty(i1,"y",17);
                            slotsModel.setProperty(i1,"dx",8);
                            slotsModel.setProperty(i1,"dy",8);
                            var newParams2 = {};
                           newParams2.isEmpty=false;
                           newParams2.key2=slotItem.key2;
                           newParams2.x=i4*8 +1;
                           newParams2.y=17;
                           newParams2.dx=8;
                           newParams2.dy=8;
                           newParams2.type=slotItem.type;
                           newParams2.params=slotItem.params;
                           newParams2.qml_path=slotItem.qml_path;
                           //zonesmodel.append(newParams);
                           slotsModel.set(index,newParams2);
                           root.globSignalsObject.zoneChanged(i1,newParams2);
                            i4++;
                            continue;
                        //}
                    }
                    else
                    {
                        itemObj.isEmpty = true;
                        itemObj.key2 = "Свободное место";
                        itemObj.x=i4*8 +1;
                        itemObj.y=17;
                        itemObj.dx=8;
                        itemObj.dy=8;
                        itemObj.type="empty";
                        itemObj.params={};
                        itemObj.qml_path ="";
                        root.addEmptySlotWithParams(itemObj);
                        //root.addCameraEmptySlot(itemObj);
                        i4++;
                    }
                }
                else if(i1>11 && i1 <16)
                {
                    if(slotsModel.count>i1)
                    {
                        var slotItem = slotsModel.get(i1);
                        //if(slotItem.isEmpty === false)
                        //{
                            slotItem.x=i5*8 +1;
                            slotItem.y=25;
                            slotItem.dx=8;
                            slotItem.dy=8;
                            slotsModel.setProperty(i1,"x",i5*8 +1);
                            slotsModel.setProperty(i1,"y",25);
                            slotsModel.setProperty(i1,"dx",8);
                            slotsModel.setProperty(i1,"dy",8);
                            var newParams2 = {};
                           newParams2.isEmpty=false;
                           newParams2.key2=slotItem.key2;
                           newParams2.x=i5*8 +1;
                           newParams2.y=25;
                           newParams2.dx=8;
                           newParams2.dy=8;
                           newParams2.type=slotItem.type;
                           newParams2.params=slotItem.params;
                           newParams2.qml_path=slotItem.qml_path;
                           //zonesmodel.append(newParams);
                           slotsModel.set(index,newParams2);
                           root.globSignalsObject.zoneChanged(i1,newParams2);
                            i5++;
                            continue;
                        //}
                    }
                    else
                    {
                        itemObj.isEmpty = true;
                        itemObj.key2 = "Свободное место";
                        itemObj.x=i5*8 +1;
                        itemObj.y=25;
                        itemObj.dx=8;
                        itemObj.dy=8;
                        itemObj.type="empty";
                        itemObj.params={};
                        itemObj.qml_path ="";
                        root.addEmptySlotWithParams(itemObj);
                        //root.addCameraEmptySlot(itemObj);
                        i5++;
                    }
                }
            }
            if(slotsModel.count>15)
            {

                for(var y1=16;y1 < slotsModel.count;)
                {
                    if(!slotsModel.get(y1).isEmpty)
                    {
                        itemObj.isEmpty = false;
                        itemObj.key2 = slotsModel.get(y1).key2;
                        itemObj.x=1;
                        itemObj.y=1;
                        itemObj.dx=8;
                        itemObj.dy=8;
                        itemObj.type=slotsModel.get(y1).type;
                        itemObj.params=slotsModel.get(y1).params;
                        itemObj.qml_path =slotsModel.get(y1).qml_path;
                        zonesmodel.append(itemObj);
                        slotsModel.remove(y2);
                    }
                }
            }
        }
    }

    onCurrentPressetChanged:
    {



        /*
        "x":1,
        "y":1,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        },
        {
        "x":9,
        "y":1,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"288224c5c4c04ae225498c5bd37d254d"
        },
        {
        "x":17,
        "y":1,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"2ed36de8e130e5823e9cdd3db40c5340"
        },
        {
        "x":25,
        "y":1,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"01f097848260358cdc17f25f503076c9"
        },
        {
        "x":1,
        "y":9,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"526292b3d3ace2e744c584e91efe26a4"
        },
        {
        "x":9,
        "y":9,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"cdcf19b61e398110f58f2eefe8c011b9"
        },
        {
        "x":17,
        "y":9,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"e00158c97752e981201dedbf5264795e"
        },
        {
        "x":1,
        "y":25,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"dfa8d01a0e1f6948aa02f0307a11a133"
        },
        {
        "x":25,
        "y":17,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"dfa8d01a0e1f6948aa02f0307a11a133"
        },
        {
        "x":25,
        "y":9,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"dfa8d01a0e1f6948aa02f0307a11a133"
        },
        {
        "x":17,
        "y":17,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"dfa8d01a0e1f6948aa02f0307a11a133"
        },
        {
        "x":9,
        "y":17,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"dfa8d01a0e1f6948aa02f0307a11a133"
        },
        {
        "x":1,
        "y":17,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"f300244bf55f3a4314eaf59a6845ac86"
        },
        {
        "x":9,
        "y":25,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"b7eaa1c76bcfe7bc6de2bef78d3a49e9"
        },
        {
        "x":17,
        "y":25,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"b7eaa1c76bcfe7bc6de2bef78d3a49e9"
        },
        {
        "x":25,
        "y":25,
        "dx":8,
        "dy":8,
        "type":"empty",
        "params":{
        },
        "qml_path":"",
        "guid":"b7eaa1c76bcfe7bc6de2bef78d3a49e9"
        }*/




        /*
        if(root.currentPresset === 0)
        {
            if(slotsModel.count === 0)
            {
                slotsModel.append({isEmpty:true,key2:"",emptyText:"Свободная зона",zoneIndex:1,type:"free slot"});
            }
            getStrFromModel(slotsModel);
        }
        else if(root.currentPresset === 1)
        {
            if(slotsModel.count === 0)
            {
                for(var i = 0;i<7;i++)
                {
                    slotsModel.append({isEmpty:true,key2:"",emptyText:"Свободная зона",zoneIndex:i+1,type:"free slot"});
                }
                 getStrFromModel(slotsModel);
            }
            else if(slotsModel.count<7)
            {
                for(var i=slotsModel.count; slotsModel.count<7;i++)
                {
                    slotsModel.append({isEmpty:true,key2:"",emptyText:"Свободная зона",zoneIndex:i+1,type:"free slot"});
                }
                 getStrFromModel(slotsModel);
            }
            else if(slotsModel.count>7)
            {
                for(var i=7; i<slotsModel.count;)
                {
                    var slotsObj = slotsModel.get(i);
                    if(slotsObj.isEmpty)
                    {
                        slotsModel.remove(i);
                    }
                    else
                    {
                        zonesmodel.append({key2:slotsObj.key2,type:slotsObj.type});
                        slotsModel.remove(i);
                    }
                }
                getStrFromModel(slotsModel);

            }
            else
            {

            }
        }
        else if(root.currentPresset === 2)
        {
            if(slotsModel.count === 0)
            {
                for(var i = 0;i<17;i++)
                {
                    slotsModel.append({isEmpty:true,key2:"",emptyText:"Свободная зона",zoneIndex:i+1,type:"free slot"});
                }
                 getStrFromModel(slotsModel);
            }
            else if(slotsModel.count < 16)
            {
                for(var i=slotsModel.count; slotsModel.count<16;i++)
                {
                    slotsModel.append({isEmpty:true,key2:"",emptyText:"Свободная зона",zoneIndex:i+1,type:"free slot"});
                }
                 getStrFromModel(slotsModel);
            }
            else if(slotsModel.count > 16)
            {
                for(var i=16; i<slotsModel.count;)
                {
                    var slotsObj = slotsModel.get(i);
                    if(slotsObj.isEmpty)
                    {
                        slotsModel.remove(i);
                    }
                    else
                    {
                        zonesmodel.append({key2:slotsObj.key2,type:slotsObj.type});
                        slotsModel.remove(i);
                    }
                }
                 getStrFromModel(slotsModel);
            }
            else
            {

            }
        }
        else if(root.currentPresset === 3)
        {
            if(slotsModel.count === 0)
            {
                for(var i = 0;i<32;i++)
                {
                    slotsModel.append({isEmpty:true,key2:"",emptyText:"Свободная зона",zoneIndex:i+1,type:"free slot"});
                }
                 getStrFromModel(slotsModel);
            }
            else if(slotsModel.count < 32)
            {
                for(var i=slotsModel.count; slotsModel.count<32;i++)
                {
                    slotsModel.append({isEmpty:true,key2:"",emptyText:"Свободная зона",zoneIndex:i+1,type:"free slot"});
                }
                 getStrFromModel(slotsModel);
            }
            else if(slotsModel.count > 32)
            {
                for(var i=slotsModel.count; slotsModel.count<32;i++)
                {
                    var slotsObj = slotsModel.get(i);
                    if(slotsObj.isEmpty)
                    {
                        slotsModel.remove(i);
                    }
                    else
                    {
                        zonesmodel.append({key2:slotsObj.key2,type:slotsObj.type});
                        slotsModel.remove(i);
                    }
                }
                 getStrFromModel(slotsModel);
            }
            else
            {

            }
        }*/
    }
    /*
    0) 1 камеры
    1) 7 камер
    2) 17 камер
    3) 32
    */
    onSetNameChanged:
    {
        //root.setName = se
    }

    IVCustomSets
    {
        id:customSets
    }
    function addEmptySlotWithoutZones()
    {
        slotsModel.append({isEmpty:true,key2:"Свободное место",x:1,y:1,dx:8,dy:8,type:"empty",params:{},qml_path:""});
        var zoneObj = {};
        zoneObj.x = 1;
        zoneObj.y = 1;
        zoneObj.dx = 8;
        zoneObj.dy = 8;
        zoneObj.type = "empty";
        zoneObj.params = {};
        zoneObj.qml_path = "";
        //root.globSignalsObject.zonesAdded("",JSON.stringify(zoneObj));
    }
    function addEmptySlotWithZone(zone)
    {

        if(zone.params.key2 !== undefined)
        {
            zone.key2 = zone.params.key2;
        }
        else
        {
            if(zone.key2 === undefined)
            {
                if(zone.isEmpty)
                {
                    zone.key2  = "Свободная зона";
                }
            }

//            if(zone.key2 === undefined)
//            {
//                zone.key2 = zone.type;
//            }
//            else
//            {
//                if(zone.key2 === "empty")
//                {
//                    zone.key2  = "Свободная зона";
//                }
//            }
        }
        slotsModel.append(zone);

        //root.globSignalsObject.zonesAdded("",JSON.stringify(zoneObj));
    }
    function addEmptySlot()
    {
        slotsModel.append({isEmpty:true,key2:"Свободное место",x:1,y:1,dx:8,dy:8,type:"empty",params:{},qml_path:""});
        var zoneObj = {};
        zoneObj.x = 1;
        zoneObj.y = 1;
        zoneObj.dx = 8;
        zoneObj.dy = 8;
        zoneObj.type = "empty";
        zoneObj.params = {};
        zoneObj.qml_path = "";
        root.globSignalsObject.zonesAdded("",JSON.stringify(zoneObj));
    }
    function addEmptySlotWithParams(params)
    {
        slotsModel.append(params);
//        var zoneObj = {};
//        zoneObj.x = 1;
//        zoneObj.y = 1;
//        zoneObj.dx = 8;
//        zoneObj.dy = 8;
//        zoneObj.type = "empty";
//        zoneObj.params = {};
//        zoneObj.qml_path = "";
        root.globSignalsObject.zonesAdded("",JSON.stringify(params));
    }
    function addCameraToSlot(index,zone)
    {
        var key22 = "";
        if(zone.params.key2 !== undefined)
        {
            key22 =zone.params.key2;
        }
        else
        {
            if(zone.key2 !== undefined)
            {
                key22 = zone.key2;
            }
            else
            {
                key22 =zone.type;
            }
        }
        for(var i1 = 0;i1< slotsModel.count;i1++)
        {
            if(index === i1)
            {
                if(slotsModel.get(i1).isEmpty === true)
                {
                    slotsModel.set(i1,{isEmpty:false,key2:key22,x:zone.x,y:zone.y,dx:zone.dx,dy:zone.dy,type:zone.type,params:zone.params,qml_path:zone.qml_path})
                    root.globSignalsObject.zoneChanged(i1,zone);
                    return;
                }
            }
        }
    }
    function addCameraEmptySlot(zone)
    {
        var key22 = "";
        if(zone.params.key2 !== undefined)
        {
            key22 =zone.params.key2;
        }
        else
        {
            if(zone.key2 !== undefined)
            {
                key22 = zone.key2;
            }
            else
            {
                key22 =zone.type;
            }
        }
        for(var i1 = 0;i1< slotsModel.count;i1++)
        {
            var slotObj = slotsModel.get(i1);
            if(slotObj.isEmpty === true || slotObj.type === "empty")
            {
                zone.x = slotObj.x;
                zone.y = slotObj.y;
                zone.dx = slotObj.dx;
                zone.dy = slotObj.dy;
                slotsModel.set(i1,{isEmpty:false,key2:key22,x:zone.x,y:zone.y,dx:zone.dx,dy:zone.dy,type:zone.type,params:zone.params,qml_path:zone.qml_path})
                root.globSignalsObject.zoneChanged(i1,zone);
                return true;
            }
        }
        return false;
    }
    function addSlot(index,zone)
    {
        if(zone !== null && zone !== undefined)
        {
            var key22 = "";
            if(zone.params.key2 !== undefined)
            {
                key22 =zone.params.key2;
            }
            else
            {
                key22 =zone.type;
            }
            for(var i1 = 0;i1< slotsModel.count;i1++)
            {
                if(slotsModel.get(i1).isEmpty === true && index === i1)
                {
                    slotsModel.set(i1,{isEmpty:false,key2:key22,x:zone.x,y:zone.y,dx:zone.dx,dy:zone.dy,type:zone.type,params:zone.params,qml_path:zone.qml_path})
                    root.globSignalsObject.zoneChanged(i1,zone);
                    return;
                }
            }
            slotsModel.append({isEmpty:false,key2:key22,x:zone.x,y:zone.y,dx:zone.dx,dy:zone.dy,type:zone.type,params:zone.params,qml_path:zone.qml_path});
            root.globSignalsObject.zonesAdded("",JSON.stringify(zone));
        }
        else
        {
            slotsModel.append({isEmpty:true,key2:"Свободное место",x:1,y:1,dx:8,dy:8,type:"empty",params:{},qml_path:""});
            var zoneObj = {};
            zoneObj.x = 1;
            zoneObj.y = 1;
            zoneObj.dx = 8;
            zoneObj.dy = 8;
            zoneObj.type = "empty";
            zoneObj.params = {};
            zoneObj.qml_path = "";
            root.globSignalsObject.zonesAdded("",JSON.stringify(zoneObj));
        }
    }
    function refreshZone(index,zoneparams)
    {
        var slotObject = zoneparams;
        slotsModel.setProperty(index,"x",zoneparams.x);
        slotsModel.setProperty(index,"y",zoneparams.y);
        slotsModel.setProperty(index,"dx",zoneparams.dx);
        slotsModel.setProperty(index,"dy",zoneparams.dy);
    }

    Connections
    {
        id:myConn
        target: root.globSignalsObject

//        onTabSelected:
//        {
//            zonesmodel.clear();
//            slotsModel.clear();
//            root.setName = tabname;

//        }
        onZoneChangedFromMouse:
        {
            //root.refreshZone(index, zoneparams)
        }

        onCamsAutoModeOn:
        {
            root.isAutoMode = true;
        }
        onCamsAutoModeOff:
        {
            root.isAutoMode = false;
        }
        onSetSelected:
        {
            root.setName = setname;
            //root.globSignalsObject.getZonesFromSet();
        }
        onZoneSelected:
        {
            //zonesListView.currentIndex = index;
        }
        onZoneRemoved:
        {
            var slotItem = slotsModel.get(index);
            if(slotItem.isEmpty)
            {
                slotsModel.remove(index);
                return;
            }
            var slotObj = {};
            slotObj.key2 = slotItem.key2;
            slotObj.x = slotItem.x;
            slotObj.y = slotItem.y;
            slotObj.dx = slotItem.dx;
            slotObj.dy = slotItem.dy;
            slotObj.type = slotItem.type;
            slotObj.params = slotItem.params;
            slotObj.qml_path = slotItem.qml_path;
            zonesmodel.append(slotObj);
            slotsModel.remove(index);
        }
        onSetRefreshed:
        {
            //zonesmodel.clear();
            //slotsModel.clear();
            if(root.visible === true)
            {
                slotsModel.clear();
                root.globSignalsObject.getZonesFromSet();
            }
            else
            {
                slotsModel.clear();
            }
        }

        onZonesAddedFromSetName:
        {
            for(var i =0;i<zoneparams.length;i++)
            {
                root.addEmptySlotWithZone(zoneparams[i]);
            }
        }
        onSetPressetIndex:
        {
            root.currentPresset = indexOfPresset;
            root.setPresset(root.currentPresset);
        }
        onAddCamToSlot:
        {
            root.getZonesFromSETS();
            var result1 = root.addCameraEmptySlot(zoneparams);
            if(result1 === false)
            {
                root.addEmptySlot();
                root.addCameraEmptySlot(zoneparams);
            }
        }
        onAddEmptySlot:
        {
            root.addEmptySlot();
        }

        onAddCamToPreview:
        {
            var key22 = "";
            if(zoneparams.params.key2 !== undefined)
            {
                key22 =zoneparams.params.key2;
            }
            else
            {
                if(zoneparams.key2 !== undefined)
                {
                    key22 = zoneparams.key2;
                }
                else
                {
                    key22 =zoneparams.type;
                }
            }

            zonesmodel.append({key2:key22,x:zoneparams.x,y:zoneparams.y,dx:zoneparams.dx,dy:zoneparams.dy,type:zoneparams.type,params:zoneparams.params,qml_path:zoneparams.qml_path});
        }

    }
    Rectangle
    {
        id:slotsRect
        anchors.top: parent.top
        anchors.bottom: dragRect.top
        anchors.bottomMargin: -3
        color: "#d9d9d9"
        width: parent.width
        ListModel
        {
            id:slotsModel
        }
        ListView
        {
            id:slotsListView
            clip: true
            anchors.fill: parent
            boundsBehavior: ListView.StopAtBounds
            model:slotsModel
            spacing: 1
            property int dragItemIndex: -1
            property bool isOverDelegate: false
            delegate:Item
            {
                id:slotsItem
                width: parent.width
                height: 30
                Popup
                {
                    id:addCamsPopUp
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent | Popup.CloseOnPressOutside
                    width: 200
                    height: addCamsListView.contentHeight>350?350:addCamsListView.contentHeight
                    property int indexOfSlot: model.index
                    bottomPadding: 0
                    topPadding: 0
                    leftPadding: 0
                    rightPadding: 0
                    ListView
                    {
                        id:addCamsListView
                        clip: true
                        boundsBehavior: ListView.StopAtBounds
                        anchors.fill: parent
                        model:zonesmodel
                        spacing:1
                        delegate: Item {
                            id: addItem
                            width: addCamsListView.width
                            height: 30
                            Rectangle
                            {
                                id:key2Rect
                                color: "white"
                                border.width: 1
                                border.color: "black"
                                anchors.fill:parent
                                Label
                                {
                                    id:key2Label2
                                    text: key2
                                    color: "black"
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: 14
                                    MouseArea
                                    {
                                        id:addMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked:
                                        {
                                            var zoneItem = zonesmodel.get(index);
                                            //slotsModel.setProperty(addCamsPopUp.indexOfSlot,"isEmpty",false);
                                           // slotsModel.setProperty(addCamsPopUp.indexOfSlot,"key2",zoneItem.key2);
                                           // slotsModel.setProperty(addCamsPopUp.indexOfSlot,"type",zoneItem.type);
                                            root.addCameraToSlot(addCamsPopUp.indexOfSlot,zoneItem);
                                            zonesmodel.remove(index);
                                            addCamsPopUp.close();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                IVClientSlotDelegate
                {
                    id:slotsDelegate
                    onSlotClear:
                    {
                        var slotsObj = slotsModel.get(index);
                        var newParams = {};
                        newParams.isEmpty=true;
                        newParams.key2=slotsObj.key2;
                        newParams.x=slotsObj.x;
                        newParams.y=slotsObj.y;
                        newParams.dx=slotsObj.dx;
                        newParams.dy=slotsObj.dy;
                        newParams.type=slotsObj.type;
                        newParams.params=slotsObj.params;
                        newParams.qml_path=slotsObj.qml_path;

                        slotsObj.key2 = "Свободное место";
                        slotsObj.type = "empty";
                        slotsObj.isEmpty = true;
                        slotsObj.params ={};
                        slotsObj.qml_path = "";
                         var newParams2 = {};
                        newParams2.isEmpty=true;
                        newParams2.key2="Свободное место";
                        newParams2.x=slotsObj.x;
                        newParams2.y=slotsObj.y;
                        newParams2.dx=slotsObj.dx;
                        newParams2.dy=slotsObj.dy;
                        newParams2.type="empty";
                        newParams2.params={};
                        newParams2.qml_path="";
                        zonesmodel.append(newParams);
                        slotsModel.set(index,newParams2);
                        root.globSignalsObject.zoneChanged(index,newParams2);

                        //slotsModel.setProperty(index,"isEmpty",true);
                        //slotsModel.setProperty(index,"key2","");
                        //slotsModel.setProperty(index,"type","free");
                    }
                    onOpenAddPopUp:
                    {
                        addCamsPopUp.indexOfSlot = index;
                        addCamsPopUp.x = slotsListView.x;
                        addCamsPopUp.y = slotsListView.y;
                        addCamsPopUp.open();
                    }
                }
            }
        }
    }
    Rectangle
    {
        id:dragRect
        width: parent.width
        height: 10
        color: "transparent"
        Drag.active: dragMA.drag.active
        y:parent.height/2
        Rectangle
        {
            id:dragRect2
            width: parent.width
            height: 4
            color: "black"
            anchors.verticalCenter: parent.verticalCenter
        }
        MouseArea
        {
            id:dragMA
            anchors.fill: parent
            drag.target: dragRect
            drag.minimumY: 30
            drag.axis: Drag.YAxis
            drag.maximumY: root.height-30
            cursorShape: Qt.SplitVCursor
        }
    }
    MessageDialog {
        id: messageDialog
        width: 200
        height: 80
        title: "Добавление камеры в свободное место"
        text: "Нет свободных мест для размещения камеры. Добавить свободное место для данной камеры?"
        property var zoneparams: ""
        property int indexInModel: -1
        visible: false
        standardButtons: StandardButton.Yes | StandardButton.No

        onYes:
        {
            root.addEmptySlot();
            var result = root.addCameraEmptySlot(messageDialog.zoneparams);
            if(!result&& messageDialog.indexInModel !== -1)
            {
            }
            else
            {
                zonesmodel.remove(messageDialog.indexInModel);
            }
            messageDialog.close();
        }
        onNo:
        {
            messageDialog.close();
        }
    }
    Rectangle
    {
        id:camsRect
        anchors.top: dragRect.bottom
        anchors.topMargin: 3
        anchors.bottom: parent.bottom
        color: "#d9d9d9"
        width: parent.width
        ListModel
        {
            id:zonesmodel
        }
        ListView
        {
            id:zonesListView
            anchors.fill: parent
            boundsBehavior: ListView.StopAtBounds
            clip: true
            model: zonesmodel
            currentIndex: -1
            property int dragItemIndex: -1
            delegate: Item
            {
                id: delItem
                width: parent.width
                height: 30
                IVClientZonesDelegate
                {
                    id:zoneItem
                    width:parent.width
                    height:parent.height
                    currentIndex: zonesListView.currentIndex
                    innerIndex: index
                    globSignalsObject: root.globSignalsObject
                    onDeleteClicked:
                    {
                        zonesmodel.remove(zoneItem.innerIndex);
                    }
                    onDoubleClicked:
                    {
                        var zoneItem = zonesmodel.get(index);
                        var newParams = {};
                        newParams.isEmpty=false;
                        newParams.key2=zoneItem.key2;
                        newParams.x=zoneItem.x;
                        newParams.y=zoneItem.y;
                        newParams.dx=zoneItem.dx;
                        newParams.dy=zoneItem.dy;
                        newParams.type=zoneItem.type;
                        newParams.params=zoneItem.params;
                        newParams.qml_path=zoneItem.qml_path;

                        var result = root.addCameraEmptySlot(newParams);
                        if(!result)
                        {
                            messageDialog.zoneparams = newParams;
                            messageDialog.indexInModel = index;
                            messageDialog.open();
                            return;
                        }
                        zonesmodel.remove(index);
                    }
                }
            }
        }
    }
}

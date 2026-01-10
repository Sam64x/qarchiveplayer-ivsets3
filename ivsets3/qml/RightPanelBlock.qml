import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.sets.sets3 1.0
import QtQuick.Dialogs 1.1


Rectangle
{
    id:root
    color: "white"
    anchors.fill: parent
    property var globSignalsObject: null
    property string setName: ""
    property var zoneTypes: null
    property var setParams: null
    property var zoneParams: null
    property int currZoneIndex: -1
    property bool isSetSelected: false
    onGlobSignalsObjectChanged:
    {
        if(root.globSignalsObject !== null & root.globSignalsObject !== undefined)
        {
          globSigConnection.target = Qt.binding(function() {return root.globSignalsObject;});
        }
    }
    Component.onCompleted:
    {
        var _zTypes = customSets.getZoneTypes();
        var _cameras = customSets.getCameras();
        try
        {
            //addZonesModel
            root.zoneTypes = JSON.parse(_zTypes);
            for(var paramName in root.zoneTypes)
            {
                addZonesModel.append({type:root.zoneTypes[paramName].type,params:JSON.stringify(root.zoneTypes[paramName].params),qml_path:root.zoneTypes[paramName].qml_path});
            }
        }
        catch(exception)
        {
        }
    }

    IVCustomSets
    {
        id:customSets
    }
    Connections
    {
        id:globSigConnection
        target:globSignalsObject
        onSetSelected:
        {
            root.setName = setname;
            root.isSetSelected = true;
            root.setParams = JSON.parse(customSets.getZone(root.setName)).zones;

            for(var zz in root.setParams)
            {
                //var paramsArray =
                //availZonesModel.append({type:root.setParams[zz].type , params:JSON.stringify(root.setParams[zz].params),qml_path:root.setParams[zz].qml_path});
            }

        }
        onSetSaved2:
        {
            root.globSignalsObject.setSaved(setNameInput.text);
        }
        onZoneSelected:
        {
            //zoneparams
            availZonesModel.clear();
            root.zoneParams = JSON.parse(zoneparams);
            root.currZoneIndex =  index;
            if(root.zoneParams)
            {
               // for(var ii in root.zoneParams)
              //  {
//                    if(ii !== "params")
//                    {
//                        //availZonesModel.append({name:ii,value:root.zoneParams[ii]});
//                    }
//                    else
//                    {
                        for(var yy in root.zoneParams.params)
                        {
                            availZonesModel.append({name:yy,value:root.zoneParams.params[yy]});
                        }
                    //}

               // }



            }
        }
    }
    Rectangle
    {
        id:topLabelRect
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        Label
        {
            id:settsLabel
            text: "Настройки набора"
            font.pixelSize: 16
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Rectangle
    {
        id:setsSettingsRect
        color:"white"
        width:parent.width
       // height: 210
        anchors.top: topLabelRect.bottom
        anchors.bottom: availZones.top
        visible: root.isSetSelected
        Rectangle
        {
            id:setNameRect
            width: parent.width
            height: 30
            border.color: "#14a3b3"
            border.width:2
            Label
            {
                id:setNameLabel
                text: "Имя набора"
                font.pixelSize: 16
                width:150
                anchors.left: parent.left
                anchors.leftMargin: 2
                height: parent.height
                clip: true
                verticalAlignment: Text.AlignVCenter
            }

            TextInput
            {
                id:setNameInput
                text:root.setName
                font.pixelSize: 16
                //width:130
                anchors.left: setNameLabel.right
                anchors.right: parent.right
                anchors.rightMargin: 2
                height: parent.height
                verticalAlignment: Text.AlignVCenter
            }

        }
        Rectangle
        {
            id:setMonNumberRect
            width: parent.width
            height: 30
            border.color: "#14a3b3"
            border.width:2
            anchors.top:setNameRect.bottom
            anchors.topMargin: 2
            Label
            {
                id:setMonNumberLabel
                text: "Номер монитора"
                font.pixelSize: 16
                width:150
                anchors.left: parent.left
                anchors.leftMargin: 2
                height: parent.height
                clip: true
                verticalAlignment: Text.AlignVCenter
            }

            TextInput
            {
                id:setMonNumberInput
                text:root.setMonNumber
                font.pixelSize: 16
                //width:130
                anchors.left: setMonNumberLabel.right
                anchors.right: parent.right
                anchors.rightMargin: 2
                height: parent.height
                verticalAlignment: Text.AlignVCenter
            }
        }
        Rectangle
        {
            id:setWidthRect
            width: parent.width
            height: 30
            border.color: "#14a3b3"
            border.width:2
            anchors.top:setMonNumberRect.bottom
            anchors.topMargin: 2
            Label
            {
                id:setWidthLabel
                text: "Ширина(px)"
                font.pixelSize: 16
                width:150
                anchors.left: parent.left
                anchors.leftMargin: 2
                height: parent.height
                clip: true
                verticalAlignment: Text.AlignVCenter
            }

            TextInput
            {
                id:setWidthInput
                text:root.setWidth
                font.pixelSize: 16
                //width:130
                anchors.left: setWidthLabel.right
                anchors.right: parent.right
                anchors.rightMargin: 2
                height: parent.height
                verticalAlignment: Text.AlignVCenter
            }

        }
        Rectangle
        {
            id:setHeightRect
            width: parent.width
            height: 30
            border.color: "#14a3b3"
            border.width:2
            anchors.top:setWidthRect.bottom
            anchors.topMargin: 2
            Label
            {
                id:setHeightLabel
                text: "Высота(px)"
                font.pixelSize: 16
                width:150
                anchors.left: parent.left
                anchors.leftMargin: 2
                height: parent.height
                clip: true
                verticalAlignment: Text.AlignVCenter
            }

            TextInput
            {
                id:setHeightInput
                text:root.setWidth
                font.pixelSize: 16
                //width:130
                anchors.left: setHeightLabel.right
                anchors.right: parent.right
                anchors.rightMargin: 2
                height: parent.height
                verticalAlignment: Text.AlignVCenter
            }

        }
        Label
        {
            id:addLabel
            text: "Добавление зон"
            font.pixelSize: 16
            anchors.top: setHeightRect.bottom
            width: parent.width
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            height: 30
        }
        Rectangle
        {
            id:setZonesAddRect
            width: parent.width
            height: paramsListModel.height+30
            anchors.top:addLabel.bottom
            anchors.topMargin: 2
            color: "transparent"
            ListModel
            {
                id:addZonesModel
            }
            ListModel
            {
                id:paramsModel
            }
            ComboBox
            {
                id:typesCombo
                currentIndex: 0
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.right: parent.right
                anchors.rightMargin: 2

                height: 30
                model: addZonesModel
                textRole: "type"
                onCurrentIndexChanged:
                {
                    try
                    {
                        if(addZonesModel.get(currentIndex).params)
                        {
                            var prms = JSON.parse(addZonesModel.get(currentIndex).params);
                            paramsModel.clear();
                            if(prms)
                            {
                                for(var propName in prms)
                                {
                                    paramsModel.append({key:propName,value:prms[propName].toString()});
                                }
                            }
                        }
                        //paramsListModel.currentIndex = typesCombo.currentIndex;
                    }
                    catch(excp)
                    {
                    }
                }
            }
            ListView
            {
                id:paramsListModel
                clip: true
                boundsBehavior: ListView.StopAtBounds
               // currentIndex:
                width: parent.width
                height: contentHeight
                model:paramsModel
                anchors.top:typesCombo.bottom
                anchors.topMargin: 2
              //  anchors.bottom: parent.bottom
                onCurrentIndexChanged:
                {
                }
                delegate:
                Item
                {
                    id: delItem2
                    height: 30
                    width:parent.width
                    property int indexOfDel: index
                    Row
                    {
                        height: 30
                        width: parent.width
                        Rectangle
                        {
                            height: parent.height
                            width: 145
                            color: "transparent"
                            border.width: 1
                            border.color: "white"
                            Text
                            {
                                id:tttTextProp
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text:key
                                anchors.fill: parent
                                color: "black"
                            }
                        }
                        Rectangle
                        {
                            height: parent.height
                            width: 145
                            color: "transparent"
                            border.width: 1
                            border.color: "white"
                            TextInput
                            {
                                id:tttTextProp2
                                color: "black"
                                text:value
                                anchors.fill: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                onTextEdited:
                                {
                                    var index2 = paramsListModel.currentIndex;
                                    paramsModel.setProperty(indexOfDel, "value", tttTextProp2.text)
                                }
                            }
                        }
                    }
                }
            }
        }
        Button
        {
            id:addZonesBtn
            width: parent.width
            height: 30
            text: "Добавить зону"
            anchors.top: setZonesAddRect.bottom
            onClicked:
            {
                var _zoneObj = {};
                _zoneObj["x"] = 0;
                _zoneObj["y"] = 0;
                _zoneObj["dx"] = 8;
                _zoneObj["dy"] = 8;
                var type = addZonesModel.get(typesCombo.currentIndex).type;
                var qml_path = addZonesModel.get(typesCombo.currentIndex).qml_path;
                _zoneObj["type"] = type;
                var params = {};
                for(var i=0;i<paramsModel.count;i++)
                {
                    var elem = paramsModel.get(i);
                    params[elem.key] = elem.value;
                }
                _zoneObj["params"] = params;
                _zoneObj["qml_path"] =qml_path;
                var _zz_ = JSON.stringify(_zoneObj);
                root.globSignalsObject.zonesAdded("",_zz_);
                //setsZone.addZone(_zoneObj);
               // zonesListView.updateZones();
            }
        }


    }
    Rectangle
    {
        id:availZones
        color: "transparent"
        //anchors.top: setsSettingsRect.bottom
      //  anchors.topMargin: 2
        height: paramsListModel2.contentHeight
        width: parent.width
        anchors.bottom: saveZonesBtn.top
        ListModel
        {
            id:availZonesModel

        }
        ListView
        {
            id:paramsListModel2
            clip: true
            boundsBehavior: ListView.StopAtBounds
           // currentIndex:
            width: parent.width
           // height: contentHeight
            model:availZonesModel
            anchors.top:availZones.top
            anchors.topMargin: 2
            anchors.bottom: parent.bottom
           // anchors.bottomMargin: 2
            onCurrentIndexChanged:
            {
            }
            delegate:
            Item
            {
                id: delItem3
                height: 30
                width:parent.width
                property int indexOfDel: index
                Row
                {
                    height: 30
                    width: parent.width
                    Rectangle
                    {
                        height: parent.height
                        width: 75
                        color: "transparent"
                        border.width: 1
                        border.color: "white"
                        Text
                        {
                            id:tttTextProp4
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text:name
                            anchors.fill: parent
                            color: "black"
                        }
                    }
                    Rectangle
                    {
                        height: parent.height
                        width: 145
                        color: "transparent"
                        border.width: 1
                        border.color: "white"
                        TextInput
                        {
                            id:tttTextProp3
                            color: "black"
                            text:value
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            onTextEdited:
                            {
                                var index2 = paramsListModel2.currentIndex;
                                availZonesModel.setProperty(indexOfDel, "value", tttTextProp3.text)
                            }
                        }
                    }
                    Image
                    {
                        width: 30
                        height: 30
                        source: "file:///"+applicationDirPath + "/images/blue/plus.svg"
                        anchors.right: parent.right
                        ToolTip.text: "Выбрать имя камеры из списка"
                        ToolTip.delay: 500
                        ToolTip.visible:  mar1.containsMouse
                        MouseArea
                        {
                            id:mar1
                            anchors.fill: parent
                            onClicked:
                            {

                            }

                        }


                    }
                }
            }
        }
    }
    Button
    {
        id:saveZonesBtn
        width: parent.width
        height: 30
        text: "Сохранить изменения"
        anchors.bottom: parent.bottom
        onClicked:
        {
            var pars = {};
            for(var i=0;i<availZonesModel.count;i++)
            {
                var elem = availZonesModel.get(i);
                pars[elem.name] = elem.value;
            }

           // availZonesModel
            root.zoneParams.params =pars;
            //var strPar = JSON.stringify()
            //root.globSignalsObject.zoneChanged(root.currZoneIndex,root.zoneParams.params);
        }
    }
}

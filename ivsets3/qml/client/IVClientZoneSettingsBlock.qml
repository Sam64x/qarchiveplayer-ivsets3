import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import iv.plugins.loader 1.0
import QtQuick.Window 2.3
import iv.sets.sets3 1.0
import iv.components.windows 1.0

Rectangle
{
    id:root
    color: "white"
    property var globalSignalsObject: null
    property int zoneIndex:-1
    Component.onCompleted:
    {
        var _zTypes = customSets.getZoneTypes();

        try
        {

            var zoneTypes = JSON.parse(_zTypes);
            for(var paramName in zoneTypes)
            { console.error("Right panelBlock parse zones error =",zoneTypes[paramName].qml_path);
                comboModel.append({type:zoneTypes[paramName].type,params:JSON.stringify(zoneTypes[paramName].params),qml_path:zoneTypes[paramName].qml_path});
            }
        }
        catch(exception)
        {
            console.error("Right panelBlock parse zones error =",exception);
        }
    }
    onGlobalSignalsObjectChanged:
    {
        console.error("Z============================",root.globalSignalsObject)
        globSigConnection.target = root.globalSignalsObject;
    }

    Connections
    {
        id:globSigConnection
        //target:root.globSignalsObject
        onZoneSelected:
        {
            //zoneparams
            console.error("zoneparams = 1")
            console.error("zoneparams = ",zoneparams)
            root.zoneIndex = index;
            //availZonesModel.clear();
            var zoneParams = JSON.parse(zoneparams);
            var currZoneIndex =  index;
            if(zoneParams)
            {
                for(var i=0;i<comboModel.count;i++)
                {
                    if(zoneParams.type === comboModel.get(i).type )
                    {
                        comboModel.set(i,{type:zoneParams.type,params:JSON.stringify(zoneParams.params),qml_path:zoneParams.qml_path});
                        console.error("vv+++++++++++++ = ",comboModel.get(i).params)
                        typeCombo.currentIndex = -1;
                        typeCombo.currentIndex = i;
                        break;
                    }
                }
            }
            else
            {
                console.error("zone params not found");
            }
        }
    }
    IVCustomSets
    {
        id:customSets
    }
    Rectangle
    {
        id:headerRect
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 30
        color: "green"
        border.width: 1
        border.color: "black"
        Label
        {
            id:headerLabel
            text: "Настройка выбранного объекта"
            font.pixelSize: 18
            color: "black"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }
    ListModel
    {
        id:comboModel
    }
    ListModel
    {
        id:paramsModel
    }
    Rectangle
    {
        id:bodyRect
        anchors.top:headerRect.bottom
        anchors.bottom: confirmRect.top
        anchors.left: parent.left
        anchors.right: parent.right
        color: "azure"
        Rectangle
        {
            id:zoneTypeRect
            color: "transparent"
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 30
            Label
            {
                id:typeLabel
                text: "Тип объекта:"
                font.pixelSize: 16
                color: "black"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                anchors.left: parent.left
                width: parent.width/2
                height: parent.height
            }
            ComboBox
            {
                id:typeCombo
                height: parent.height
                width: parent.width/2
                anchors.right: parent.right
                model: comboModel
                textRole: "type"
                onCurrentIndexChanged:
                {
                    //console.error(typesCombo.currentIndex)
                    paramsModel.clear();
                    console.error("23232323qqqqqqqqqqqq",currentIndex ,comboModel.count);
                    var item2 = comboModel.get(currentIndex);
                    //
                    if(comboModel.get(currentIndex).params === undefined)
                    {
                        return;
                    }
                    console.error("23232323",comboModel.get(currentIndex).params);
                    try
                    {
                        if(comboModel.get(currentIndex).params)
                        {
                            var prms = JSON.parse(comboModel.get(currentIndex).params);
                            if(prms)
                            {
                                for(var propName in prms)
                                {
                                   // console.error("zzzz = ",propName,prms[propName]);
                                    paramsModel.append({key:propName,value:prms[propName].toString()});
                                }
                            }
                        }
                        //paramsListModel.currentIndex = typesCombo.currentIndex;
                    }
                    catch(excp)
                    {
                        console.error("excp = ",excp);
                    }
                }
            }
        }
        Rectangle
        {
            id:delimRect22
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: "black"
            anchors.top:zoneTypeRect.bottom
        }
        Rectangle
        {
            id:paramsRect
            anchors.top:delimRect22.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            color: "transparent"
            ListView
            {
                id:paramsListModel
                clip: true
                boundsBehavior: ListView.StopAtBounds
               // currentIndex:
                anchors.fill: parent
                model:paramsModel
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
    }

    Rectangle
    {
        id:confirmRect
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: parent.left
        height: 20
        Button
        {
            id:confButton
            text: "Применить"
            anchors.fill: parent
            onClicked:
            {
                var props = {};
                props["type"] = comboModel.get(typeCombo.currentIndex).type;
                var nParams = {};
                for(var i=0;i<paramsModel.count;i++)
                {
                    var pp = paramsModel.get(i);

                    nParams[pp.key] = pp.value;
                }
                props["params"] = nParams;
                props["qml_path"] = comboModel.get(typeCombo.currentIndex).qml_path;
                console.error("AAAAATTTTTTTTTTTTTTTT",props["params"],props["qml_path"],props["type"])
                //props["params"] = comboModel.get(typeCombo.currentIndex).params;
                console.error(JSON.stringify(props.params));
                root.globalSignalsObject.zoneChanged(root.zoneIndex,props);
            }
        }
    }
}

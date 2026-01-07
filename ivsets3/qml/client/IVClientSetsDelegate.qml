import QtQuick 2.11
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.sets.sets3 1.0
import iv.colors 1.0

Rectangle
{
    id:root
    color: IVColors.get("Colors/Background new/BgFormPrimaryThemed")//"#d9d9d9"
   //color: "transparent"
    signal delClicked()
    signal addCamsClicked()
    signal addTab()
    property string textColor: "black"
    property int innerIndex: -1
    property int currentIndex: -1
    property var globSignalsObject: null
    visible: isVisible
    height: isVisible? 30 : 0
    width: parent.width//-10
    IVCustomSets
    {
        id:customSets
    }
    Connections
    {
        id:myConn
        target: root.globSignalsObject
        onTabEditedOff:
        {
            editBtn.isOn = false;
        }
        onTabEditedOn:
        {
            editBtn.isOn = true;
        }
    }


    function onLoadCams()
    {
        var zones = customSets.getZone(name);
        var zonesObj = null;
        try
        {
            zonesObj = JSON.parse(zones);
             var zoness = zonesObj["zones"];
            for(var j = 0;j < zoness.length;j++)
            {
                camsModel.append({key2:zoness[i].params.key2})
            }
        }
        catch(exception)
        {

        }
    }

    Component.onCompleted:
    {
        root.onLoadCams();
    }

    onHeightChanged:
    {

        //console.error("SETS DELEG HEIGHT = ",setsDel.height,isVisible )
    }
    ListModel
    {
        id:camsModel
    }

    onCurrentIndexChanged:
    {
        //console.error("onCurrentIndexChanged = ",currentIndex , "root.innerIndex = ",setsDel.innerIndex);
        if(setsDel.currentIndex == setsDel.innerIndex)
        {
            setsDel.color = "#b4b4b4";
            setsDel.textColor = "white";
        }
        else
        {
            setsDel.color = "#d9d9d9";
            setsDel.textColor = "black";
        }
    }
    Text
    {
        id:setsName
        anchors.fill: parent
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text:name
        color: root.textColor
        font.pixelSize: 18
        MouseArea
        {
            anchors.fill: parent
            onClicked:
            {
                var isEditorEnabled = root.globSignalsObject.getEditorStatus();
                if(!isEditorEnabled)
                {
                    root.delClicked();
                }
            }
            onDoubleClicked:
            {
               // root.showSet

            }
        }
    }
    Image
    {
        id:showSetsImg
        source: "file:///"+applicationDirPath + "/images/black/arrow_right.svg"
        width: 16
        height: 16
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 5
        ToolTip.text: "Показать список камер"
        ToolTip.delay: 500
        ToolTip.visible:  mar66.containsMouse
        //visible: !local
        property bool isOpened: false
        MouseArea
        {
            anchors.fill: parent
            id:mar66
            hoverEnabled: true
            onClicked:
            {
                if(showSetsImg.isOpened)
                {
                    showSetsImg.isOpened = false;
                    showSetsImg.source = "file:///"+applicationDirPath + "/images/black/arrow_right.svg"

                }
                else
                {
                    showSetsImg.isOpened = true;
                    showSetsImg.source = "file:///"+applicationDirPath + "/images/black/down.svg"

                }
            }
            onEntered:
            {

            }
            onExited:
            {

            }
        }
    }
    Image
    {
        id:editBtn
        source: "file:///"+applicationDirPath + "/images/blue/edit.svg"
        width: 28
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        anchors.right:parent.right
        anchors.leftMargin: 5
        ToolTip.text: "Редактировать набор"
        ToolTip.delay: 500
        ToolTip.visible:  mar8.containsMouse
        property bool isOn: false
        visible: local && root.innerIndex === root.currentIndex
        MouseArea
        {
            anchors.fill: parent
            id:mar8
            hoverEnabled: true
            onClicked:
            {
                if(editBtn.isOn)
                {
                    root.delClicked();
                    setsDel.globSignalsObject.tabEditedOff();
                    editBtn.isOn = false;
                }
                else
                {
                    root.delClicked();
                    setsDel.globSignalsObject.tabEditedOn();
                    editBtn.isOn = true;
                }
            }
            onEntered:
            {
                if(!editBtn.isOn)
                {
                    editBtn.source="file:///"+applicationDirPath + "/images/white/edit.svg"
                }
            }
            onExited:
            {
                if(!editBtn.isOn)
                {
                    editBtn.source="file:///"+applicationDirPath + "/images/blue/edit.svg"
                }
            }
        }
    }


}

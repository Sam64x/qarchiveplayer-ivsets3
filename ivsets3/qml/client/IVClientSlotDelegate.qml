import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.sets.sets3 1.0

Rectangle
{
    id:root
    anchors.fill: parent
    color:"transparent"
   // property ListModel zonesmodel: null
    //property ListModel slotsModel: null
    signal openAddPopUp()
    signal slotClear()
    Rectangle
    {
        id:slotsRect2
        anchors.fill: parent
        border.width: 1
        border.color: "black"
        Rectangle
        {
            id:slotPosRect
            width: 30
            height: 30
            color: isEmpty?"#d9d9d9":"#3ad981"
            anchors.left: parent.left
            Label
            {
                id:posNumberLabel
                anchors.fill: parent
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                text: model.index+1
                font.pixelSize: 14
            }
        }
        Rectangle
        {
            id:key2Rect
            height: parent.height
            anchors.left: slotPosRect.right
            anchors.right: clearRect.left
            color: isEmpty?"#d9d9d9":"#3ad981"
            Label
            {
                id:key2Label
                anchors.fill: parent
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 14
                color: isEmpty?"black":"white"
                text:key2
            }
        }
        Rectangle
        {
            id:addRect
            width: isEmpty?30:0
            height: 30
            anchors.right: clearRect.left
            color: isEmpty?"#d9d9d9":"#3ad981"
            //visible: isEmpty?false:true
            Image
            {
                id:addImage
                source: "file:///"+applicationDirPath + "/images/black/bar_vis.svg"
                anchors.fill: parent
                property real scalePower: 1
                ToolTip.text: "Выбрать камеру"
                ToolTip.delay: 500
                ToolTip.visible:  mar44.containsMouse
                MouseArea
                {
                    anchors.fill: parent
                    hoverEnabled: true
                    id:mar44
                    onClicked:
                    {
                        root.openAddPopUp();
                    }
                    onEntered:
                    {

                    }
                    onExited:
                    {

                    }
                }
            }
        }
        Rectangle
        {
            id:clearRect
            width: isEmpty?0:30
            height: 30
            anchors.right: parent.right
            color: isEmpty?"#d9d9d9":"#3ad981"
            //visible: isEmpty?false:true
            Image
            {
                id:zoneDelImage
                source: "file:///"+applicationDirPath + "/images/white/clear.svg"
                anchors.fill: parent
                property real scalePower: 1
                ToolTip.text: "Очистить зону"
                ToolTip.delay: 500
                ToolTip.visible:  mar4.containsMouse
                MouseArea
                {
                    anchors.fill: parent
                    hoverEnabled: true
                    id:mar4
                    onClicked:
                    {
                        root.slotClear();
                    }
                    onEntered:
                    {
                    }
                    onExited:
                    {
                    }
                }
            }
        }
    }
}

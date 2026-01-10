import QtQuick 2.11
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.sets.sets3 1.0
Rectangle
{
    id:root
    color: "#d9d9d9"
    signal delClicked()
    signal addCamsClicked()
    signal addTab()
    property string textColor: "black"
    property int innerIndex: -1
    property int currentIndex: -1
    onCurrentIndexChanged:
    {
        if(root.currentIndex == root.innerIndex)
        {
            setsDel.color = "#26cee0";
            setsDel.textColor = "white";
        }
        else
        {
            setsDel.color = "white";
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
                root.delClicked();
            }
            onDoubleClicked:
            {
               // root.showSet

            }
        }
    }
    Image
    {
        id:showBtn
        source: "file:///"+applicationDirPath + "/images/black/plus.svg"
        width: 28
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: plusBtn.left
        anchors.leftMargin: 5
        ToolTip.text: "Показать вкладку"
        ToolTip.delay: 500
        ToolTip.visible:  mar6.containsMouse
        visible: mar6.containsMouse
        MouseArea
        {
            anchors.fill: parent
            id:mar6
            hoverEnabled: true
            onClicked:
            {

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
        id:plusBtn
        source: "file:///"+applicationDirPath + "/images/blue/edit.svg"
        width: 28
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.leftMargin: 5
        ToolTip.text: "Добавить камеры к набору"
        ToolTip.delay: 500
        ToolTip.visible:  mar5.containsMouse
        visible: root.currentIndex == root.innerIndex?true:false
        MouseArea
        {
            anchors.fill: parent
            id:mar5
            hoverEnabled: true
            onClicked:
            {
                root.delClicked();
                root.addCamsClicked();
            }
            onEntered:
            {
                plusBtn.source="file:///"+applicationDirPath + "/images/black/edit.svg"
            }
            onExited:
            {
                plusBtn.source="file:///"+applicationDirPath + "/images/blue/edit.svg"
            }
        }
    }


}

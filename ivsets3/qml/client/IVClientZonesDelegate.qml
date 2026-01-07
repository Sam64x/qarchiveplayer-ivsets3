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
    color: "#d9d9d9"
    signal deleteClicked()
    signal doubleClicked()
    property string textColor: "black"
    property int innerIndex: -1
    property int currentIndex: -1
    property var globSignalsObject: null
    onCurrentIndexChanged:
    {
        console.error("onCurrentIndexChanged = ",currentIndex , "root.innerIndex = ",root.innerIndex);
        if(root.currentIndex == root.innerIndex)
        {
            root.color = "#3ad981";
            root.textColor = "white";
        }
        else
        {
            root.color = "#d9d9d9";
            root.textColor = "black";
        }
    }
    Image
    {
        id:plusImage
        source: "file:///"+applicationDirPath + "/images/white/plus.svg"
        width: 30
        height: 30
        //anchors.top: parent.top
       // anchors.topMargin: 2
        anchors.left: parent.left
        //anchors.leftMargin: 1
        property real scalePower: 1
       // scale: setsEditorImage.scalePower
        ToolTip.text: "Добавить камеру в набор"
        ToolTip.delay: 1000
        ToolTip.visible:  mar5.containsMouse
        property bool _pressed: false
        MouseArea
        {
            anchors.fill: parent
            hoverEnabled: true
            id:mar5
            onClicked:
            {
                root.doubleClicked();
            }
            onEntered:
            {

            }
            onExited:
            {

            }
        }
    }
    Text
    {
        id:zoneName
        //anchors.fill: parent
        height: parent.height
        anchors.left: plusImage.right
        anchors.right: zoneDelImage.left
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text:key2
        color: root.textColor
        font.pixelSize: 16
        MouseArea
        {
            anchors.fill: parent
            onClicked:
            {
                //root.globSignalsObject.zoneSelected(root.innerIndex,null);
            }
            onDoubleClicked:
            {
               root.doubleClicked();

            }
        }
    }
    Image
    {
        id:zoneDelImage
        source: "file:///"+applicationDirPath + "/images/white/clear.svg"
        width: 30
        height: 30
        //anchors.top: parent.top
       // anchors.topMargin: 2
        anchors.right: parent.right
        //anchors.leftMargin: 1
        property real scalePower: 1
       // scale: setsEditorImage.scalePower
        ToolTip.text: "Удалить камеру"
        ToolTip.delay: 1000
        ToolTip.visible:  mar4.containsMouse
        property bool _pressed: false
        MouseArea
        {
            anchors.fill: parent
            hoverEnabled: true
            id:mar4
            onClicked:
            {
                root.deleteClicked();
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

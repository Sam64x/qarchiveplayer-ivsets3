import QtQml 2.3
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
//import iv.plugins.loader 1.0
//import iv.guicomponents 1.0
//import iv.components.windows 1.0
import iv.sets.sets3 1.0

Rectangle
{
    id:root
    color: "transparent"
    property int slotIndex: -1
    property var globSignalsObject: null
    Image
    {
        id:zoneDelImage
        source: "file:///"+applicationDirPath + "/images/white/clear.svg"
        anchors.fill: parent
        //anchors.top: parent.top
       // anchors.topMargin: 2
       // anchors.right: parent.right
        //anchors.leftMargin: 1
        property real scalePower: 1
       // scale: setsEditorImage.scalePower
        //ToolTip.text: ""
        //ToolTip.delay: 1000
        //ToolTip.visible:  mar4.containsMouse
        property bool _pressed: false
        MouseArea
        {
            anchors.fill: parent
            hoverEnabled: true
            id:mar4
            onClicked:
            {
               // root.globSignalsObject.zoneRemoved(root.innerIndex);
                console.error("slot clicked = ",root.slotIndex);
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

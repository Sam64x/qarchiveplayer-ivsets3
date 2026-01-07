import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.sets.sets3 1.0

Rectangle
{
    id: root
    color: "transparent"
    anchors.fill: parent
    Component.onCompleted:
    {

    }
    QtObject
    {
        id:globSignalsObject
        signal zoneChanged(int index,variant newparams)
        signal zoneSelected(int index,string zoneparams)
        signal setChanged(string setname)
        signal setAdded(string setname)
        signal setRemoved(string setname)
        signal setSelected(string setname)
        signal setSaved(string setname)
        signal setSaved2()
        signal setNameChanged(string setname,string newSetName)
        signal setCopy(string setname)
        signal zonesAdded(string setname,string zone)
        signal setPresset1()
        signal setPresset2()
        signal setPresset3()
    }

    IVCustomSets
    {
        id:customSets
    }
    Rectangle
    {
        id:setsBlockRect
        color: "white"
        height: parent.height
        width: 300
        anchors.left: parent.left
        SetsBlock
        {
            id:setsBlock
            anchors.rightMargin: 5
            anchors.leftMargin: 5
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            globSignalsObject:globSignalsObject
        }
    }
    Rectangle
    {
        id:delimRect1
        anchors.top:parent.top
        anchors.bottom: parent.bottom
        anchors.left: setsBlockRect.right
        width: 4
        //x:parent.width*0.2
        color: "azure"
        Drag.active: true
        MouseArea
        {
            anchors.fill: parent
            id: dragArea
            drag.target: parent
            cursorShape: Qt.SplitHCursor
            drag.axis: Drag.XAxis
            drag.minimumX: 150
            drag.maximumX: 300
            Rectangle
            {
                id:brdRect
                width: 2
                height: parent.height
                color: "lightgray"
            }
        }
    }
    Rectangle
    {
        id:topPanelRect
        color: "white"
        anchors.top: root.top
        anchors.right: delimRect3.left
        anchors.left: delimRect1.right
        height: 110
        TopPanelBlock
        {
            id:topPanelBlock
             globSignalsObject:globSignalsObject

        }

    }
    Rectangle
    {
        id:delimRect2
        anchors.top:topPanelRect.bottom
        anchors.left: delimRect1.right
        anchors.right: delimRect3.left
        height: 4
        //x:parent.width*0.2
        color: "azure"
        Drag.active: true
        MouseArea
        {
            anchors.fill: parent
            id: dragArea2
            drag.target: parent
            cursorShape: Qt.SplitHCursor
            drag.axis: Drag.XAxis
            drag.minimumY: 30
            drag.maximumY: 50
            Rectangle
            {
                id:brdRect2
                height: 2
                width: parent.width
                color: "lightgray"
            }
        }
    }

    Rectangle
    {
        id:setMainRect
        color: "white"
        anchors.left: delimRect1.right
        anchors.right: delimRect3.left
        anchors.top:delimRect2.bottom
        anchors.bottom: root.bottom
        //anchors.topMargin: 3
        //anchors.leftMargin: 3
        IVSetZone
        {
            anchors.fill: parent
            globSignalsObject:globSignalsObject
            isEditor:true

        }
    }
    Rectangle
    {
        id:delimRect3
        anchors.top:parent.top
        anchors.bottom: parent.bottom
        anchors.right:rightPanelRect.left

        width: 4
        //x:parent.width*0.2
        color: "azure"
        Drag.active: true
        MouseArea
        {
            anchors.fill: parent
            id: dragArea3
            drag.target: parent
            cursorShape: Qt.SplitHCursor
            drag.axis: Drag.XAxis
            drag.minimumX: 150
            drag.maximumX: 300
            Rectangle
            {
                id:brdRect3
                width: 2
                height: parent.height
                color: "lightgray"
            }
        }
    }
    Rectangle
    {
        id:rightPanelRect
        anchors.right: root.right
        anchors.top:root.top
        anchors.bottom: root.bottom
       // anchors.left: delimRect3.right
        width: 300
        color: "white"
        RightPanelBlock
        {
            id:rightParentBlock
            anchors.fill: parent
            globSignalsObject:globSignalsObject
        }
    }
}

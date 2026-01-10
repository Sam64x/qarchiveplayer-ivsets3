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
    color:"#d9d9d9"
    anchors.fill: parent
    property var globSignalsObject: null
    property string type: "row"
    signal backClicked()
    property bool backVis: true
    ListModel
    {
        id:camsModel
    }

    onGlobSignalsObjectChanged:
    {
        if(root.globSignalsObject !== null & root.globSignalsObject !== undefined)
        {
          myGlobConnect.target = Qt.binding(function() {return root.globSignalsObject;});
        }
    }
    Component.onCompleted:
    {

    }
    Timer
    {
        id:tmm
        repeat: false
        triggeredOnStart: false
        interval:5000
        running: true
        onTriggered:
        {
            var cams = customSets.getCameras();
            //camsModel.append({key2:"1"});
            var camsArray = [];
            try
            {
                camsArray = JSON.parse(cams);
                for(var keyW in camsArray)
                {
                    camsModel.append({key2:camsArray[keyW]});
                }
            }
            catch(exception)
            {
            }
        }
    }

    Connections
    {
        id:myGlobConnect
    }
    IVCustomSets
    {
        id:customSets
    }
    Rectangle
    {
        id:panelRect
        width: parent.width
        height: 30
        color: "#65da5c"
        Image
        {
            id:backBtn
            source: "file:///"+applicationDirPath + "/images/blue/arrow_left.svg"
            width: 28
            height: 28
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 5
            ToolTip.text: "Назад к выбору наборов"
            ToolTip.delay: 500
            ToolTip.visible:  mar5.containsMouse
            visible: root.backVis
            MouseArea
            {
                anchors.fill: parent
                id:mar5
                hoverEnabled: true
                onClicked:
                {
                    root.backClicked();
                }
                onEntered:
                {
                    backBtn.source="file:///"+applicationDirPath + "/images/black/arrow_left.svg"
                }
                onExited:
                {
                    backBtn.source="file:///"+applicationDirPath + "/images/blue/arrow_left.svg"
                }
            }
        }
        Label
        {
            id:textCams
            anchors.left: backBtn.right
            anchors.right: rowBtn.left
            text:"Камеры"
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 14
        }
        Image
        {
            id:rowBtn
            source: "file:///"+applicationDirPath + "/images/blue/minus.svg"
            width: 28
            height: 28
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: previewBtn.left
            anchors.leftMargin: 5
            ToolTip.text: "Строки"
            ToolTip.delay: 500
            ToolTip.visible:  mar2.containsMouse
            MouseArea
            {
                anchors.fill: parent
                id:mar2
                hoverEnabled: true
                onClicked:
                {
                    root.type = "row";
                }
                onEntered:
                {
                    rowBtn.source="file:///"+applicationDirPath + "/images/black/minus.svg"
                }
                onExited:
                {
                    rowBtn.source="file:///"+applicationDirPath + "/images/blue/minus.svg"
                }
            }
        }
        Image
        {
            id:previewBtn
            source: "file:///"+applicationDirPath + "/images/blue/photo.svg"
            width: 28
            height: 28
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.leftMargin: 5
            ToolTip.text: "Превью"
            ToolTip.delay: 500
            ToolTip.visible:  mar1.containsMouse
            MouseArea
            {
                anchors.fill: parent
                id:mar1
                hoverEnabled: true
                onClicked:
                {
                    root.type = "preview";
                }
                onEntered:
                {
                    previewBtn.source="file:///"+applicationDirPath + "/images/black/photo.svg"
                }
                onExited:
                {
                    previewBtn.source="file:///"+applicationDirPath + "/images/blue/photo.svg"
                }
            }
        }

    }
    Rectangle
    {
        id:camsRect
        width: parent.width
        anchors.top:panelRect.bottom
        anchors.bottom: parent.bottom
        ListView
        {
            id:setsListView
            clip: true
            boundsBehavior: ListView.StopAtBounds
            anchors.fill: parent
            spacing:2
            model:camsModel
            currentIndex: -1

            onCurrentIndexChanged:
            {

            }
            delegate:Component
            {
                Loader
                {
                    height: children.height
                    width: parent.width
                    id:tmpLoad
                    source: switch(root.type)
                    {
                        case "preview": return "IVPreviewCam.qml"
                        case "row": return "IVRowCam.qml"
                    }
                    onStatusChanged:
                    {
                        if(tmpLoad.status === Loader.Ready)
                        {
                            tmpLoad.item.globSignalsObject = root.globSignalsObject;
                        }
                    }
                }
            }
        }
    }
}

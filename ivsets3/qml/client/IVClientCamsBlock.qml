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
    property bool isHided: false
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
            //console.error("hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh 222222222222222222");
            var cams = customSets.getCameras();
            var devices = customSets.getZoneTypes();
            var maps = customSets.getMapsList();
            //console.error("CAMS = ",cams)
            //camsModel.append({key2:"1"});
            var camsArray = [];
            var devicesArray = [];
            var mapsArray = [];
            try
            {
                camsArray = JSON.parse(cams);
                devicesArray = JSON.parse(devices);
                mapsArray = JSON.parse(maps);
                //console.error("cams = ", cams);
                //console.error("devices = ", devices);
                //console.error("maps = ", maps);
                for(var i2 in devicesArray)
                {
                    //console.error("AAAAA =====================",JSON.stringify(devicesArray[i2].params));
                    if(devicesArray[i2].type === "MapViewer" || devicesArray[i2].type === "camera" )
                        continue;
                    camsModel.append({params:devicesArray[i2].params,key2:devicesArray[i2].type ,type: devicesArray[i2].type, qmlPath: devicesArray[i2].qml_path,isVisible:true});
                }
                var params1 = {};

                for(var i4 in mapsArray)
                {
                    //console.error("AAAAA masp  =====================",JSON.stringify(mapsArray[i4].params));
                    params1["jsonDataFileName"] = mapsArray[i4];
                    //var splitName = mapsArray[i4].split(".");
                    //camsModel.append({params:params1,key2:splitName[0] ,type: "MapViewer", qmlPath: "qtplugins/iv/mapviewer/qml/QMapViewer.qml",isVisible:true});
                }

                var params2 = {};
                //params["qmlPath"] = ;
                params2["running"] = true;
                params2["video"] = "#000_FULLSCREEN";
                //console.error("AAAAA =====================222222222",JSON.stringify(camsArray));
                for(var i3 in camsArray)
                {
                    params2["key2"] = camsArray[i3];
                    camsModel.append({type:"camera" ,key2:camsArray[i3], params:params2,qmlPath:"qtplugins/iv/viewers/viewer/IVViewer.qml", isVisible:true});
                }

            }
            catch(exception)
            {
                console.error("IVCAMSBLOCK PARSE CAMS ERROR = ", exception);
            }
        }
    }

    Connections
    {
        id:myGlobConnect
        onCamsHided:
        {
            root.isHided = true;
            //camsRect.height = 0;
            camsRect.visible = false;
        }
        onCamsShowed:
        {
            root.isHided = false;
           // camsRect.height = 0;
            camsRect.visible = true;
        }
        onSearch:
        {
            //console.error("search in cams block st = ", searchText);
            var modelCount = camsModel.count;
            if(searchText === "")
            {
                for(var i1 = 0; i1<modelCount;i1++)
                {
                    camsModel.setProperty(i1,"isVisible",true);
                }
                return;
            }
//            else
//            {
//                for(var i2 = 0; i2<modelCount;i2++)
//                {
//                    camsModel.setProperty(i2,"isVisible",true);
//                }
//            }

            for(var i = 0; i<modelCount;i++)
            {
                var key2 = camsModel.get(i).key2;

                if(key2.indexOf(searchText) === -1 )
                {
                    //console.error("search in cams block key2 = ", key2);
                    camsModel.setProperty(i,"isVisible",false);
                }
                else
                {

                }
            }
        }
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
        color: "#35a8e0"
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
        Image
        {
            id:hideBtn
            source: root.isHided?"file:///"+applicationDirPath + "/images/black/bar_hide.svg":"file:///"+applicationDirPath + "/images/black/bar_vis.svg"
            width: 28
            height: 28
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 5
            ToolTip.text: root.isHided?"Показать камеры":"Скрыть камеры"
            ToolTip.delay: 500
            ToolTip.visible:  mar55.containsMouse
            visible: !root.backVis
            MouseArea
            {
                anchors.fill: parent
                id:mar55
                hoverEnabled: true
                onClicked:
                {

                    if(root.isHided)
                    {
                        root.globSignalsObject.camsShowed();
                    }
                    else
                    {
                        root.globSignalsObject.camsHided();
                    }
                }
                onEntered:
                {
                    //hideBtn.source="file:///"+applicationDirPath + "/images/black/bar_hide.svg"
                }
                onExited:
                {
                    //hideBtn.source="file:///"+applicationDirPath + "/images/black/bar_hide.svg"
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
            font.pixelSize: 20
            font.bold: true
        }
        Image
        {
            id:rowBtn
            source: "file:///"+applicationDirPath + "/images/blue/matchCase.svg"
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
                    rowBtn.source="file:///"+applicationDirPath + "/images/black/matchCase.svg"
                }
                onExited:
                {
                    rowBtn.source="file:///"+applicationDirPath + "/images/blue/matchCase.svg"
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
        color: "#d9d9d9"
//        Rectangle
//        {
//            id:devicesRect
//            width: parent.width
//            anchors.top: parent.top
//            height: devicesListView.contentHeight
//            color: "#d9d9d9"
//            ListModel
//            {
//                id:devicesModel
//            }

//            ListView
//            {
//                id:devicesListView
//                clip: true
//                boundsBehavior: ListView.StopAtBounds
//                anchors.fill: parent
//                spacing:2
//                model:devicesModel
//                currentIndex: -1
//                delegate: Item
//                {
//                    width:parent.width
//                    height:30
//                    Label
//                    {
//                        id:typelabel
//                        text: type
//                        anchors.fill: parent
//                        color: "black"
//                    }
//                }
//            }
//        }

        ListView
        {
            id:camssListView
            clip: true
            boundsBehavior: ListView.StopAtBounds
            anchors.fill: parent
            spacing:2
            model:camsModel
            //height: contentHeight
            currentIndex: -1

            ScrollBar{

            }

            onCurrentIndexChanged:
            {

            }
            delegate:Component
            {
                IVClientCamsDelegate
                {
                    id:camsDel
                    innerIndex:index
                    currentIndex:camssListView.currentIndex
                    globSignalsObject:root.globSignalsObject
                    typeOfDelegate:root.type

                }


            }
        }
    }
}

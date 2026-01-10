import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.plugins.loader 1.0
import iv.sets.sets3 1.0
import QtQuick.Dialogs 1.1

Rectangle
{
    id:root
    color:"transparent"
   // anchors.fill: parent
    property var globSignalsObject: null
    property bool isHided: false
    onGlobSignalsObjectChanged:
    {
        if(root.globSignalsObject !== null & root.globSignalsObject !== undefined)
        {
          myGlobConnect.target = Qt.binding(function() {return root.globSignalsObject;});
        }
    }
    function refreshModel()
    {

    }



    Component.onCompleted:
    {
        var setsList = customSets.getSetsList();
        var setsListArray = JSON.parse(setsList);
        for(var setName in setsListArray)
        {
            setsModel.append({name:setsListArray[setName],local:true,isVisible:true});
        }
        var remoteSetsList = customSets.getRemoteSetsList();
        var remoteSetsListArray = JSON.parse(remoteSetsList);
        for(var setName2 in remoteSetsListArray)
        {

            setsModel.append({name:remoteSetsListArray[setName2],local:false,isVisible:true});
        }
    }
    Connections
    {
        id:myGlobConnect
        onSetNameChanged:
        {
            var oldIndex = 0;
            var setsList = customSets.getSetsList();
            setsModel.clear();

            var setsListArray = JSON.parse(setsList);
            for(var i in setsListArray)
            {

                setsModel.append({name:setsListArray[i],local:true,isVisible:true});
                if(setsListArray[i] === newSetName)
                {
                    oldIndex = i;
                }
            }
            var remoteSetsList = customSets.getRemoteSetsList();
            var remoteSetsListArray = JSON.parse(remoteSetsList);
            for(var setName2 in remoteSetsListArray)
            {

                setsModel.append({name:remoteSetsListArray[setName2],local:false,isVisible:true});
            }
            setsListView.currentIndex = oldIndex;
        }
        onSearch:
        {
            //searchText


            var modelCount = setsModel.count;
            if(searchText === "")
            {
                for(var i1 = 0; i1<modelCount;i1++)
                {
                    setsModel.setProperty(i1,"isVisible",true);
                }
                return;
            }
            else
            {
                for(var i2 = 0; i2<modelCount;i2++)
                {
                    setsModel.setProperty(i2,"isVisible",true);
                }
            }

            for(var i = 0; i<modelCount;i++)
            {
                var setName = setsModel.get(i).name;
                if(!setsModel.get(i).local)
                {
                    if(setName.indexOf(searchText) === -1)
                    {
                        setsModel.setProperty(i,"isVisible",false);
                        continue;
                    }
                }

                if(setName.indexOf(searchText) === -1 )
                {
                    var zones = customSets.getZone(setName);
                    var zonesObj = null;
                    var isFound = false;
                    try
                    {
                        zonesObj = JSON.parse(zones);
                         var zoness = zonesObj["zones"];
                        for(var j = 0;j < zoness.length;j++)
                        {
                            if( zoness[j].type === "camera")
                            {
                                var isContains  = zoness[j].params.key2.indexOf(searchText);

                                if(isContains !== -1)
                                {
                                    isFound = true;
                                    break;
                                }
                            }
                            else if(zoness[j].type !== "camera")
                            {
                                 var isContains2  = zoness[j].type.indexOf(searchText);
                                if(isContains2!== -1)
                                {
                                    isFound = true;
                                    break;
                                }
                            }
                            else
                            {
                                //error
                            }
                        }


                    }
                    catch(exception)
                    {
                    }
                    if(!isFound)
                    {
                        setsModel.setProperty(i,"isVisible",false);
                    }
                    //setsModel.setProperty(i,"isVisible",false);

                }
                else
                {

                }
            }
        }

//        onNewSetAdded:
//        {


//            var setName = "Набор "+(setsModel.count+1);
//            setsModel.append({name:setName,local:true,isVisible:true});
//            setsListView.currentIndex = setsModel.count-1;
//            customSets.saveSet(setName,setName,"{\"cols\":32,\"rows\":32,\"grid_type\":0,\"zones\":[]}");
//            root.globSignalsObject.setAdded(setName);
//        }
//        onSetRemoved:
//        {
//            if(setsListView.currentIndex<0)
//            {
//                messageDialog.text = "Набор не выбран!!!"
//                messageDialog.modality = Qt.WindowModal;
//                messageDialog.standardButtons = StandardButton.Ok;
//                messageDialog.open();
//            }
//            else
//            {
//                messageDialog.setName = setsModel.get(setsListView.currentIndex).name;
//                if(messageDialog.setName !== undefined && messageDialog.setName !== "")
//                {
//                    messageDialog.modality = Qt.WindowModal;
//                    messageDialog.text = "Вы действительно хотите удалить выбранный набор: "+messageDialog.setName+"?"
//                    messageDialog.standardButtons =  StandardButton.Yes | StandardButton.No
//                    messageDialog.open();
//                }
//                else
//                {
//                    //error!!!
//                }
//            }
//        }
        onSetsHided:
        {
            root.isHided = true;
            setsBodyRect.visible = false;
            addRemoveRect.visible = false;

        }
        onSetsShowed:
        {
            root.isHided = false;
            setsBodyRect.visible = true;
            addRemoveRect.visible = true
        }


//        onTabSelected:
//        {
//           // tabname
//            for(var i1 = 0; setsModel.count;i1++)
//            {
//                var setItem = setsModel.get(i1);
//                if(setItem.name === tabname)
//                {
//                    setsListView.currentIndex = i1;
//                }
//            }
//        }

    }
    IVCustomSets
    {
        id:customSets
    }
    Rectangle
    {
        id:setsRect
        color: "#d9d9d9"
       // color: transparent
        width:parent.width
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        z:1
        Rectangle
        {
            id:miniSetupBlock//+-
            anchors.top:parent.top
            width: parent.width
            color: "#35a8e0"
            height: 30

            Image
            {
                id:hideBtn
                source: root.isHided?"file:///"+applicationDirPath + "/images/black/bar_hide.svg":"file:///"+applicationDirPath + "/images/black/bar_vis.svg"
                width: 28
                height: 28
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
                ToolTip.text: root.isHided?"Показать наборы":"Скрыть наборы"
                ToolTip.delay: 500
                ToolTip.visible:  mar55.containsMouse
                MouseArea
                {
                    anchors.fill: parent
                    id:mar55
                    hoverEnabled: true
                    onClicked:
                    {

                        if(root.isHided)
                        {
                            root.globSignalsObject.setsShowed();
                        }
                        else
                        {
//                            root.isHided = true;
//                            setsBodyRect.height = 0;
//                            root.height = 30;
                            root.globSignalsObject.setsHided();
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
                id:textSets
                anchors.left: miniSetupBlock.left
                anchors.right: syncBtn.left
                text:"Наборы"
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 20
                font.bold: true
            }

            Image
            {
                id:syncBtn
                source: "file:///"+applicationDirPath + "/images/blue/load.svg"
                width: 28
                height: 28
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.leftMargin: 5
                ToolTip.text: "Синхронизировать наборы с сервером"
                ToolTip.delay: 500
                ToolTip.visible:  mar5.containsMouse
                MouseArea
                {
                    anchors.fill: parent
                    id:mar5
                    hoverEnabled: true
                    onClicked:
                    {
                        customSets.syncSets();
                    }
                    onEntered:
                    {
                        syncBtn.source="file:///"+applicationDirPath + "/images/black/load.svg"
                    }
                    onExited:
                    {
                        syncBtn.source="file:///"+applicationDirPath + "/images/blue/load.svg"
                    }
                }
            }
        }
        Rectangle
        {
            id:setsBodyRect
            width:parent.width
            anchors.top:miniSetupBlock.bottom
           // anchors.topMargin: 5
           // height: parent.height
            anchors.bottom: addRemoveRect.top
            color: "#d9d9d9"
            //color: "orange"
            ListModel
            {
                id:setsModel
            }
            MessageDialog {
                id: messageDialog
                width: 200
                height: 80
                title: "Удаление набора!"
               // text: "Вы действительно хотите удалить выбранный набор: "+messageDialog.setName+"?"
                property string setName: ""
                visible: false
                standardButtons: StandardButton.Yes | StandardButton.No

                onYes:
                {
                    customSets.deleteSet(messageDialog.setName);
                    var newIndex = setsListView.currentIndex-1;
                    if(newIndex<0)
                    {
                        newIndex = 0;
                    }

                    setsModel.remove(setsListView.currentIndex,1);
                    setsListView.currentIndex = newIndex;
                    root.globSignalsObject.tabRemoved("",-1);
                    messageDialog.close();
                }

                onNo:
                {
                     messageDialog.close();
                }

            }
            ListView
            {
                id:setsListView
                clip: true
                boundsBehavior: ListView.StopAtBounds
                anchors.fill: parent
                spacing:2
                model:setsModel
                currentIndex: -1
                Layout.fillWidth: true
                Layout.fillHeight: true
                ScrollBar
                {
                    id: vbar
                    hoverEnabled: true
                    active: hovered || pressed
                    orientation: Qt.Vertical
                    size: setsListView.height / setsListView.contentHeight
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                }

                IvVcliSetting
                {
                    id:hideNewSets
                    name:"settings.hide_new_sets"
                }

                onCurrentIndexChanged:
                {
                    if(hideNewSets.value === "true")
                    {
                        root.globSignalsObject.setSelected(setsModel.get(setsListView.currentIndex).name);
                    }
                }
                delegate:
                    Component {
                   // width: parent.width
                   // height: setsDel.height
                    IVClientSetsDelegate
                    {
                        id:setsDel
                        //anchors.fill: parent
                        innerIndex:index
                        //width: parent.width
                       // height: 30
                        currentIndex:setsListView.currentIndex
                        globSignalsObject:root.globSignalsObject
                        onDelClicked:
                        {
                            setsListView.currentIndex = index;
                            if(hideNewSets.value === "false");
                            {
                                root.globSignalsObject.tabAdded(setsModel.get(index).name,-1);
                            }
                        }
                        onAddCamsClicked:
                        {
                             setsRect.visible = true;
                             camsRect.visible = true;
                        }
                    }
                }
            }
        }
        Rectangle
        {
            id:addRemoveRect
            anchors.bottom: parent.bottom
            width: parent.width
            height: 30
            color: "#35a8e0"
            Rectangle
            {
                id:plusRect
                width: 28
                height: 28
                color: "#3ad981"
                anchors.left: parent.left
                anchors.leftMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                //opacity: 0.7
                radius: 14
                Image
                {
                    id:plusBtn
                    source: "file:///"+applicationDirPath + "/images/white/plus.svg"
                    //width: 16
                   // height: 16
                    anchors.fill: parent
                   // anchors.verticalCenter: parent.verticalCenter
                    //anchors.left: parent.left
                   // anchors.leftMargin: 5
                    ToolTip.text: "Создать новый набор"
                    ToolTip.delay: 500
                    ToolTip.visible:  mar88.containsMouse
                    MouseArea
                    {
                        anchors.fill: parent
                        id:mar88
                        hoverEnabled: true
                        onClicked:
                        {
                            root.globSignalsObject.newSetAdded("");
                        }
                        onEntered:
                        {
                            plusBtn.source="file:///"+applicationDirPath + "/images/black/plus.svg"
                        }
                        onExited:
                        {
                            plusBtn.source="file:///"+applicationDirPath + "/images/white/plus.svg"
                        }
                    }
                }
            }
            Rectangle
            {
                id:removeSetRect
                width: 28
                height: 28
                color: "red"
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                radius: 14
                //opacity: 0.7
                Image
                {
                    id:removeBtn
                    source: "file:///"+applicationDirPath + "/images/white/delete.svg"
                    //width: 16
                   // height: 16
                    anchors.fill: parent
                   // anchors.verticalCenter: parent.verticalCenter
                    //anchors.left: parent.left
                   // anchors.leftMargin: 5
                    ToolTip.text: "Удалить набор"
                    ToolTip.delay: 500
                    ToolTip.visible:  mar21.containsMouse
                    MouseArea
                    {
                        anchors.fill: parent
                        id:mar21
                        hoverEnabled: true
                        onClicked:
                        {
                            root.globSignalsObject.setRemoved("");
                            //root.globSignalsObject.tabRemoved("",-1);
                        }
                        onEntered:
                        {
                            //plusBtn.source="file:///"+applicationDirPath + "/images/black/plus.svg"
                        }
                        onExited:
                        {
                            //plusBtn.source="file:///"+applicationDirPath + "/images/white/plus.svg"
                        }
                    }
                }

            }
        }
    }
}

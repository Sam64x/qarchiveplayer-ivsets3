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
    color:"white"
    anchors.fill: parent
    property var globSignalsObject: null
    onGlobSignalsObjectChanged:
    {
        if(root.globSignalsObject !== null & root.globSignalsObject !== undefined)
        {
          myGlobConnect.target = Qt.binding(function() {return root.globSignalsObject;});
        }
    }
    Component.onCompleted:
    {
        var setsList = customSets.getSetsList();
        var setsListArray = JSON.parse(setsList);
        console.error("setsList = ",setsList);
        for(var setName in setsListArray)
        {
            console.error("setName = ",setsListArray[setName]);
            setsModel.append({name:setsListArray[setName]});
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
            console.error("setsList = ",setsList);
            for(var i in setsListArray)
            {

                //console.error("setName = ",setsListArray[setName]);
                setsModel.append({name:setsListArray[i]});
                if(setsListArray[i] === newSetName)
                {
                    oldIndex = i;
                }
            }
            setsListView.currentIndex = oldIndex;

        }

    }
    IVCustomSets
    {
        id:customSets
    }


    Rectangle
    {
        id:searchRect
        color: "transparent"
        width:parent.width
        height: 50
        anchors.top:root.top
        Rectangle
        {
            id:searchContainer
            radius: 2
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            border.width: 2
            border.color: "transparent"
            color: "#d0d5db"
            TextInput
            {
                id:searchInput
                anchors.fill: parent
                //displayText: "Поиск..."
                font.pixelSize: 14
                color: "black"
            }
        }
    }
    Rectangle
    {
        id:setsRect
        color: "transparent"
        width:parent.width
        anchors.top:searchRect.bottom
        anchors.bottom: parent.bottom
        z:1
        Rectangle
        {
            id:miniSetupBlock//+-
            anchors.top:parent.top
            width: parent.width
            color: "white"
            height: 30
            Image
            {
                id:plusBtn
                source: "file:///"+applicationDirPath + "/images/blue/plus.svg"
                width: 28
                height: 28
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 5
                ToolTip.text: "Создать набор"
                ToolTip.delay: 500
                ToolTip.visible:  mar2.containsMouse
                MouseArea
                {
                    anchors.fill: parent
                    id:mar2
                    hoverEnabled: true
                    onClicked:
                    {
                        console.error("aaaa plus clicked!!!");
                        var setName = "Набор "+(setsModel.count+1);
                        setsModel.append({name:setName});
                        setsListView.currentIndex = setsModel.count-1;
                        customSets.saveSet(setName,setName,"{\"cols\":32,\"rows\":32,\"zones\":[]}");
                        root.globSignalsObject.setAdded(setName);
                    }
                    onEntered:
                    {
                        plusBtn.source="file:///"+applicationDirPath + "/images/black/plus.svg"
                    }
                    onExited:
                    {
                        plusBtn.source="file:///"+applicationDirPath + "/images/blue/plus.svg"
                    }
                }
            }
            Image
            {
                id:minusBtn
                source: "file:///"+applicationDirPath + "/images/blue/minus.svg"
                width: 28
                height: 28
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: plusBtn.right
                anchors.leftMargin: 5
                ToolTip.text: "Удалить набор"
                ToolTip.delay: 500
                ToolTip.visible:  mar1.containsMouse
                MouseArea
                {
                    anchors.fill: parent
                    id:mar1
                    hoverEnabled: true
                    onClicked:
                    {
                        if(setsListView.currentIndex<0)
                        {
                            messageDialog.text = "Набор не выбран!!!"
                            messageDialog.modality = Qt.WindowModal;
                            messageDialog.standardButtons = StandardButton.Ok;
                            messageDialog.open();
                        }
                        else
                        {
                            messageDialog.setName = setsModel.get(setsListView.currentIndex).name;
                            if(messageDialog.setName !== undefined && messageDialog.setName !== "")
                            {
                                messageDialog.modality = Qt.WindowModal;
                                messageDialog.text = "Вы действительно хотите удалить выбранный набор: "+messageDialog.setName+"?"
                                messageDialog.standardButtons =  StandardButton.Yes | StandardButton.No
                                messageDialog.open();
                            }
                            else
                            {
                                //error!!!
                            }
                        }

                        console.error("aaaa minus clicked!!!");
                    }
                    onEntered:
                    {
                        minusBtn.source="file:///"+applicationDirPath + "/images/black/minus.svg"
                    }
                    onExited:
                    {
                        minusBtn.source="file:///"+applicationDirPath + "/images/blue/minus.svg"
                    }
                }
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
            anchors.topMargin: 5
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            color: "white"
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
                onCurrentIndexChanged:
                {
                    root.globSignalsObject.setSelected(setsModel.get(setsListView.currentIndex).name);
                }
                delegate:
                    Item {
                    width: parent.width
                    height: 60
                    IVSetsDelegate
                    {
                        id:setsDel
                        anchors.fill: parent
                        innerIndex:index
                        currentIndex:setsListView.currentIndex
                        onDelClicked:
                        {
                            console.error("set clicked!!!! index = ",index);
                            setsListView.currentIndex = index;
                            root.globSignalsObject.setSelected(setsModel.get(index).name);
                        }
                        onAddCamsClicked:
                        {
                            console.error("onAddCamsClicked index = ",index);
                            setsRect.visible = false;
                            camsRect.visible = true;
                        }
                    }
                }
            }
        }
    }
    Rectangle
    {
        id:camsRect
        color: "transparent"
        width:parent.width
        anchors.top:searchRect.bottom
        anchors.bottom: parent.bottom
        z:0
        visible: false
        IVCamsBlock
        {
            id:camsBlock
            width:parent.width
            anchors.top:parent.top
            anchors.bottom: parent.bottom
            globSignalsObject:root.globSignalsObject
            onBackClicked:
            {
                setsRect.visible = true;
                camsRect.visible = false;
            }

        }
    }
}

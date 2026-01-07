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
   // anchors.fill: parent
    property var globSignalsObject: null
    property bool isSetsHidden: false
    property bool isCamsHidden: false

    onGlobSignalsObjectChanged:
    {
        if(root.globSignalsObject !== null & root.globSignalsObject !== undefined)
        {
          //myGlobConnect.target = Qt.binding(function() {return root.globSignalsObject;});
        }
    }
    Connections
    {
        id:myConn
        target: root.globSignalsObject
        onTabEditedOff:
        {

        }
        onTabEditedOn:
        {

        }
        onSetsHided:
        {
            root.isSetsHidden = true;
            dragRect.y = 27
            dragRect.visible = false;

        }
        onSetsShowed:
        {
            root.isSetsHidden = false;
            dragRect.y = setsAndCamsRect.height/2-30
            if(root.isCamsHidden)
            {
                dragRect.visible = false;
            }
            else
            {
                dragRect.visible = true;
            }



        }
        onCamsHided:
        {
            root.isCamsHidden = true;
            if(root.isSetsHidden)
            {
                dragRect.y = 27;
                //console.error("sets hidded ,cams hidded")

            }
            else
            {
                dragRect.y =setsAndCamsRect.height-30;
            }
            dragRect.visible = false;
        }
        onCamsShowed:
        {
            root.isCamsHidden = false;
            if(root.isSetsHidden)
            {
                dragRect.y = 27;
                //console.error("sets hidded ,cams showed")

            }
            else
            {
                dragRect.visible = true;
                dragRect.y = setsAndCamsRect.height/2-30
            }

        }



    }

    Rectangle
    {
        id:searchRect
        color:"#d9d9d9"
        width:parent.width
        height: 44
        anchors.top:root.top
        NumberAnimation {
            id:settingsHide
            target: showerRect
            property: "height"
            from:44
            to: 0
            duration: 200
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            id:settingsShow
            target: showerRect
            property: "height"
            from:0
            to: 44
            duration: 200
            easing.type: Easing.InOutQuad
        }

        Rectangle
        {
            id:settingsRect
            width: 88
            height: 44
            anchors.left: parent.left
            color: "#3ad981"
            Image
            {
                id:settingsImg
                source: "file:///"+applicationDirPath + "/images/white/extend.svg"
                width: 44
                height: 44
                anchors.left: parent.left
               // anchors.right: setsImg.left
               // anchors.rightMargin: 5
                ToolTip.text:settingsImg.isOn? "Скрыть режимы показа":"Показать показать режимы показа"
                ToolTip.delay: 500
                ToolTip.visible:  mar8.containsMouse
                property bool isOn: false
                MouseArea
                {
                    anchors.fill: parent
                    id:mar8
                    hoverEnabled: true
                    onClicked:
                    {
                        if(settingsImg.isOn)
                        {
                            settingsImg.isOn = false;
                            settingsImg.source="file:///"+applicationDirPath + "/images/white/extend.svg"
                            //settingsShow.stop();
                            settingsHide.start();
                        }
                        else
                        {
                            settingsImg.isOn = true;
                            settingsImg.source="file:///"+applicationDirPath +"/images/blue/extend.svg"
                            //settingsHide.stop();
                            settingsShow.start();
                        }
                    }
                    onEntered:
                    {
                       // if(!settingsImg.isOn)
                       // {
                           // settingsImg.source="file:///"+applicationDirPath + "/left_pan_butons/filter_ho.svg"
                       // }
                    }
                    onExited:
                    {
                       // if(!settingsImg.isOn)
                       // {
                           // settingsImg.source="file:///"+applicationDirPath + "/images/left_pan_butons/filter.svg"
                       // }
                    }
                }
            }
            Image
            {
                id:serchImg
                source: "file:///"+applicationDirPath + "/images/white/search.svg"
                width: 44
                height: 44
                 anchors.left: settingsImg.right
               // anchors.right: setsImg.left
               // anchors.rightMargin: 5
                ToolTip.text:"Начать поиск"
                ToolTip.delay: 500
                ToolTip.visible:  mar81.containsMouse
                property bool isOn: false
                MouseArea
                {
                    anchors.fill: parent
                    id:mar81
                    hoverEnabled: true
                    onClicked:
                    {
                        searchInput.forceActiveFocus();
                    }
                    onEntered:
                    {
                       // if(!settingsImg.isOn)
                       // {
                           // settingsImg.source="file:///"+applicationDirPath + "/left_pan_butons/filter_ho.svg"
                       // }
                    }
                    onExited:
                    {
                       // if(!settingsImg.isOn)
                       // {
                           // settingsImg.source="file:///"+applicationDirPath + "/images/left_pan_butons/filter.svg"
                       // }
                    }
                }
            }


        }
        Rectangle
        {
            id:searchContainer
           // radius: 2

            //anchors.fill: parent
            anchors.left: settingsRect.right
           // anchors.leftMargin: 1
            anchors.right: parent.right
            //anchors.rightMargin: 1
            anchors.top:parent.top
            //anchors.topMargin:1
            anchors.bottom:parent.bottom
            //anchors.bottomMargin: 1
            //border.width: 2
            border.color: "transparent"
            color: "#3ad981"
            clip: true
            TextInput
            {
                id:searchInput
                height: parent.height
                anchors.left: parent.left
                anchors.right: serchCancelImg.left
                //anchors.fill: parent
                //preeditText: "awdawd"
                //displayText: "Поиск..."
                font.pixelSize: 18
                color: "black"
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                clip:true
                onTextEdited:
                {
                    root.globSignalsObject.search(searchInput.text);
                }

            }
            Image
            {
                id:serchCancelImg
                source: "file:///"+applicationDirPath + "/images/white/clear.svg"
                width: 44
                height: 44
                 anchors.right: parent.right
               // anchors.right: setsImg.left
               // anchors.rightMargin: 5
                ToolTip.text:"Отменить поиск"
                ToolTip.delay: 500
                ToolTip.visible:  mar821.containsMouse
                property bool isOn: false
                visible: searchInput.text !== ""
                MouseArea
                {
                    anchors.fill: parent
                    id:mar821
                    hoverEnabled: true
                    onClicked:
                    {
                        searchInput.text = "";
                        root.globSignalsObject.search("");

                    }
                    onEntered:
                    {
                       // if(!settingsImg.isOn)
                       // {
                           // settingsImg.source="file:///"+applicationDirPath + "/left_pan_butons/filter_ho.svg"
                       // }
                    }
                    onExited:
                    {
                       // if(!settingsImg.isOn)
                       // {
                           // settingsImg.source="file:///"+applicationDirPath + "/images/left_pan_butons/filter.svg"
                       // }
                    }
                }
            }
        }
    }
    Rectangle
    {
        id:showerRect
        width: parent.width
        anchors.top:searchRect.bottom
        height: 0
        color: "transparent"
        Image
        {
            id:cameraImg
            source: "file:///"+applicationDirPath + "/images/blue/camera.svg"
            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: setsImg.left
            anchors.rightMargin: 5
            ToolTip.text:cameraImg.isOn? "Скрыть блок камер":"Показать блок камер"
            ToolTip.delay: 500
            ToolTip.visible:  mar2.containsMouse
            property bool isOn: false
            visible: showerRect.height<30?false:true
            MouseArea
            {
                anchors.fill: parent
                id:mar2
                hoverEnabled: true
                onClicked:
                {
                    if(cameraImg.isOn)
                    {
                        cameraImg.isOn = false;
                        cameraImg.source="file:///"+applicationDirPath + "/images/black/camera.svg";

                    }
                    else
                    {
                        cameraImg.isOn = true;
                        cameraImg.source="file:///"+applicationDirPath + "/images/blue/camera.svg"
                    }
                }
                onEntered:
                {
                    //cameraImg.source="file:///"+applicationDirPath + "/images/black/camera.svg"
                }
                onExited:
                {
                    //cameraImg.source="file:///"+applicationDirPath + "/images/blue/camera.svg"
                }
            }
        }
        Image
        {
            id:setsImg
            source: "file:///"+applicationDirPath + "/images/blue/edit.svg"
            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
           // anchors.leftMargin: 5
            ToolTip.text:setsImg.isOn? "Скрыть блок наборов":"Показать блок наборов"
            ToolTip.delay: 500
            ToolTip.visible:  mar1.containsMouse
            property bool isOn: true
            visible: showerRect.height<30?false:true
            MouseArea
            {
                anchors.fill: parent
                id:mar1
                hoverEnabled: true
                onClicked:
                {
                    if(setsImg.isOn)
                    {
                        setsImg.isOn = false;
                        setsImg.source="file:///"+applicationDirPath + "/images/blue/edit.svg"
                    }
                    else
                    {
                        setsImg.isOn = true;
                        setsImg.source="file:///"+applicationDirPath + "/images/white/edit.svg"
                    }
                }
                onEntered:
                {
                   // minusBtn.source="file:///"+applicationDirPath + "/images/black/minus.svg"
                }
                onExited:
                {
                   //minusBtn.source="file:///"+applicationDirPath + "/images/blue/minus.svg"
                }
            }
        }
    }
    Rectangle
    {
        id:setsAndCamsRect
        color: "#d9d9d9"
       // color:"green"
        anchors.top: showerRect.bottom
        anchors.bottom: addRemoveRect.top
        //anchors.bottomMargin: 30
        width: parent.width
        Rectangle
        {
            id:setsRect
            width: parent.width
            //height: setsImg.isOn?(cameraImg.isOn?parent.height/2 -30:parent.height):0
            anchors.top:parent.top
            anchors.bottom: dragRect.top
            //visible: setsImg.isOn?false:true
             color: "#d9d9d9"
           // color: "blue"
            IVClientSetsBlock
            {
                id:setsBlock
                //color: "transparent"
                width:parent.width
                anchors.fill: parent
                globSignalsObject:root.globSignalsObject

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
                        //console.error("aaaa plus clicked!!!");
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
                        //console.error("aaaa plus clicked!!!");
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

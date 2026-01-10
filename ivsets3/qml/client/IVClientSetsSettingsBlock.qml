import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import QtQuick.Dialogs 1.1
import iv.sets.sets3 1.0
Rectangle
{
    /*
    1) Сделать прессеты из свг
    2) Сделать слоты в прессетах + свободное редактирование
    3) Сделать виртуальный набор с просмотром одиночной камеры + добавление камер в этот набор
    4) Не обосраться на совещании
    */

    id:root
   // anchors.fill: parent
    color: "#d9d9d9"
    property string qmlfile: "/qtplugins/iv/sets/sets3/IVSetZone.qml"
    property var globSignalsObject: null
    property string setName: ""
    property bool isAutoMode: false
    function getTempFunc()
    {
        cliCamsSlots.getZonesFromSETS();
    }

    Connections
    {
        id:myConn
        target: root.globSignalsObject
        onSetSelected:
        {
            root.setName = setname;
        }
        onCamsAutoModeOn:
        {
            doneImg2._pressed = true;
        }
        onCamsAutoModeOff:
        {
            doneImg2._pressed = false;
        }
    }
    Rectangle
    {
        id:leftBlackRect
        anchors.left: parent.left
        width: 1
        color: "black"
        height: parent.height
        z:2
    }
    Rectangle
    {
        id:nameRect
        width: parent.width
        color: "#3ad981"
        height: 44
        anchors.top:parent.top
        TextInput
        {
            anchors.fill: parent
            text:root.setName
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 18
            color: "black"
            id:setNameEditor
            onTextEdited:
            {
                //root.setName = setNameEditor.text;
            }
        }
    }
    IVClientCamsSlots
    {
        id:cliCamsSlots
        width: parent.width
        globSignalsObject: root.globSignalsObject
        anchors.top:  nameRect.bottom
        anchors.bottom: saveSetRect.top
    }
    IVCustomSets
    {
        id:customSets
    }
    Rectangle
    {
        id:saveSetRect
        width: parent.width
        height: 28
        anchors.bottom: settingsRect.top
        color: "#d9d9d9"
        Image
        {
            id:plusImg
            source: "file:///"+applicationDirPath + "/images/blue/plus.svg"
            width:28
            height: 28
            //anchors.top: parent.top
            //anchors.topMargin: 2
            anchors.left: parent.left
            anchors.leftMargin: 3
            property real scalePower: 1
            scale: plusImg.scalePower
            ToolTip.text: "Добавить пустую зону"
            ToolTip.delay: 1000
            ToolTip.visible:  mar1.containsMouse
            property bool _pressed: false
            MouseArea
            {
                anchors.fill: parent
                hoverEnabled: true
                id:mar1
                onClicked:
                {
                    root.globSignalsObject.addEmptySlot();
                }
                onEntered:
                {
                    //plusImg.scalePower = 0.8
                }
                onExited:
                {
                    //plusImg.scalePower = 1
                }
            }
        }
        Image
        {
            id:minusImg
            source: "file:///"+applicationDirPath + "/images/blue/minus.svg"
            width: 28
            height: 28
           // anchors.top: parent.top
           // anchors.topMargin: 2
            anchors.left: plusImg.right
            anchors.leftMargin: 3
            property real scalePower: 1
            scale: minusImg.scalePower
            ToolTip.text: "delete empty zone"
            ToolTip.delay: 1000
            ToolTip.visible:  mar2.containsMouse
            property bool _pressed: false
            MouseArea
            {
                anchors.fill: parent
                hoverEnabled: true
                id:mar2
                onClicked:
                {

                }
                onEntered:
                {
                    minusImg.scalePower = 0.8
                }
                onExited:
                {
                    minusImg.scalePower = 1
                }
            }
        }
        Image
        {
            id:exitImg
            source: "file:///"+applicationDirPath + "/images/blue/arrow_left.svg"
            width: 28
            height: 28
            anchors.left: minusImg.right
            anchors.leftMargin: 3
            property real scalePower: 1
            scale: exitImg.scalePower
            ToolTip.text: "Exit"
            ToolTip.delay: 1000
            ToolTip.visible:  mar8.containsMouse
           // property bool _pressed: false
            MouseArea
            {
                anchors.fill: parent
                hoverEnabled: true
                id:mar8
                onClicked:
                {
                    //var isEditor = root.globSignalsObject.getEditorStatus();
                    //if(isEditor)
                    {
                        root.globSignalsObject.tabEditedOff();
                    }

                }
            }
        }
        Rectangle
        {
            width: 28
            height: 28
            id:doneRect3
            anchors.top: parent.top
            //anchors.topMargin: 2
            anchors.right: doneRect2.left
            anchors.leftMargin: 3
            color: "black"
            Image
            {
                id:doneImg3
                source: "file:///"+applicationDirPath + "/images/white/swap_v.svg"
                anchors.fill: parent
                property real scalePower: 1
                scale: doneImg3.scalePower
                ToolTip.text: "Добавить все камеры в пустые зоны"
                ToolTip.delay: 1000
                ToolTip.visible:  mar333.containsMouse
                property bool _pressed: false
                MouseArea
                {
                    anchors.fill: parent
                    hoverEnabled: true
                    id:mar333
                    onClicked:
                    {
                        cliCamsSlots.autoSetAll();
                    }
                    onEntered:
                    {
                        //doneImg.scalePower = 0.8
                    }
                    onExited:
                    {
                        //doneImg.scalePower = 1
                    }
                }
            }
        }
        Rectangle
        {
            width: 28
            height: 28
            id:doneRect2
            anchors.top: parent.top
            //anchors.topMargin: 2
            anchors.right: doneRect.left
            anchors.leftMargin: 3
            color: "white"
            Image
            {
                id:doneImg2
                source: doneImg2._pressed?"file:///"+applicationDirPath + "/images/black/done.svg":"file:///"+applicationDirPath + "/images/blue/done.svg"
                anchors.fill: parent
                property real scalePower: 1
                scale: doneImg.scalePower
                ToolTip.text: !doneImg2._pressed? "Включить быстрое добавление камер в набор":"Выключить быстрое добавление камер в набор"
                ToolTip.delay: 1000
                ToolTip.visible:  mar33.containsMouse
                property bool _pressed: false
                MouseArea
                {
                    anchors.fill: parent
                    hoverEnabled: true
                    id:mar33
                    onClicked:
                    {

                        if(doneImg2._pressed)
                        {
                            root.globSignalsObject.camsAutoModeOff();
                        }
                        else
                        {
                            root.globSignalsObject.camsAutoModeOn();
                        }
                    }
                    onEntered:
                    {
                        //doneImg.scalePower = 0.8
                    }
                    onExited:
                    {
                        //doneImg.scalePower = 1
                    }
                }
            }
        }
        Rectangle
        {
            width: 28
            height: 28
            id:doneRect
            anchors.top: parent.top
            //anchors.topMargin: 2
            anchors.right: cancelRect.left
            anchors.leftMargin: 3
            color: "black"
            MessageDialog {
                id: messageDialog
                width: 200
                height: 80
                title: "Сохранение набора"
                property string setName: ""
                visible: false
                standardButtons: StandardButton.Apply
                onApply:
                {
                }
            }
            Image
            {
                id:doneImg
                source: "file:///"+applicationDirPath + "/images/white/save.svg"
                anchors.fill: parent
                property real scalePower: 1
                scale: doneImg.scalePower
                ToolTip.text: "Сохранить набор"
                ToolTip.delay: 1000
                ToolTip.visible:  mar3.containsMouse
                property bool _pressed: false
                MouseArea
                {
                    anchors.fill: parent
                    hoverEnabled: true
                    id:mar3
                    onClicked:
                    {
                        if(setNameEditor.text === "")
                        {
                            //root.globSignalsObject.setSaved(root.setName);
                            messageDialog.text = "Имя набора не задано. Пожалуйста, выберете имя."
                            messageDialog.open();
                            return;
                        }
                        else
                        {
                            if(setNameEditor.text === root.setName)
                            {
                                root.globSignalsObject.setSaved("");
                            }
                            else
                            {
                                var setsList = customSets.getSetsList();
                                //var setsListObject = JSON.parse(setsList);
                                var lowerNewSetName = setNameEditor.text.toLowerCase();
                                for(var i = 0; i<setsList.length;i++)
                                {
                                    var savedSetName = setsListObject[i]["setName"].toLowerCase();
                                    if(savedSetName === lowerNewSetName)
                                    {
                                        messageDialog.text = "Имя набора совпадает с уже созданным набором. Пожалуйста, выберете другое имя."
                                        messageDialog.open();
                                        return;
                                    }
                                }
                                root.globSignalsObject.setSaved(setNameEditor.text);
                            }
                        }
                    }
                    onEntered:
                    {
                        //doneImg.scalePower = 0.8
                    }
                    onExited:
                    {
                        //doneImg.scalePower = 1
                    }
                }
            }
        }

        Rectangle
        {
            id:cancelRect
            width: 28
            height: 28
            anchors.top: parent.top
            //anchors.topMargin: 2
            anchors.right: parent.right
            anchors.leftMargin: 3
            color: "red"
            Image
            {
                id:cancelImg
                source: "file:///"+applicationDirPath + "/images/white/cancel.svg"
                anchors.fill: parent
                property real scalePower: 1
                scale: cancelImg.scalePower
                ToolTip.text: "Отменить изменения"
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
                        setNameEditor.text = root.setName;
                        root.globSignalsObject.setRefreshed(root.setName);
                    }
                    onEntered:
                    {
                        //cancelImg.scalePower = 0.8
                    }
                    onExited:
                    {
                       // cancelImg.scalePower = 1
                    }
                }
            }
        }
    }
    Rectangle
    {
        id:settingsRect
        width: parent.width
        anchors.bottom: parent.bottom
        color: "lightgray"
        height: 150
        Rectangle
        {
            id:pressetSettings
            color: "transparent"
            anchors.fill: parent
            ListModel
            {
                id:pressetsModel
                ListElement
                {
                    name:"set.svg"
                    tooltiptext:"Свободный прессет"

                }
                ListElement
                {
                    name:"first.png.svg"
                    tooltiptext:"Свободный прессет"
                }
                ListElement
                {
                    name:"second.png.svg"
                    tooltiptext:"Свободный прессет"
                }
                ListElement
                {
                    name:"third.png.svg"
                    tooltiptext:"Свободный прессет"
                }
                ListElement
                {
                    name:"fourth.png.svg"
                    tooltiptext:"Свободный прессет"
                }
                ListElement
                {
                    name:"fifth.png.svg"
                    tooltiptext:"Свободный прессет"
                }
                ListElement
                {
                    name:"sixth.png.svg"
                    tooltiptext:"Свободный прессет"
                }

            }
            GridView
            {
                id:pressetsListView
                clip: true
                boundsBehavior: ListView.StopAtBounds
                anchors.fill: parent
                anchors.leftMargin: 5
                anchors.rightMargin: 5
                anchors.topMargin: 5
                anchors.bottomMargin: 5
                model: pressetsModel
                cellHeight: 60
                cellWidth: 60
                delegate:
                Component
                {
                    id:delComp
                    Rectangle
                    {
                        width: 60
                        height: 60
                        color:"gray"
                        ToolTip.delay: 500
                        ToolTip.text: tooltiptext
                        ToolTip.visible:awd.containsMouse
                        Image
                        {
                            id: pressetImage
                            anchors.fill: parent
                            source: "file:///"+applicationDirPath + "/images/pressets/"+name
                            MouseArea
                            {
                                id:awd
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked:
                                {
                                    //if(name === "presset1")
                                   // {
                                        root.globSignalsObject.setPressetIndex(index);
                                    //}
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

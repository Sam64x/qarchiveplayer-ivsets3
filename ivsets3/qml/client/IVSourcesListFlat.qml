import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import QtGraphicalEffects 1.0
import iv.plugins.loader 1.0
import iv.sets.sets3 1.0
import QtQuick.Dialogs 1.1
import iv.colors 1.0
import iv.controls 1.0
Rectangle
{
    id:root
    color: "transparent"
    property var customSets:null
    property var devices:null
    property var globSignalsObject:null
    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }
    property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1
    property var  messageDialog: null
    property bool useAnimation:true
    property var maximumSetsheight: root.height/2 - 40
    property bool isSetsVisible:true
    property bool isEditor: false
    property bool setNeedCamsVisible: newSetsHideCames.value==="false" || newSetsHideCames.value===""?true:false
    property bool isSameOpened: false
    property bool isAllOpen: false
    property bool isHideSets: hideSets.value==="true"
    property string currentTab:""
    signal openSignal()
    signal searchSignal()
    property bool isFixArchive: archive_fix.value === "true"


    function openAll()
    {
        root.isAllOpen = true;
        root.isSameOpened = true;
        root.openSignal();
    }
    function closeAll()
    {
        root.isAllOpen = false;
        root.isSameOpened=false;
        root.openSignal();
    }

    IvVcliSetting {
        id: newSetsHideCames
        name: 'settings.new_sets_hide_cams'
    }
    Component.onCompleted:
    {
      //  root.isSetsVisible = root.globSignalsObject.getEditorStatus()
    }
    IvVcliSetting {
        id:hideSets
        name: 'settings.hide_new_sets'
    }
    IvVcliSetting {
        id: archive_fix
        name: 'archive.fixVisible'
    }
    Connections
    {
        id:myConn
        target: root.globSignalsObject
        //onShowSetsAndCams: root.opened = true
       // onHideSetsAndCams: root.opened = false


        onTabSelected5:
        {
          root.currentTab = tabname;

        }

        onTabEditedOff:
        {
            //listDownPanel.updateValue();
            //listDownPanel.visible = false;
            root.isSetsVisible = true;
            root.isEditor = false;

        }
        onTabEditedOn:
        {
            //listDownPanel.visible = true;
            root.isSetsVisible = false;
            root.isEditor = true;
        }
        onSetNameChanged:
        {
//            root.setName = newSetName;
//            devices.remove()
//            console.error("onSetNameChanged devices.init")
//            devices.init("sources")
        }
        onSetRemoved2:
        {
            console.error("DELETE SET onSetRemoved2",setname, setId)
            root.customSets.deleteSet2(setname, setId);
        }
    }
    Item
    {
        id: setsAndCamsCommonRect
        //color: "transparent"
        anchors.fill: parent
        anchors.bottomMargin: 16
        Timer
        {
            id:reloadTimer
            interval: 60000
            triggeredOnStart: false
            repeat: false
            running: false
            onTriggered:
            {
                //console.error("onCurrentUserChanged" , userName);
                //root.devices.remove()
                //console.error("devices.init")
                //root.devices.init("sources")
            }
        }
        Component
        {
            id:customComponent
            Item
            {
                id:customRect
               // color: "transparent"
                //radius: 8 *root.isize
                anchors.left: parent.left
                anchors.right: parent.right
                //property int currIndex:customRect.parent.parent.parent.model.index
                property var modelVis: customRect.model.getProp("visible")
                property var name: customRect.model.getProp("name_")
                property var type:customRect.model.getProp("type")
                property string view_type:customRect.model.getProp("view_type")
                property var isVisible: customRect.model.visible//customRect.model.getProp("visible")
                property var model: null
                property bool opened: customRect.model.opened//customRect.model.getProp("opened")
                visible: isVisible
                height: isVisible?(customRect.opened === true?(headerRect.height+bodyRect.height):headerRect.height):0
                function open()
                {
                    //customRect.opened = true;
                    customRect.model.opened = true;
                    root.isSameOpened = true;
                }
                function close()
                {
                    customRect.model.opened = false;
                    //customRect.opened = false;
                }
                Connections
                {
                    id:myCustom
                    target: root
                    onOpenSignal:
                    {
                        //customRect.opened = Qt.binding(function(){return root.isAllOpen});
                        customRect.model.opened = root.isAllOpen;
                    }
                }

                //property bool isCurrentItem: customRect.currIndex === componentListView.currentIndex?true:false
                Rectangle
                {
                    id:headerRect
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    color:IVColors.get("Colors/Background new/BgListPrimaryThemed")
                    height: buttText.paintedHeight>40?buttText.paintedHeight*root.isize:40*root.isize
                    radius:8
                    state: "normal"
                    property string imagePath:"new_images/help-circle.svg"
                    IVToolTip {
                        text: customRect.name
                        visible: ma4.containsMouse
                    }
                    IVContextMenu
                    {
                        id: contextMenu
                        x: ma4.clickPosX
                        y: ma4.clickPosY
                        function refresh()
                        {
                            menuModel.refreshModel();
                        }

                        component: Component {
                            ListView {
                                model: menuModel
                                width: 254 * root.isize
                                height: contentHeight

                                delegate: IVContextMenuItem {
                                    width: parent.width
                                    type: model.status ? model.status : IVContextMenuItem.Type.Default
                                    source: model.icon ? model.icon : ""
                                    text: model.text ? model.text : ""
                                    enabled: model.enabled ? model.enabled : true
                                    onClicked:
                                    {
//                                        if(action === "open")
//                                        {
//                                            root.globSignalsObject.tabAdded2(groupRect.name,groupRect.type);
//                                        }
//                                        else if(action === "open_archive")
//                                        {
//                                            root.globSignalsObject.tabAdded3(groupRect.name,groupRect.type,"archive");
//                                        }
//                                        else if(action === "settings")
//                                        {
//                                            root.globSignalsObject.tabAdded2(groupRect.name,groupRect.type);
//                                            root.globSignalsObject.tabEditedOn();
//                                        }
//                                        else if(action === "remove")
//                                        {

//                                        }
//                                        else
//                                        {

//                                        }

                                        contextMenu.close();
                                    }
                                }
                            }
                        }
                        ListModel
                        {
                            id: menuModel
                            Component.onCompleted:
                            {
                               // refreshModel();
                            }
                            function refreshModel()
                            {
                                clear();
                                console.error("refreshModel() items in menu")

                                    console.error("append items in menu")
//                                    append({text: "Открыть",
//                                               status: IVContextMenuItem.Type.Default,
//                                               icon: "new_images/expand",
//                                               enabled: true,
//                                               action: "open"
//                                           });
//                                    append({text: "Открыть в архиве",
//                                               status: IVContextMenuItem.Type.Default,
//                                               icon: "new_images/expand",
//                                               enabled: true,
//                                               action: "open_archive"
//                                           });
//                                    append({text: "Редактировать",
//                                               icon: "new_images/settings-04",
//                                               status: IVContextMenuItem.Type.Default,
//                                               enabled: true,
//                                               action: "settings"
//                                           });

//                                    if (groupRect.isLocal) {
//                                        append({text: "Удалить",
//                                                   icon: "new_images/del",
//                                                   status: IVContextMenuItem.Type.Critical,
//                                                   enabled: true,
//                                                   action: "remove"
//                                               });
//                                    }
                            }
                        }
                    }
                    MouseArea
                    {
                        anchors.fill: parent
                        hoverEnabled: true
                        //propagateComposedEvents: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        property var clickPosX: 0
                        property var clickPosY: 0
                        id:ma4
                        //drag.target: groupRect
                        //drag.onActiveChanged:
                        //{
    //                        if (ma4.drag.active)
    //                        {
    //                            dropArea.enabled = false;
    //                            root.fromListView = groupRect.parent.parent.parent;
    //                            //console.error("ON DRAG =" ,groupRect.parent , groupRect.parent.parent,groupRect.parent.parent.parent,groupRect.parent.parent.parent.parent,groupRect.parent.parent.parent.parent.parent);
    //                            root.fromListView.dragItemIndex = groupRect.currIndex;
    //                            console.error("ON DRAG =" , root.fromListView,root.fromListView.dragItemIndex , root.fromListView.model.count);
    //                        }
    //                        else
    //                        {
    //                            dropArea.enabled = true;
    //                        }

    //                        groupRect.Drag.drop();
                       // }
                        //drag.target: groupRect
                        //onClicked:
                       // {

                            //componentListView.currentIndex = groupRect.currIndex;
                            //root.selectedGroup = groupRect;

                        //}
                        onContainsMouseChanged: {
                            if (containsMouse) headerRect.state = "hovered"
                            else headerRect.state = "normal"
                        }
                        onPressed: {
                            headerRect.state = "pressed"
                        }
                        onClicked: {
                            //console.error("MOUSE CLICKED")
                            if(mouse.button & Qt.RightButton)
                            {

                                    //console.error("MOUSE CLICKED RIGHT")
                                    ma4.clickPosX= mouseX;
                                    ma4.clickPosY= mouseY;
                                    contextMenu.refresh();
                                    contextMenu.open();
                            }
                            else
                            {
                                //console.error("MOUSE CLICKED LEFT")
                                if (ma4.containsMouse){
                                    if (customRect.view_type === "group")
                                    {
                                        if(customRect.opened)
                                        {
                                            customRect.close();
                                        }
                                        else
                                        {
                                            customRect.open();
                                        }
                                    }
                                    else root.clicked()
                                    customRect.state = "hovered"
                                }
                                else headerRect.state = "normal"
                            }
                        }
                        onDoubleClicked:
                        {


                        }

                    }
                    states:
                    [
                        State {
                            name: "normal"
                            PropertyChanges {
                                target: headerRect
                                color: IVColors.get("Colors/Background new/BgListPrimaryThemed")
                            }
//                            PropertyChanges {
//                                target: buttText
//                                color: groupRect.type === "group" ?
//                                               IVColors.get("Colors/Text new/TxAccentThemed") :
//                                               IVColors.get("Colors/Text new/TxPrimaryThemed")
//                            }
    //                        PropertyChanges {
    //                            target: checkImage
    //                            color: !root.selected ? IVColors.get("Colors/Text new/TxTertiaryThemed") :
    //                                                    IVColors.get("Colors/Text new/TxAccentThemed")
    //                        }
    //                        PropertyChanges {target: icon; color: IVColors.get("Colors/Text new/TxAccentThemed")}
    //                        PropertyChanges {target: iconArrow; color: IVColors.get("Colors/Text new/TxTertiaryThemed")}
    //                        PropertyChanges {target: lockImage; color: IVColors.get("Colors/Text new/TxSecondaryThemed")}
                        },
                        State {
                            name: "hovered"
                            PropertyChanges {
                                target: headerRect
                                color: customRect.view_type === "group" ?
                                               IVColors.get("Colors/Background new/BgBtnTertiaryThemed-hover") :
                                               IVColors.get("Colors/Background new/BgFormAccent")
                            }
    //                        PropertyChanges {
    //                            target: buttText
    //                            color: root.type === IVListElement.Type.Group ?
    //                                           IVColors.get("Colors/Text new/TxAccentThemed") :
    //                                           IVColors.get("Colors/Text new/TxContrast")
    //                        }
    //                        PropertyChanges {
    //                            target: icon
    //                            color: root.type === IVListElement.Type.Group ?
    //                                           IVColors.get("Colors/Text new/TxAccentThemed") :
    //                                           IVColors.get("Colors/Text new/TxContrast")
    //                        }
    //                        PropertyChanges {
    //                            target: checkImage
    //                            color: !root.selected ? IVColors.get("Colors/Text new/TxSecondaryContrast") :
    //                                                    IVColors.get("Colors/Text new/TxContrast")
    //                        }
                            //PropertyChanges {target: iconArrow; color: IVColors.get("Colors/Text new/TxTertiaryThemed")}
                            //PropertyChanges {target: lockImage; color: IVColors.get("Colors/Text new/TxSecondaryContrast")}
                        },
                        State {
                            name: "pressed"
                            PropertyChanges {
                                target: headerRect
                                color: customRect.view_type === "group" ?
                                               IVColors.get("Colors/Background new/BgBtnTertiaryThemed-click") :
                                               IVColors.get("Colors/Background new/BgFormAccent")
                            }
    //                        PropertyChanges {
    //                            target: buttText
    //                            color: root.type === IVListElement.Type.Group ?
    //                                           IVColors.get("Colors/Text new/TxAccentThemed") :
    //                                           IVColors.get("Colors/Text new/TxContrast")
    //                        }
    //                        PropertyChanges {
    //                            target: icon
    //                            color: root.type === IVListElement.Type.Group ?
    //                                           IVColors.get("Colors/Text new/TxAccentThemed") :
    //                                           IVColors.get("Colors/Text new/TxContrast")
    //                        }
    //                        PropertyChanges {
    //                            target: checkImage
    //                            color: !root.selected ? IVColors.get("Colors/Text new/TxSecondaryContrast") :
    //                                                    IVColors.get("Colors/Text new/TxContrast")
    //                        }
    //                        PropertyChanges {target: iconArrow; color: IVColors.get("Colors/Text new/TxTertiaryThemed")}
    //                        PropertyChanges {target: lockImage; color: IVColors.get("Colors/Text new/TxSecondaryContrast")}
                        }
                    ]
                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        //z:10

                        onDropped: {
                            //var cccp = root.fromListView.model.get(root.fromListView.dragItemIndex);
                            //console.error("ON DROPPED =" , root.fromListView,componentListView,root.fromListView.dragItemIndex ,root.fromListView.model.count,  cccp.name,cccp.type,cccp.key2);
                            //componentModel.insert(0,cccp);
                            //root.fromListView.model.remove(root.fromListView.dragItemIndex)
                            //console.error(componentModel,root.fromListView.model);
                           // root.fromListView.dragItemIndex = -1;

                            //componentModel.insert(0,{name:"GROUP",type:"group",key2:"", params:{},local:true,qmlPath:"",isVisible:true});
                        }
                    }
//                    IVImage
//                    {
//                        id: typeImage
//                        width: 20*root.isize
//                        height: 20*root.isize
//                        name:headerRect.imagePath
//                        visible:  true
//                        fillMode: Image.PreserveAspectFit
//                        anchors.verticalCenter: parent.verticalCenter
//                        anchors.left: parent.left
//                        anchors.leftMargin: 8
//                        color:IVColors.get("Colors/Text new/TxAccentThemed")
//                        //anchors.topMargin: 8
//                        //anchors.top: parent.top
//                    }
                    Item
                    {
                        id:icoRect
                        width: 24 * root.isize
                        height: 24 * root.isize
                        //color: "transparent"
                        anchors
                        {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: 8
                        }
                        IVImage
                        {
                            id: iconArrow
                            visible:customRect.type === "set"?(root.setNeedCamsVisible?true:false):true
                            name: customRect.opened?"new_images/chevron-down":"new_images/chevron-right"
                            fillMode: Image.PreserveAspectFit

                            //rotation: iconArrow.opened ? 180 : 0
                            anchors.centerIn: parent
                            width: 24 * root.isize
                            height: 24 * root.isize
                            color: IVColors.get("Colors/Text new/TxTertiaryThemed")
                            MouseArea
                            {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked:
                                {
                                    //console.error("MOUSE CLIECKED ON CUSTOM HEADER", customRect.opened)
                                    if(customRect.opened)
                                    {
                                       // console.error("customRect.opened true close menu");
                                        customRect.close();
                                    }
                                    else
                                    {
                                        //console.error("customRect.opened false open menu");
                                        customRect.open();
                                    }
                                }
                            }
                        }
                    }
                    Text
                    {
                        id: buttText
                        text: customRect.name
                        clip: true
                        elide: Text.ElideRight
                        font: IVColors.getFont("Label accent")
                        wrapMode: Text.WordWrap
                        anchors
                        {
                            verticalCenter: parent.verticalCenter
                            left: icoRect.right
                            right: rightBlockRect.left
                        }
                        //height: parent.height
                        color: "white"
                    }


                    Item
                    {
                        id:rightBlockRect
                        //color:"transparent"//Qt.rgba(255, 255, 255, 0.1)
                        width: 69*root.isize
                        height: 40*root.isize
                        anchors.right: headerRect.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle
                        {
                            width: 20*root.isize
                            height: 24*root.isize
                            radius: 8*root.isize
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            id:tempRect2
                            color:Qt.rgba(255, 255, 255, 0.1)
//                            Rectangle
//                            {
//                                id:notAvalRect
//                                width: 16
//                                height: 16
//                                radius: 8
//                                color:IVColors.get("Colors/Statuse new/Defective")
//                                visible: true//(groupRect.isNotAvalCount!== undefined && groupRect.isNotAvalCount>0)?true:false
//                                x:tempRect2.x+width
//                                y:-8
//                                Text
//                                {
//                                    id: countNotAvalText
//                                    text: "0"//groupRect.isNotAvalCount;
//                                    clip: true
//                                    elide: Text.ElideRight
//                                    font: IVColors.getFont("Label accent")
//                                    color: Qt.rgba(255, 255, 255, 0.6)
//                                    anchors.centerIn:  parent
//                                }

//                            }
                            Text
                            {
                                id: countText
                                text: customRect.model.getCurrentCount()
                                clip: true
                                elide: Text.ElideRight
                                font: IVColors.getFont("Label accent")
                                color: Qt.rgba(255, 255, 255, 0.6)
                                anchors.centerIn:  parent
                            }
                        }
//                        Rectangle
//                        {
//                            id:plus_rect
//                            width: 24 * root.isize
//                            height:40 * root.isize
//                            color: "transparent"

//                            anchors
//                            {
//                                verticalCenter: parent.verticalCenter
//                                right: parent.right
//                                rightMargin: 4
//                            }
//                            IVImage
//                            {
//                                id: plus_ico
//                                name:"new_images/plus_circle"
//                                fillMode: Image.PreserveAspectFit
//                                //rotation: iconArrow.opened ? 180 : 0
//                                anchors.centerIn: parent
//                                width: 24 * root.isize
//                                height:24 * root.isize
//                                color: IVColors.get("Colors/Text new/TxTertiaryThemed")
//                                MouseArea
//                                {
//                                    anchors.fill: parent
//                                    hoverEnabled: true
//                                    onClicked:
//                                    {
//                                        //console.error("plus_ico add group",customRect.model);
//                                        customRect.model.addGroupFromQml(customRect.model,"new group");
//                                    }
//                                }
//                            }
//                        }
                    }
                    Item
                    {
                        id:bodyRect
                        width: parent.width
                        anchors.top:headerRect.bottom
                        height: customRect.type === "set"?(root.setNeedCamsVisible ?(customRect.opened?componentListView.contentHeight:0):0):customRect.opened?componentListView.contentHeight:0
                        visible:customRect.type === "set"?(root.setNeedCamsVisible? (customRect.opened?true:false):false):customRect.opened?true:false
                        //color: "transparent"
                        ListView
                        {
                            id:componentListView
                            boundsBehavior: ListView.StopAtBounds
                            anchors.fill:parent
                            property int dragItemIndex: -1
                            model:customRect.model.children
                            orientation: ListView.Vertical
                            snapMode:ListView.SnapToItem
                            clip: true
                            spacing:1
                            cacheBuffer:1000
                            ScrollBar.vertical: ScrollBar
                            {
                                parent: bodyRect
                                width: customRect.type === "set"?(root.setNeedCamsVisible?8:0):8
                                height: customRect.type === "set"?(root.setNeedCamsVisible?parent.height:0):parent.height
                                anchors.horizontalCenter: parent.right
                                //policy: ScrollBar.AlwaysOn
                                contentItem: Rectangle {
                                    implicitWidth: parent.width
                                    implicitHeight: parent.height / bodyRect.contentHeight
                                    radius: width / 2
                                    color: parent.pressed ? IVColors.get("Colors/Text new/TxPrimaryThemed") :
                                                             IVColors.get("Colors/Background new/BgFormSecondaryThemed")
                                }
                            }
                            delegate:
                            Loader
                            {
                                id:groupComLoader
                                anchors.left: parent.left
                                anchors.leftMargin: 16
                                anchors.right: parent.right
                                anchors.rightMargin: 2
                                property var modelVis: modelData.getProp("visible")
                                property var name: modelData.getProp("name_")
                                property var type: modelData.getProp("type")
                                property var view_type: modelData.getProp("view_type")
                                //height: compLoader.type === "set"?40:32
                                sourceComponent:switch(groupComLoader.view_type)
                                                {
                                                    case "group":
                                                    {
                                                        if(groupComLoader.type==="custom")
                                                        {
                                                            //console.error("RETURN CUSTOM COMP2");
                                                            return customComponent;
                                                        }
                                                        else
                                                        {
                                                            //console.error("RETURN GROUP COMP2");
                                                            return tempGroupComp;
                                                        }
                                                    }
                                                    case "item": return itemComponent
                                                    //case "set": return tempGroupComp
                                                }
                                onStatusChanged:
                                {
                                    if(groupComLoader.status === Loader.Ready)
                                    {
                                        groupComLoader.item.model = modelData;
                                        //groupComLoader.item.currIndex = 0;//Qt.binding(function(){return model.index});
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Component
        {
            id:itemComponent
            Rectangle
            {
                id: itemItem
                color: "transparent"//"red"
                //property int currIndex:groupRect.parent.parent.model.index
                property var itemName: itemItem.model.getProp("name_")
                property var type: itemItem.model.getProp("type")
                property var view_type: itemItem.model.getProp("view_type")
                property var isVisible: itemItem.model.visible//itemItem.model.getProp("visible")
                property var model: null
                property bool isAvailable: Boolean(itemItem.model.getProp("is_available"))
                anchors.left: parent.left
                anchors.right: parent.right
                property bool checkable:true
                property bool selected:false
                onIsVisibleChanged:
                {
                    //console.error("onIsVisibleChanged VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV")
                }
                Connections
                {
                    target: root
//                    onSearchSignal:
//                    {
//                        itemItem.isVisible = itemItem.model.getProp("visible");
//                    }
                }

                visible: itemItem.isVisible
                height: itemItem.isVisible?(buttText.paintedHeight>32?buttText.paintedHeight*root.isize:32*root.isize):0
                signal clicked
                signal checkBoxClicked
                signal doubleClicked
                state:root.isHideSets?root.currentTab===itemItem.itemName?"hovered":"normal":"normal"
                IVContextMenu
                {
                    id: contextMenuItem2
                    x: ma5.clickPosX
                    y: ma5.clickPosY
                    function refresh()
                    {
                        menuModel2.refreshModel();
                    }

                    component: Component
                    {
                        ListView
                        {
                            model: menuModel2
                            width: 254 * root.isize
                            height: contentHeight
                            delegate: IVContextMenuItem {
                                width: parent.width
                                type: model.status ? model.status : IVContextMenuItem.Type.Default
                                source: model.icon ? model.icon : ""
                                text: model.text ? model.text : ""
                                enabled: model.enabled ? model.enabled : true
                                onClicked:
                                {
                                    if(action === "open")
                                    {
                                        if(!root.isEditor)
                                        {
                                            root.globSignalsObject.tabAdded5(itemItem.itemName,itemItem.type,"","realtime");
                                        }
                                    }
                                    else if(action === "add_to_set")
                                    {
                                        //root.globSignalsObject.tabAdded2(itemItem.itemName,itemItem.type);
                                        //root.globSignalsObject.tabEditedOn();
                                        var x = 1, y = 1
                                        var dx = 8, dy = 8
                                        var cols = 32, rows = 32
                                        var item = root.customSets.getTypePreset(itemItem.type, "key2", "string", itemItem.itemName);
                                        //console.error("JSON PRESET = ",JSON.stringify(item));
                                        var _zoneObj = {} // customSets.getZZZone(el.getProp("type"), el.getProp("name_"))
                                        _zoneObj["x"] = x
                                        _zoneObj["y"] = y
                                        _zoneObj["dx"] = dx
                                        _zoneObj["dy"] = dy
                                        _zoneObj["type"] =itemItem.type
                                        _zoneObj["params"] = item.params
                                        _zoneObj["qml_path"] = item.qml_path
                                        console.error("CAMS TO SLOT onClicked =====================================",JSON.stringify(_zoneObj))
                                        root.globSignalsObject.zonesAdded("",JSON.stringify(_zoneObj));
                                    }
                                    else
                                    {

                                    }
                                    contextMenuItem2.close();
                                }
                            }
                        }
                    }
                    ListModel
                    {
                        id: menuModel2
                        Component.onCompleted:
                        {
                           // refreshModel();
                        }
                        function refreshModel()
                        {
                            clear();
                            //console.error("refreshModel() items in menu")
                            append({text: "Открыть",
                                       status: IVContextMenuItem.Type.Default,
                                       icon: "new_images/expand",
                                       enabled: true,
                                       action: "open"
                                   })
                            //if (root.globalSignalsObject)
                            //{
                                //if (root.globalSignalsObject.getEditorStatus())
                                //{
                                    append({text: "Добавить в набор",
                                               status: IVContextMenuItem.Type.Default,
                                               icon: "new_images/Add-to-sets2",
                                               enabled: true,
                                               action: "add_to_set"
                                           })
                                //}
                            //}

                        }
                    }
                }
                states: [
                    State {
                        name: "normal"
                        PropertyChanges {
                            target: itemItem
                            color: "transparent"//IVColors.get("Colors/Background new/BgListPrimaryThemed")
                        }
//                            PropertyChanges {
//                                target: buttText
//                                color: groupRect.type === "group" ?
//                                               IVColors.get("Colors/Text new/TxAccentThemed") :
//                                               IVColors.get("Colors/Text new/TxPrimaryThemed")
//                            }
//                        PropertyChanges {
//                            target: checkImage
//                            color: !root.selected ? IVColors.get("Colors/Text new/TxTertiaryThemed") :
//                                                    IVColors.get("Colors/Text new/TxAccentThemed")
//                        }
//                        PropertyChanges {target: icon; color: IVColors.get("Colors/Text new/TxAccentThemed")}
//                        PropertyChanges {target: iconArrow; color: IVColors.get("Colors/Text new/TxTertiaryThemed")}
//                        PropertyChanges {target: lockImage; color: IVColors.get("Colors/Text new/TxSecondaryThemed")}
                    },
                    State {
                        name: "hovered"
                        PropertyChanges {
                            target: itemItem
                            color: itemItem.view_type === "item" ?
                                           IVColors.get("Colors/Background new/BgBtnTertiaryThemed-hover") :
                                           IVColors.get("Colors/Background new/BgFormAccent")
                        }
//                        PropertyChanges {
//                            target: buttText
//                            color: root.type === IVListElement.Type.Group ?
//                                           IVColors.get("Colors/Text new/TxAccentThemed") :
//                                           IVColors.get("Colors/Text new/TxContrast")
//                        }
//                        PropertyChanges {
//                            target: icon
//                            color: root.type === IVListElement.Type.Group ?
//                                           IVColors.get("Colors/Text new/TxAccentThemed") :
//                                           IVColors.get("Colors/Text new/TxContrast")
//                        }
//                        PropertyChanges {
//                            target: checkImage
//                            color: !root.selected ? IVColors.get("Colors/Text new/TxSecondaryContrast") :
//                                                    IVColors.get("Colors/Text new/TxContrast")
//                        }
                        //PropertyChanges {target: iconArrow; color: IVColors.get("Colors/Text new/TxTertiaryThemed")}
                        //PropertyChanges {target: lockImage; color: IVColors.get("Colors/Text new/TxSecondaryContrast")}
                    },
                    State {
                        name: "pressed"
                        PropertyChanges {
                            target: itemItem
                            color: itemItem.view_type === "item" ?
                                           IVColors.get("Colors/Background new/BgBtnTertiaryThemed-click") :
                                           IVColors.get("Colors/Background new/BgFormAccent")
                        }
//                        PropertyChanges {
//                            target: buttText
//                            color: root.type === IVListElement.Type.Group ?
//                                           IVColors.get("Colors/Text new/TxAccentThemed") :
//                                           IVColors.get("Colors/Text new/TxContrast")
//                        }
//                        PropertyChanges {
//                            target: icon
//                            color: root.type === IVListElement.Type.Group ?
//                                           IVColors.get("Colors/Text new/TxAccentThemed") :
//                                           IVColors.get("Colors/Text new/TxContrast")
//                        }
//                        PropertyChanges {
//                            target: checkImage
//                            color: !root.selected ? IVColors.get("Colors/Text new/TxSecondaryContrast") :
//                                                    IVColors.get("Colors/Text new/TxContrast")
//                        }
//                        PropertyChanges {target: iconArrow; color: IVColors.get("Colors/Text new/TxTertiaryThemed")}
//                        PropertyChanges {target: lockImage; color: IVColors.get("Colors/Text new/TxSecondaryContrast")}
                    }
                ]

                IVToolTip {
                    text: itemItem.itemName
                    visible: ma5.containsMouse

                }
                MouseArea{
                    propagateComposedEvents: true
                    hoverEnabled: true
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    id:ma5
                    property var clickPosX: 0
                    property var clickPosY: 0
                    onDoubleClicked:
                    {
                        if(mouse.button & Qt.LeftButton)
                        {
                            var ttt = root.globSignalsObject.getEditorStatus();
                            if(ttt)
                            {
                                var x = 1, y = 1
                                var dx = 8, dy = 8
                                var cols = 32, rows = 32
                                var item = root.customSets.getTypePreset(itemItem.type, "key2", "string", itemItem.itemName);
                                console.error("JSON PRESET = ",JSON.stringify(item));
                                var _zoneObj = {} // customSets.getZZZone(el.getProp("type"), el.getProp("name_"))
                                _zoneObj["x"] = x
                                _zoneObj["y"] = y
                                _zoneObj["dx"] = dx
                                _zoneObj["dy"] = dy
                                _zoneObj["type"] =itemItem.type
                                _zoneObj["params"] = item.params
                                _zoneObj["qml_path"] = item.qml_path
                                console.error("CAMS TO SLOT onClicked =====================================",JSON.stringify(_zoneObj))
                                root.globSignalsObject.zonesAdded("",JSON.stringify(_zoneObj));
                            }
                            else
                            {
                                console.error("root.globSignalsObject.tabAdded3",itemItem.itemName,itemItem.type);
                                if(root.isFixArchive)
                                {
                                    root.globSignalsObject.tabAdded5(groupRect.name,groupRect.type,groupRect.tabId,"archive");
                                }
                                else
                                {
                                    root.globSignalsObject.tabAdded5(itemItem.itemName,itemItem.type,"","realtime");
                                }
                            }
                        }

                    }
                    onContainsMouseChanged: {
                        if (containsMouse) itemItem.state = "hovered"
                        else itemItem.state = "normal"
                    }
                    onPressed: {
                        itemItem.state = "pressed"
                    }
                    onClicked: {
                        if (ma5.containsMouse)
                        {
                            if(mouse.button & Qt.RightButton)
                            {

                                ma5.clickPosX= mouseX;
                                ma5.clickPosY= mouseY;
                                contextMenuItem2.refresh();
                                contextMenuItem2.open();
                            }
                            itemItem.state = "hovered"
                        }
                        else
                        {
                            itemItem.state = "normal"
                        }
                    }
                }
                IVImage {
                    id: checkImage

                    name: "new_images/" + (itemItem.selected ? "check-fill" : "uncheck")
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: 8 * root.isize
                    }
                    visible: itemItem.checkable
                    width: visible ? 16 * root.isize : 0
                    height: width
                    color:"white"
                    MouseArea{
                        propagateComposedEvents: true
                        hoverEnabled: true
                        anchors.fill: parent
                        onClicked: {
                            //root.checkBoxClicked()
                        }
                        onContainsMouseChanged: {
                            if (containsMouse) cursorShape = Qt.PointingHandCursor
                            else cursorShape = Qt.ArrowCursor
                        }
                    }
                }
                Text
                {
                    id: buttText
                    text: itemItem.itemName
                    clip: true
                    elide: Text.ElideRight
                    font: IVColors.getFont("Label accent")
                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: warningRect.left
                        left: checkImage.right
                        leftMargin: 4
                    }
                    color: "white"
                    wrapMode: Text.WordWrap
                }
                Rectangle
                {
                    id:warningRect
                    width: warningRect.visible?24*root.isize:0
                    height: warningRect.visible?24*root.isize:0
                    radius: 16*root.isize
                    anchors.right: plus_rect.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color:"#2875bd"
                    visible: !itemItem.isAvailable
                    IVImage
                    {
                        id: camWarIco
                        name:"new_images/camera_warning"
                        fillMode: Image.PreserveAspectFit

                        //rotation: iconArrow.opened ? 180 : 0
                        anchors.centerIn: parent
                        width:warningRect.visible? 16 * root.isize:0
                        height:warningRect.visible? 16 * root.isize:0
                        visible:warningRect.visible
                        color: Qt.rgba(255, 255, 255, 1)
                    }
                }

                Rectangle
                {
                    id:plus_rect
                    width:plus_rect.visible? 24 * root.isize:0
                    height:plus_rect.visible? 40 * root.isize:0
                    color: "transparent"
                    visible: true
                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                        rightMargin: 4
                    }
                    IVImage
                    {
                        id: plus_ico
                        name:"new_images/plus_circle"
                        fillMode: Image.PreserveAspectFit

                        //rotation: iconArrow.opened ? 180 : 0
                        anchors.centerIn: parent
                        width:plus_rect.visible? 24 * root.isize:0
                        height:plus_rect.visible? 24 * root.isize:0
                        visible:plus_rect.visible
                        color: IVColors.get("Colors/Text new/TxTertiaryThemed")
                        MouseArea
                        {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked:
                            {
                                var ttt = root.globSignalsObject.getEditorStatus();
                                if(ttt)
                                {
                                    var x = 1, y = 1
                                    var dx = 8, dy = 8
                                    var cols = 32, rows = 32
                                    var item = root.customSets.getTypePreset(itemItem.type, "key2", "string", itemItem.itemName);
                                    //console.error("JSON PRESET = ",JSON.stringify(item));
                                    var _zoneObj = {} // customSets.getZZZone(el.getProp("type"), el.getProp("name_"))
                                    _zoneObj["x"] = x
                                    _zoneObj["y"] = y
                                    _zoneObj["dx"] = dx
                                    _zoneObj["dy"] = dy
                                    _zoneObj["type"] =itemItem.type
                                    _zoneObj["params"] = item.params
                                    _zoneObj["qml_path"] = item.qml_path
                                    //console.error("CAMS TO SLOT onClicked =====================================",JSON.stringify(_zoneObj))
                                    root.globSignalsObject.zonesAdded("",JSON.stringify(_zoneObj));
                                }
                                else
                                {
                                    root.globSignalsObject.tabAdded3(itemItem.itemName,itemItem.type,"","realtime");
                                }
                            }
                        }
                    }
                }

            }
        }
        Component
        {
            id:tempGroupComp
            Item
            {
                id:groupRect

                //color: "transparent"
                //radius: 8
                anchors.left: parent.left
                anchors.right: parent.right
                //width: 200
                //border.color: "red"
                //property int currIndex:groupRect.parent.parent.parent.model.index
                //property var modelVis: groupRect.model.getProp("visible")
                property var name: groupRect.model.getProp("name_")
                property var isVisible: groupRect.model.visible//groupRect.model.getProp("visible")
                property var type:groupRect.model.getProp("type")
                property var tabId:groupRect.model.getProp("id_")
                property var isNotAvalCount:groupRect.model.getProp("isNotAval")
                property string view_type:groupRect.model.getProp("view_type")
                property var model: null
                property bool isLocal: Boolean(groupRect.model.getProp("isLocal"))
                onIsNotAvalCountChanged:
                {
                    //console.error("IS NOT AVAL COUNT = ",groupRect.isNotAvalCount )
                }
                visible: groupRect.isVisible?(root.isSetsVisible?true:(groupRect.type==="map"?true:false)):false
                height:groupRect.isVisible?(root.isSetsVisible || groupRect.type!=="map"?( groupRect.opened === true?headerRect.height+bodyRect.height:headerRect.height):0):0
                property bool opened:groupRect.model.opened //groupRect.model.getProp("opened")//?(root.isAllOpen?(groupRect.view_type==="group"? (groupRect.type==="set" ||groupRect.type==="map" ?false:true):true):false):false


//                Drag.active: ma4.drag.active
//                Drag.hotSpot.x: groupRect.width / 2
//                Drag.hotSpot.y: groupRect.height / 2
//                states:
//                [
//                    State
//                    {
//                        when: groupRect.Drag.active
//                        ParentChange
//                        {
//                            target: groupRect
//                            parent: root
//                        }

//                        AnchorChanges
//                        {
//                            target: groupRect
//                            anchors.horizontalCenter: undefined
//                            anchors.verticalCenter: undefined
//                        }
//                    }
//                ]
                function open()
                {
                    groupRect.model.opened = true;
                    root.isSameOpened = true;
                }
                function close()
                {
                    groupRect.model.opened = false;
                }
                Connections
                {
                    id:myCustom
                    target: root
                    onOpenSignal:
                    {
                        groupRect.model.opened =root.isAllOpen?(groupRect.view_type==="group"? (groupRect.type==="set" ||groupRect.type==="map" ?false:true):true):false
                    }
                    onSearchSignal:
                    {
                        //groupRect.isVisible = groupRect.model.visible//groupRect.model.getProp("visible");
                        //groupRect.opened = groupRect.model.getProp("opened");
//                        var _opened = groupRect.model.opened//groupRect.model.getProp("opened");
//                        if(_opened)
//                        {
//                            groupRect.open();
//                        }
//                        else
//                        {
//                            groupRect.close();
//                        }

                    }
                }
                //property bool isCurrentItem: groupRect.currIndex === componentListView.currentIndex?true:false


                Rectangle
                {
                    id:headerRect
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    radius: 8
                    color:IVColors.get("Colors/Background new/BgListPrimaryThemed")
                    height: buttText.paintedHeight>40?buttText.paintedHeight*root.isize:40*root.isize
                    //radius:8
                    state: root.isHideSets?root.currentTab===groupRect.name?"hovered":"normal":"normal"
                    property string imagePath: groupRect.type === "cameras"?"new_images/cctv":(groupRect.type === "set" || groupRect.type === "sets")?
                                                       "new_images/set":groupRect.type === "repeater"?
                                                           "new_images/repeater": groupRect.type === "cluster"?
                                                               "new_images/cluster":groupRect.type === "server"?
                                                                   "new_images/server_2":groupRect.type === "maps"?
                                                                        "new_images/Earth":""
                    IVContextMenu
                    {
                        id: contextMenu
                        x: ma4.clickPosX
                        y: ma4.clickPosY
                        function refresh()
                        {
                            menuModel.refreshModel();
                        }

                        component: Component {
                            ListView {
                                model: menuModel
                                width: 254 * root.isize
                                height: contentHeight
                                delegate: IVContextMenuItem {
                                    width: parent.width
                                    type: model.status ? model.status : IVContextMenuItem.Type.Default
                                    source: model.icon ? model.icon : ""
                                    text: model.text ? model.text : ""
                                    enabled: model.enabled ? model.enabled : true
                                    onClicked:
                                    {
                                        if(groupRect.type === "set")
                                        {
                                            if(action === "open")
                                            {
                                                root.globSignalsObject.tabAdded5(groupRect.name,groupRect.type,groupRect.tabId,"realtime");
                                            }
                                            else if(action === "open_archive")
                                            {
                                                //signal tabAdded5(string tabname, string type,string id,string viewType)
                                                console.error("444444444444444444444444444 1111" )
                                                root.globSignalsObject.tabAdded5(groupRect.name,groupRect.type,groupRect.tabId,"archive");
                                            }
                                            else if(action === "settings")
                                            {
                                                root.globSignalsObject.tabAdded5(groupRect.name,groupRect.type,groupRect.tabId,"realtime");
                                                root.globSignalsObject.tabEditedOn();
                                            }
                                            else if(action === "remove")
                                            {
                                                console.error("action === remove", groupRect.name,groupRect.tabId);
                                                root.globSignalsObject.setRemoved2(groupRect.name,groupRect.tabId);
                                            }
                                            else
                                            {

                                            }
                                        }
                                        else
                                        {
                                            if(action === "open")
                                            {
                                                root.globSignalsObject.tabAdded5(groupRect.name,groupRect.type,groupRect.tabId,"realtime");
                                            }
                                        }

                                        contextMenu.close();
                                    }
                                }
                            }
                        }
                        ListModel
                        {
                            id: menuModel
                            Component.onCompleted:
                            {
                               // refreshModel();
                            }
                            function refreshModel()
                            {
                                clear();
                                //console.error("refreshModel() items in menu")
                                if (groupRect.type === "set")
                                {
                                    //console.error("append items in menu")
                                    append({text: "Открыть",
                                               status: IVContextMenuItem.Type.Default,
                                               icon: "new_images/expand",
                                               enabled: true,
                                               action: "open"
                                           });
                                    append({text: "Открыть в архиве",
                                               status: IVContextMenuItem.Type.Default,
                                               icon: "new_images/expand",
                                               enabled: true,
                                               action: "open_archive"
                                           });
                                    append({text: "Редактировать",
                                               icon: "new_images/settings-04",
                                               status: IVContextMenuItem.Type.Default,
                                               enabled: true,
                                               action: "settings"
                                           });

                                    if (groupRect.isLocal) {
                                        append({text: "Удалить",
                                                   icon: "new_images/del",
                                                   status: IVContextMenuItem.Type.Critical,
                                                   enabled: true,
                                                   action: "remove"
                                               });
                                    }
                                }
                            }
                        }
                    }


                    MouseArea
                    {
                        IVToolTip {
                            text: groupRect.name
                            visible: ma4.containsMouse

                        }
                        anchors.fill: parent
                        hoverEnabled: true
                        //propagateComposedEvents: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        property var clickPosX: 0
                        property var clickPosY: 0
                        id:ma4
                        //drag.target: groupRect
                        //drag.onActiveChanged:
                        //{
    //                        if (ma4.drag.active)
    //                        {
    //                            dropArea.enabled = false;
    //                            root.fromListView = groupRect.parent.parent.parent;
    //                            //console.error("ON DRAG =" ,groupRect.parent , groupRect.parent.parent,groupRect.parent.parent.parent,groupRect.parent.parent.parent.parent,groupRect.parent.parent.parent.parent.parent);
    //                            root.fromListView.dragItemIndex = groupRect.currIndex;
    //                            console.error("ON DRAG =" , root.fromListView,root.fromListView.dragItemIndex , root.fromListView.model.count);
    //                        }
    //                        else
    //                        {
    //                            dropArea.enabled = true;
    //                        }

    //                        groupRect.Drag.drop();
                       // }
                        //drag.target: groupRect
                        //onClicked:
                       // {

                            //componentListView.currentIndex = groupRect.currIndex;
                            //root.selectedGroup = groupRect;

                        //}
                        onContainsMouseChanged:
                        {
                            if(groupRect.name === root.currentTab && isHideSets)
                            {
                                groupRect.state = Qt.binding(function(){ return root.isHideSets?root.currentTab===groupRect.name?"hovered":"normal":"normal"})
                            }
                            else
                            {
                                if (containsMouse) headerRect.state = "hovered"
                                else headerRect.state = "normal"
                            }
                        }
                        onPressed:
                        {
                            if(groupRect.name === root.currentTab && isHideSets)
                            {
                                groupRect.state = Qt.binding(function(){ return root.isHideSets?root.currentTab===groupRect.name?"hovered":"normal":"normal"})
                            }
                            else
                            {
                                headerRect.state = "pressed"
                            }
                        }
                        onClicked: {
                            console.error("MOUSE CLICKED")
                            if(mouse.button & Qt.RightButton)
                            {
                                if (groupRect.type === "set")
                                {
                                    //console.error("MOUSE CLICKED RIGHT")
                                    ma4.clickPosX= mouseX;
                                    ma4.clickPosY= mouseY;
                                    contextMenu.refresh();
                                    contextMenu.open();
                                }
                            }
                            else
                            {
                                //console.error("MOUSE CLICKED LEFT")
                                if (ma4.containsMouse)
                                {
                                    if (groupRect.view_type === "group" && groupRect.type !=="set")
                                    {
                                        if(groupRect.opened)
                                        {
                                            groupRect.close();
                                        }
                                        else
                                        {
                                            groupRect.open();
                                        }
                                    }
                                    else
                                    {
                                        //root.clicked()
                                    }
                                    if(groupRect.name === root.currentTab && isHideSets)
                                    {
                                        groupRect.state = Qt.binding(function(){ return root.isHideSets?root.currentTab===groupRect.name?"hovered":"normal":"normal"})
                                    }
                                    else
                                    {
                                        groupRect.state = "hovered"
                                    }
                                }
                                else
                                {
                                    if(groupRect.name === root.currentTab && isHideSets)
                                    {
                                        groupRect.state = Qt.binding(function(){ return root.isHideSets?root.currentTab===groupRect.name?"hovered":"normal":"normal"})
                                    }
                                    else
                                    {
                                        headerRect.state = "normal"
                                    }
                                }
                            }
                        }
                        onDoubleClicked:
                        {
                            if(groupRect.type === "set")
                            {
                                if(root.isFixArchive)
                                {
                                    root.globSignalsObject.tabAdded5(groupRect.name,groupRect.type,groupRect.tabId,"archive");
                                }
                                else
                                {
                                    root.globSignalsObject.tabAdded5(groupRect.name,groupRect.type,groupRect.tabId,"realtime");
                                }
                            }

                        }
                        //onPressAndHold:
                        //{
                            //componentListView.currentIndex = groupRect.currIndex;
                            //root.selectedGroup = groupRect;
                        //}
                    }
                    states:
                    [
                        State {
                            name: "normal"
                            PropertyChanges {
                                target: headerRect
                                color: IVColors.get("Colors/Background new/BgListPrimaryThemed")
                            }
//                            PropertyChanges {
//                                target: buttText
//                                color: groupRect.type === "group" ?
//                                               IVColors.get("Colors/Text new/TxAccentThemed") :
//                                               IVColors.get("Colors/Text new/TxPrimaryThemed")
//                            }
    //                        PropertyChanges {
    //                            target: checkImage
    //                            color: !root.selected ? IVColors.get("Colors/Text new/TxTertiaryThemed") :
    //                                                    IVColors.get("Colors/Text new/TxAccentThemed")
    //                        }
    //                        PropertyChanges {target: icon; color: IVColors.get("Colors/Text new/TxAccentThemed")}
    //                        PropertyChanges {target: iconArrow; color: IVColors.get("Colors/Text new/TxTertiaryThemed")}
    //                        PropertyChanges {target: lockImage; color: IVColors.get("Colors/Text new/TxSecondaryThemed")}
                        },
                        State {
                            name: "hovered"
                            PropertyChanges {
                                target: headerRect
                                color: root.view_type === "group" ?
                                               IVColors.get("Colors/Background new/BgBtnTertiaryThemed-hover") :
                                               IVColors.get("Colors/Background new/BgFormAccent")
                            }
    //                        PropertyChanges {
    //                            target: buttText
    //                            color: root.type === IVListElement.Type.Group ?
    //                                           IVColors.get("Colors/Text new/TxAccentThemed") :
    //                                           IVColors.get("Colors/Text new/TxContrast")
    //                        }
    //                        PropertyChanges {
    //                            target: icon
    //                            color: root.type === IVListElement.Type.Group ?
    //                                           IVColors.get("Colors/Text new/TxAccentThemed") :
    //                                           IVColors.get("Colors/Text new/TxContrast")
    //                        }
    //                        PropertyChanges {
    //                            target: checkImage
    //                            color: !root.selected ? IVColors.get("Colors/Text new/TxSecondaryContrast") :
    //                                                    IVColors.get("Colors/Text new/TxContrast")
    //                        }
                            //PropertyChanges {target: iconArrow; color: IVColors.get("Colors/Text new/TxTertiaryThemed")}
                            //PropertyChanges {target: lockImage; color: IVColors.get("Colors/Text new/TxSecondaryContrast")}
                        },
                        State {
                            name: "pressed"
                            PropertyChanges {
                                target: headerRect
                                color: groupRect.view_type === "group" ?
                                               IVColors.get("Colors/Background new/BgBtnTertiaryThemed-click") :
                                               IVColors.get("Colors/Background new/BgFormAccent")
                            }
    //                        PropertyChanges {
    //                            target: buttText
    //                            color: root.type === IVListElement.Type.Group ?
    //                                           IVColors.get("Colors/Text new/TxAccentThemed") :
    //                                           IVColors.get("Colors/Text new/TxContrast")
    //                        }
    //                        PropertyChanges {
    //                            target: icon
    //                            color: root.type === IVListElement.Type.Group ?
    //                                           IVColors.get("Colors/Text new/TxAccentThemed") :
    //                                           IVColors.get("Colors/Text new/TxContrast")
    //                        }
    //                        PropertyChanges {
    //                            target: checkImage
    //                            color: !root.selected ? IVColors.get("Colors/Text new/TxSecondaryContrast") :
    //                                                    IVColors.get("Colors/Text new/TxContrast")
    //                        }
    //                        PropertyChanges {target: iconArrow; color: IVColors.get("Colors/Text new/TxTertiaryThemed")}
    //                        PropertyChanges {target: lockImage; color: IVColors.get("Colors/Text new/TxSecondaryContrast")}
                        }
                    ]
                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        //z:10

                        onDropped: {
                            //var cccp = root.fromListView.model.get(root.fromListView.dragItemIndex);
                            //console.error("ON DROPPED =" , root.fromListView,componentListView,root.fromListView.dragItemIndex ,root.fromListView.model.count,  cccp.name,cccp.type,cccp.key2);
                            //componentModel.insert(0,cccp);
                            //root.fromListView.model.remove(root.fromListView.dragItemIndex)
                            //console.error(componentModel,root.fromListView.model);
                           // root.fromListView.dragItemIndex = -1;

                            //componentModel.insert(0,{name:"GROUP",type:"group",key2:"", params:{},local:true,qmlPath:"",isVisible:true});
                        }
                    }
                    IVImage
                    {
                        id: typeImage
                        width: 20*root.isize
                        height: 20*root.isize
                        name:headerRect.imagePath
                        visible:  true
                        fillMode: Image.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        color:IVColors.get("Colors/Text new/TxAccentThemed")
                        //anchors.topMargin: 8
                        //anchors.top: parent.top
                    }
                    Rectangle
                    {
                        id:icoRect
                        width: groupRect.type === "set"?(root.setNeedCamsVisible?24 * root.isize:0):24 * root.isize
                        height:groupRect.type === "set"?(root.setNeedCamsVisible?24 * root.isize:0):24 * root.isize
                        color: "transparent"
                        anchors
                        {
                            verticalCenter: parent.verticalCenter
                            left: typeImage.right
                            leftMargin: 8
                        }
                        IVImage
                        {
                            id: iconArrow
                            visible:groupRect.type === "set"?(root.setNeedCamsVisible?true:false):true
                            name: groupRect.opened?"new_images/chevron-down":"new_images/chevron-right"
                            fillMode: Image.PreserveAspectFit

                            //rotation: iconArrow.opened ? 180 : 0
                            anchors.centerIn: parent
                            width: groupRect.type === "set"?(root.setNeedCamsVisible?24 * root.isize:0):24 * root.isize
                            height:groupRect.type === "set"?(root.setNeedCamsVisible?24 * root.isize:0):24 * root.isize
                            color: IVColors.get("Colors/Text new/TxTertiaryThemed")
                            MouseArea
                            {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked:
                                {
//                                    if (groupRect.view_type === "group")
//                                    {
//                                        if(groupRect.opened)
//                                        {
//                                            groupRect.close();
//                                        }
//                                        else
//                                        {
//                                            groupRect.open();
//                                        }
//                                    }
//                                    else
//                                    {

//                                        root.clicked()
//                                    }
                                    if(groupRect.opened)
                                    {
                                        groupRect.close();
                                    }
                                    else
                                    {
                                        groupRect.open();
                                    }
                                }
                            }
                        }
                    }
                    Text
                    {
                        id: buttText
                        text: groupRect.name
                        clip: true
                        elide: Text.ElideRight
                        font: IVColors.getFont("Label accent")
                        wrapMode: Text.WordWrap
                        anchors
                        {
                            verticalCenter: parent.verticalCenter
                            left: icoRect.right
                            right: rightBlockRect.left
                        }
                        //height: parent.height
                        color: "white"
                    }

                    Rectangle
                    {
                        id:rightBlockRect
                        color:"transparent"//Qt.rgba(255, 255, 255, 0.1)
                        width: 69*root.isize
                        height: 40*root.isize
                        radius: 8*root.isize
                        anchors.right: headerRect.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        IVImage
                        {
                            id: lockImage
                            width: 20 * root.isize
                            height: rightBlockRect.height
                            name: "new_images/Lock2"
                            visible: !groupRect.isLocal && groupRect.type === "set"
                            fillMode: Image.PreserveAspectFit
                            color:IVColors.get("Colors/Text new/TxAccentThemed")
                            anchors.right: tempRect2.left
                            anchors.rightMargin: 4
                        }
                        Rectangle
                        {
                            width: 20*root.isize
                            height: 24*root.isize
                            radius: 8*root.isize
                            anchors.right: plus_rect.left
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            id:tempRect2
                            color:Qt.rgba(255, 255, 255, 0.1)
                            Rectangle
                            {
                                id:notAvalRect
                                width: 16*root.isize
                                height: 16*root.isize
                                radius: 8*root.isize
                                color:IVColors.get("Colors/Statuse new/Defective")
                                visible: true//(groupRect.isNotAvalCount!== undefined && groupRect.isNotAvalCount>0)?true:false
                                x:tempRect2.x+width
                                y:-8
                                Text
                                {
                                    id: countNotAvalText
                                    text: "0"//groupRect.isNotAvalCount;
                                    clip: true
                                    elide: Text.ElideRight
                                    font: IVColors.getFont("Label accent")
                                    color: Qt.rgba(255, 255, 255, 0.6)
                                    anchors.centerIn:  parent
                                }

                            }
                            Text
                            {
                                id: countText
                                text: groupRect.model.getCurrentCount()
                                clip: true
                                elide: Text.ElideRight
                                font: IVColors.getFont("Label accent")
                                color: Qt.rgba(255, 255, 255, 0.6)
                                anchors.centerIn:  parent
                            }
                        }
                        Rectangle
                        {
                            id:plus_rect
                            width:plus_rect.visible? 24 * root.isize:0
                            height:plus_rect.visible? 40 * root.isize:0
                            color: "transparent"
                            visible: groupRect.type ==="set" || groupRect.type ==="camera"
                            anchors
                            {
                                verticalCenter: parent.verticalCenter
                                right: parent.right
                                rightMargin: 4
                            }
                            IVImage
                            {
                                id: plus_ico
                                name:"new_images/plus_circle"
                                fillMode: Image.PreserveAspectFit
                                //rotation: iconArrow.opened ? 180 : 0
                                anchors.centerIn: parent
                                width:plus_rect.visible? 24 * root.isize:0
                                height:plus_rect.visible? 24 * root.isize:0
                                visible:plus_rect.visible
                                color: IVColors.get("Colors/Text new/TxTertiaryThemed")
                                MouseArea
                                {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked:
                                    {
                                        console.error("AAAAAAAAAAAAAAAAAAAAAAAAA tabadded3",groupRect.tabId)
                                        if(root.isFixArchive)
                                        {
                                            root.globSignalsObject.tabAdded5(groupRect.name,groupRect.type,groupRect.tabId,"archive");
                                        }
                                        else
                                        {
                                            root.globSignalsObject.tabAdded5(groupRect.name,groupRect.type,groupRect.tabId,"realtime");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Rectangle
                {
                    id:bodyRect
                    width: parent.width
                    anchors.top:headerRect.bottom
                    height: groupRect.type === "set"?(root.setNeedCamsVisible ?(groupRect.opened?componentListView.contentHeight:0):0):groupRect.opened?componentListView.contentHeight:0
                    visible:groupRect.type === "set"?(root.setNeedCamsVisible? (groupRect.opened?true:false):false):groupRect.opened?true:false
                    color: "transparent"
                    ListView
                    {
                        id:componentListView
                        boundsBehavior: ListView.StopAtBounds
                        anchors.fill:parent
                        property int dragItemIndex: -1
                        model:groupRect.model.children
                        orientation: ListView.Vertical
                        cacheBuffer:1000
                        //snapMode:ListView.SnapToItem
                        clip: true
                        spacing:0
//                        ScrollBar.vertical: ScrollBar
//                        {
//                            parent: bodyRect
//                            width: groupRect.type === "set"?(root.setNeedCamsVisible?8:0):8
//                            height: groupRect.type === "set"?(root.setNeedCamsVisible?parent.height:0):parent.height
//                            anchors.horizontalCenter: parent.right
//                            //policy: ScrollBar.AlwaysOn
//                            contentItem: Rectangle {
//                                implicitWidth: parent.width
//                                implicitHeight: parent.height / bodyRect.contentHeight
//                                radius: width / 2
//                                color: parent.pressed ? IVColors.get("Colors/Text new/TxPrimaryThemed") :
//                                                         IVColors.get("Colors/Background new/BgFormSecondaryThemed")
//                            }
//                        }
                        delegate:
                        Loader
                        {
                            id:compLoader
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.right: parent.right
                            anchors.rightMargin: 2
                            property var name: modelData.getProp("name_")
                            property bool isVisible: modelData.getProp("visible")
                            property var type: modelData.getProp("type")
                            property var view_type: modelData.getProp("view_type")
                            //height: compLoader.isVisible?32:0
                            //visible: compLoader.isVisible
                            sourceComponent:switch(compLoader.view_type)
                                            {
                                                case "group": return tempGroupComp
                                                case "item": return itemComponent
                                                //case "set": return tempGroupComp
                                            }
                            onStatusChanged:
                            {
                                if(compLoader.status === Loader.Ready)
                                {
                                    compLoader.item.model = modelData;
                                    //compLoader.item.currIndex = 0;//Qt.binding(function(){return model.index});
                                }
                            }
                        }
                    }
                }
            }
        }
        Item
        {
            anchors.fill: parent
            //color:"transparent"
//            Rectangle
//            {
//                id:firstRect
//                width: parent.width
//                height: 30
//                anchors.bottom:  parent.bottom
//                color: "red"
//                z:100
//                MouseArea
//                {
//                    anchors.fill: parent
//                    hoverEnabled: true
//                    propagateComposedEvents: true
//                    onClicked:
//                    {
//                        console.error("CLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL333333333");
//                        root.devices.addGroupFromQml(0,"New group");
//                        sdrgsdr.model = null;
//                        sdrgsdr.model =root.devices.children
//                    }
//                }

//            }

            ListView
            {
                id:sdrgsdr
                anchors.fill: parent
                model:root.devices.children
                boundsBehavior: ListView.StopAtBounds
                z:50
                spacing:1
                cacheBuffer:3000
                //snapMode:ListView.SnapToItem

                delegate:
                Loader
                {
                    id:compLoader
                    property var modelVis: modelData.getProp("visible")
                    property var name: modelData.getProp("name_")
                    property var type: modelData.getProp("type")
                    property var view_type: modelData.getProp("view_type")
                    anchors.left: parent.left
                    anchors.right: parent.right
                    //visible: name=== "sets"?root.isSetsVisible:true
                    onTypeChanged:
                    {
                        //console.error("LOADER TYPE = ", compLoader.type,"LOADER VIEW_TYPE = ", compLoader.view_type)
                    }

                    sourceComponent:switch(compLoader.view_type)
                                    {
                                        case "group":
                                        {
                                            if(compLoader.type==="custom")
                                            {
                                                //console.error("RETURN CUSTOM COMP");
                                                return customComponent;
                                            }
                                            else
                                            {
                                                //console.error("RETURN GROUP COMP");
                                                return tempGroupComp;
                                            }
                                        }
                                        case "camera": return itemComponent
                                        case "set": return tempGroupComp
                                    }
                    onStatusChanged:
                    {
                        if(compLoader.status === Loader.Ready)
                        {
                            compLoader.item.model = modelData;

                            //compLoader.item.currIndex = Qt.binding(function(){return model.index});
                        }
                    }
                }
                clip: true
            }
        }

    }

}

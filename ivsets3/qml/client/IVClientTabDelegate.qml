import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import QtQuick.Dialogs 1.1
import QtQml 2.3
import iv.sets.sets3 1.0
import iv.plugins.loader 1.0
import iv.colors 1.0
import iv.controls 1.0
import QtGraphicalEffects 1.0

Rectangle
{
    id:root
    width: 160*root.isize
    height: 32*root.isize
    radius: 8*root.isize
    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }
    property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1
    border.width: switch (view){
                  case IVClientTabDelegate.View.Small: return 2
                  case IVClientTabDelegate.View.Light: return 1
                  default: return 0
                  }
    border.color: status === IVClientTabDelegate.Status.Warning ? IVColors.get("Colors/Statuse new/Critical") :
                                                                  IVColors.get("Colors/Text new/TxAccentThemed")
    readonly property bool useAnimation: false //true //

    property int view: IVClientTabDelegate.View.Default
    property int status: IVClientTabDelegate.Status.Default
    property int type2: IVClientTabDelegate.Type.Set
    readonly property string typeImagePath:
        root.type2 === IVClientTabDelegate.Type.Set ? "new_images/layout-grid-02" :
        root.type2 === IVClientTabDelegate.Type.Camera ? "new_images/cctv" :
        root.type2 === IVClientTabDelegate.Type.Map ? "new_images/Earth" :
        root.type2 === IVClientTabDelegate.Type.EditedSet ? "new_images/gridEdited" :
        "new_images/help-circle.svg"

    property bool isLocalSet: true

    readonly property string selectedContentColor: {
        switch (root.view){
        case IVClientTabDelegate.View.Small:
            return IVColors.get("Colors/Text new/TxContrast")
        case IVClientTabDelegate.View.Light:
            switch (root.status){
            case IVClientTabDelegate.Status.Warning: return IVColors.get("Colors/Text new/TxContrast")
            default: return IVColors.get("Colors/Text new/TxAccent")
            }
        default:
            switch (root.status){
            case IVClientTabDelegate.Status.Warning: return IVColors.get("Colors/Text new/TxContrast")
            default: return IVColors.get("Colors/Text new/TxAccent")
            }
        }
    }

    readonly property string defaultContentColor: {
        switch (root.view){
        case IVClientTabDelegate.View.Small:
            switch (root.status){
            case IVClientTabDelegate.Status.Warning: return IVColors.get("Colors/Statuse new/Critical")
            default: return IVColors.get("Colors/Text new/TxAccentThemed")
            }

        case IVClientTabDelegate.View.Light:
            return IVColors.get("Colors/Text new/TxContrast")

        default:
            switch (root.status){
            case IVClientTabDelegate.Status.Warning: return IVColors.get("Colors/Statuse new/Critical")
            default: return IVColors.get("Colors/Text new/TxAccentThemed")
            }
        }
    }
    state: "normal"
    states:[
        State {
            name: "normal"
            PropertyChanges {
                target: root
                color: switch (root.view){
                       case IVClientTabDelegate.View.Small:
                           return IVColors.get("Colors/Background new/BgFormPrimaryThemed")

                       case IVClientTabDelegate.View.Light:
                           switch (root.status){
                           case IVClientTabDelegate.Status.Warning: return IVColors.get("Colors/Background new/BgCritical-alpha")
                           default: return "transparent"
                           }

                       default:
                           return IVColors.get("Colors/Background new/BgFormTertiaryThemed")
                       }
            }
            PropertyChanges {
                target: tabNameLabel
                color: root.defaultContentColor
            }
            PropertyChanges {
                target: typeImage
                color: root.defaultContentColor
            }
//            PropertyChanges {
//                target: contextMenuTabImage
//                color: root.defaultContentColor
//            }
        },
        State {
            name: "selected"
            PropertyChanges {
                target: root
                color: switch (root.view){
                       case IVClientTabDelegate.View.Small:
                           switch (root.status){
                           case IVClientTabDelegate.Status.Warning: return IVColors.get("Colors/Statuse new/Critical")
                           default: return IVColors.get("Colors/Text new/TxAccentThemed")
                           }
                       case IVClientTabDelegate.View.Light:
                           switch (root.status){
                           case IVClientTabDelegate.Status.Warning: return IVColors.get("Colors/Statuse new/Critical")
                           default: return IVColors.get("Colors/Background new/BgBtnContrast")
                           }
                       default:
                           switch (root.status){
                           case IVClientTabDelegate.Status.Warning: return IVColors.get("Colors/Background new/BgBtnSecondaryCritical-click")
                           default: return IVColors.get("Colors/Background new/BgBtnContrast")
                           }
                       }
            }
            PropertyChanges {
                target: tabNameLabel
                color: root.selectedContentColor
            }
            PropertyChanges {
                target: typeImage
                color: root.selectedContentColor
            }
//            PropertyChanges {
//                target: contextMenuTabImage
//                color: root.selectedContentColor
//            }
        }
    ]

    property string tabName: ""
    property int innerIndex: -2
    property int currentIndex: -1
    signal tabClicked()
    property bool isSetChanged: false
    property string type:""
    property string tabId:""
    property int modelSize: 0


    onTypeChanged: {
        switch (type) {
        case "set": root.type2 = IVClientTabDelegate.Type.Set; break;
        case "camera": root.type2 = IVClientTabDelegate.Type.Camera; break;
        case "map": root.type2 = IVClientTabDelegate.Type.Map; break;
        default: root.type2 = IVClientTabDelegate.Type.Undefined;
        }
    }

    property var globalSignalsObject: null
    property bool isEditorEnabled: false
    property string viewType: ""
    onViewTypeChanged:
    {
        console.error("77777777777777777777774 ", root.viewType)
    }

    Connections
    {
        id:myConn
        target: root.globalSignalsObject
        onTabSelected5:
        {
            console.error("tab 333 onTabSel = " , root.tabName , tabname , root.tabId , id)
            if (root.tabName === tabname && root.tabId === id)
            {
                root.state = "selected";
                root.globalSignalsObject.tabUniqId = root.toString();
            }
            else root.state = "normal"
        }
        onTabEditedOff:
        {
            root.isEditorEnabled = false;
        }
        onTabEditedOn:
        {
            root.isEditorEnabled = true;
        }
        onTabTypeChanged:
        {
            root.type = tabtype;
            //console.error("TAB TYPE CHANGED = ", tabtype);
        }
        onSetChanged:
        {
            if(root.tabName === setname )
            {
                root.isSetChanged = true;
                root.type2 = IVClientTabDelegate.Type.EditedSet;
            }
            else
            {
                root.isSetChanged = false;
                root.type2 = IVClientTabDelegate.Type.Set;
            }

        }
    }
    IvVcliSetting
    {
        id: archive_fix2
        name: 'archive.fixVisible'
    }
    signal rightClicked()
    IVToolTip {
        text: root.tabName
        visible: ma8.containsMouse
    }
    MouseArea
    {
        id:ma8
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked:
        {
            //compListModel.clear();
            console.error("CURR INDEX = ",root.currentIndex)
            console.error("CURR INDEX = ",root.modelSize)
            //console.error("CURR INDEX = ",root.innerIndex)


            if(mouse.button & Qt.RightButton)
            {

                //moreMenu.component.children[0].refreshMenu();




                ma8.oldMouseX= mouseX;
                ma8.oldMouseY= mouseY;
                //moreMenu.open();
                root.rightClicked();

            }
            else
            {
                if(!root.isEditorEnabled)
                {

                    if(archive_fix2.value === "true")
                    {
                        console.error("on tab clicked  ==== ", root.tabName,root.type, root.type2,root.tabId ,root.viewType);
                        root.globalSignalsObject.tabSelected5(root.tabName,root.type,root.tabId,"archive");
                    }
                    else
                    {
                        root.globalSignalsObject.tabSelected5(root.tabName,root.type,root.tabId,root.viewType);
                    }




                    activeTabSettings.value = root.tabName;

                }
            }
            console.error("MOUSE CLICKED = " , root.globalSignalsObject.tabUniqId ,root.toString())
            root.globalSignalsObject.tabUniqId = root.toString() ;


        }
        property var oldMouseX :0
        property var oldMouseY :0

        onEntered:
        {
            //contextMenuTabImage.opacity = 1
        }
        onExited:
        {
            //contextMenuTabImage.opacity = 0.8
        }

    }
    Rectangle{
        color: "transparent"
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: 12
            rightMargin: 6
        }
        height: 32*root.isize
        IVImage
        {
            id:typeImage
            width: 20*root.isize
            height: 20*root.isize
            anchors.left: parent.left
            anchors.top:parent.top
            anchors.leftMargin: 2
            anchors.topMargin: 6
            name:  root.typeImagePath
        }

        Label {
            id:tabNameLabel
            text: root.tabName

            anchors{
                verticalCenter: parent.verticalCenter
                left: typeImage.right
                leftMargin: 4
                right: parent.right
            }
            font: IVColors.getFont("Subtext accent")
            clip: true
        }
    }
    IVContextMenu {
        id: moreMenu
        x: -20
        y: root.height
        bgColor : IVColors.get("Colors/Background new/BgContextMenuThemed")
        property bool isArchive: root.viewType === "archive"
        component: Component {
            Rectangle
            {
                id:commonRect
                width: 364 * root.isize
                color: "transparent"
                //height: contextListView.contentHeight+150
                height: root.type2 === IVClientTabDelegate.Type.Set ||root.type2 === IVClientTabDelegate.Type.EditedSet?(contextListView.contentHeight+150)*root.isize:contextListView.contentHeight*root.isize
                function refreshMenu()
                {
                    menuListModel.clear();
                    if (root.type2 === IVClientTabDelegate.Type.Set ||root.type2 === IVClientTabDelegate.Type.EditedSet)
                    {
                        console.error("66666666666666666666666666 ",moreMenu.isArchive , root.viewType )
                        menuListModel.append({text: !moreMenu.isArchive?"Перейти в архив":"Перейти в реалтайм", icon: "new_images/toArchiveBtn", enabled: true})
                        if (root.isLocalSet)
                        {
                            menuListModel.append({text: "Расширенное редактирование", icon: "new_images/settings-04", enabled: true})
                        }
                        else
                        {
                            menuListModel.append({text: "Редактирование невозможно", icon: "new_images/Lock2", enabled: false})
                        }
                    }
                    if(root.innerIndex>0)
                    {
                        menuListModel.append({text: "Закрыть все вкладки слева", icon: "new_images/chevron-left-big", enabled: true})
                    }
                    if(root.innerIndex!==root.modelSize-1)
                    {
                        menuListModel.append({text: "Закрыть все вкладки справа", icon: "new_images/chevron-right-big", enabled: true})
                    }
                    menuListModel.append({text: "Закрыть", icon: "new_images/x-close", enabled: true})
                }
                Connections
                {
                    id:menuToRoot
                    target: root
                    onRightClicked:
                    {
                        commonRect.refreshMenu();
                        moreMenu.open();

                    }
                }

                Rectangle
                {
                    id:headerMenuRect
                    color: "transparent"
                    width: parent.width*root.isize
                    //height: 48
                    height: root.type2 === IVClientTabDelegate.Type.Set ||root.type2 === IVClientTabDelegate.Type.EditedSet?48*root.isize:0
                    visible: root.type2 === IVClientTabDelegate.Type.Set ||root.type2 === IVClientTabDelegate.Type.EditedSet?true:false
                    anchors.top: parent.top
                    //anchors.topMargin: 4
                    //radius: 8
                    TextInput
                    {
                        property bool isNameChanged: false
                        id:headerSetNameInput
                        width: 300*root.isize
                        height: 20*root.isize
                        text: root.tabName
                        enabled: false
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                        onTextChanged:
                        {
                            if(root.tabName !== text)
                            {
                                isNameChanged = true;
                            }
                        }
                    }
                    IVImage
                    {
                        id: renameImage
                        width:32*root.isize
                        height: 32*root.isize
                        name:"new_images/editSetName"
                        visible:  true
                        fillMode: Image.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        color:IVColors.get("Colors/Text new/TxTertiaryThemed")
                        //anchors.topMargin: 8
                        //anchors.top: parent.top
                        MouseArea
                        {
                            id:clickArea
                            anchors.fill: parent
                            onClicked:
                            {
                                headerSetNameInput.focus = true;
                                headerSetNameInput.enabled = true;
                                headerSetNameInput.selectAll();
                            }
                        }
                    }

                }
                MessageDialog {
                    id: messageDialogSave
                    width: 200*root.isize
                    height: 80*root.isize
                    title: "Сохранение набора"
                    property string setName: ""
                    visible: false
                    standardButtons: StandardButton.Apply
                    onApply:
                    {
                    }
                }
                IVButton
                {
                    type: IVButton.Type.Primary
                    text: "Сохранить"
                    //width: 364
                    //height: 32
                    //visible: true
                    height: root.type2 === IVClientTabDelegate.Type.Set ||root.type2 === IVClientTabDelegate.Type.EditedSet?32*root.isize:0
                    visible: root.type2 === IVClientTabDelegate.Type.Set ||root.type2 === IVClientTabDelegate.Type.EditedSet?true:false
                    enabled:headerSetNameInput.isNameChanged || pressetsRow.isPressetChanged || root.isSetChanged
                    id:saveSetBtn
                    //color:IVColors.get("Colors/Background new/BgBtnPrimary")
                    anchors {
                        rightMargin: 16
                        right: parent.right
                        left:parent.left
                        leftMargin:16
                        top:headerMenuRect.bottom
                    }
                    onClicked:
                    {
                        if(!saveSetBtn.enabled)
                        {
                            return;
                        }

                        var local_sets = customSets.getLocalSetsList();
                        var remote_sets = customSets.getRemoteSetsList();
                        if (headerSetNameInput.text === "New tab")
                        {
                            messageDialogSave.text = "Недопустимое имя набора. Пожалуйста, выберете другое имя."
                            messageDialogSave.open();
                            return;
                        }
                        //console.error("SAVE SET = " ,root.tabName ,  headerSetNameInput.text)
                        var lowerNewSetName = headerSetNameInput.text.toLowerCase();
                        if (headerSetNameInput.text === root.tabName)
                        {
                            for (var i2=0;i2<remote_sets.length;i2++)
                            {
                                if (remote_sets[i2].toLowerCase() === lowerNewSetName) {
                                    messageDialogSave.text = "Имя набора совпадает с уже созданным набором. Пожалуйста, выберете другое имя."
                                    messageDialogSave.open();
                                    return;
                                }
                            }
                            //console.error("SAVE SET2 = " ,root.tabName ,  headerSetNameInput.text)
                            root.globalSignalsObject.setSaved("");
                            //console.error("pressetsRow.isPressetChanged = " , pressetsRow.isPressetChanged)
                            //root.globalSignalsObject.setAdded(tabNameField.text)
                            headerSetNameInput.focus = false;
                            headerSetNameInput.enabled = false;
                            pressetsRow.isPressetChanged = false;
                            root.isSetChanged = false;
                             root.type2 = IVClientTabDelegate.Type.Set;
                        }
                        else
                        {
                            //console.error("SAVE SET3 = " ,root.tabName ,  headerSetNameInput.text)


                            for (var i1=0;i1<local_sets.length;i1++)
                            {
                                if (local_sets[i1].toLowerCase() === lowerNewSetName)
                                {
                                    messageDialogSave.text = "Имя набора совпадает с уже созданным набором. Пожалуйста, выберете другое имя."
                                    messageDialogSave.open();
                                    return;
                                }
                            }
                            for (var i2=0;i2<remote_sets.length;i2++)
                            {
                                if (remote_sets[i2].toLowerCase() === lowerNewSetName) {
                                    messageDialogSave.text = "Имя набора совпадает с уже созданным набором. Пожалуйста, выберете другое имя."
                                    messageDialogSave.open();
                                    return;
                                }
                            }
                            //console.error("pressetsRow.isPressetChanged = " , pressetsRow.isPressetChanged)
                            root.globalSignalsObject.setSaved(headerSetNameInput.text)
                            //root.globalSignalsObject.setAdded(tabNameField.text)
                            headerSetNameInput.focus = false;
                            headerSetNameInput.enabled = false;
                            pressetsRow.isPressetChanged = false;
                            root.isSetChanged = false;
                            root.type2 = IVClientTabDelegate.Type.Set;
                            //headerSetNameInput.selectAll();

                        }
                    }
                }
                Rectangle
                {
                    id:pressetsRect
                    height: root.type2 === IVClientTabDelegate.Type.Set ||root.type2 === IVClientTabDelegate.Type.EditedSet ?76*root.isize:0
                    visible: root.type2 === IVClientTabDelegate.Type.Set ||root.type2 === IVClientTabDelegate.Type.EditedSet?true:false
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: saveSetBtn.bottom
                    color: "transparent"
                    Label
                    {
                        id:pressetsLabel
                        text: "Сетка"
                        color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                        font.pixelSize: 14*root.isize
                        clip: true
                        width: 35*root.isize
                        height: 16*root.isize
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.top: parent.top
                        anchors.topMargin: 4
                    }
                    Row
                    {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.top: pressetsLabel.bottom
                        anchors.topMargin: 4
                        height: 40*root.isize
                        property var currPreset: 5
                        property bool isPressetChanged: false
                        onCurrPresetChanged:
                        {
                            if(pressetsRow.currPreset !== 5)
                            {
                                pressetsRow.isPressetChanged = true;
                            }
                        }

                        id:pressetsRow
                        property var presetsNames: [
                            "Grid 1", "Grid 1_2","Grid 1_3", "Grid 2", "Grid 3",
                            "Grid 4", "Grid 5"//, "Grid Custom"
                        ]
                        Repeater {
                            model: pressetsRow.presetsNames
                            delegate: IVButton {
                                width: parent.width
                                checkable: true
                                checked: index === pressetsRow.currPreset
                                source: "new_images/grids/"+modelData
                                onClicked: {

                                    pressetsRow.currPreset = index
                                    root.globalSignalsObject.setPreset(pressetsRow.currPreset);
                                }
                            }
                        }
                    }

                }

                ListView {
                    width: parent.width// * root.isize
                    height: contentHeight
                    anchors.bottom: parent.bottom
                    anchors.top: pressetsRect.bottom
                    id:contextListView


                    model:ListModel
                    {
                        id:menuListModel
                        Component.onCompleted:
                        {
                            commonRect.refreshMenu();
                        }
                    }

                    delegate: IVContextMenuItem {
                        width: parent.width
                        type: model.status ? model.status : IVContextMenuItem.Type.Default
                        source: model.icon ? model.icon : ""
                        text: model.text ? model.text : ""
                        enabled: model.enabled !== undefined ? model.enabled : true
                        onClicked: {

                            if (text === "Перейти в архив")
                            {
                                //root.globalSignalsObject.setToArchive();
                                //moreMenu.isArchive = true;
                               // root.model.view = "archive";
                                // console.error("FFFFFFFFFFFFFFF onTabAdded5 = ",tabname,type,id,viewType);
                                root.globalSignalsObject.tabAdded5(root.tabName,root.type,root.tabId,"archive");
                            }
                            if (text === "Перейти в реалтайм")
                            {
                                //root.globalSignalsObject.setToRealtime();
                                //moreMenu.isArchive = false;
                                //root.model.view = "realtime";
                                  root.globalSignalsObject.tabAdded5(root.tabName,root.type,root.tabId,"realtime");
                            }
                            if (text === "Расширенное редактирование")
                            {
                                root.globalSignalsObject.tabSelected5(root.tabName,root.type,root.tabId,"realtime");
                                root.globalSignalsObject.tabEditedOn();
                            }
                            if (text === "Закрыть все вкладки слева")
                            {
                                root.globalSignalsObject.tabRemoveLeft(root.tabName);
                            }
                            if (text === "Закрыть все вкладки справа")
                            {
                                root.globalSignalsObject.tabRemoveRight(root.tabName);
                            }
                            if (text === "Закрыть") root.globalSignalsObject.tabRemoved2(root.tabName);
                            if (enabled) moreMenu.close()
                        }

                    }
                }
            }


        }
    }
    onCurrentIndexChanged:
    {
        //console.error("onCurrentIndexChanged currentIndex", root.currentIndex)
        //console.error("onCurrentIndexChanged innerIndex", root.innerIndex)
//        compListModel.clear();

//        if (root.type2 === IVClientTabDelegate.Type.Set ||root.type2 === IVClientTabDelegate.Type.EditedSet)
//        {
//            compListModel.append({text: "Перейти в архив", icon: "new_images/toArchiveBtn", enabled: true})
//            if (root.isLocalSet)
//            {
//                compListModel.append({text: "Расширенное редактирование", icon: "new_images/settings-04", enabled: true})
//            }
//            else
//            {
//                compListModel.append({text: "Редактирование невозможно", icon: "new_images/Lock2", enabled: false})
//            }
//        }
//        //console.error("CURR INDEX = ",root.currentIndex)
//        //console.error("CURR INDEX = ",root.modelSize)
//        //console.error("CURR INDEX = ",root.innerIndex)
//        if(root.innerIndex>0)
//        {
//            compListModel.append({text: "Закрыть все вкладки слева", icon: "new_images/chevron-left-big", enabled: true})
//        }
//        if(root.innerIndex!==root.modelSize-1)
//        {
//            compListModel.append({text: "Закрыть все вкладки справа", icon: "new_images/chevron-right-big", enabled: true})
//        }


//        compListModel.append({text: "Закрыть", icon: "new_images/x-close", enabled: true})
        if (root.currentIndex === root.innerIndex) root.state = "selected"
        else root.state = "normal"
    }
    onModelSizeChanged:
    {
//        compListModel.clear();

//        if (root.type2 === IVClientTabDelegate.Type.Set ||root.type2 === IVClientTabDelegate.Type.EditedSet)
//        {
//            compListModel.append({text: "Перейти в архив", icon: "new_images/toArchiveBtn", enabled: true})
//            if (root.isLocalSet)
//            {
//                compListModel.append({text: "Расширенное редактирование", icon: "new_images/settings-04", enabled: true})
//            }
//            else
//            {
//                compListModel.append({text: "Редактирование невозможно", icon: "new_images/Lock2", enabled: false})
//            }
//        }
//        //console.error("CURR INDEX = ",root.currentIndex)
//        //console.error("CURR INDEX = ",root.modelSize)
//        //console.error("CURR INDEX = ",root.innerIndex)
//        if(root.innerIndex>0)
//        {
//            compListModel.append({text: "Закрыть все вкладки слева", icon: "new_images/chevron-left-big", enabled: true})
//        }
//        if(root.innerIndex!==root.modelSize-1)
//        {
//            compListModel.append({text: "Закрыть все вкладки справа", icon: "new_images/chevron-right-big", enabled: true})
//        }


//        compListModel.append({text: "Закрыть", icon: "new_images/x-close", enabled: true})

    }

    onInnerIndexChanged:
    {
        //console.error("onCurrentIndexChanged currentIndex", root.currentIndex)
        //console.error("onCurrentIndexChanged innerIndex", root.innerIndex)
//        compListModel.clear();

//        if (root.type2 === IVClientTabDelegate.Type.Set ||root.type2 === IVClientTabDelegate.Type.EditedSet)
//        {
//            compListModel.append({text: "Перейти в архив", icon: "new_images/toArchiveBtn", enabled: true})
//            if (root.isLocalSet)
//            {
//                compListModel.append({text: "Расширенное редактирование", icon: "new_images/settings-04", enabled: true})
//            }
//            else
//            {
//                compListModel.append({text: "Редактирование невозможно", icon: "new_images/Lock2", enabled: false})
//            }
//        }
//        console.error("CURR INDEX = ",root.currentIndex)
//        console.error("CURR INDEX = ",root.modelSize)
//        console.error("CURR INDEX = ",root.innerIndex)
//        if(root.innerIndex>0)
//        {
//            compListModel.append({text: "Закрыть все вкладки слева", icon: "new_images/chevron-left-big", enabled: true})
//        }
//        if(root.innerIndex!==root.modelSize-1)
//        {
//            compListModel.append({text: "Закрыть все вкладки справа", icon: "new_images/chevron-right-big", enabled: true})
//        }


//        compListModel.append({text: "Закрыть", icon: "new_images/x-close", enabled: true})


        if (root.currentIndex === root.innerIndex) root.state = "selected"
        else root.state = "normal"
    }
    enum Type {
        Set,
        Camera,
        Map,
        EditedSet,
        Undefined
    }
    enum Status {
        Default,
        Warning
    }
    enum View {
        Default,
        Small,
        Light
    }
}

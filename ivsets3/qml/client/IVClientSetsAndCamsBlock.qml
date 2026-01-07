import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
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
    property bool opened: false
    property bool isNeedCustom: true
    IvVcliSetting
    {
        id:sourcesWidth
        name:"sourcesList.width"
    }
    IvVcliSetting
    {
        id:sourcesCurrent
        name:"sourcesList.currentView"
    }
    onOpenedChanged: {
        console.log("IVClientSetsAndCamsBlock.qml opened", opened)
        if(opened)
        {
//            if(sourcesWidth.value !== "")
//            {
//                var newWidth = parseFloat(sourcesWidth.value);
//                root.width=newWidth;
//                return;
//            }
            //console.error("OPENED = ", root.expandWidth)
            var _width = sourcesWidth.value!== ""?parseInt(sourcesWidth.value):0
            if(_width>=328 && _width<=500)
            {
                root.expandWidth = _width;
                root.width= _width;
            }
            else
            {
                if(_width>500)
                {
                    root.expandWidth = 500;
                    root.width= root.expandWidth;
                }
                if(_width<328)
                {
                    root.expandWidth = 328;
                    root.width= root.expandWidth;
                }
            }

        }
        else
        {
            root.width=0;
        }
    }
    property real expandWidth: 328
    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
        Component.onCompleted:
        {
            var valllllue = interfaceSize.value;
            //console.error("LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL = ",valllllue );
        }
        onValueChanged:
        {
            var valllllue = interfaceSize.value;
            //console.error("LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL2 = ",valllllue );
        }
    }
    property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1
    readonly property string mainColor: !root.isNeedCustom?IVColors.get("Colors/Background new/BgFormPrimaryThemed"):IVColors.get("Colors/Background new/BgContextMenuThemed")
    gradient:
        Gradient
        {
            GradientStop { position: 0.0; color: IVColors.get("Colors/Background new/BgFormPrimaryThemed")}
            GradientStop { position: 0.05; color: mainColor }
        }
    visible: opacity > 0
    opacity: 1//width/expandWidth
    width:  opened?root.expandWidth:0
    Behavior on width {
        NumberAnimation { duration: 100; easing.type: Easing.InOutQuad }
    }
    Component.onDestruction:
    {
        root.globSignalsObject.clearView();
    }


    property var selectedGroup: null
    property var fromListView: null
    property var toListView: null
    property string setName: ""

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
    MessageDialog {
        id: messageDialogSave
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
    MessageDialog {
        id: messageDialog
        width: 200
        height: 80
        title: "Удаление набора!"
       // text: "Вы действительно хотите удалить выбранный набор: "+messageDialog.setName+"?"
        property var itemPath
        visible: false
        standardButtons: StandardButton.Yes | StandardButton.No
        onYes: {
            var setName = devices.get(itemPath).getProp("name_")
            console.log("messageDialog onYes name:", setName)
            root.globSignalsObject.tabRemoved2(setName);
            customSets.deleteSet(setName);
            devices.remove(itemPath)
            messageDialog.close();
        }
        onNo: messageDialog.close()
    }

    property bool isEditor: false
    Connections
    {
        id:myConn
        target: root.globSignalsObject
        onShowSetsAndCams:
        {
            sourcesOpened.value = "true";
            //console.error("onShowSetsAndCams = ", root.opened );
            root.opened = true;
        }
        onHideSetsAndCams:
        {
            sourcesOpened.value = "false";
            //console.error("onHideSetsAndCams = ", root.opened );
            root.opened = false
        }
        onTabEditedOn:
        {
            root.isEditor = true;
            root.opened = true
            listLoader.create1(cntAdaptive.currentIndex);

        }
        onTabEditedOff:
        {
            //console.error("ON TAB EDITOR OFF IN CAMS BLOCK");
            root.isEditor = false;
            reloadTimer.start();


        }
        onSetNameChanged:
        {
            root.setName = newSetName;
            reloadTimer.start();

        }
    }
    Rectangle
    {
        id: commonRect
        color: "transparent"
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        Rectangle
        {
            id: camsAndSetsLabelRect
            color: "transparent"
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 48 * root.isize
            Rectangle
            {
                id: textRect
                color: "transparent"
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                //anchors.right: dotsButton.left
                Text
                {
                    id: camsSetstext
                    text:"Источники"
                    font: IVColors.getFont("Subtitle accent")
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                    verticalAlignment: Text.AlignVCenter
                }
            }
            IVButton
            {
                id: closePanelBtn
                source: "new_images/x-close"
                toolTipText: "Закрыть источники"
                type: IVButton.Type.Helper
                anchors.top: parent.top
                anchors.right:  parent.right
                anchors.bottom: parent.bottom
                visible:root.isNeedCustom
                width: root.isNeedCustom?24* root.isize:0
                onClicked:
                {
                    root.globSignalsObject.hideSetsAndCams()
                    //customSets.getEvents();
                }
            }
            IvVcliSetting
            {
                id:settingsViewtype
                name:"settings.sets.view_type"
            }
            IvVcliSetting
            {
                id: settingsType
                name: "settings.sets.type"
            }

        }
        Rectangle
        {
            id: allRect
            color: "transparent"
            anchors.top: camsAndSetsLabelRect.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 8* root.isize
            height: root.isNeedCustom?40* root.isize:0
            visible: root.isNeedCustom
            Column
            {
                width: 332* root.isize
                anchors.topMargin: 0
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 40* root.isize
                Rectangle {
                    width: parent.width
                    height: 40
                    color: "transparent"
                    radius: 12

                    IVSegmentedControl {
                        id: allBtn
                        width: parent.width
                        height: 40* root.isize
                        property var oldIndex
                        enabled: true
                        visible:root.opened
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                            margins: 0
                        }
                        model: allModel
                        onCurrentIndexChanged: allModel.get(currentIndex).type
                        Component.onCompleted: {
                            switch (settingsType.value)
                            {
                                case "all": oldIndex = currentIndex = 0; break
                                case "added": oldIndex = currentIndex = 1; break
                                default: oldIndex = currentIndex = 0; break
                            }
                        }
                        onEnabledChanged:
                        {
                            if (enabled)
                            {
                                currentIndex = oldIndex
                            }
                            else
                            {
                                oldIndex = currentIndex
                                currentIndex = typeModel.count-1
                            }
                        }
                    }
                    ListModel
                    {
                        id:allModel
                        ListElement
                        {
                            type:"all"
                            text:"Все"
                        }
                        ListElement
                        {
                            type:"added"
                            text:"В наборе"
                        }
                    }
                }
            }
        }
        Rectangle
        {
            id:groupRect
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: allRect.bottom
            height: 72* root.isize
            color: "transparent"

            ListModel {
                id:adaptiveModel
//                ListElement
//                {
//                    type:"flat"
//                    iconName:"new_images/list"
//                    text:"Плоская"
//                }
//                ListElement
//                {
//                    type:"fact"
//                    iconName:"new_images/fact_list"
//                    text:"Фактическая"
//                }
//                ListElement
//                {
//                    type:"custom"
//                    iconName:"new_images/list_custom"
//                    text:"Моя"
//                }
                Component.onCompleted:
                {
                    adaptiveModel.append({type:"flat",iconName:"new_images/list",text:"Плоская"});
                    adaptiveModel.append({type:"fact",iconName:"new_images/fact_list",text:"Фактическая"});
                    if(root.isNeedCustom)
                    {
                        adaptiveModel.append({type:"custom",iconName:"new_images/list_custom",text:"Моя"});
                    }
                }
            }
            Rectangle
            {
                id:rectViewlabel
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                color: "transparent"
                height: 16* root.isize
                Label {
                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                    text:"Группировка"
                    font: IVColors.getFont("Subtext")

                    anchors.left: parent.left
                    anchors.top: parent.top
                }
            }
            Timer
            {
                id:currttt
                triggeredOnStart: false
                interval: 200
                running: false
                repeat: false
                onTriggered:
                {
                    if(sourcesCurrent.value !== "")
                    {
                        var currAdaptive = parseInt(sourcesCurrent.value);
                        if(currAdaptive<0 && currAdaptive>2)
                        {
                            currAdaptive = 0;
                        }
                        cntAdaptive.currentIndex = currAdaptive;
                    }
                }
            }

            IVSegmentedControlAdaptive
            {
                id:cntAdaptive
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: rectViewlabel.bottom
                height: 40* root.isize
                model: adaptiveModel
                currentIndex:0
                onCurrentIndexChanged:
                {
                    //reloadTimer.start();
                    listLoader.create1(cntAdaptive.currentIndex);
                    sourcesCurrent.value = cntAdaptive.currentIndex.toString();
                }
                Component.onCompleted:
                {
                    currttt.start();
                }
            }
        }
        Rectangle
        {
            id:searchRect
            height: 32* root.isize
           // width: parent.width
            color:"transparent"
            anchors {
                top:groupRect.bottom
                left: parent.left
                right: parent.right
                topMargin: 2
            }
            IVInputField
            {
                id: searchField
                //height: 32
                size: IVInputField.Size.Small
                anchors
                {
                    left:parent.left
                    bottom:parent.bottom
                    top:parent.top
                    right:hideshowBtn.left
                }

                source: "new_images/search-md"
                placeholderText: "Найти по названию"
                onTextChanged: filterDelay.restart()
//                Timer // ст. Площадь Восс
//                {
//                    id: filterDelay2
//                    interval: 100
//                    triggeredOnStart: false
//                    repeat: false
//                    onTriggered:
//                    {
//                        //console.error("SEARCH SIGNAL!!!");
//                        listLoader.sourcesList.searchSignal();
//                    }
//                }

                Timer
                {
                    id: filterDelay
                    interval: 300
                    triggeredOnStart: false
                    repeat: false
                    onTriggered:
                    {
                        console.error("SEARCH START!!!!!!!!" , searchField.text);
                        if(root.isEditor && listLoader.currIndex !==1 )
                        {
                            devicesCameras.search3(searchField.text);
                        }
                        if(listLoader.currIndex ===2)
                        {
                            devicesCustom.search3(searchField.text);
                        }
                        else if(listLoader.currIndex ===1)
                        {
                            devicesFact.search3(searchField.text);
                        }
                        else if(listLoader.currIndex ===0)
                        {
                            devicesFlat.search3(searchField.text);
                        }

//                        if(searchField.text === "")
//                        {
//                            devicesCameras.search3(searchField.text);
//                        }



//                        devicesFlat.search3(searchField.text);
//                        devicesFact.search3(searchField.text);
//                        devicesCustom.search3(searchField.text);
//                        devicesCameras.search3(searchField.text);
                        //listLoader.sourcesList.searchSignal();
                        //filterDelay2.start();

//                        devicesFlat.remove();
//                        devicesFact.remove();
//                        devicesCustom.remove();
//                        devicesCameras.remove();
//                        devicesFlat.init("sources");
//                        devicesFact.init("fact");
//                        devicesCustom.init("custom");
                    }
                }
            }
            Rectangle
            {
                id:hideshowBtn
                width: 32* root.isize
                height: 32* root.isize
                anchors.right: parent.right
                color: IVColors.get("Colors/Background new/BgFormTertiaryThemed")
                radius:8* root.isize
                visible: true

                IVToolTip
                {
                    text:listLoader.sourcesList.isSameOpened?"Свернуть всё":"Развернуть всё"
                    visible: coolapseMouse.containsMouse
                }
                IVImage
                {
                    id: customEdits
                    property bool isExpand: false
                    name: listLoader.sourcesList.isSameOpened?"new_images/collapse2":"new_images/max"
                    //anchors.fill: parent
                    width:32* root.isize
                    height:32* root.isize
                    anchors.centerIn: parent
                    color:  IVColors.get("Colors/Text new/TxSecondaryThemed")
                    MouseArea
                    {
                        anchors.fill: parent
                        id:coolapseMouse
                        onClicked:
                        {
                            if(listLoader.sourcesList.isSameOpened)
                            {
                                listLoader.sourcesList.closeAll();
                            }
                            else
                            {
                                listLoader.sourcesList.openAll();
                            }
                            //listLoader.sourcesList.setNeedCamsVisible = false;
                        }
                    }
                }
            }
        }
        Rectangle
        {
            id: setsAndCamsCommonRect
            color: "transparent"
            anchors
            {
                top: searchRect.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: 16
            }
            Timer
            {
                id:reloadTimer
                interval: 1000
                triggeredOnStart: true
                repeat: false
                running: false
                onTriggered:
                {
                    //console.error("onCurrentUserChanged" , userName);
                    devicesFlat.remove();
                    devicesFact.remove();
                    devicesCustom.remove();
                    devicesCameras.remove();
                    devicesFlat.init("sources");
                    devicesFact.init("fact");
                    devicesCustom.init("custom");
                    devicesCameras.init("cameras");
//                    if(cntAdaptive.currentIndex ===2)
//                    {
//                        devices.init("custom");
//                    }
//                    else if(cntAdaptive.currentIndex ===1)
//                    {
//                        devices.init("fact");
//                    }
//                    else
//                    {
//                        devices.init("sources");
//                    }
                    listLoader.create1(cntAdaptive.currentIndex);
                }
            }
            IVCustomSets
            {
                id: customSets
                onCurrentUserChanged:
                {
                    root.globSignalsObject.clearView();
                    root.globSignalsObject.userChanged(userName);
                    reloadTimer.start();
                }
                Component.onCompleted: customSets.initWs();
            }
            IVTree {
                id: devicesCameras
                view: "all"
                Component.onCompleted: {
                    reloadTimer.start();
                    //devicesCameras.init("cameras");
                    //listLoader.create1();
                }
            }
            IVTree {
                id: devicesFlat
                view: "all"
                Component.onCompleted: {

                   // devicesFlat.init("sources");
                    //listLoader.create1();
                }
            }
            IVTree {
                id: devicesCustom
                view: "all"
                Component.onCompleted: {

                    //devicesCustom.init("custom");
                    //listLoader.create1();
                }
            }
            IVTree {
                id: devicesFact
                view: "all"
                Component.onCompleted: {

                   // devicesFact.init("flat");
                    //listLoader.create1();
                }
            }
            Loader
            {
                id:listLoader
                anchors.fill: parent
                property int currIndex: 0
                property var sourcesList: null
//                source: {
//                    switch(cntAdaptive.currentIndex)
//                    {
//                        case 0: return "IVSourcesListFlat.qml"
//                        case 1: return "IVSourcesListFlat.qml"
//                        case 2: return "IVSourcesListFlat.qml"
//                    }
//                }
                function create1(ind)
                {
                    console.error("CREATE1 CALLED with index:", ind, "isEditor:", root.isEditor);
                    listLoader.currIndex = ind;

                    if(ind === 2)
                    {
                        // devices.init("custom");
                    }
                    else if(ind === 1)
                    {
                        // devices.init("fact");
                    }
                    else if(ind === 0)
                    {
                        // devices.init("sources");
                    }

                    listLoader.source = "";
                    listLoader.source = "IVSourcesListFlat.qml";
                }

                onStatusChanged:
                {
                    if(listLoader.status === Loader.Ready)
                    {
                        listLoader.sourcesList = listLoader.item;
                        listLoader.item.globSignalsObject = root.globSignalsObject;
                        listLoader.item.customSets = customSets;
                        listLoader.item.messageDialog = messageDialog;

                        if(listLoader.currIndex ===2)
                        {
                            listLoader.item.devices = devicesCustom;
                        }
                        else if(listLoader.currIndex ===1)
                        {
                            listLoader.item.devices = devicesFact;
                        }
                        else if(listLoader.currIndex ===0)
                        {
                            listLoader.item.devices = devicesFlat;
                        }
                        filterDelay.start();
                    }
                }
            }
            Rectangle
            {
                id: listDownPanel
                visible: false
                height: visible ? 48 * root.isize : 0
                color: IVColors.get("Colors/Background new/BgFormAccent")
                radius: 16 * root.isize
                property int selected: -1
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    bottomMargin: 8 * root.isize
                }
                MouseArea {
                    id: selectedChb
                    width: 24 * root.isize
                    height: 24 * root.isize
                    property bool checked:
                    {
                        if(cntAdaptive.currentIndex === 2)
                        {
                            return parent.selected === devicesCustom.getCount("all")
                        }
                        else if(cntAdaptive.currentIndex === 1)
                        {
                            return parent.selected === devicesFact.getCount("all")
                        }
                        else if(cntAdaptive.currentIndex === 0)
                        {
                            return parent.selected === devicesFlat.getCount("all")
                        }
                        else
                        {
                            return false;
                        }
                    }
                    anchors {
                        leftMargin: 16 * root.isize
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    IVImage {
                        id: checkImage
                        name: "new_images/" +
                                (selectedChb.checked ? "check-fill" : "uncheck")
                        anchors.fill: parent
                        color: !selectedChb.checked ? IVColors.get("Colors/Text new/TxSecondaryContrast") :
                                                                             IVColors.get("Colors/Text new/TxContrast")
                    }
                    onClicked:
                    {
                        if(cntAdaptive.currentIndex === 2)
                        {
                            devicesCustom.setProp("checkState", checked ? 0 : 2)
                        }
                        else if(cntAdaptive.currentIndex === 1)
                        {
                           devicesFact.setProp("checkState", checked ? 0 : 2)
                        }
                        else if(cntAdaptive.currentIndex === 0)
                        {
                            devicesFlat.setProp("checkState", checked ? 0 : 2)
                        }
                        else
                        {

                        }
                        listDownPanel.updateValue()
                    }
                }
                Text {
                    id: selectedText
                    text:
                    {
                        if(cntAdaptive.currentIndex === 2)
                        {
                            return "Всего " +devicesCustom.getCount(settingsType.value)
                        }
                        else if(cntAdaptive.currentIndex === 1)
                        {
                            return "Всего " +devicesFact.getCount(settingsType.value)
                        }
                        else if(cntAdaptive.currentIndex === 0)
                        {
                            return "Всего " +devicesFlat.getCount(settingsType.value)
                        }
                        else
                        {
                            return "Всего 0";
                        }
                    }
                    font: IVColors.getFont("Text body")
                    color: IVColors.get("Colors/Text new/TxContrast")
                    anchors {
                        leftMargin: 8 * root.isize
                        left: selectedChb.right
                        verticalCenter: parent.verticalCenter
                    }
                }
                IVButton
                {
                    type: IVButton.Type.Outline
                    text: "Добавить"
                    width: 92 * root.isize
                    height: 32 * root.isize
                    visible: parent.selected > 0
                    anchors
                    {
                        rightMargin: 8 * root.isize
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    onClicked:
                    {
                        var devices = 0;
                        if(cntAdaptive.currentIndex === 2)
                        {
                            devices = devicesCustom.getCount(settingsType.value)
                        }
                        else if(cntAdaptive.currentIndex === 1)
                        {
                            devices = devicesFact.getCount(settingsType.value)
                        }
                        else if(cntAdaptive.currentIndex === 0)
                        {
                            devices = devicesFlat.getCount(settingsType.value)
                        }
                        else
                        {
                           devices = 0;
                        }


                        for (var i = 0; i < devices.getCount(settingsType.value); i++) {
                            var el = devices.get([1,i])
                            if (el.getProp("checkState") > 0) {
                                var x = 1, y = 1
                                var dx = 8, dy = 8
                                var cols = 32, rows = 32
                                console.log("onClicked add", i, el.getProp("name_"))
                                var item = customSets.getTypePreset(el.getProp("type"), "key2", "string", el.getProp("name_"));
                                //console.error("JSON PRESET = ",JSON.stringify(item));
                                var _zoneObj = {} // customSets.getZZZone(el.getProp("type"), el.getProp("name_"))
                                _zoneObj["x"] = x
                                _zoneObj["y"] = y
                                _zoneObj["dx"] = dx
                                _zoneObj["dy"] = dy
                                _zoneObj["type"] = el.getProp("type")
                                _zoneObj["params"] = item.params
                                _zoneObj["qml_path"] = item.qml_path
                                //console.error("CAMS TO SLOT onClicked =====================================",JSON.stringify(_zoneObj))
                                root.globSignalsObject.zonesAdded("",JSON.stringify(_zoneObj));
                                x += dx
                                y += (x > 32 ? dy : 0)
                                x = x%cols
                            }
                        }

                        root.globSignalsObject.hideSetsAndCams();
                    }
                }

                onVisibleChanged: {
                    if (!visible)
                    {
                        var devices = 0;
                        if(cntAdaptive.currentIndex === 2)
                        {
                            devices = devicesCustom.getCount(settingsType.value)
                        }
                        else if(cntAdaptive.currentIndex === 1)
                        {
                            devices = devicesFact.getCount(settingsType.value)
                        }
                        else if(cntAdaptive.currentIndex === 0)
                        {
                            devices = devicesFlat.getCount(settingsType.value)
                        }
                        else
                        {
                           devices = 0;
                        }
                        devices.setProp("checkState", 0)
                    }
                    updateValue()
                }

                function updateValue()
                {
                    var devices = 0;
                    if(cntAdaptive.currentIndex === 2)
                    {
                        devices = devicesCustom.getCount(settingsType.value)
                    }
                    else if(cntAdaptive.currentIndex === 1)
                    {
                        devices = devicesFact.getCount(settingsType.value)
                    }
                    else if(cntAdaptive.currentIndex === 0)
                    {
                        devices = devicesFlat.getCount(settingsType.value)
                    }
                    else
                    {
                       devices = 0;
                    }
                    var allCount = devices.getCount(settingsType.value)
                    selected = devices.getCount(settingsType.value, 2)
                    selectedChb.checked = (selected === allCount)
                    if (selected > 0) selectedText.text = selected + " из " + allCount
                    else selectedText.text = "Всего " + allCount
                }
            }
        }

    }
}

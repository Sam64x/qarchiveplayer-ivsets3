import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
//import QtQuick.Particles 2.0
import iv.plugins.loader 1.0
import iv.components.windows 1.0
import iv.sets.sets3 1.0
import iv.colors 1.0
import iv.controls 1.0

Rectangle
{
    id:root
    color: IVColors.get("Colors/Background new/BgFormPrimaryThemed")
    anchors.fill: parent

    property var oldWinFlags: null
    property string unique:"newclient"



    QtObject
    {
        id:globSignalsObject
        signal zoneChanged(int index,variant zoneparams)
        signal zoneChangedFromMouse(int index,variant zoneparams)
        signal clearView()
        signal zoneSelected(int index,string zoneparams)
        signal zonesAdded(string setname,string zone)
        signal zonesAddedFromSetName(string setname,variant zoneparams)
        signal zoneRemoved(int index)
        signal getZonesFromSet()

        signal setToArchive()
        signal setToRealtime()
        signal setsCompleted()
        signal setChanged(string setname)
        signal setAdded(string setname)
        signal setRemoved(string setname)
        signal setRemoved2(string setname, string setId)
        signal setSelected(string setname)
        signal setSaved(string setname)
        signal setRefreshed(string setname)
        signal setColsRowsChanged(int cols, int rows)
        signal setColsChanged(int cols)
        signal setRowsChanged(int rows)
        signal setSaved2()
        signal setNameChanged(string setname,string newSetName)
        signal setCopy(string setname)
        signal newSetAdded(string setname)
        signal ratioChanged(int ratioX, int ratioY)
        signal ratioXChanged(int ratioX)
        signal ratioYChanged(int ratioY)

        signal setPreset(var presetNumber);
        signal setPreset1()
        signal setPreset2()
        signal setPreset3()

        signal setPressetIndex(int indexOfPresset)

        signal slotsChanged(string slotsModel,int pressetNumber)

        signal tabSelected(string tabname, int index)
        //signal tabSelected2(string tabname, string type)
        //signal tabSelected3(string tabname, string type,string id)
        signal tabSelected4(string tabname, string type,string id,string key2)
        signal tabSelected5(string tabname, string type,string id,string viewType)
        signal tabRemoved(string tabname, int index)
        signal tabRemoved2(string tabname)
        signal tabRemovedCurrent()
        signal tabAdded(string tabname, int index)
        signal tabAdded2(string tabname, string type)
        //signal tabAdded3(string tabname, string type,string id)
        signal tabAdded4(string tabname, string type,string id,string key2)
        signal tabAdded5(string tabname, string type,string id,string viewType)
        signal tabTypeChanged(string tabtype)
        signal tabRemoveLeft(string tabname)
        signal tabRemoveRight(string tabname)
        signal tabRemoveAll(string tabname)
        signal tabSetUniqId(string tabUniq)
        onTabUniqIdChanged:
        {
            //globSignalsObject.tabUniqId = tabUniq;
            console.error("globSignalsObject.tabUniqId = ", globSignalsObject.tabUniqId)
        }
        property string tabUniqId:""
        function getTabUniq()
        {
            console.error("getTabUniq = ", globSignalsObject.tabUniqId)
            return globSignalsObject.tabUniqId;
        }

        signal userChanged(string userName);
//        signal tabSelectedOnceCam(string tabName,int innerIndex,string type,var params,string qmlPath)


        signal showSetsAndCams()
        signal hideSetsAndCams()
        property bool setsAndCamsBlockOpened: cliSetsAndCams.opened

        signal showSetsStrangeBlock()
        signal hideSetsStrangeBlock()
        property bool setsStrangeBlockOpened: false//cliSetsAndCams.opened

        signal showStrangeBlock()
        signal hideStrangeBlock()
        property bool strangeBlockOpened: false//cliSetsAndCams.opened

        signal showLeftMenu()
        signal hideLeftMenu()

        signal settingsLoad()
        signal setsLoad()
        signal setsHided()
        signal setsShowed()
        signal camsHided()
        signal camsShowed()

        signal search(string searchText)


        signal switch_fullscreen(int index)


        //редактор наборов
        signal tabEditedOn()
        signal tabEditedOff()
        property bool isEditorEnabled:false
        function getEditorStatus()
        {
            return isEditorEnabled;
        }
        onTabEditedOff:
        {
            //cliSetsSettingsOpen.stop();
            //cliSetsSettingsClose.start();
            //cliSetsSettingsBlock.visible = false;
            isEditorEnabled = false;
        }
        onTabEditedOn:
        {
            //cliSetsSettingsClose.stop();
            //cliSetsSettingsOpen.start();
            //cliSetsSettingsBlock.visible = true;
            isEditorEnabled = true;
            //cliSetsSettingsBlock.getTempFunc();
        }
        //


        //автодобавление камер с созданием новой зоны
        signal camsAutoModeOn()
        signal camsAutoModeOff()
        property bool isCamsAutoMode:true
        function getCamsAutoModeStatus()
        {
            return isCamsAutoMode;
        }
        onCamsAutoModeOn:
        {
            isCamsAutoMode = true;
        }
        onCamsAutoModeOff:
        {
            isCamsAutoMode = false;
        }

        //добавление камер в предпросмотр
        signal addCamToPreview(variant zoneparams)
        signal addCamToSlot(variant zoneparams)
        signal addEmptySlot()







        ///Для поддержки старых сигналов
        signal command1(string command,var sender,var params)
        ///Для поддержки старых сигналов
    }

    onWidthChanged:
    {
       if(root.Window.window.visibility === Window.Windowed || root.Window.window.visibility === Window.Maximized)
       {
           root.Window.window.visibility === Window.Windowed;
       }
    }
    onHeightChanged:
    {
        if(root.Window.window.visibility === Window.Windowed || root.Window.window.visibility === Window.Maximized)
        {
            root.Window.window.visibility === Window.Windowed;
        }
    }

    IVClientLeftMenu {
        id:leftMenu
        anchors {
            left: parent.left
            top: tabsPanel.bottom
            bottom: parent.bottom
        }
        extended_menu: false
        globalSignalsObject:globSignalsObject
        z: 10
    }

    IVClientSetsAndCamsBlock {
        id: cliSetsAndCams
        anchors {
            left: parent.left
            top: tabsPanel.bottom
            bottom: parent.bottom
        }
//        expandWidth:
//        {
//            if(cliSetsAndCams.opened)
//            {
//                var _width = 0;
//                if(sourcesWidth.value !== "")
//                {
//                    _width = parseInt(sourcesWidth.value);
//                    if(_width <328)
//                    {
//                        _width = 328;
//                    }
//                }

//                return  _width;
//            }
//            else
//            {
//                return 0;
//            }
//        }
        globSignalsObject: globSignalsObject
        onOpenedChanged: {
            //globSignalsObject.setsAndCamsBlockOpened
        }
    }
    IvVcliSetting
    {
        id:sourcesWidth
        name:"sourcesList.width"
    }
    IvVcliSetting
    {
        id:sourcesOpened
        name:"sourcesList.opened"
        Component.onCompleted:
        {
            if(sourcesOpened.value === "true")
            {
                globSignalsObject.showSetsAndCams();
            }

        }
    }

    Rectangle
    {
        id:rightSizeRect
        anchors.right: cliSetsAndCams.right
        width: 3
        height: parent.height
        color: dragWidthMa.containsMouse?"#070d53":"transparent"
        Timer
        {
            id:widthTimer
            interval: 200
            triggeredOnStart: false
            repeat: false
            running: false
            onTriggered:
            {
                if(cliSetsAndCams.width < 328)
                    cliSetsAndCams.width = 328;
                if(cliSetsAndCams.width>500)
                {
                    cliSetsAndCams.width = 500;
                }
                sourcesWidth.value = cliSetsAndCams.width.toString();
                //console.error("sourcesWidth.value = ", sourcesWidth.value)
            }
        }

        MouseArea
        {
            anchors.fill: parent
            hoverEnabled: true
            id:dragWidthMa
            drag
            {
                target: parent
                axis: Drag.XAxis
            }
            cursorShape: Qt.SizeHorCursor
            onReleased:
            {
               widthTimer.start();
            }

            onMouseXChanged:
            {
                if(drag.active )
                {
                    if(cliSetsAndCams.width <= 500 && cliSetsAndCams.width>=328)
                    {
                        cliSetsAndCams.width = cliSetsAndCams.width + mouseX;

                        if(cliSetsAndCams.width < 328)
                        {
                            cliSetsAndCams.width = 328;
                        }
                        if(cliSetsAndCams.width>500)
                        {
                            cliSetsAndCams.width = 500;
                        }
                        //return;
                    }
//                    root.width += mouseX;
//                    if(root.width>root.Window.window.width/2)
//                    {
//                        root.width = root.Window.window.width/2;
//                        if(root.width<328)
//                        {
//                            root.width = 328;
//                        }
//                        return;
//                    }
//                    if(root.width<328)
//                    {
//                        root.width = 328;
//                        return;
//                    }


                }
            }

        }
    }
    Rectangle {
        anchors {
            left: cliSetsAndCams.right
            top: tabsPanel.bottom
            bottom: parent.bottom
            right: parent.right
        }
        color: "transparent"
        IVClientMainRect {
            id: mainRect
            globalSignalsObject:globSignalsObject
        }
    }
    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }
    property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1
    Item {
        id: tabsPanel
        property real standartHeight: 48*root.isize
        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
        }
        height: standartHeight
        visible: height > 0
        opacity: height/standartHeight

        Rectangle {
            id:menuRect
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            z: 11
            width: 72*root.isize
            color: leftMenu.opened ? IVColors.get("Colors/Background new/BgFormPrimaryThemed") :
                                     IVColors.get("Colors/Background new/BgContextMenuThemed")
            Behavior on color {
                ColorAnimation {duration: 150}
            }

            IVMenuButton {
                id: menuButton
                width: 56*root.isize
                height: 40*root.isize
                anchors {
                    fill: parent
                    leftMargin: 8
                    rightMargin: 8
                    topMargin: 4
                    bottomMargin: 4
                }
                source: "new_images/Earth"
                toolTipText: "Меню"
                onClicked:{
                    console.log("IVButton menuButton clicked")
                    var isEditor = globSignalsObject.getEditorStatus();
                    if (!isEditor)
                    {
                        if (leftMenu.opened) globSignalsObject.hideLeftMenu()
                        else globSignalsObject.showLeftMenu()
                    }
                }
            }
        }
        IVClientTabsPanel {
            anchors.left: menuRect.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            globalSignalsObject:globSignalsObject
            onMiniClicked:
            {
                tabsPanel.height = 0
                miniHeader.opacity = 1
                root.oldWinFlags = root.Window.window.flags;
                //root.Window.window.flags = Qt.FramelessWindowHint;

            }
        }
        IVClientTopEditPanel {
            anchors.left: menuRect.right
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            globalSignalsObject:globSignalsObject
            z: 10000
        }

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad}
        }
    }

    IVClientHeaderMini {
        id: miniHeader
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: 0
        globalSignalsObject:globSignalsObject
        onMiniClicked: {
            tabsPanel.height = tabsPanel.standartHeight
            miniHeader.opacity = 0
            //root.Window.window.flags =  root.oldWinFlags
        }
    }

    Component.onCompleted:
    {
        //root.Window.window.border.width = 0;
        //root.Window.window.color = IVColors.get("Colors/Background new/BgFormPrimaryThemed");
       // mainLoader.create1();

    }
    IvVcliSetting {
        id: archive
        name: 'archive.common_panel'
        onValueChanged:
        {
            if(archive.value === "true")
            {
                console.error("COMMON ARCHIVE CREATE!!!!");
                //mainLoader.create1();
            }
        }
    }
}

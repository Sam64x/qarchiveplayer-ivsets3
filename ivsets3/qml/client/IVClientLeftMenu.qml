import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.plugins.loader 1.0
import iv.plugins.users 1.0
import iv.sets.sets3 1.0
import iv.components.windows 1.0
import iv.exprogress 1.0
import iv.colors 1.0
import iv.controls 1.0
import QtGraphicalEffects 1.0

Rectangle
{
    id:root
    color: IVColors.get("Colors/Background new/BgFormPrimaryThemed")
    width: opened ? expandWidth : 0
    height: parent.height

    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }
    property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1
    readonly property int expandWidth: 72*root.isize
    property var globalSignalsObject: null
    property bool extended_menu: false
    property bool isSameMenuExpanded: false
    property bool opened: false
    opacity: width/expandWidth
    property var templateStandart: null


    IvVcliSetting
    {
        id: ptzEnabled
        name: 'PTZEnabled'
    }

    IvVcliSetting
    {
        id:standartTemplates
        name:"qml.templates.standart"
    }
    IvVcliSetting
    {
        id:mainAreaTemplates
        name:"qml.templates.mainarea"
    }
    IvVcliSetting
    {
        id:setsTimerSettings
        name:root.Window.window.unique?root.Window.window.unique+"#tabs#setsTimer":""
        //value:setsTimerImage._pressed?"running":""
    }
    IvVcliSetting
    {
        id: arc_stat_new
        name: 'archive.new_stat'
    }
    IvAccess
    {
      id: arch_detector_acc
      access: "{detector_archive_analyze}"
    }
    IvAccess
    {
      id: arc_stat_acc
      access: "{archive_statistic}"
    }
    IvAccess
    {
      id: events_acc
      access: "{event_log}"
    }
    IvAccess
    {
      id: createWindow
      access: "{creating_windows}"
    }
    IvAccess
    {
      id: clientSettings
      access: "{client_settings}"
    }
//    IvAccess {
//      id: events_acc
//      access: "{event_log}"
//    }



    Iv7Log {id: idLog; name: 'qexprogress'}
    IvAccess {id: export_progress; access: "{media_export_progress}"}
    IvVcliSetting {id: cmdArgsMode; name: 'cmd_args.mode'}



    Behavior on width {
        NumberAnimation {
            duration: 200; easing.type: Easing.InOutQuad
        }
    }

    Connections {
        id: myConn
        target: root.globSignalsObject
        onShowLeftMenu: root.opened = true
        onHideLeftMenu: root.opened = false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
    }

    ColumnLayout {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 6
            leftMargin: 8
            rightMargin: 8
        }
        spacing: 4
        Rectangle {
            color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
            Layout.fillWidth: true
            height: 2
            radius: 1
        }
//        ivComponent.command('WindowsCreator', 'windows:add', {'template':template, 'width':1000, 'height':700,
//        'minimumWidth':50, 'minimumHeight':50});
        IVMenuButton {
            id: createNewWindBtn
            Layout.fillWidth: true
            height: 40*root.isize
            source: "new_images/monitor-01"
            toolTipText: "Создать новое окно клиента"
            enabled: createWindow.isAllowed
            property int maxWinCount: 4
            property var windows: []
            onClicked: {
                if(root.templateStandart === null)
                {
                    root.templateStandart = JSON.parse(mainAreaTemplates.value);
                }

                if (opened) root.globalSignalsObject.hideLeftMenu()
                if (windows.length > maxWinCount-1) {
                    //console.log("exportProgress windows count > 0")
                    // перемещаем фокус на уже созданное окно
                    //windows[maxWinCount-1].requestActivate()
                    return
                }
//                var path = 'file:///' + applicationDirPath +
//                        '/qtplugins/iv/semantica/IVSemanticaWindow.qml'
//                var info = {}
//                info.title = "Видеосемантика"
//                createWindow(createSemaWndButt, path, false, info)
                //console.error(standartTemplates.value);
                root.Window.window.ivComponent.command('WindowsCreator', 'windows:add', {'template':"standart", 'width':1000, 'height':700,
                                                                       'minimumWidth':50, 'minimumHeight':50});
            }
        }

//        IVMenuButton {
//            id: setsStrangeButton
//            Layout.fillWidth: true
//            height: 40
//            source: "new_images/layout-grid-02"
//            toolTipText: "Создать новое окно"
//            enabled: false
//        }
//        IVMenuButton {
//            id: arcButton
//            Layout.fillWidth: true
//            height: 40
//            source: "new_images/monitor-01"
//            toolTipText: "Создать окно архива"
//            enabled: true
//            onClicked: {
//                if (opened) {
//                    root.globalSignalsObject.hideLeftMenu()
//                    var path = 'file:///' + applicationDirPath +
//                            '/qtplugins/iv/sets/sets3/IVClientArchiveWindow.qml'
//                    var info = {}
//                    info.title = "Архив"
//                    createWindow1(arcButton,path, false, info);
//                }
//            }
//        }
        IVMenuButton {
            id: createSemaWndButt
            Layout.fillWidth: true
            height: 40*root.isize
            source: "new_images/monitor-01"
            toolTipText: "Создать окно семантики"
            enabled: createWindow.isAllowed
            property int maxWinCount: 4
            property var windows: []
            onClicked: {
                if (opened) root.globalSignalsObject.hideLeftMenu()
                if (windows.length > maxWinCount-1) {
//                    console.log("exportProgress windows count > 0")
//                    // перемещаем фокус на уже созданное окно
//                    windows[maxWinCount-1].requestActivate()
                    return
                }
                var path ='/qtplugins/iv/semantica/IVSemanticaWindow.qml'
//                var info = {}
//                info.title = "Видеосемантика"
//                createWindow(createSemaWndButt, path, false, info)
                root.Window.window.ivComponent.command('WindowsCreator', 'windows:add', {'qml':path,'width':1000, 'height':700,
                                      'minimumWidth':150, 'minimumHeight':150});
            }
        }
        Rectangle {
            color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
            Layout.fillWidth: true
            visible: root.width > 0
            height: 2
            radius: 1
        }
        IVMenuButton {
            id: camsAndSetsButton
            Layout.fillWidth: true
            height: 40*root.isize
            source: "new_images/cctv"
            toolTipText: "Источники"
            onClicked: {
                //root.globSignalsObject.setCopy("");
                var isEditor = root.globalSignalsObject.getEditorStatus();
                if (!isEditor) {
                    if (opened) {
                        root.globalSignalsObject.hideLeftMenu()
                        root.isSameMenuExpanded = true
                    }
                    else {
                        root.globalSignalsObject.showLeftMenu()
                        root.isSameMenuExpanded = false
                    }
                    if (!root.globalSignalsObject.setsAndCamsBlockOpened){
                        root.globalSignalsObject.showSetsAndCams()
                    }
                }
            }
        }
        IVMenuButton {
            id: archiveDetectButt
            Layout.fillWidth: true
            height: 40*root.isize
            source: "new_images/data"
            toolTipText: "Детекция по архиву"
            enabled: arch_detector_acc.isAllowed
            property var windows: []
            onClicked: {
                if (opened) root.globalSignalsObject.hideLeftMenu()
                if (windows.length > 0) {
                    console.log("exportProgress windows count > 0")
                    // перемещаем фокус на уже созданное окно
                    windows[0].requestActivate()
                    return
                }
                var path = 'file:///' + applicationDirPath +
                        '/qtplugins/iv/archivedetector/IVArchiveDetectorWnd.qml'
                createWindow1(archiveDetectButt, path)
            }
        }
        IVMenuButton {
            id: archiveStatButt
            Layout.fillWidth: true
            height: 40*root.isize
            source: "new_images/bar-chart-07"
            toolTipText: "Статистика архива"
            enabled: arc_stat_acc.isAllowed
            property var windows: []
            onClicked: {
                if (opened) root.globalSignalsObject.hideLeftMenu()
                if (windows.length > 0) {
                    console.log("exportProgress windows count > 0")
                    // перемещаем фокус на уже созданное окно
                    windows[0].requestActivate()
                    return
                }
                var path = 'file:///' + applicationDirPath + "/qtplugins/iv/archivecomponents/"
                if (JSON.parse(arc_stat_new.value) === true){
                    path += "qarc_stat_plgn/StatMain.qml"
                    createWindow1(archiveStatButt, path)
                }
                else {
                    path += "passgraph/qcallstatchart.qml"
                    createWindow1(archiveStatButt, path, false)
                }
            }
        }
        Rectangle {
            color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
            Layout.fillWidth: true
            visible: root.width > 0
            height: 2
            radius: 1
        }
        IVMenuButton {
            id: eventsButton
            Layout.fillWidth: true
            height: 40*root.isize
            source: "new_images/Event"
            toolTipText: "События"
            enabled:events_acc.isAllowed
            property var windows: []
            onClicked: {
                if (opened) root.globalSignalsObject.hideLeftMenu()
                if (windows.length > 0) {
                    console.log("exportProgress windows count > 0")
                    // перемещаем фокус на уже созданное окно
                    windows[0].requestActivate()
                    return
                }
                if (events_acc.isAllowed){
                    var path = 'file:///' + applicationDirPath +
                            '/qtplugins/iv/events/events/IVEventsAreaWindow.qml'
                    createWindow1(eventsButton, path)
                }
            }
        }
        IVMenuButton {
            id: exportProgressButt
            Layout.fillWidth: true
            height: 40*root.isize
            source: "new_images/clipboard-arrow-down"
            toolTipText: "Прогресс выгрузок"
            enabled: export_progress.isAllowed
            property int winCount: MExprogress.windows_count
            property var windows: []
            onClicked: {
                if (opened) root.globalSignalsObject.hideLeftMenu()
                if (winCount > 0) {
                    if (windows.length > 0) {
                        console.log("exportProgress windows count > 0")
                        // перемещаем фокус на уже созданное окно
                        windows[0].requestActivate()
                    }
                    return
                }
                var path = 'file:///' + applicationDirPath +
                        '/qtplugins/iv/exprogress/Settings.qml'
                createWindow1(exportProgressButt, path, true)
            }
            function onExprogressWindowEvent(sender, eventname, json) {
                if (eventname === 'onClosing')
                    sender.commandToParent('cleanExprogressWindow', {})
            }
        }
//        Rectangle {
//            color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
//            Layout.fillWidth: true
//            visible: root.width > 0
//            height: 2
//            radius: 1
//        }
//        IVMenuButton {
//            id: strange2Button
//            Layout.fillWidth: true
//            height: 40
//            source: "new_images/help-circle"
//            //toolTipText: "Алексей, что это?"
//            enabled: false
//            onClicked: {
//                if (opened) {
//                    root.globalSignalsObject.hideLeftMenu()
//                    root.isSameMenuExpanded = true
//                }
//                else {
//                    root.globalSignalsObject.showLeftMenu()
//                    root.isSameMenuExpanded = false
//                }
//            }
//        }
    }
    ColumnLayout {
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            leftMargin: 8
            rightMargin: 8
            bottomMargin: 8
        }
        IVMenuButton {
            id: settingsButton
            Layout.fillWidth: true
            height: 40*root.isize
            visible: root.opened
            enabled:clientSettings.isAllowed
            source: "new_images/settings-02"
            toolTipText: "Настройки клиента"
            onClicked: {
                var isEditor = root.globalSignalsObject.getEditorStatus();
                if (!isEditor){
                    root.globalSignalsObject.tabAdded5("Настройки клиента","client_settings","","");
                    if (opened) {
                        root.globalSignalsObject.hideLeftMenu()
                        root.isSameMenuExpanded = true
                    }
                    else {
                        root.globalSignalsObject.showLeftMenu()
                        root.isSameMenuExpanded = false
                    }
                }
            }
        }
        IVMenuButton {
            id: fullscreenButt
            Layout.fillWidth: true
            height: 40*root.isize
            visible: root.opened
            source: "new_images/max"
            toolTipText: "Полный экран"
            onClicked: {
                root.Window.window.visibility = Window.FullScreen;
                if (opened) {
                    root.globalSignalsObject.hideLeftMenu()
                    root.isSameMenuExpanded = true
                }
                else {
                    root.globalSignalsObject.showLeftMenu()
                    root.isSameMenuExpanded = false
                }
            }
        }
        Label
        {
            id:versLabel
            Layout.fillWidth: true
            width: parent.width
            height: 20
            text: "v7.0.794"
            color: "white"
        }
    }

    onGlobalSignalsObjectChanged: myConn.target = globalSignalsObject
    function createWindow1(sender, path, hasWindow, info) {
        var comp, win
        if (hasWindow === false){
            comp = Qt.createComponent("IVNewQmlWindow.qml")

            if (comp.status === Component.Ready)
            {
                win = comp.createObject(root)
                if (info !== undefined) win.params = info
                win.path = path
                sender.windows.push(win)
                console.log("createWindow", sender, sender.windows, "params:", comp.params)
                win.Component.onDestruction.connect(function() {
                    sender.windows.splice(sender.windows.indexOf(win), 1)
                    console.log("onDestruction connect", sender, sender.windows)
                })
            }
            else console.log("ssssssss =", comp.errorString())
        }
        else {
            comp = Qt.createComponent(path)
            if (comp.status === Component.Ready) {
                win = comp.createObject(root)
                sender.windows.push(win)
                console.log("createWindow", sender, sender.windows)
                win.onClosing.connect(function() {
                    sender.windows.splice(sender.windows.indexOf(win), 1)
                    console.log("onClosing connect", sender, sender.windows)
                })
            }
            else console.log("ssssssss =", comp.errorString())
        }
        win.show();
    }
}

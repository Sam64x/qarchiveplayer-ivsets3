import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import QtGraphicalEffects 1.0
import QtQuick.Dialogs 1.1

import iv.plugins.loader 1.0
import iv.sets.sets3 1.0
import iv.colors 1.0
import iv.controls 1.0

Rectangle {
    id: root

    property var globSignalsObject

    readonly property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1

    implicitWidth: 364
    implicitHeight: 700

    color: IVColors.get("Colors/Background new/BgContextMenuThemed")

    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }

    Connections {
        target: root.globSignalsObject
        onSetSaved: {
            reloadTimer.start();
        }
        onServerSetSaved: {
            reloadTimer.start();
        }
        onSetRemoved: {
            reloadTimer.start();
        }
    }

    ColumnLayout {
        id: contentLayout
        anchors {
            fill: parent
            topMargin: 8
            leftMargin: 16
            rightMargin: 6
        }
        spacing: 4

        ColumnLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 10
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text:"Источники"
                    font: IVColors.getFont("Subtitle accent")
                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                }

                Item {
                    Layout.fillWidth: true
                }

                IVButton {
                    Layout.preferredWidth: 32 * root.isize
                    Layout.preferredHeight: 32 * root.isize

                    source: "new_images/x-close"
                    toolTipText: "Закрыть источники"
                    type: IVButton.Type.Helper
                    onClicked: {
                        root.globSignalsObject.setsAndCamsBlockOpened = false;
                    }
                }
            }

            // IVSegmentedControl {
            //     Layout.fillWidth: true
            //     Layout.preferredHeight: 40 * root.isize

            //     radius: 8 * root.isize
            //     currentIndex: 0

            //     model: ListModel {
            //         ListElement {
            //             type: "all"
            //             text: "Все"
            //         }
            //         ListElement {
            //             type: "added"
            //             text: "В наборе"
            //         }
            //     }

            //     IvVcliSetting {
            //         id: settingsType
            //         name: "settings.sets.type"
            //     }
            // }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                    font: IVColors.getFont("Subtext")
                    text:"Группировка"
                }

                IVSegmentedControlAdaptive {
                    id: cntAdaptive

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40 * root.isize

                    currentIndex: 0
                    model: ListModel {
                        ListElement {
                            type: "flat"
                            iconName: "new_images/list"
                            text: "Плоская"
                        }
                        ListElement {
                            type: "fact"
                            iconName: "new_images/fact_list"
                            text: "Фактическая"
                        }
                        ListElement {
                            type: "custom"
                            iconName: "new_images/list_custom"
                            text: "Пользовательская"
                        }
                    }
                    onCurrentIndexChanged: {
                        sourcesCurrent.value = cntAdaptive.currentIndex.toString();
                    }
                    Component.onCompleted: {
                        if (sourcesCurrent.value !== "") {
                            const currAdaptive = clamp(parseInt(sourcesCurrent.value), 0, model.count - 1);
                            cntAdaptive.currentIndex = currAdaptive;
                        }
                    }

                    function clamp(value, min, max) {
                        return Math.max(min, Math.min(value, max));
                    }

                    IvVcliSetting {
                        id: sourcesCurrent
                        name: "sourcesList.currentView"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                IVInputField {
                    id: searchField

                    Layout.fillWidth: true

                    size: IVInputField.Size.Small
                    source: "new_images/search-md"
                    placeholderText: "Найти по названию"
                    onTextChanged: {
                        filterDelay.restart()
                    }

                    Timer {
                        id: filterDelay
                        interval: 300
                        triggeredOnStart: false
                        repeat: false
                        onTriggered: {
                            // if(root.isEditor && sourcesList.currentIndex !==1 ) {
                            //     devicesCameras.search3(searchField.text);
                            // }
                            if (sourcesList.currentIndex === 2) {
                                devicesCustom.search3(searchField.text);
                            }
                            else if(sourcesList.currentIndex === 1) {
                                devicesFact.search3(searchField.text);
                            }
                            else if(sourcesList.currentIndex === 0) {
                                devicesFlat.search3(searchField.text);
                            }
    //                        if(searchField.text === "") {
    //                            devicesCameras.search3(searchField.text);
    //                        }

    //                        devicesFlat.search3(searchField.text);
    //                        devicesFact.search3(searchField.text);
    //                        devicesCustom.search3(searchField.text);
    //                        devicesCameras.search3(searchField.text);
                            //sourcesList.searchSignal();
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

                IVButtonControl {
                    Layout.preferredWidth: 32 * root.isize
                    Layout.preferredHeight: 32 * root.isize

                    type: IVButtonControl.Type.Helper
                    source: sourcesList.isSameOpened ? "new_images/collapse2" : "new_images/collapse2_expand.svg"
                    toolTipText: sourcesList.isSameOpened ? "Свернуть всё" : "Развернуть всё"

                    onClicked: {
                        if (sourcesList.isSameOpened) {
                            sourcesList.closeAll();
                        }
                        else {
                            sourcesList.openAll();
                        }
                    }
                }
            }
        }

        IVSourcesListFlat {
            id: sourcesList

            readonly property int currentIndex: cntAdaptive.currentIndex

            Layout.fillWidth: true
            Layout.fillHeight: true

            globSignalsObject: root.globSignalsObject
            customSets: customSets
            devices: {
                switch (currentIndex) {
                case 2: return devicesCustom;
                case 1: return devicesFact;
                case 0: return devicesFlat;
                }
                return null;
            }

            onDevicesChanged: {
                filterDelay.start();
            }
        }

        Loader {
            Layout.preferredHeight: 48 * root.isize
            Layout.fillWidth: true

            active: false
            visible: active

            sourceComponent: Rectangle {
                id: listDownPanel

                property int selected: -1

                color: IVColors.get("Colors/Background new/BgFormAccent")
                radius: 16 * root.isize

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
                                var item = customSets.getTypePreset(el.getProp("type"), "key2", "string", el.getProp("name_"));
                                var _zoneObj = {} // customSets.getZZZone(el.getProp("type"), el.getProp("name_"))
                                _zoneObj["x"] = x
                                _zoneObj["y"] = y
                                _zoneObj["dx"] = dx
                                _zoneObj["dy"] = dy
                                _zoneObj["type"] = el.getProp("type")
                                _zoneObj["params"] = item.params
                                _zoneObj["qml_path"] = item.qml_path
                                root.globSignalsObject.zonesAdded("",JSON.stringify(_zoneObj));
                                x += dx
                                y += (x > 32 ? dy : 0)
                                x = x%cols
                            }
                        }

                        root.globSignalsObject.setsAndCamsBlockOpened = false;
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

    Timer {
        id:reloadTimer
        interval: 1000
        onTriggered: {
            devicesFlat.remove();
            devicesFact.remove();
            devicesCustom.remove();
            devicesCameras.remove();
            devicesFlat.init("sources");
            devicesFact.init("fact");
            devicesCustom.init("custom");
            devicesCameras.init("cameras");
        }
    }
    IVCustomSets {
        id: customSets
        onCurrentUserChanged: {
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
        }
    }
    IVTree {
        id: devicesFlat
        view: "all"
        Component.onCompleted: {
           // devicesFlat.init("sources");
        }
    }
    IVTree {
        id: devicesCustom
        view: "all"
        Component.onCompleted: {
            //devicesCustom.init("custom");
        }
    }
    IVTree {
        id: devicesFact
        view: "all"
        Component.onCompleted: {
           // devicesFact.init("flat");
        }
    }
}

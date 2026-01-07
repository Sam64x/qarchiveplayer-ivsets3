import QtQuick 2.7
import QtQml 2.3
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtQuick.Window 2.11

import iv.colors 1.0
import iv.singletonLang 1.0
import iv.controls 1.0 as C
import iv.viewers.archiveplayer 1.0
import ArchiveComponents 1.0

C.IVButtonControl {
    id: ev_settings_butt

    property var rootRef
    property int posAlignment: Qt.AlignTop | Qt.AlignLeft

    readonly property real rootWidth: rootRef.width
    readonly property real rootHeight: rootRef.height

    implicitHeight: 24
    implicitWidth: 24
    checkable: true
    checked: settingsMenu.opened
    source: "new_images/settings-04.svg"
    size: C.IVButtonControl.Size.Small
    type: C.IVButtonControl.Type.Secondary
    toolTipText: Language.getTranslate("Settings","Настройки")
    toolTipVisible: !settingsMenu.opened && toolTipText.length > 0 && hovered

    onClicked: {
        if (settingsMenu.opened)
            settingsMenu.close();
        else
            settingsMenu.open();
    }

    C.IVContextMenuControl {
        id: settingsMenu

        property var filter: []
        property bool applied: false

        readonly property real popupWidth: 305
        readonly property real controlWidth: popupWidth + settingsMenu.leftPadding + settingsMenu.rightPadding

        bgColor: IVColors.get("Colors/Background new/BgContextMenuThemed")
        bottomPadding: 16

        onOpened: {
            applied = false
            backend.open()
        }

        x: {
            settingsMenu.opened;
            var cx = (ev_settings_butt.width - settingsMenu.controlWidth) / 2;
            var p = ev_settings_butt.mapToItem(rootRef, 0, 0);
            var right = p.x + cx + settingsMenu.controlWidth + settingsMenu.leftPadding;
            var diff = Math.min(0, rootWidth - right);
            return cx + diff;
        }

        component: ColumnLayout {
            id: filterColumn

            spacing: 8
            width: settingsMenu.popupWidth
            height: Math.min(496, rootHeight*0.7)

            Item {
                height: 40
                width: parent.width

                Text {
                    text: Language.getTranslate("Settings", "Настройки")
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                    font: IVColors.getFont("Subtitle accent")
                }
            }

            C.IVSegmentedControl {
                Layout.fillWidth: true
                height: 40
                model: ListModel {
                    ListElement { text: "Изображение"; iconName: "" }
                    ListElement { text: "События";     iconName: "" }
                }
                currentIndex: 0
                onCurrentIndexChanged: contentStack.currentIndex = currentIndex
            }

            StackLayout {
                id: contentStack

                Layout.fillHeight: true
                Layout.fillWidth: true
                currentIndex: 0

                Flickable {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    contentWidth: width
                    contentHeight: imageColumn.implicitHeight
                    interactive: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: imageColumn
                        width: parent.width
                        spacing: 8

                        Text {
                            text: Language.getTranslate("Display camera information", "Отображать информацию о камере")
                            height: 24
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignBottom
                            color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                            font: IVColors.getFont("Label")
                        }

                        Rectangle {
                            id: orientationButtons

                            Layout.fillWidth: true
                            height: 40
                            radius: 8
                            color: "transparent"
                            clip: true

                            ButtonGroup {
                                id: exclusiveGroup
                                exclusive: true
                            }

                            function flagsToIndex(flags) {
                                var top  = (flags & Qt.AlignTop) === Qt.AlignTop
                                var left = (flags & Qt.AlignLeft) === Qt.AlignLeft
                                if (top && left)  return 0
                                if (top && !left) return 1
                                if (!top && left) return 2
                                return 3
                            }
                            function indexToFlags(i) {
                                switch (i) {
                                case 0: return Qt.AlignTop    | Qt.AlignLeft
                                case 1: return Qt.AlignTop    | Qt.AlignRight
                                case 2: return Qt.AlignBottom | Qt.AlignLeft
                                default:return Qt.AlignBottom | Qt.AlignRight
                                }
                            }
                            function syncUIFromIndex(i) {
                                var buttons = [btnTL, btnTR, btnBL, btnBR]
                                i = Math.max(0, Math.min(3, i))
                                exclusiveGroup.checkedButton = buttons[i]
                                ev_settings_butt.posAlignment = indexToFlags(i)
                            }

                            Connections {
                                target: settingsMenu
                                onOpened: {
                                    orientationButtons.syncUIFromIndex(backend.orientationIndex)
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                spacing: 1

                                C.IVButtonControl {
                                    id: btnTL
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 0
                                    topLeftRadius: 8
                                    bottomLeftRadius: 8
                                    source: "new_images/top-left-pos.svg"
                                    checkable: true
                                    size: C.IVButtonControl.Size.Big
                                    type: C.IVButtonControl.Type.Secondary
                                    ButtonGroup.group: exclusiveGroup
                                    onClicked: posAlignment = Qt.AlignTop | Qt.AlignLeft
                                }

                                C.IVButtonControl {
                                    id: btnTR
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    radius: 0
                                    source: "new_images/top-right-pos.svg"
                                    checkable: true
                                    size: C.IVButtonControl.Size.Big
                                    type: C.IVButtonControl.Type.Secondary
                                    ButtonGroup.group: exclusiveGroup
                                    onClicked: posAlignment = Qt.AlignTop | Qt.AlignRight
                                }

                                C.IVButtonControl {
                                    id: btnBL
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 0
                                    source: "new_images/bot-left-pos.svg"
                                    size: C.IVButtonControl.Size.Big
                                    type: C.IVButtonControl.Type.Secondary
                                    checkable: true
                                    ButtonGroup.group: exclusiveGroup
                                    onClicked: posAlignment = Qt.AlignBottom | Qt.AlignLeft
                                }

                                C.IVButtonControl {
                                    id: btnBR
                                    source: "new_images/bot-right-pos.svg"
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 0
                                    topRightRadius: 8
                                    bottomRightRadius: 8
                                    size: C.IVButtonControl.Size.Big
                                    type: C.IVButtonControl.Type.Secondary
                                    checkable: true
                                    ButtonGroup.group: exclusiveGroup
                                    onClicked: posAlignment = Qt.AlignBottom | Qt.AlignRight
                                }
                            }
                        }

                        C.IVSlider {
                            id: brightness_slider
                            Layout.fillWidth: true
                            height: 32
                            minValue: 0
                            maxValue: 100
                            text: Language.getTranslate("Brightness", "Яркость")
                            value: draft.brightness
                            live: true
                            onValueChanged: {
                                draft.brightness = value
                                imagePipeline.brightness = value
                            }
                        }

                        C.IVSlider {
                            id: contrast_slider
                            Layout.fillWidth: true
                            height: 32
                            minValue: 0
                            maxValue: 100
                            live: true
                            text: Language.getTranslate("Contrast", "Контраст")
                            value: draft.contrast
                            onValueChanged: {
                                draft.contrast = value
                                imagePipeline.contrast = Math.round(value)
                            }
                        }

                        C.IVSlider {
                            id: saturation_slider
                            Layout.fillWidth: true
                            height: 32
                            minValue: 0
                            maxValue: 100
                            live: true
                            text: Language.getTranslate("Saturation", "Насыщенность")
                            value: draft.saturation
                            onValueChanged: {
                                draft.saturation = value
                                imagePipeline.saturation = Math.round(value)
                            }
                        }

                        C.IVSlider {
                            id: red_slider
                            Layout.fillWidth: true
                            height: 32
                            minValue: 0
                            maxValue: 255
                            live: true
                            text: Language.getTranslate("Red", "Красный")
                            value: draft.red
                            onValueChanged: {
                                draft.red = value
                                imagePipeline.rgbR = Math.round(value)
                            }
                        }

                        C.IVSlider {
                            id: green_slider
                            Layout.fillWidth: true
                            height: 32
                            minValue: 0
                            maxValue: 255
                            live: true
                            text: Language.getTranslate("Green", "Зелёный")
                            value: draft.green
                            onValueChanged: {
                                draft.green = value
                                imagePipeline.rgbG = Math.round(value)
                            }
                        }

                        C.IVSlider {
                            id: blue_slider
                            Layout.fillWidth: true
                            height: 32
                            minValue: 0
                            maxValue: 255
                            live: true
                            text: Language.getTranslate("Blue", "Синий")
                            value: draft.blue
                            onValueChanged: {
                                draft.blue = value
                                imagePipeline.rgbB = Math.round(value)
                            }
                        }

                        Connections {
                            target: settingsMenu
                            onOpened: {
                                brightness_slider.value = backend.brightness
                                contrast_slider.value   = backend.contrast
                                saturation_slider.value = backend.saturation
                                red_slider.value        = backend.red
                                green_slider.value      = backend.green
                                blue_slider.value       = backend.blue
                            }
                        }
                    }
                }

                Flickable {
                    Layout.fillHeight: true
                    Layout.fillWidth:  true
                    contentWidth:  width
                    contentHeight: filterContent.implicitHeight
                    interactive:   true
                    clip:          true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id:     filterContent
                        width:  parent.width
                        spacing: 8

                        C.IVInputField {
                            id: searchField
                            Layout.fillWidth: true
                            source: "new_images/search"
                            placeholderText: "Найти по названию"

                            Timer {
                                id: filterDelay
                                property string searchText: ""
                                interval: 300
                                onTriggered: {
                                    searchText = searchField.text
                                    filterModel.search(searchText)
                                }
                            }
                            Connections {
                                target: settingsMenu
                                onClosed: {
                                    searchField.text = ""
                                    filterDelay.restart()
                                }
                            }
                            onTextChanged: filterDelay.restart()
                        }

                        Repeater {
                            id: categoriesRepeater
                            model: filterModel.tree

                            delegate: Column {
                                spacing: 4
                                width:   parent.width
                                visible: modelData.visible

                                Text {
                                    text: modelData.name
                                    height: 24
                                    width:  parent.width
                                    verticalAlignment:   Text.AlignBottom
                                    horizontalAlignment: Text.AlignBottom
                                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                    font:  IVColors.getFont("Label")
                                }

                                Repeater {
                                    model: modelData.childItems

                                    delegate: Column {
                                        id:    grCol
                                        spacing: 4
                                        width:   parent.width
                                        visible: modelData.visible

                                        property int committedState: modelData.state

                                        Connections {
                                            target: settingsMenu
                                            onOpened: committedState = modelData.state
                                        }
                                        Connections {
                                            target: settingsMenu
                                            onClosed: {
                                                if (!settingsMenu.applied)
                                                    modelData.state = committedState
                                            }
                                        }

                                        Rectangle {
                                            id: groupHeader
                                            width:  parent.width
                                            height: 40
                                            radius: 8
                                            clip:   true

                                            property bool hovered: groupHeaderMarea.containsMouse
                                            color: hovered
                                                 ? IVColors.get("Colors/Background new/BgBtnSecondaryThemed")
                                                 : "transparent"

                                            MouseArea {
                                                id: groupHeaderMarea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: modelData.isOpen = !modelData.isOpen
                                            }

                                            C.IVImage {
                                                id: chevronImg
                                                width:  16
                                                height: 16
                                                anchors.left:  parent.left
                                                anchors.leftMargin: 4
                                                anchors.verticalCenter: parent.verticalCenter
                                                name: "new_images/chevron-down"
                                                rotation: modelData.isOpen ? 180 : 0
                                                fillMode: Image.PreserveAspectFit
                                                color: IVColors.get(
                                                           modelData.state === 2
                                                           ? "Colors/Text new/TxAccentThemed"
                                                           : "Colors/Text new/TxSecondaryThemed")
                                                Behavior on rotation {
                                                    NumberAnimation {
                                                        duration: 200
                                                        easing.type: Easing.InOutQuad
                                                    }
                                                }
                                            }

                                            C.IVImage {
                                                id: groupIcon
                                                width: 24
                                                height: width
                                                anchors.left:  chevronImg.right
                                                anchors.leftMargin: 8
                                                anchors.verticalCenter: parent.verticalCenter
                                                name: modelData.icon === undefined || modelData.icon === ""
                                                      ? ""
                                                      : "new_images/" + modelData.icon
                                                color: IVColors.get(
                                                           modelData.state === 2
                                                           ? "Colors/Text new/TxAccentThemed"
                                                           : "Colors/Text new/TxSecondaryThemed")
                                            }

                                            RowLayout {
                                                anchors {
                                                    verticalCenter: parent.verticalCenter
                                                    right: groupSwitch.left
                                                    left:  groupIcon.right
                                                    margins: 8
                                                }
                                                Text {
                                                    text:  modelData.name
                                                    font:  IVColors.getFont("Button middle")
                                                    color: groupHeaderMarea.containsMouse
                                                           ? IVColors.get("Colors/Text new/TxAccentThemed")
                                                           : modelData.state > 0
                                                             ? IVColors.get("Colors/Text new/TxPrimaryThemed")
                                                             : IVColors.get("Colors/Text new/TxSecondaryThemed")
                                                }
                                                Rectangle {
                                                    color: "transparent"
                                                    Layout.fillWidth: true
                                                    height: 16
                                                }
                                            }

                                            C.IVCheckBoxControl {
                                                id: groupSwitch
                                                anchors.right: parent.right
                                                anchors.rightMargin: 10
                                                anchors.verticalCenter: parent.verticalCenter
                                                width:  16
                                                height: 16
                                                checkState: modelData.state
                                                onClicked: modelData.state = modelData.state < 2 ? 2 : 0
                                            }

                                            Rectangle {
                                                width: parent.width
                                                visible: !groupHeader.hovered
                                                height: 1
                                                anchors.bottom: parent.bottom
                                                color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
                                            }
                                        }

                                        Column {
                                            spacing: 4
                                            width:   parent.width
                                            visible: modelData.isOpen && modelData.visible

                                            Repeater {
                                                id: eventsRepeater
                                                model: modelData.childItems

                                                delegate: Rectangle {
                                                    id:    evdel
                                                    height: 40
                                                    radius: 8
                                                    clip:   true

                                                    property int committedState: modelData.state

                                                    Connections {
                                                        target: settingsMenu
                                                        onOpened: committedState = modelData.state
                                                    }
                                                    Connections {
                                                        target: settingsMenu
                                                        onClosed: {
                                                            if (!settingsMenu.applied)
                                                                modelData.state = committedState
                                                        }
                                                    }

                                                    property bool hovered: eventMarea.containsMouse
                                                    color: hovered
                                                         ? IVColors.get("Colors/Background new/BgBtnSecondaryThemed")
                                                         : "transparent"

                                                    visible: parent.visible && modelData.visible
                                                    anchors {
                                                        right: parent.right
                                                        left:  parent.left
                                                        leftMargin: 28
                                                    }

                                                    MouseArea {
                                                        id: eventMarea
                                                        anchors.fill: parent
                                                        ToolTip {
                                                            text: modelData.name
                                                            visible: parent.containsMouse && eventName.truncated
                                                            timeout: 3000
                                                            delay:  300
                                                        }
                                                        onClicked: modelData.state = modelData.state < 2 ? 2 : 0
                                                        onVisibleChanged: hoverEnabled = visible
                                                    }

                                                    Text {
                                                        id: eventName
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        anchors.left:  parent.left
                                                        anchors.right: eventSwitch.left
                                                        anchors.leftMargin:  8
                                                        anchors.rightMargin: 8
                                                        clip: true
                                                        elide: Text.ElideRight
                                                        text: modelData.name
                                                        font: IVColors.getFont("Button middle")
                                                        color: eventMarea.containsMouse
                                                               ? IVColors.get("Colors/Text new/TxAccentThemed")
                                                               : modelData.state > 1
                                                                 ? IVColors.get("Colors/Text new/TxPrimaryThemed")
                                                                 : IVColors.get("Colors/Text new/TxSecondaryThemed")
                                                    }

                                                    C.IVCheckBoxControl {
                                                        id: eventSwitch
                                                        anchors.right: parent.right
                                                        anchors.rightMargin: 10
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        width:  16
                                                        height: 16
                                                        checkState: modelData.state
                                                        onCheckStateChanged: {
                                                            var id    = parseInt(modelData.id)
                                                            var isOn  = checkState > 0
                                                            if (isOn !== settingsMenu.eventInFilter(id))
                                                                settingsMenu.addRemoveIdFilter(id)
                                                        }
                                                        onClicked: modelData.state = modelData.state < 2 ? 2 : 0
                                                    }

                                                    Rectangle {
                                                        width: parent.width
                                                        height: 1
                                                        anchors.bottom: parent.bottom
                                                        visible: !evdel.hovered
                                                        color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth:  true
                Layout.alignment:  Qt.AlignBottom

                spacing: 8

                C.IVButtonControl {
                    text: Language.getTranslate("Cancel", "Сбросить")
                    Layout.fillWidth:      true
                    Layout.preferredWidth: 1
                    size:  C.IVButtonControl.Size.Big
                    type:  C.IVButtonControl.Type.Secondary
                    onClicked: {
                        backend.cancel()
                        settingsMenu.close()
                    }
                }

                C.IVButtonControl {
                    text: Language.getTranslate("Apply", "Применить")
                    Layout.fillWidth:      true
                    Layout.preferredWidth: 1
                    size:  C.IVButtonControl.Size.Big
                    type:  C.IVButtonControl.Type.Contrast

                    onClicked: {
                        settingsMenu.applied = true
                        backend.apply()
                        settingsMenu.close()
                    }
                }
            }
        }

        FilterModel { id: filterModel }

        Timer {
            id: filterRefresh
            interval: 1000
            onTriggered: iv_arc_slider_new.updateFilter(ev_settings_butt.filter)
        }

        function eventInFilter(id){
            return filter.indexOf(id) >= 0
        }

        function addRemoveIdFilter(id){
            var ind = filter.indexOf(id)
            filterRefresh.restart()
            if (ind < 0) {
                filter.push(id);
                return true
            } else {
                filter.splice(ind, 1)
                return false
            }
        }

        Connections {
            target: settingsMenu
            onClosed: {
                if (!settingsMenu.applied)
                    ev_settings_butt.posAlignment = backend.indexToFlags(backend.orientationIndex)
            }
        }
    }

    QtObject {
        id: backend

        property int brightness: imagePipeline.brightness
        property int contrast:   imagePipeline.contrast
        property int saturation: imagePipeline.saturation
        property int red:        imagePipeline.rgbR
        property int green:      imagePipeline.rgbG
        property int blue:       imagePipeline.rgbB
        property int orientationIndex: 0

        function flagsToIndex(flags) {
            var top  = (flags & Qt.AlignTop) === Qt.AlignTop
            var left = (flags & Qt.AlignLeft) === Qt.AlignLeft
            if (top && left)  return 0
            if (top && !left) return 1
            if (!top && left) return 2
            return 3
        }
        function indexToFlags(i) {
            switch (i) {
            case 0: return Qt.AlignTop    | Qt.AlignLeft
            case 1: return Qt.AlignTop    | Qt.AlignRight
            case 2: return Qt.AlignBottom | Qt.AlignLeft
            default:return Qt.AlignBottom | Qt.AlignRight
            }
        }

        function open() {
            brightness = imagePipeline.brightness
            contrast   = imagePipeline.contrast
            saturation = imagePipeline.saturation
            red        = imagePipeline.rgbR
            green      = imagePipeline.rgbG
            blue       = imagePipeline.rgbB

            draft.brightness = brightness
            draft.contrast   = contrast
            draft.saturation = saturation
            draft.red        = red
            draft.green      = green
            draft.blue       = blue
        }

        function cancel() {
            imagePipeline.brightness = backend.brightness
            imagePipeline.contrast   = backend.contrast
            imagePipeline.saturation = backend.saturation
            imagePipeline.rgbR       = backend.red
            imagePipeline.rgbG       = backend.green
            imagePipeline.rgbB       = backend.blue

            draft.brightness = backend.brightness
            draft.contrast   = backend.contrast
            draft.saturation = backend.saturation
            draft.red        = backend.red
            draft.green      = backend.green
            draft.blue       = backend.blue

            ev_settings_butt.posAlignment = backend.indexToFlags(backend.orientationIndex)
        }

        function apply() {
            backend.orientationIndex = backend.flagsToIndex(ev_settings_butt.posAlignment)

            backend.brightness = draft.brightness
            backend.contrast   = draft.contrast
            backend.saturation = draft.saturation
            backend.red        = draft.red
            backend.green      = draft.green
            backend.blue       = draft.blue
        }
    }

    QtObject {
        id: draft
        property int brightness: imagePipeline.brightness
        property int contrast:   imagePipeline.contrast
        property int saturation: imagePipeline.saturation
        property int red:        imagePipeline.rgbR
        property int green:      imagePipeline.rgbG
        property int blue:       imagePipeline.rgbB
    }
}

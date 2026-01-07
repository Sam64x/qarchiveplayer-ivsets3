import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Controls 2.4

import iv.sets.sets3 1.0
import iv.colors 1.0
import iv.controls 1.0


Rectangle {
    id: root
    color: IVColors.get("Colors/Background new/BgFormPrimaryThemed")

    readonly property real isize: 1
    function dp(px){return px * root.isize}

    property bool followSlider: true
    property int addPeriod: 600000

    property real zoom: 1
    property real zoomStep: 0.15/timelineArea.visibleArea.widthRatio
    property real minZoom: 1
    property real maxZoom: 20

    property var previewDate: new Date(0)
    property bool showPreview: false

    property var currDate: mainClass.start

    property bool isSelectInterval: false //true //
    property real intervalLeft: 0.15
    property real intervalRight: 0.3

    property real speedScale: 10

    property var bookmarks: []

    IVMainArea {
        id: mainClass
    }
    Timer {
        id: fakePlay
        interval: 100
        repeat: true
        onTriggered: {
            var newCurrDate = new Date(root.currDate.getTime() + interval*root.speedScale)
            root.currDate = newCurrDate
            if (root.timeToPos(root.currDate) >= 1) {
                stop()
            }
        }
    }

    IVContextMenu {
        id: gridsMenu
        property int currSetIndex: 1
        property var setsModel: [
            {cols: 1, rows:1, source: "grids/Grid 1"},
            {cols: 1, rows:2, source: "grids/Grid 1_2"},
            {cols: 2, rows:2, source: "grids/Grid 1_3"},
            {cols: 4, rows:4, source: "grids/Grid 5"}
        ]
        component: ListView {
            model: gridsMenu.setsModel
            width: dp(40)
            height: contentHeight
            delegate: IVButton {
                width: parent.width
                checkable: true
                checked: index === gridsMenu.currSetIndex
                source: "new_images/"+modelData.source
                onClicked: gridsMenu.currSetIndex = index
            }
        }
    }

    IVContextMenu {
        id: calendar
        bgColor: IVColors.get("Colors/Background new/BgContextMenuThemed")
        topPadding: shadowWidth + 8*root.isize
        leftPadding: shadowWidth + 16*root.isize
        rightPadding: shadowWidth + 16*root.isize
//        property var periodsModel: [
//            {period: 10*60*1000,     text: "10 мин"},
//            {period: 30*60*1000,     text: "30 мин"},
//            {period: 60*60*1000,     text: "1 час"},
//            {period: 3*60*60*1000,   text: "3 часа"},
//            {period: 6*60*60*1000,   text: "6 часов"},
//            {period: 12*60*60*1000,  text: "12 часов"},
//            {period: 24*60*60*1000,  text: "24 часа"}
//        ]
        component: Component {
            ColumnLayout {
                id: col
                spacing: 8 * root.isize
                Text {
                    text: "Выбрать период"
                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                    font: IVColors.getFont("Subtitle accent")
                    Layout.fillWidth: true
                }
//                Text {
//                    text: "За последние"
//                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
//                    font: IVColors.getFont("Label")
//                    Layout.fillWidth: true
//                }
//                Grid {
//                    rowSpacing: 8 * root.isize
//                    columnSpacing: 8 * root.isize
//                    columns: 5
//                    rows: 3
//                    Layout.fillWidth: true
//                    Repeater {
//                        model: calendar.periodsModel
//                        delegate: IVRadioButton {
//                            type: IVRadioButton.Type.Chips
//                            checked: [-1,0,1].indexOf(calendBody.end - calendBody.start - modelData.period) > -1
//                            text: modelData.text
//                            width: 70 * root.isize
//                            onClicked: {
//                                calendBody.start = new Date(new Date().getTime() - modelData.period)
//                                calendBody.end = new Date()
//                            }
//                        }
//                    }
//                }
                RowLayout {
                    Layout.fillWidth: true
                    IVInputField {
                        id: startInputField
                        Layout.fillWidth: true
                        text: Qt.formatDateTime(mainClass.start, "dd.MM.yyyy hh:mm:ss")
                        name: "С"
                        mask: "00.00.0000 00:00:00"
                        onTextEdited: {
                            var ds = Date.fromLocaleString(Qt.locale(), text, "dd.MM.yyyy hh:mm:ss")
                            var de = Date.fromLocaleString(Qt.locale(), endInputField.text, "dd.MM.yyyy hh:mm:ss")

                            if (ds.toString() !== "Invalid Date" && ds < new Date())
                            {
                                if (de.toString() !== "Invalid Date") {
                                    if (ds < de) {
                                        isCorrect = true
                                        endInputField.isCorrect = true
                                        calendBody.start = ds
                                        calendBody.end = de
                                    }
                                    else isCorrect = false
                                }
                                else isCorrect = true
                            }
                            else isCorrect = false
                        }
                        onInputAccepted:{
                            endInputField.setFocused()
                        }
                    }
                    IVInputField {
                        id: endInputField
                        Layout.fillWidth: true
                        text: Qt.formatDateTime(mainClass.end, "dd.MM.yyyy hh:mm:ss")
                        name: "По"
                        mask: "00.00.0000 00:00:00"
                        onTextEdited: {
                            var ds = Date.fromLocaleString(Qt.locale(), startInputField.text, "dd.MM.yyyy hh:mm:ss")
                            var de = Date.fromLocaleString(Qt.locale(), text, "dd.MM.yyyy hh:mm:ss")

                            if (de.toString() !== "Invalid Date" && de < new Date())
                            {
                                if (ds.toString() !== "Invalid Date") {
                                    if (ds < de) {
                                        isCorrect = true
                                        startInputField.isCorrect = true
                                        calendBody.start = ds
                                        calendBody.end = de
                                    }
                                    else isCorrect = false
                                }
                                else isCorrect = true
                            }
                            else isCorrect = false
                        }
                    }
                }
                IVCalendar {
                    id: calendBody
                    width: 390 * root.isize
                    selectable: true
                    property string startStr: Qt.formatDateTime(start, "d.MM.yyyy hh:mm")
                    property string endStr: Qt.formatDateTime(end, "d.MM.yyyy hh:mm")
                    onStartChanged: {
                        if (start) {
                            startInputField.text = Qt.formatDateTime(start, "dd.MM.yyyy hh:mm:ss")
                            if (end < start) {
                                end = start
                                startInputField.isCorrect = true
                                endInputField.isCorrect = true
                            }
                        }
                    }
                    onEndChanged: {
                        if (end) {
                            endInputField.text = Qt.formatDateTime(end, "dd.MM.yyyy hh:mm:ss")
                            if (end < start) {
                                start = end
                                startInputField.isCorrect = true
                                endInputField.isCorrect = true
                            }
                        }
                    }
                    Component.onCompleted: {
                        calendBody.start = mainClass.start
                        calendBody.end = mainClass.end
                    }
                }
                IVButton {
                    id: acceptButton
                    text: calendBody.startStr.length > 0 ?
                          "Отобразить " + calendBody.startStr + " - " + calendBody.endStr : "Интервал не задан"
                    Layout.fillWidth: true
                    type: IVButton.Type.Primary
                    enabled: calendBody.startStr !== "" && calendBody.endStr !== ""
                    onClicked: {
                        if (root.checkedCount > 0) {
                            root.checkedEvents = []
                            root.checkedOnCurrPage = []

                            root.currPageAllChecked = (root.checkedOnCurrPage.length === root.events.length && root.events.length > 0)
                            root.checkedCount = root.checkedEvents.length
                            root.updateCheckedEvents()
                        }
                        calendar.close()
                        root.zoom = 1
                        root.zoomTo(Qt.point(timelineArea.contentWidth/2, 0))
                        mainClass.setInterval(calendBody.start, calendBody.end)
                        root.currDate = mainClass.start
                        markersItem.createTimeMarkers()
                    }
                }
            }
        }
    }
    IVContextMenu {
        id: sourcesMenu
        component: ListView {
            model: mainClass.allSourcesList
            width: dp(240)
            height: dp(360)
            delegate: IVButton {
                width: parent.width
                height: dp(32)
                source: "new_images/cctv"
                text: modelData
                onClicked: {
                    mainClass.addSources([modelData])
                }
            }
        }
    }

    Rectangle {
        id: viewerRect
        anchors {
            top: header.bottom
            right: parent.right
            left: leftPanel.right
            bottom: bottomPanel.top
        }
        color: "transparent"
        GridLayout {
            id: camsGrid
            columns: gridsMenu.setsModel[gridsMenu.currSetIndex].cols
            rows: gridsMenu.setsModel[gridsMenu.currSetIndex].cols
            anchors.centerIn: parent
            property real ratio: 16/9
            width: Math.min(parent.width, parent.height*ratio)
            height: Math.min(parent.width/ratio, parent.height)
            clip: true
            Repeater {
                model: mainClass.sources
                delegate: Rectangle {
                    color: "#99000000"
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    opacity: modelData.visible ? 1 : 0.2
                    Text {
                        anchors.margins: dp(4)
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: contentWidth + dp(16)
                        height: contentHeight + dp(8)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: IVColors.get("Colors/Text new/TxContrast")
                        font: IVColors.getFont("Label accent")
                        text: modelData.name
                        Rectangle {
                            color: IVColors.get("Colors/Background new/BgFormOverVideo")
                            width: childrenRect.width
                            height: childrenRect.height
                            anchors.fill: parent
                            radius: dp(4)
                            z: parent.z - 1
                        }
                    }
                }
            }
        }
        Rectangle {
            color: IVColors.get("Colors/Background new/BgFormOverVideo")
            width: menuRow.width + dp(8)
            height: menuRow.height + dp(8)
            radius: dp(8)
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: dp(8)
            }
            Row {
                id: menuRow
                anchors.centerIn: parent
                spacing: dp(4)
                Rectangle {
                    radius: dp(4)
                    color: IVColors.get("Colors/Background new/BgBtnOverVideo")
                    width: dp(66)
                    height: dp(24)
                }
                Row {
                    height: parent.height
                    spacing: 0
                    Rectangle {
                        radius: dp(4)
                        color: IVColors.get("Colors/Background new/BgBtnOverVideo")
                        width: dp(24)
                        height: dp(24)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: ":"
                        color: IVColors.get("Colors/Text new/TxContrast")
                        font: IVColors.getFont("Label")
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        radius: dp(4)
                        color: IVColors.get("Colors/Background new/BgBtnOverVideo")
                        width: dp(24)
                        height: dp(24)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: ":"
                        color: IVColors.get("Colors/Text new/TxContrast")
                        font: IVColors.getFont("Label")
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        radius: dp(4)
                        color: IVColors.get("Colors/Background new/BgBtnOverVideo")
                        width: dp(24)
                        height: dp(24)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Row {
                    height: parent.height
                    spacing: dp(1)
                    IVButtonIcon {
                        size: IVButtonIcon.Size.Small
                        type: IVButtonIcon.Type.Secondary
                        width: dp(32)
                        height: dp(24)
                        source: "new_images/" + (fakePlay.running ? "pause" : "play")
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: {
                            if (fakePlay.running) fakePlay.stop()
                            else fakePlay.start()
                        }
                    }
                    IVButton {
                        text: "x"+getFormattedValue(root.speedScale)
                        size: IVButton.Size.Small
                        type: IVButton.Type.Secondary
                        width: dp(32)
                        height: dp(24)
                        anchors.verticalCenter: parent.verticalCenter

                        function getFormattedValue(a)
                        {
                            var aStr = a.toString()
                            var decIdx = aStr.indexOf('.')

                            if (decIdx < 0 || aStr[decIdx+1] === "0") return a.toFixed(0)
                            else if (aStr.length-decIdx-1 > 2) return a.toFixed(2)
                            else return a.toFixed(1)
                        }
                    }
                }
                IVButtonIcon {
                    size: IVButtonIcon.Size.Small
                    type: IVButtonIcon.Type.Secondary
                    width: dp(24)
                    height: dp(24)
                    source: "new_images/On center"
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        root.fixAreaToSlider()
                    }
                }
                Row {
                    height: parent.height
                    spacing: dp(1)
                    IVButtonIcon {
                        size: IVButtonIcon.Size.Small
                        type: IVButtonIcon.Type.Secondary
                        width: dp(16)
                        height: dp(24)
                        source: "new_images/chevron-left"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    IVButtonIcon {
                        size: IVButtonIcon.Size.Small
                        type: IVButtonIcon.Type.Secondary
                        width: dp(24)
                        height: dp(24)
                        source: "new_images/Flag Time tag"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    IVButtonIcon {
                        size: IVButtonIcon.Size.Small
                        type: IVButtonIcon.Type.Secondary
                        width: dp(16)
                        height: dp(24)
                        source: "new_images/chevron-right"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                IVButtonIcon {
                    size: IVButtonIcon.Size.Small
                    type: IVButtonIcon.Type.Secondary
                    width: dp(24)
                    height: dp(24)
                    source: "new_images/settings-04"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Rectangle {
        id: bottomPanel
        height: dp(150)
        anchors {
            bottom: parent.bottom
            right: parent.right
            left: parent.left
        }
        clip: true
        color: "transparent"
        Rectangle {
            id: leftBottomRect
            width: dp(342)
            color: IVColors.get("Colors/Background new/BgContextMenuThemed")
            anchors {
                top: parent.top
                left: parent.left
                bottom: parent.bottom
            }
            // Дата и манипуляторы
            Rectangle {
                id: setDateArea
                color: "transparent"
                width: parent.width
                height: dp(56)
                RowLayout {
                    anchors {
                        fill: parent
                        topMargin: dp(12)
                        bottomMargin: dp(12)
                        leftMargin: dp(8)
                        rightMargin: dp(8)
                    }
                    spacing: dp(24)
                    Rectangle {
                        width: dp(204)
                        height: dp(32)
                        radius: dp(4)
                        color: "transparent"
                        border {
                            width: dp(1)
                            color: "#33FFFFFF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            property string hovColor: IVColors.get("Colors/Background new/BgFormTertiaryThemed")
                            property string pressedColor: IVColors.get("Colors/Background new/BgBtnTertiaryThemed-click")
                            property string mainColor: "transparent"

                            Row {
                                id: calendButtonRow
                                anchors.centerIn: parent
                                spacing: dp(4)
                                IVImage {
                                    name: "new_images/calendar-selector"
                                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                    width: dp(16)
                                    height: width
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    id: dateField
                                    property string startStr: Qt.formatDateTime(mainClass.start, "d.MM.yy hh:mm")
                                    property string endStr: Qt.formatDateTime(mainClass.end, "d.MM.yy hh:mm")
                                    text: startStr + " - " + endStr
                                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                    font: IVColors.getFont("Label")
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            onEntered: parent.color = hovColor
                            onExited: parent.color = mainColor
                            onPressed: parent.color = pressedColor
                            onReleased: {
                                parent.color = hovColor
                                calendar.parent = parent
                                calendar.y = -calendar.height - dp(8)
                                calendar.open()
                            }
                        }
                    }
                    Row {
                        spacing: dp(1)
                        IVButton {
                            source: "new_images/zoom-out"
                            type: IVButton.Type.Helper
                            size: IVButton.Size.Middle
                            Layout.alignment: Qt.AlignVCenter
                            width: dp(32)
                            height: dp(32)
                            onClicked: {
                                if (root.zoom-root.zoomStep >= root.minZoom)
                                    root.zoom -= root.zoomStep
                                else
                                    root.zoom = 1
                                var viewCenter = timelineArea.leftPos+(timelineArea.rightPos - timelineArea.leftPos)/2
                                root.zoomTo(Qt.point(timelineArea.contentWidth * viewCenter, 0))
                            }
                        }
                        IVButton {
                            source: "new_images/Full space"
                            type: IVButton.Type.Helper
                            size: IVButton.Size.Middle
                            Layout.alignment: Qt.AlignVCenter
                            width: dp(32)
                            height: dp(32)
                            onClicked: {
                                root.zoom = 1
                                root.zoomTo(Qt.point(timelineArea.contentWidth/2, 0))
                            }
                        }
                        IVButton {
                            source: "new_images/zoom-in"
                            type: IVButton.Type.Helper
                            size: IVButton.Size.Middle
                            Layout.alignment: Qt.AlignVCenter
                            width: dp(32)
                            height: dp(32)
                            onClicked: {
                                if (root.zoom+root.zoomStep <= root.maxZoom)
                                    root.zoom += root.zoomStep
                                else
                                    root.zoom = root.maxZoom
                                var viewCenter = timelineArea.leftPos+(timelineArea.rightPos - timelineArea.leftPos)/2
                                root.zoomTo(Qt.point(timelineArea.contentWidth * viewCenter, 0))
                            }
                        }
                    }
                }
                // Разделитель
                Rectangle {
                    color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
                    width: parent.width
                    height: dp(1)
                    anchors.bottom: parent.bottom
                }
            }
            // Список источников и архивов
            ListView {
                id: camsView
                anchors.left: parent.left
                anchors.top: setDateArea.bottom
                anchors.bottom: parent.bottom
                width: root.width
                model: mainClass.sources
                clip: true
                cacheBuffer: 0
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: -1
                moveDisplaced: Transition {
                    NumberAnimation { property: "y"; duration: 200 }
                }
                delegate: Rectangle {
                    id: camsDelegate
                    height: dp(32)
                    width: parent.width
                    color: camsView.currentIndex !== index ? "transparent" :
                                                             IVColors.get("Colors/Background new/BgBtnSecondaryThemed-hover")
                    property int _index: index
                    Drag.active: dragArea.drag.active
                    Drag.hotSpot.y: height / 2
                    Row {
                        anchors.fill: parent
                        spacing: 0
                        opacity: modelData.visible ? 1 : 0.3
                        Item {
                            width: leftBottomRect.width
                            height: parent.height
                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                propagateComposedEvents: true
                                enabled: modelData.visible
                                drag.target: camsDelegate
                                drag.threshold: 0
                                drag.axis: Drag.YAxis
                                drag.minimumY: 0
                                drag.maximumY: camsView.contentHeight - height
                                onClicked: {
                                    if (camsView.currentIndex === index) camsView.currentIndex = -1
                                    else camsView.currentIndex = index
                                }
                                drag.onActiveChanged: {
                                    if (drag.active) camsDelegate.z = 2
                                    else camsDelegate.z = 1
                                    dropA.enabled = !dropA.enabled;
                                    camsDelegate.Drag.drop();
                                    if (dropA.enabled) {
                                        camsDelegate.y = camsDelegate._index * camsDelegate.height;
                                    }
                                }
                            }
                            RowLayout {
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    left: parent.left
                                    right: camMoreButton.left
                                    margins: dp(4)
                                }
                                spacing: dp(6)
                                Layout.alignment: Qt.AlignVCenter
                                IVButton {
                                    source: "new_images/" + (modelData.visible ? "eye" : "eye-off")
                                    type: IVButton.Type.Helper
                                    Layout.fillHeight: true
                                    width: height
                                    onClicked: modelData.visible = !modelData.visible
                                }
                                Text {
                                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                    font: IVColors.getFont("Text body")
                                    text: modelData.name
                                    clip: true
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }
                            }
                            IVButton {
                                id: camMoreButton
                                anchors.right: parent.right
                                height: parent.height
                                width: height
                                source: "new_images/dots-vertical"
                                type: IVButton.Type.Helper
                                onClicked: camMenu.open()
                            }
                            IVContextMenu {
                                id: camMenu
                                x: parent.x + parent.width - shadowWidth + 8 * isize
                                y: parent.y - shadowWidth
                                property var camName: modelData.name
                                component: Column {
                                    width: 254 * isize
                                    IVContextMenuItem {
                                        width: parent.width
                                        type: IVContextMenuItem.Type.Critical
                                        source: "new_images/del"
                                        text: "Удалить"
                                        onClicked: {
                                            camMenu.close()
                                            mainClass.removeSources([camMenu.camName])
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
                                width: leftBottomRect.width
                                height: dp(1)
                                anchors.bottom: parent.bottom
                            }
                            Rectangle {
                                id: dropFiller
                                width: leftBottomRect.width
                                anchors.bottom: parent.bottom
                                color: IVColors.get("Colors/Background new/BgBtnPrimary")
                                Behavior on height {
                                    NumberAnimation {duration: 100; easing.type: Easing.InOutQuad}
                                }
                            }
                            DropArea {
                                id: dropA
                                anchors.fill: parent
                                onDropped: mainClass.moveSource(drag.source._index,
                                                                camsDelegate._index)
                                onEntered: dropFiller.height = dropFiller.parent.height
                                onExited: dropFiller.height = 0
                            }
                        }
                        Flickable {
                            id: fullnessView
                            property var source: modelData
                            width: timelineArea.width
                            height: parent.height
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            contentHeight: height
                            contentWidth: timelineArea.contentWidth
                            interactive: false
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onMouseXChanged: {
                                    if (containsMouse) root.previewDate = root.posToTime(mouseX/width)
                                }
                                onContainsMouseChanged: root.showPreview = containsMouse
                                onClicked: root.currDate = root.posToTime(mouseX/width)
                            }

                            // Заполненность
                            Loader {
                                asynchronous: true
                                height: fullnessView.height
                                active: modelData.fullness.length > 0
                                sourceComponent: Repeater {
                                    model: modelData.fullness
                                    delegate: Rectangle {
                                        x: timelineArea.contentWidth * modelData.startPos
                                        width: (modelData.endPos - modelData.startPos)
                                               * timelineArea.contentWidth
                                        height: parent.height/2
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: "#22FFFFFF"
                                        radius: dp(4)
                                    }
                                }
                            }
                            // Метки
                            Loader {
                                asynchronous: true
                                height: fullnessView.height
                                active: modelData.bookmarks.length > 0
                                sourceComponent: Repeater {
                                    model: modelData.bookmarks
                                    delegate: Rectangle {
                                        height: dp(24)
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: modelData.startPos * timelineArea.contentWidth
                                        width: (modelData.endPos - modelData.startPos)
                                               * timelineArea.contentWidth
                                        color: "transparent"
                                        radius: dp(8)
                                        border {
                                            color: IVColors.get("Colors/Text new/TxTertiaryContrast")
                                            width: dp(2)
                                        }
                                        IVImage {
                                            name: "new_images/Flag Time tag"
                                            color: IVColors.get("Colors/Text new/TxContrast")
                                            anchors {
                                                top: parent.top
                                                bottom: parent.bottom
                                                left: parent.left
                                                margins: dp(4)
                                            }
                                            width: height
                                        }
                                    }
                                }
                            }
                            // События
                            Loader {
                                asynchronous: true
                                height: fullnessView.height
                                active: modelData.events.length > 0
                                sourceComponent: Repeater {
                                    model: modelData.events
                                    delegate: MouseArea {
                                        property int groupSize: 0
                                        visible: fullnessView.source ? modelData.source === fullnessView.source.name
                                                                     : false
                                        width: dp(24)
                                        height: dp(24)
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: modelData.startPos * timelineArea.contentWidth - width/2
                                        hoverEnabled: true
                                        ToolTip {
                                            visible: parent.containsMouse
                                            text: modelData.startTime + " - " +
                                                  modelData.endTime + "\n" +
                                                  modelData.typeName + "\n" +
                                                  modelData.source
                                        }
                                        IVImage {
                                            anchors.fill: parent
                                            name: "new_images/Event bg"
                                        }
                                        IVImage {
                                            visible: parent.groupSize === 0
                                            name: "new_images/Event"
                                            color: IVColors.get("Colors/Text new/TxContrast")
                                            anchors.fill: parent
                                            anchors.margins: dp(4)
                                        }
                                        Text {
                                            visible: parent.groupSize > 0
                                            anchors.centerIn: parent
                                            color: IVColors.get("Colors/Text new/TxContrast")
                                            font: IVColors.getFont("Subtext accent")
                                            text: parent.groupSize
                                        }
                                        onContainsMouseChanged: {
                                            if (containsMouse) cursorShape = Qt.PointingHandCursor
                                        }
                                    }
                                }
                            }
                            Connections {
                                target: timelineArea
                                onContentXChanged: {
                                    fullnessView.contentX = fullnessView.getContentX()
                                }
                            }
                            Component.onCompleted: contentX = getContentX()
                            function getContentX(){
                                var cX = fullnessView.contentX
                                var cXN = cX - fullnessView.originX
                                var cXP = cX + fullnessView.originX
                                var vars = [cXN, cXP]

                                var absVars = [], i = 0
                                for (i; i < vars.length; i++) {
                                    absVars.push(Math.abs(vars[i]))
                                }

                                i = absVars.indexOf(Math.min(absVars))
                                var min = timelineArea.contentX
                                if (i > -1) min = vars[i]
                                return min
                            }
                        }
                    }
                }
            }
        }
        Item {
            id: timelineRect
            clip: true
            anchors {
                top: parent.top
                bottom: parent.bottom
                right: parent.right
            }
            width: parent.width - leftBottomRect.width
            Rectangle {
                width: parent.width
                height: dp(56)
                color: "#30354A"
            }
            Column {
                anchors.fill: parent
                spacing: 0
                RowLayout {
                    width: parent.width
                    height: dp(24)
                    spacing: 0
                    IVButtonIcon {
                        id: addLeftSpace
                        width: dp(40)
                        Layout.fillHeight: true
                        source: "new_images/add left period"
                        type: IVButtonIcon.Type.Secondary
                        onClicked: {
                            mainClass.start = new Date(mainClass.start.getTime()-root.addPeriod)
                            sliderArea.updatePosition()
                            markersItem.createTimeMarkers()
                        }
                    }
                    Item {
                        id: zoomArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        property var minWidth: dp(6)

                        property real leftX: leftHandle.x
                        property real rightX: rightHandle.x + rightHandle.width

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.width * (sliderArea.x + sliderArea.width/2)/timelineArea.contentWidth
                            width: dp(2)
                            height: parent.height
                            color: IVColors.get("Colors/Text new/TxAccent")
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.width * root.intervalLeft
                            width: parent.width * (root.intervalRight - root.intervalLeft)
                            height: dp(4)
                            radius: dp(8)
                            color: IVColors.get("Colors/Background new/BgEventSecondary")
                            visible: root.isSelectInterval
                        }

                        Rectangle {
                            id: leftHandle
                            width: dp(6)
                            height: dp(16)
                            radius: dp(4)
                            color: "#66FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                            signal updatePosition

                            MouseArea {
                                id: lh_area
                                anchors.fill: parent
                                hoverEnabled: true
                                drag.target: parent
                                drag.minimumX: 0
                                drag.maximumX: rightHandle.x - zoomArea.minWidth - width
                                drag.threshold: 0
                                onContainsMouseChanged: if (containsMouse || drag.active) cursorShape = Qt.SizeHorCursor
                            }

                            onXChanged: {
                                if (lh_area.drag.active) {
                                    var leftX = x, rightX = rightHandle.x + rightHandle.width
                                    root.zoom = zoomArea.width / (rightX - leftX)
                                    var x_ = (rightX/zoomArea.width) * timelineArea.contentWidth
                                    root.zoomTo(Qt.point(x_, 0))
                                }
                            }
                            onUpdatePosition: {
                                if (!lh_area.drag.active) x = timelineArea.leftPos * zoomArea.width
                            }
                            Component.onCompleted: updatePosition()
                        }

                        Rectangle {
                            height: dp(16)
                            radius: dp(4)
                            color: "#33FFFFFF"

                            property real lh_dx: leftHandle.width + dp(2)
                            property real rh_dx: rightHandle.width + dp(2)

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: bodyArea.drag.active ? undefined : leftHandle.right
                            anchors.right: bodyArea.drag.active ? undefined : rightHandle.left
                            anchors.leftMargin: bodyArea.drag.active ? undefined : dp(2)
                            anchors.rightMargin: bodyArea.drag.active ? undefined : dp(2)
                            MouseArea {
                                id: bodyArea
                                anchors.fill: parent
                                drag.target: parent
                                drag.threshold: 0
                                hoverEnabled: true
                                drag.maximumX: zoomArea.width - width - parent.rh_dx
                                drag.minimumX: parent.lh_dx
                                onContainsMouseChanged: if (containsMouse || drag.active) cursorShape = Qt.SplitHCursor
                            }
                            onXChanged: {
                                if (bodyArea.drag.active) {
                                    root.followSlider = false
                                    timelineArea.contentX = ((x-lh_dx) / parent.width) * timelineArea.contentWidth
                                }
                            }
                        }

                        Rectangle {
                            id: rightHandle
                            height: dp(16)
                            width: dp(6)
                            radius: dp(4)
                            color: "#66FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                            signal updatePosition

                            MouseArea {
                                id: rh_area
                                anchors.fill: parent
                                hoverEnabled: true
                                drag.threshold: 0
                                drag.target: parent
                                drag.minimumX: zoomArea.leftX + zoomArea.minWidth + width
                                drag.maximumX: zoomArea.width - width

                                onContainsMouseChanged: if (containsMouse || drag.active) cursorShape = Qt.SizeHorCursor
                            }

                            onXChanged: {
                                if (rh_area.drag.active) {
                                    var leftX = leftHandle.x, rightX = x + width
                                    root.zoom = zoomArea.width / (rightX - leftX)
                                    var x_ = (leftX/zoomArea.width) * timelineArea.contentWidth
                                    root.zoomTo(Qt.point(x_, 0))
                                }
                            }
                            onUpdatePosition: {
                                if (!rh_area.drag.active) x = (timelineArea.rightPos * zoomArea.width) - width
                            }
                            Component.onCompleted: updatePosition()
                        }

                    }
                    IVButtonIcon {
                        id: addRightSpace
                        width: dp(40)
                        Layout.fillHeight: true
                        source: "new_images/add right period"
                        type: IVButtonIcon.Type.Secondary
                        onClicked: {
                            mainClass.end = new Date(mainClass.end.getTime()+root.addPeriod)
                            sliderArea.updatePosition()
                            markersItem.createTimeMarkers()
                        }
                    }
                }
                Rectangle {
                    color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
                    width: parent.width
                    height: dp(1)
                }
                Item {
                    width: parent.width
                    height: dp(32)
                    Flickable {
                        id: timelineArea
                        anchors.fill: parent
                        contentHeight: height
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: false
                        readonly property real rightPos: visibleArea.xPosition + visibleArea.widthRatio
                        readonly property real leftPos: visibleArea.xPosition
                        Item {
                            id: markersItem
                            anchors.top: parent.top
                            width: timelineArea.contentWidth
                            height: dp(16)
                            property var timeMarkers: []
                            property var levels: [
                                60*1000,        // 0 // 1 мин
                                5*60*1000,      // 1 // 5 мин
                                15*60*1000,     // 2 // 15 мин
                                30*60*1000,     // 3 // 30 мин
                                60*60*1000,     // 4 // 1 ч
                                3*60*60*1000,   // 5 // 3 ч
                                6*60*60*1000,   // 6 // 6 ч
                                12*60*60*1000,  // 7 // 12 ч
                                24*60*60*1000   // 8 // 1 день
                            ]
                            Repeater {
                                id: markerList
                                model: markersItem.timeMarkers
                                delegate: Rectangle {
                                    anchors.bottom: parent.bottom
                                    x: parent.width/(markerList.count-1)*index
                                    color: "white"
                                    width: dp(1)
                                    height: dp(4)
                                    Text {
                                        text: modelData.date
                                        color: "white"
                                        font.pixelSize: dp(8)
                                        property real cW: contentWidth
                                        x: parent.x < cW/2 ? -parent.x :
                                           parent.x+cW/2 > parent.parent.width ?
                                           -(cW-(parent.parent.width-parent.x)) : -cW/2
                                        anchors.bottom: parent.top
                                    }
                                }
                            }
                            onWidthChanged: if (width > 0) createTimeMarkers()
                            function createTimeMarkers(){
                                var s = mainClass.start.getTime()
                                var e = mainClass.end.getTime()
                                var minWidth = dp(80)
                                for (var i = 0; i < markersItem.levels.length; i++)
                                {
                                    var ticks = parseInt((e-s)/markersItem.levels[i])
                                    if (width/ticks >= minWidth)
                                    {
                                        var newTM = []
                                        for (var j = 0; j <= ticks; j++) {
                                            newTM.push({date: Qt.formatTime(new Date(s+(j*markersItem.levels[i])),"hh:mm:ss")})
                                        }
                                        timeMarkers = newTM
                                        break
                                    }
                                }
                            }
                        }

                        onWidthChanged: updatePositions()
                        onContentXChanged: updatePositions()
                        onContentWidthChanged: updatePositions()

                        function updatePositions() {
                            if (contentWidth < width)
                                contentWidth = width * root.zoom

                            rightHandle.updatePosition()
                            leftHandle.updatePosition()
                            sliderArea.updatePosition()
                        }

                        Component.onCompleted: {
                            contentWidth = width * root.zoom
                            markersItem.createTimeMarkers()
                        }
                    }
                    MouseArea {
                        id: mM
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.currDate = root.posToTime((timelineArea.contentX + mouseX)/timelineArea.contentWidth)
                        onContainsMouseChanged: root.showPreview = containsMouse
                        onWheel: {
                            if (wheel.angleDelta.y > 0) root.zoom += root.zoomStep
                            else root.zoom -= root.zoomStep
                            if (root.zoom < 1) root.zoom = 1
                            root.zoomTo(Qt.point(timelineArea.contentX + mouseX, 0))
                        }
                        onMouseXChanged: {
                            if (containsMouse)
                                root.previewDate = root.posToTime((timelineArea.contentX + mouseX)/timelineArea.contentWidth)
                        }
                    }

                    Item {
                        anchors.top: parent.top
                        anchors.topMargin: dp(16)
                        height: dp(16)
                        width: timelineArea.contentWidth
                        x: -timelineArea.contentX
                        opacity: root.isSelectInterval
                        Rectangle {
                            id: intervalLeftHandle
                            anchors.verticalCenter: parent.verticalCenter
                            width: dp(6)
                            height: parent.height
                            x: parent.width * root.intervalLeft
                            radius: dp(4)
                            color: IVColors.get("Colors/Text new/TxEvent")
                            MouseArea {
                                id: lih_area
                                anchors.fill: parent
                                hoverEnabled: true
                                drag.target: parent
                                drag.minimumX: 0
                                drag.maximumX: intervalRightHandle.x - width - zoomArea.minWidth
                                drag.threshold: 0
                                onContainsMouseChanged: if (containsMouse) cursorShape = Qt.SizeHorCursor
                            }
                            onXChanged: {
                                if (lih_area.drag.active) {
                                    root.intervalLeft = x/parent.width
                                }
                            }
                        }
                        Rectangle {
                            width: dp(120)
                            height: dp(8)
                            radius: dp(4)
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: intervalLeftHandle.right
                                right: intervalRightHandle.left
                                leftMargin: dp(2)
                                rightMargin: dp(2)
                            }
                            color: IVColors.get("Colors/Text new/TxEvent")
                        }
                        Rectangle {
                            id: intervalRightHandle
                            anchors.verticalCenter: parent.verticalCenter
                            width: dp(6)
                            x: parent.width * root.intervalRight - width
                            height: parent.height
                            radius: dp(4)
                            color: IVColors.get("Colors/Text new/TxEvent")
                            MouseArea {
                                id: rih_area
                                anchors.fill: parent
                                hoverEnabled: true
                                drag.threshold: 0
                                drag.target: parent
                                drag.minimumX: intervalLeftHandle.x + width + zoomArea.minWidth
                                drag.maximumX: parent.parent.width - width
                                onContainsMouseChanged: if (containsMouse) cursorShape = Qt.SizeHorCursor
                            }
                            onXChanged: {
                                if (rih_area.drag.active) {
                                    root.intervalRight = (x + width)/parent.width
                                }
                            }
                        }
                        Rectangle {
                            anchors {
                                top: parent.bottom
                                left: intervalLeftHandle.right
                                right: intervalRightHandle.left
                                leftMargin: -intervalLeftHandle.width/2
                                rightMargin: -intervalRightHandle.width/2
                            }
                            color: IVColors.get("Colors/Background new/BgEventThertary")
                            height: camsView.height
                        }
                    }
                    Item {
                        anchors.top: parent.top
                        height: bottomPanel.height
                        width: timelineArea.contentWidth
                        x: -timelineArea.contentX
                        MouseArea {
                            id: sliderArea
                            anchors.top: parent.top
                            width: dp(14)
                            height: parent.height
                            hoverEnabled: true
                            drag.threshold: 0
                            drag.target: this
                            drag.minimumX: -width/2
                            drag.maximumX: timelineArea.contentWidth - width/2
                            signal updatePosition
                            Column {
                                anchors.fill: parent
                                spacing: 0
                                Rectangle {
                                    color: IVColors.get("Colors/Text new/TxAccent")
                                    width: parent.width
                                    height: parent.width
                                    radius: parent.width/2
                                }
                                Rectangle {
                                    color: IVColors.get("Colors/Text new/TxAccent")
                                    width: dp(2)
                                    height: sliderArea.height
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                            onContainsMouseChanged: {
                                if (containsMouse) cursorShape = Qt.SizeHorCursor
                            }
                            onXChanged: {
                                if (drag.active) {
                                    root.currDate = root.posToTime(x / (timelineArea.contentWidth - width/2))
                                }
                                else if (root.followSlider) {
                                    root.fixAreaToSlider()
                                }
                            }
                            onUpdatePosition: {
                                if (!drag.active) x = root.timeToPos(root.currDate) * timelineArea.contentWidth - width/2
                            }
                            Component.onCompleted: {
                                updatePosition()
                            }
                        }
                    }

                    Rectangle {
                        id: dateTT
                        x: root.timeToPos(root.previewDate) * timelineArea.contentWidth - timelineArea.contentX
                        visible: root.showPreview
                        width: dp(1)
                        height: bottomPanel.height
                        anchors.top: parent.top
                        color: IVColors.get("Colors/Background new/BgModalInverse")
                    }
                    Popup {
                        visible: root.showPreview
                        x: Math.max(0, Math.min(dateTT.x-width/2, parent.width-width))
                        y: 0
                        topPadding: 0
                        bottomPadding: 0
                        rightPadding: dp(4)
                        leftPadding: dp(4)
                        closePolicy: Popup.NoAutoClose
                        contentItem: Text {
                            text: Qt.formatDateTime(root.previewDate, "dd.MM.yy hh:mm:ss.zzz")
                            font: IVColors.getFont("Label")
                            color: IVColors.get("Colors/Text new/TxPrimary")
                        }
                        background: Rectangle {
                            radius: dp(4)
                            color: IVColors.get("Colors/Background new/BgModalInverse")
                        }
                    }
                }
            }
        }

        Canvas {
            width: dp(32)
            opacity: 0.6
            property var from: {"x":0, "y":0}
            property var to: {"x":width, "y":0}
            anchors {
                top: parent.top
                left: parent.left
                leftMargin: leftBottomRect.width
                bottom: parent.bottom
            }
            onPaint: {
                var ctx = getContext("2d")
                ctx.globalAlpha = 0.3
                var gradient = ctx.createLinearGradient(from.x, from.y, to.x, to.y)
                gradient.addColorStop(0, "#020720")
                gradient.addColorStop(1, "transparent")
                ctx.fillStyle = gradient
                ctx.fillRect(0, 0, width, height)
            }
            Component.onCompleted: {
                requestPaint()
            }
        }
        Rectangle {
            color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
            width: parent.width
            height: dp(1)
        }
    }

    Rectangle {
        id: leftPanel
        width: dp(280)
        anchors {
            bottom: bottomPanel.top
            top: header.bottom
            left: parent.left
        }
        color: IVColors.get("Colors/Background new/BgContextMenuThemed")

        IVEventsFilter {
            id: eventsFilter
            x: parent.width
            Timer {
                id: applyDelay
                property bool include
                property var events
                interval: 1000
                onTriggered: mainClass.updateEventsGroup(include, events)
            }
            onReady: {
                applyDelay.include = include
                applyDelay.events = events
                applyDelay.restart()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: dp(8)
            spacing: dp(4)
            Item {
                Layout.fillWidth: true
                height: dp(48)
                RowLayout {
                    anchors.fill: parent
                    spacing: dp(4)
                    IVButton {
                        source: "new_images/roll-left"
                        type: IVButton.Type.Helper
                        Layout.alignment: Qt.AlignVCenter
                        width: dp(32)
                        height: dp(32)
                    }
                    Text {
                        text: "События"
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                        font: IVColors.getFont("Subtitle accent")
                    }
                    IVButton {
                        source: "new_images/dots-vertical"
                        type: IVButton.Type.Helper
                        Layout.alignment: Qt.AlignVCenter
                        width: dp(32)
                        height: dp(32)
                        onClicked: {
                            if (eventsFilter.opened) eventsFilter.close()
                            else eventsFilter.open()
                        }
                    }
                }
            }
            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: dp(8)
                IVSegmentedControl {
                    id: viewCombo
                    height: dp(32)
                    width: parent.width
                    model: ListModel {
                        Component.onCompleted: {
                            append({text: "Все", iconName: "new_images/Event"})
                            append({text: "Метки", iconName: "new_images/Flag Time tag"})
                            viewCombo.currentIndex = 0
                        }
                    }
                }
                IVInputField {
                    id: searchField
                    width: parent.width
                    source: "new_images/search"
                    placeholderText: "Найти по названию"
                    Timer {
                        id: filterDelay
                        property string searchText: ""
                        interval: 300
                        onTriggered: {
                            console.log("Пока что поиск не работает")
                        }
                    }
//                    Connections {
//                        target: root
//                        onOpenedChanged: {
//                            searchField.text = ""
//                            filterDelay.restart()
//                        }
//                    }
                    onTextChanged: filterDelay.restart()
                }
            }
            Item {
                id: leftEventsViewArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                ListView {
                    id: leftEventsView
                    anchors.fill: parent
                    model: viewCombo.currentIndex === 0 ? mainClass.events : mainClass.bookmarks
                    delegate: viewCombo.currentIndex === 0 ? leftAreaEventDeleg
                                                           : leftAreaBookmarkDeleg
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Component {
                        id: leftAreaEventDeleg
                        MouseArea {
                            width: parent.width
                            height: dp(64)
                            hoverEnabled: true
                            propagateComposedEvents: true
                            Rectangle {
                                anchors.fill: parent
                                color: IVColors.get("Colors/Text new/TxContrast")
                                opacity: parent.containsMouse ? 0.1 : 0
                            }
                            RowLayout {
                                anchors.fill: parent
                                spacing: dp(8)
                                IVImage {
                                    width: dp(24)
                                    height: dp(24)
                                    name: "new_images/Event bg"
                                    Layout.alignment: Qt.AlignVCenter
                                    IVImage {
                                        name: "new_images/Event"
                                        color: IVColors.get("Colors/Text new/TxContrast")
                                        anchors.fill: parent
                                        anchors.margins: dp(4)
                                    }
                                }
                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    Text {
                                        text: modelData.startTime + " - " + modelData.endTime
                                        color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                        font: IVColors.getFont("Subtext")
                                    }
                                    Text {
                                        text: modelData.typeName ? modelData.typeName : ""
                                        color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                        font: IVColors.getFont("Label accent")
                                    }
                                    Text {
                                        text: modelData.source
                                        color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                        font: IVColors.getFont("Subtext")
                                    }
                                }
                                MouseArea {
                                    width: dp(24)
                                    Layout.fillHeight: true
                                    hoverEnabled: true
                                    IVImage {
                                        width: dp(16)
                                        height: dp(16)
                                        anchors.centerIn: parent
                                        color: modelData.isFavorite ? IVColors.get("Colors/Text new/" + (parent.containsMouse ? "TxTertiaryThemed" : "TxContrast")) :
                                                                      IVColors.get("Colors/Text new/" + (parent.containsMouse ? "TxContrast" : "TxTertiaryThemed"))
                                        name: "new_images/" + (modelData.isFavorite ? "star-filled" : "star-01")
                                    }
                                    onClicked:{
                                        console.log("Function to set is favorite")
                                    }
                                }
                            }
                            Rectangle {
                                color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
                                width: parent.width
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: dp(1)
                            }
                        }
                    }
                    Component {
                        id: leftAreaBookmarkDeleg
                        MouseArea {
                            width: parent.width
                            height: dp(64)
                            hoverEnabled: true
                            propagateComposedEvents: true
                            Rectangle {
                                anchors.fill: parent
                                color: IVColors.get("Colors/Text new/TxContrast")
                                opacity: parent.containsMouse ? 0.1 : 0
                            }
                            RowLayout {
                                anchors.fill: parent
                                spacing: dp(8)
                                IVImage {
                                    name: "new_images/Flag Time tag"
                                    color: IVColors.get("Colors/Text new/TxContrast")
                                    width: dp(24)
                                    height: dp(24)
                                }
                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    Text {
                                        property var startStr: Qt.formatDateTime(modelData.startTime, "dd.MM.yy hh:mm:ss")
                                        property var endStr: Qt.formatDateTime(modelData.endTime, "dd.MM.yy hh:mm:ss")
                                        text: startStr + " - " + endStr
                                        color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                        font: IVColors.getFont("Subtext")
                                    }
                                    Text {
                                        text: modelData.comment ? modelData.comment : ""
                                        color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                        font: IVColors.getFont("Label accent")
                                    }
                                    Text {
                                        text: modelData.source
                                        color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                        font: IVColors.getFont("Subtext")
                                    }
                                }
                            }
                            Rectangle {
                                color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
                                width: parent.width
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: dp(1)
                            }
                        }
                    }
                    ScrollBar.vertical: ScrollBar {
                        parent: leftEventsViewArea
                        width: dp(8)
                        height: parent.height
                        anchors.horizontalCenter: parent.right
                        policy: ScrollBar.AlwaysOn
                        contentItem: Rectangle {
                            implicitWidth: parent.width
                            implicitHeight: parent.height / leftEventsView.contentHeight
                            radius: width / 2
                            color: parent.pressed ? IVColors.get("Colors/Text new/TxPrimaryThemed") :
                                                     IVColors.get("Colors/Background new/BgFormSecondaryThemed")
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: header
        height: dp(48)
        anchors {
            top: parent.top
            right: parent.right
            left: parent.left
        }
        color: IVColors.get("Colors/Background new/BgContextMenuThemed")
        Canvas {
            height: 32 * root.isize
            opacity: 0.6
            property var from: {"x":0, "y":0}
            property var to: {"x":0, "y":height}
            anchors {
                top: parent.bottom
                left: parent.left
                right: parent.right
            }
            onPaint: {
                var ctx = getContext("2d")
                ctx.globalAlpha = 0.3
                var gradient = ctx.createLinearGradient(from.x, from.y, to.x, to.y)
                gradient.addColorStop(0, "#020720")
                gradient.addColorStop(1, "transparent")
                ctx.fillStyle = gradient
                ctx.fillRect(0, 0, width, height)
            }
        }
        Row {
            id: leftArea
            spacing: dp(16)
            anchors {
                left: parent.left
                bottom: parent.bottom
                top: parent.top
                topMargin: dp(4)
                bottomMargin: dp(4)
                leftMargin: dp(8)
            }
            IVMenuButton {
                id: menuButton
                width: dp(56)
                height: dp(40)
                anchors.verticalCenter: parent.verticalCenter
                source: "new_images/Earth"
                toolTipText: "Меню"
                onClicked:{
                    var isEditor = globSignalsObject.getEditorStatus();
                    if (!isEditor)
                    {
                        if (leftMenu.opened) globSignalsObject.hideLeftMenu()
                        else globSignalsObject.showLeftMenu()
                    }
                }
            }
            Text {
                id: winType
                anchors.verticalCenter: parent.verticalCenter
                text: "Архив"
                color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                font: IVColors.getFont("Subtitle accent")
            }
        }
        Row {
            id: centerArea
            spacing: dp(8)
            anchors {
                centerIn: parent
            }
            IVButton {
                id: sourcesButton
                width: dp(40)
                height: dp(40)
                anchors.verticalCenter: parent.verticalCenter
                source: "new_images/cctv"
                toolTipText: "Источники"
                checkable: true
                checked: sourcesMenu.opened
                onClicked:{
                    if (checked) sourcesMenu.close()
                    else sourcesMenu.open()
                }
                Component.onCompleted: {
                    sourcesMenu.parent = sourcesButton
                    sourcesMenu.x = -sourcesMenu.width/2
                    sourcesMenu.y = height
                }
            }
            IVButton {
                id: gridButton
                width: dp(40)
                height: dp(40)
                anchors.verticalCenter: parent.verticalCenter
                source: "new_images/"+gridsMenu.setsModel[gridsMenu.currSetIndex].source
                toolTipText: "Сетка"
                checkable: true
                checked: gridsMenu.opened
                onClicked:{
                    if (checked) gridsMenu.close()
                    else gridsMenu.open()
                }
                Component.onCompleted: {
                    gridsMenu.parent = gridButton
                    gridsMenu.x = -gridsMenu.width/2
                }
            }
        }
        Row {
            id: rightArea
            spacing: dp(8)
            anchors {
                right: parent.right
                bottom: parent.bottom
                top: parent.top
                margins: dp(4)
            }
            IVButton {
                id: recordsButton
                property int redordsCount: 0
                anchors.verticalCenter: parent.verticalCenter
                height: dp(32)
                width: dp(73)
                type: IVButton.Type.Secondary
                toolTipText: "Список выгрузок"
                source: "new_images/rec_Appeard"
                chevroned: true
                sourceOverlay: false
                text: redordsCount
            }
            Loader {
                id: dateTimeLoader
                asynchronous: false
                width: dp(220)
                height: dp(24)
                anchors.verticalCenter: parent.verticalCenter
                onStatusChanged: {
                    if (dateTimeLoader.status === Loader.Ready) {
                        //item.anchors.fill = dateTimeLoader;
                    }
                    if (dateTimeLoader.status === Loader.Error) {
                        console.error("dateTimeLoader error");
                    }
                }
                Component.onCompleted: {
                    source = 'file:///' + applicationDirPath +  "/qtplugins/iv/datetimecomponent/DateTimeComponent.qml";
                }
            }
            IVButton {
                id: userButton
                Layout.fillHeight: true
                anchors.verticalCenter: parent.verticalCenter
                width: 40 * root.isize
                type: IVButton.Type.Secondary
                toolTipText: "Ник/ФИО/Логин пользователя"
                source: "new_images/user-01"
            }
        }
    }

    function fixAreaToSlider() {
        root.followSlider = true
        var sliderCenter = sliderArea.x + sliderArea.width/2
        var visCenter = timelineArea.width/2 + timelineArea.contentX
        var cW = timelineArea.contentWidth - timelineArea.width

        if (sliderCenter - timelineArea.width/2 < 0)
            timelineArea.contentX = 0
        else if (sliderCenter + timelineArea.width/2 > timelineArea.contentWidth)
            timelineArea.contentX = cW
        else
            timelineArea.contentX += sliderCenter - visCenter
    }

    function zoomTo(zoomPoint) {
        root.followSlider = false
        timelineArea.resizeContent((timelineArea.width * root.zoom), timelineArea.height, zoomPoint);
        timelineArea.returnToBounds();
    }
    function timeToPos(date) {
        var res = (date - mainClass.start) / (mainClass.end - mainClass.start)
        return res
    }
    function posToTime(pos) {
        var resTime = parseInt(pos * (mainClass.end.getTime() - mainClass.start.getTime()))
        return (new Date(mainClass.start.getTime() + resTime))
    }

    onCurrDateChanged: {
        sliderArea.updatePosition()
    }
}

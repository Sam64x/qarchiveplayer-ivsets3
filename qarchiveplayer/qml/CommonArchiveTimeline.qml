import QtQuick 2.9
import QtQml 2.1
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import iv.viewers.archiveplayer 1.0
import iv.colors 1.0
import iv.controls 1.0 as C
import iv.singletonLang 1.0

Item {
    id: root

    property var players: []
    property real isize: 1
    property int commonScale: 0
    property var sharedCurrentDate: null

    property var fullnessVisibility: ({})
    property var key2Frequency: ({})
    property bool showFullnessToggles: false

    signal timeChanged(var date)
    signal boundsChanged(var bounds)

    readonly property var primaryPlayer: players.length > 0 ? players[0] : null

    property var viewStart: null
    property var viewEnd: null

    ListModel {
        id: periodsModel
        Component.onCompleted: {
            append({text: "10 мин", checked: false, period: 10*60*1000})
            append({text: "30 мин", checked: false, period: 30*60*1000})
            append({text: "1 час", checked: false, period: 60*60*1000})
            append({text: "3 часа", checked: false, period: 3*60*60*1000})
            append({text: "6 часов", checked: false, period: 6*60*60*1000})
            append({text: "12 часов", checked: false, period: 12*60*60*1000})
            append({text: "24 часа", checked: false, period: 24*60*60*1000})
            append({text: "48 часов", checked: false, period: 48*60*60*1000})
        }
    }

    function updateViewWindow() {
        if (!mainSlider || !mainSlider.timelineModelView || mainSlider.timelineModelView.count === 0) {
            viewStart = null
            viewEnd = null
            return
        }
        viewStart = mainSlider.timelineModelView.get(0)["start"]
        viewEnd = mainSlider.timelineModelView.get(mainSlider.timelineModelView.count - 1)["end"]
    }

    function syncSliderBounds(startDate, endDate) {
        if (!mainSlider || !mainSlider.setBounds || !mainSlider.ready)
            return

        if (!(startDate instanceof Date) || isNaN(startDate.getTime()))
            return

        if (!(endDate instanceof Date) || isNaN(endDate.getTime()))
            return

        var left = startDate
        var right = endDate

        if (right < left) {
            var temp = left
            left = right
            right = temp
        }

        mainSlider.setBounds(left, right)
        mainSlider.boundsChanged()
    }

    function setScale(scaleIndex) {
        if (mainSlider && mainSlider.setScale)
            mainSlider.setScale(scaleIndex)
    }

    function visibilityKeyForPlayer(player, index) {
        var hasIndex = index !== undefined && index !== null
        var resolvedIndex = hasIndex ? index : players.indexOf(player)
        var baseKey = player && player.key2 ? player.key2 : "player"
        var sameKeyCount = key2Frequency[baseKey]

        if (sameKeyCount > 1 && resolvedIndex >= 0)
            return baseKey + "_" + resolvedIndex

        if (player && player.key2)
            return player.key2

        if (resolvedIndex >= 0)
            return baseKey + "_" + resolvedIndex

        return baseKey
    }

    function fullnessOpacityFor(player, index) {
        if (!player)
            return 1

        var visibilityKey = visibilityKeyForPlayer(player, index)
        return fullnessVisibility[visibilityKey] === false ? 0.5 : 1
    }

    function setFullnessVisible(playerKey, visible) {
        if (!playerKey)
            return

        var updatedVisibility = Object.assign({}, fullnessVisibility)
        updatedVisibility[playerKey] = visible
        fullnessVisibility = updatedVisibility
    }

    onPlayersChanged: {
        var frequency = {}
        var updatedVisibility = {}
        for (var i = 0; i < players.length; ++i) {
            var player = players[i]
            var rawKey = player && player.key2 ? player.key2 : "player"
            frequency[rawKey] = (frequency[rawKey] || 0) + 1
        }

        key2Frequency = frequency

        for (var j = 0; j < players.length; ++j) {
            var currentPlayer = players[j]
            var key = visibilityKeyForPlayer(currentPlayer, j)
            var existing = fullnessVisibility.hasOwnProperty(key) ? fullnessVisibility[key] : true
            updatedVisibility[key] = existing
        }
        fullnessVisibility = updatedVisibility
    }

    IVSeparator {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: timelineArea.left
        height: 1
    }

    ColumnLayout {
        id: timelineControls
        spacing: 0
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: timelineArea.left
        width: 370

        RowLayout {
            id: timeFieldLayout

            property string fromText: root.startDate ? Qt.formatDateTime(root.startDate, "dd.MM.yyyy hh:mm:ss") : ""
            property string toText: root.endDate ? Qt.formatDateTime(root.endDate, "dd.MM.yyyy hh:mm:ss") : ""
            property bool suppressFieldSync: false

            Layout.preferredHeight: 54
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8

            function updateFieldsFromSlider() {
                if (!mainSlider || !mainSlider.getViewBounds || !mainSlider.ready)
                    return

                var bounds = mainSlider.getViewBounds()
                var haveBounds = bounds && bounds.left instanceof Date && bounds.right instanceof Date
                                && !isNaN(bounds.left.getTime()) && !isNaN(bounds.right.getTime())
                                && mainSlider.timelineModelView && mainSlider.timelineModelView.count > 0

                if (!haveBounds) {
                    fromText = ""
                    toText = ""
                    return
                }

                fromText = Qt.formatDateTime(bounds.left, "dd.MM.yyyy hh:mm:ss")
                toText = Qt.formatDateTime(bounds.right, "dd.MM.yyyy hh:mm:ss")
            }

            function syncSliderBoundsFromFields(startText, endText) {
                var ds = Date.fromLocaleString(Qt.locale(), startText, "dd.MM.yyyy hh:mm:ss")
                var de = Date.fromLocaleString(Qt.locale(), endText, "dd.MM.yyyy hh:mm:ss")

                if (ds.toString() === "Invalid Date" || de.toString() === "Invalid Date")
                    return

                if (ds < de)
                    root.syncSliderBounds(ds, de)
            }

            C.IVInputField {
                id: fromField
                Layout.fillWidth: true
                topLabelText: Language.getTranslate("From", "С")
                mask: "00.00.0000 00:00:00"

                property string previousState: state

                function applyFromInput() {
                    if (!timeFieldLayout.suppressFieldSync) {
                        timeFieldLayout.suppressFieldSync = true
                        timeFieldLayout.syncSliderBoundsFromFields(text, timeFieldLayout.toText)
                        timeFieldLayout.suppressFieldSync = false
                    }
                }

                Binding {
                    target: fromField
                    property: "text"
                    value: timeFieldLayout.fromText
                    when: !fromField.activeFocus
                }

                onTextChanged: {
                    if (timeFieldLayout.fromText !== text)
                        timeFieldLayout.fromText = text
                }
                onTextEdited: {
                    var ds = Date.fromLocaleString(Qt.locale(), text, "dd.MM.yyyy hh:mm:ss")
                }
                onInputAccepted: applyFromInput()
                onStateChanged: {
                    if (previousState === "focused" && state === "normal")
                        applyFromInput()

                    previousState = state
                }
            }

            Rectangle {
                implicitHeight: 1
                implicitWidth: 6
                color: IVColors.get("Colors/Text new/TxSecondaryThemed")
            }

            C.IVInputField {
                id: toField
                Layout.fillWidth: true
                topLabelText: Language.getTranslate("To", "По")
                mask: "00.00.0000 00:00:00"

                property string previousState: state

                function applyToInput() {
                    timeFieldLayout.suppressFieldSync = true
                    timeFieldLayout.syncSliderBoundsFromFields(timeFieldLayout.fromText, text)
                    timeFieldLayout.suppressFieldSync = false
                }

                Binding {
                    target: toField
                    property: "text"
                    value: timeFieldLayout.toText
                    when: !toField.activeFocus
                }

                onTextChanged: {
                    if (timeFieldLayout.toText !== text)
                        timeFieldLayout.toText = text
                }
                onTextEdited: {
                    var ds = Date.fromLocaleString(Qt.locale(), text, "dd.MM.yyyy hh:mm:ss")
                }
                onInputAccepted: applyToInput()
                onStateChanged: {
                    if (previousState === "focused" && state === "normal")
                        applyToInput()

                    previousState = state
                }
            }

            C.IVButtonControl {
                source: "new_images/calendar-selector"
                type: C.IVButtonControl.Type.Flat
                toolTipText: calendar.opened ? "" : Language.getTranslate("Calendar","Календарь")

                checkable: true
                checked: calendar.opened

                onClicked: {
                    if (calendar.opened)
                        calendar.close();
                    else
                        calendar.open();
                }
                C.IVContextMenuControl {
                    id: calendar
                    bgColor: IVColors.get("Colors/Background new/BgContextMenuThemed")
                    component: Component {
                        ColumnLayout {
                            id: col
                            spacing: 8 * root.isize
                            width: 360
                            Text {
                                text: "Выбрать период"
                                color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                font: IVColors.getFont("Subtitle accent")
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "За последние"
                                color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                font: IVColors.getFont("Label")
                                Layout.fillWidth: true
                            }
                            GridLayout {
                                id: periodsGrid

                                Layout.preferredWidth: parent.width
                                rowSpacing: 8
                                rows: 2
                                columns: 4

                                Repeater {
                                    model: periodsModel
                                    delegate: C.IVRadioButton {
                                        type: C.IVRadioButton.Type.Chips
                                        checked: model.checked
                                        text: model.text
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        onClicked: {
                                            calendBody.start = new Date(new Date().getTime() - model.period)
                                            calendBody.end = new Date()
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true

                                C.IVInputField {
                                    id: startInputField
                                    Layout.fillWidth: true
                                    text: timeFieldLayout.fromText
                                    name: "С"
                                    mask: "00.00.0000 00:00:00"
                                    Binding {
                                        target: startInputField
                                        property: "text"
                                        value: timeFieldLayout.fromText
                                        when: !startInputField.activeFocus
                                    }
                                    onTextChanged: {
                                        if (timeFieldLayout.fromText !== text)
                                            timeFieldLayout.fromText = text
                                    }
                                    onInputAccepted: {
                                        timeFieldLayout.syncSliderBoundsFromFields(text, endInputField.text)
                                    }
                                    onTextEdited: {
                                        var ds = Date.fromLocaleString(Qt.locale(), text, "dd.MM.yyyy hh:mm:ss")
                                        var de = Date.fromLocaleString(Qt.locale(), endInputField.text, "dd.MM.yyyy hh:mm:ss")

                                        if (ds.toString() !== "Invalid Date" && ds < new Date())
                                        {
                                            if (de.toString() !== "Invalid Date") {
                                                if (ds < de) {
                                                    calendBody.start = ds
                                                    calendBody.end = de
                                                    root.syncSliderBounds(ds, de)
                                                }
                                            }
                                        }
                                    }
                                }
                                C.IVInputField {
                                    id: endInputField
                                    Layout.fillWidth: true
                                    text: timeFieldLayout.toText
                                    name: "По"
                                    mask: "00.00.0000 00:00:00"
                                    Binding {
                                        target: endInputField
                                        property: "text"
                                        value: timeFieldLayout.toText
                                        when: !endInputField.activeFocus
                                    }
                                    onTextChanged: {
                                        if (timeFieldLayout.toText !== text)
                                            timeFieldLayout.toText = text
                                    }
                                    onInputAccepted: {
                                        timeFieldLayout.syncSliderBoundsFromFields(startInputField.text, text)
                                    }
                                    onTextEdited: {
                                        var ds = Date.fromLocaleString(Qt.locale(), startInputField.text, "dd.MM.yyyy hh:mm:ss")
                                        var de = Date.fromLocaleString(Qt.locale(), text, "dd.MM.yyyy hh:mm:ss")

                                        if (de.toString() !== "Invalid Date" && de < new Date())
                                        {
                                            if (ds.toString() !== "Invalid Date") {
                                                if (ds < de) {
                                                    calendBody.start = ds
                                                    calendBody.end = de
                                                    root.syncSliderBounds(ds, de)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            C.IVCalendar {
                                id: calendBody
                                Layout.fillWidth: true
                                selectable: true
                                property string startStr: Qt.formatDateTime(start, "d.MM.yyyy hh:mm")
                                property string endStr: Qt.formatDateTime(end, "d.MM.yyyy hh:mm")
                                onStartChanged: {
                                    if (start) {
                                        timeFieldLayout.fromText = Qt.formatDateTime(start, "dd.MM.yyyy hh:mm:ss")
                                        if (end < start) {
                                            end = start
                                        }
                                        root.periodTime = end - start
                                    }
                                }
                                onEndChanged: {
                                    if (end) {
                                        timeFieldLayout.toText = Qt.formatDateTime(end, "dd.MM.yyyy hh:mm:ss")
                                        if (end < start) {
                                            start = end
                                        }
                                        root.periodTime = end - start
                                    }
                                }
                                Component.onCompleted: {
                                    calendBody.start = root.startDate
                                    calendBody.end = root.endDate
                                }
                            }
                            C.IVButton {
                                id: acceptButton
                                text: calendBody.startStr.length > 0 ?
                                      "Отобразить " + calendBody.startStr + " - " + calendBody.endStr :
                                      "Интервал не задан"
                                Layout.fillWidth: true
                                type: IVButton.Type.Primary
                                size: IVButton.Size.Small
                                enabled: calendBody.startStr !== "" && calendBody.endStr !== ""
                                onClicked: {
                                    if (root.checkedCount > 0) {
                                        root.checkedEvents = []
                                        root.checkedOnCurrPage = []

                                        root.currPageAllChecked =
                                                (root.checkedOnCurrPage.length === root.events.length && root.events.length > 0)
                                        root.checkedCount = root.checkedEvents.length
                                        root.updateCheckedEvents()
                                    }
                                    root.startDate = calendBody.start
                                    root.endDate   = calendBody.end
                                    root.periodTime = root.endDate - root.startDate

                                    timeFieldLayout.fromText = Qt.formatDateTime(root.startDate, "dd.MM.yyyy hh:mm:ss")
                                    timeFieldLayout.toText = Qt.formatDateTime(root.endDate, "dd.MM.yyyy hh:mm:ss")

                                    periodsModel.updateChecked()

                                    calendar.close()
                                    loadBanner.opacity = 1
                                    if (updateEvtTimer.running) updateEvtTimer.restart()
                                    ivevent.init(root.startDate, root.endDate, root.filter)
                                }
                            }
                        }
                    }
                }
            }
        }

        Repeater {
            model: players

            delegate: Item {
                implicitHeight: 32
                implicitWidth: parent.width

                IVSeparator {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                }

                C.IVCheckBoxControl {
                    id: key2CheckBox

                    property string visibilityKey: root.visibilityKeyForPlayer(modelData, index)
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    implicitHeight: 32
                    text: modelData.key2
                    checked: true

                    function updateCheckedFromVisibility() {
                        var shouldBeChecked = fullnessVisibility[visibilityKey] !== false
                        if (checked !== shouldBeChecked)
                            checked = shouldBeChecked
                    }

                    onCheckedChanged: setFullnessVisible(visibilityKey, checked)

                    Connections {
                        target: root
                        onFullnessVisibilityChanged: key2CheckBox.updateCheckedFromVisibility()
                    }
                }
            }
        }
    }

    ColumnLayout {
        id: timelineArea

        anchors.left: timelineControls.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        spacing: 0

        Rectangle {
            Layout.preferredHeight: 24
            Layout.preferredWidth: parent.width

            border.color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
            border.width: 1
            color: IVColors.get("Colors/Background new/BgContextMenuThemed")

            RowLayout {
                anchors.fill: parent
                spacing: 0

                C.IVButtonControl {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 40

                    radius: 0
                    size: C.IVButtonControl.Size.Small
                    type: C.IVButtonControl.Type.Secondary
                    source: "new_images/add left period"
                    onClicked: {
                        if (!mainSlider || !mainSlider.currentDate)
                            return

                        mainSlider.currentDate = mainSlider.decrementDate(mainSlider.timeline_model, mainSlider.currentDate)
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.margins: 4

                    radius: 4
                    color: IVColors.get("Colors/Text new/TxScroll")
                }

                C.IVButtonControl {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 40

                    radius: 0
                    size: C.IVButtonControl.Size.Small
                    type: C.IVButtonControl.Type.Secondary
                    source: "new_images/add right period"
                    onClicked: {
                        if (!mainSlider || !mainSlider.currentDate)
                            return

                        mainSlider.currentDate = mainSlider.incrementDate(mainSlider.timeline_model, mainSlider.currentDate)
                    }
                }
            }

        }

        MouseArea {
            id: commonPanelMa

            Layout.fillHeight: true
            Layout.fillWidth: true
            hoverEnabled: true
            propagateComposedEvents: true

            onClicked: {
                if (!mainSlider)
                    return

                var mappedX = commonPanelMa.mouseX + mainSlider.viewportOffset()
                var clampedX = Math.min(mappedX, mainSlider.nowX)

                mainSlider.currentDate = mainSlider.xToTime(clampedX)
            }

            Label {
                id: previewDate

                property var date: mainSlider.xToTime(commonPanelMa.mouseX +
                                                    mainSlider.viewportOffset())
                property var dayNames: [
                    Language.getTranslate("Su","Вс"),
                    Language.getTranslate("Mo","Пн"),
                    Language.getTranslate("Tu","Вт"),
                    Language.getTranslate("We","Ср"),
                    Language.getTranslate("Th","Чт"),
                    Language.getTranslate("Fr","Пт"),
                    Language.getTranslate("Sa","Сб")
                ];
                property var monthNames: [
                    Language.getTranslate("JAN","ЯНВ"),
                    Language.getTranslate("FEB","ФЕВ"),
                    Language.getTranslate("MAR","МАР"),
                    Language.getTranslate("APR","АПР"),
                    Language.getTranslate("MAY","МАЙ"),
                    Language.getTranslate("JUNE","ИЮН"),
                    Language.getTranslate("JUL","ИЮЛ"),
                    Language.getTranslate("AUG","АВГ"),
                    Language.getTranslate("SEPT","СЕН"),
                    Language.getTranslate("OCT","ОКТ"),
                    Language.getTranslate("NOV","НОЯ"),
                    Language.getTranslate("DEC","ДЕК")
                ];
                leftPadding: 8
                rightPadding: 8
                topPadding: 2
                bottomPadding: 2
                text: date !== null ? dayNames[date.getDay()] + " " +
                                      date.getDate() + " " +
                                      monthNames[date.getMonth()] + " " +
                                      date.getFullYear() + " " +
                                      date.toLocaleTimeString() : ""
                color: IVColors.get("Colors/Text new/TxPrimary")
                font: IVColors.getFont("Label")
                z: mainSlider.z + 2
                anchors.top: translucentSliderRect.top
                anchors.horizontalCenter: translucentSliderRect.horizontalCenter
                visible: commonPanelMa.containsMouse
                background: Rectangle{
                    color: IVColors.get("Colors/Background new/BgModalInverse")
                    border.color: "black"
                    border.width: 1
                    radius: 4
                }
            }

            Rectangle {
                id: translucentSliderRect
                width: 2
                height: parent.height
                z: mainSlider.z + 1
                x: commonPanelMa.mouseX
                opacity: 0.6
                visible: commonPanelMa.containsMouse
                color: IVColors.get("Colors/Background new/BgModalInverse")
            }

            Item {
                id: sliderRect

                property real targetX: !mainSlider ? 0 : mainSlider.timeToX(mainSlider.currentDate)

                width: sliderTracer.implicitWidth
                x: mainSlider ? (targetX - mainSlider.viewportOffset()) - width / 2 : -width / 2

                z: mainSlider.z + 1
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Rectangle {
                    id: sliderTracer

                    anchors.top: parent.top
                    anchors.topMargin: previewDate.implicitHeight
                    anchors.horizontalCenter: parent.horizontalCenter

                    implicitWidth: 16
                    implicitHeight: 16
                    radius: width/2
                    color: IVColors.get("Colors/Text new/TxAccent")
                }


                Rectangle {
                    anchors.top: sliderTracer.bottom
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: sliderTracer.horizontalCenter
                    implicitWidth: 2
                    color: IVColors.get("Colors/Text new/TxAccent")
                }

                DropShadow {
                    anchors.fill: sliderTracer
                    source: sliderTracer
                    verticalOffset: 4
                    radius: 8
                    color: Qt.rgba(2/255, 7/255, 32/255, 0.4)
                }
            }


            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                IVArc_slider_new2 {
                    id: mainSlider

                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    isize: root.isize
                    archivePlayer: root.primaryPlayer.idarchive_player
                    key2: root.key2
                    previewMargin: 0
                    isMultiscreen: true
                    isCommonPanel: true
                    setInterval: true

                    onReadyChanged: {
                        if (ready)
                            timeFieldLayout.updateFieldsFromSlider()
                    }

                    onFirstBorderTimeChanged: timeFieldLayout.updateFieldsFromSlider()
                    onSecondBorderTimeChanged: timeFieldLayout.updateFieldsFromSlider()

                    onFirstSetChanged: timeFieldLayout.updateFieldsFromSlider()
                    onSecondSetChanged: timeFieldLayout.updateFieldsFromSlider()

                    onTimeline_modelChanged: {
                        root.commonScale = timeline_model
                        root.updateViewWindow()
                    }

                    onUpdateCalendarDT: root.timeChanged(currentDate)

                    onCurrentDateChanged: {
                        root.sharedCurrentDate = currentDate
                        root.timeChanged(currentDate)
                        root.updateViewWindow()
                    }

                    onBoundsChanged: {
                        root.boundsChanged(getSelectedInterval())
                        timeFieldLayout.updateFieldsFromSlider()
                    }
                }

                Repeater {
                    model: players
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    delegate: CommonArchiveCameraBar {
                        Layout.preferredHeight: 32
                        Layout.fillWidth: true
                        archivePlayer: modelData
                        key2: modelData ? modelData.key2 : null
                        timelineModel: mainSlider.timeline_model
                        viewStart: root.viewStart
                        viewEnd: root.viewEnd
                        fullnessOpacity: root.fullnessOpacityFor(modelData, index)
                    }
                }
            }
        }
    }
    Component.onCompleted: {
        updateViewWindow()
        timeFieldLayout.updateFieldsFromSlider()
    }
}

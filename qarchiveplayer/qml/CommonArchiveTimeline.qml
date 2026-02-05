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
    property var playersList: []
    property int commonScale: 0
    property var sharedCurrentDate: null
    property var localCurrentDate: null
    property var startDate: null
    property var endDate: null
    property int periodTime: 0
    property bool initialBoundsApplied: false
    property int scaleIndex

    onScaleIndexChanged: {
        if (mainSlider && mainSlider.ready) {
            pendingScaleIndex = null
        } else {
            pendingScaleIndex = root.scaleIndex
        }
    }

    property var fullnessVisibility: ({})
    property var key2Frequency: ({})
    property bool showFullnessToggles: false
    property var pendingBounds: null
    property var pendingScaleIndex: null
    property bool exportMode: false
    property var exportStartTime: null
    property var exportEndTime: null
    property var exportBounds: ({ "left": null, "right": null })
    property var exportCameraIds: []
    property int maxVisiblePlayers: 4

    signal timeChanged(var date)
    signal boundsChanged(var bounds)

    readonly property var primaryPlayer: playersList.length > 0 ? playersList[0] : null
    readonly property int timeFieldHeight: 54
    readonly property int timelineHeaderHeight: 24
    readonly property int sliderHeight: 32
    readonly property int playerRowHeight: 32
    readonly property int visiblePlayersCount: Math.min(playersList.length, maxVisiblePlayers)
    readonly property int playersListHeight: visiblePlayersCount * playerRowHeight

    property var viewStart: null
    property var viewEnd: null
    property bool suppressBoundsPropagation: false
    property bool suppressTimePropagation: false

    function adjustDate(startDate, index, add) {
        var d = new Date(startDate), m = add ? 1 : -1
        switch(index) {
        case 0: d.setFullYear(d.getFullYear() + m); break
        case 1: d.setMonth(d.getMonth() + m); break
        case 2: d.setDate(d.getDate() + 7 * m); break
        case 3: d.setDate(d.getDate() + m); break
        case 4: d.setHours(d.getHours() + m); break
        case 5: d.setMinutes(d.getMinutes() + 30 * m); break
        case 6: d.setMinutes(d.getMinutes() + 10 * m); break
        case 7: d.setMinutes(d.getMinutes() + m); break
        }
        return d
    }

    property alias mainSlider: mainSlider
    property alias canAutoMove: mainSlider.canAutoMove

    implicitHeight: timeFieldHeight + timelineHeaderHeight + sliderHeight + playersListHeight

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
        if (!mainSlider) {
            viewStart = null
            viewEnd = null
            return
        }
        var bounds = mainSlider.viewBounds || (mainSlider.getViewBounds ? mainSlider.getViewBounds() : null)
        if (bounds && bounds.left && bounds.right) {
            viewStart = bounds.left
            viewEnd = bounds.right
            return
        }

        var leftBorder = mainSlider.leftTimeBorder
        var rightBorder = mainSlider.rightTimeBorder
        if (leftBorder instanceof Date && rightBorder instanceof Date &&
                !isNaN(leftBorder.getTime()) && !isNaN(rightBorder.getTime())) {
            viewStart = leftBorder
            viewEnd = rightBorder
            return
        }

        viewStart = null
        viewEnd = null
    }

    function currentFrameDate() {
        if (primaryPlayer && primaryPlayer.getFrameTime) {
            var frameTime = primaryPlayer.getFrameTime()
            if (frameTime > 0)
                return new Date(frameTime)
        }
        return null
    }

    function syncSliderToFrameTime() {
        if (!mainSlider)
            return
        var frameDate = currentFrameDate()
        if (!frameDate)
            return
        if (!mainSlider.currentDate || !mainSlider.currentDate.getTime ||
                mainSlider.currentDate.getTime() !== frameDate.getTime()) {
            mainSlider.currentDate = frameDate
        }
    }


    function syncSliderBounds(startDate, endDate) {
        if (!mainSlider)
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

        root.startDate = left
        root.endDate = right

        var centerMs = Math.round((left.getTime() + right.getTime()) / 2)
        if (!mainSlider.currentDate || !mainSlider.currentDate.getTime ||
                mainSlider.currentDate.getTime() !== centerMs) {
            mainSlider.currentDate = new Date(centerMs)
        }

        mainSlider.leftTimeBorder = left
        mainSlider.rightTimeBorder = right

        if (mainSlider.ready) {
            mainSlider.boundsChanged()
        } else {
            pendingBounds = { "left": left, "right": right, "suppressBounds": false }
        }
    }

    function syncSliderViewBounds(startDate, endDate) {
        if (!mainSlider)
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

        root.startDate = left
        root.endDate = right
        root.periodTime = root.endDate - root.startDate

        var centerMs = Math.round((left.getTime() + right.getTime()) / 2)

        root.suppressBoundsPropagation = true
        root.suppressTimePropagation = true

        if (!mainSlider.currentDate || !mainSlider.currentDate.getTime ||
                mainSlider.currentDate.getTime() !== centerMs) {
            mainSlider.currentDate = new Date(centerMs)
        }

        if (mainSlider.ready) {
            mainSlider.leftTimeBorder = left
            mainSlider.rightTimeBorder = right
            mainSlider.boundsChanged()
        } else {
            pendingBounds = { "left": left, "right": right, "suppressBounds": true }
        }

        Qt.callLater(function() {
            root.suppressBoundsPropagation = false
            root.suppressTimePropagation = false
        })
    }

    function applyInitialBoundsFromSharedDate() {
        if (initialBoundsApplied || pendingBounds)
            return
        if (!mainSlider)
            return
        var centerDate = sharedCurrentDate instanceof Date && !isNaN(sharedCurrentDate.getTime())
            ? sharedCurrentDate
            : (localCurrentDate instanceof Date && !isNaN(localCurrentDate.getTime()) ? localCurrentDate : null)
        if (!centerDate)
            return
        if (mainSlider.leftTimeBorder instanceof Date && mainSlider.rightTimeBorder instanceof Date) {
            initialBoundsApplied = true
            return
        }

        var dayMs = 24 * 60 * 60 * 1000
        var centerMs = centerDate.getTime()
        var leftMs = centerMs - dayMs / 2
        var rightMs = centerMs + dayMs / 2
        var nowMs = Date.now()
        if (rightMs > nowMs) {
            rightMs = nowMs
            leftMs = rightMs - dayMs
        }
        if (rightMs < leftMs)
            rightMs = leftMs

        var left = new Date(leftMs)
        var right = new Date(rightMs)
        root.startDate = left
        root.endDate = right
        root.periodTime = root.endDate - root.startDate
        root.syncSliderBounds(root.startDate, root.endDate)
        timeFieldLayout.fromText = Qt.formatDateTime(root.startDate, "dd.MM.yyyy hh:mm:ss")
        timeFieldLayout.toText = Qt.formatDateTime(root.endDate, "dd.MM.yyyy hh:mm:ss")

        initialBoundsApplied = true
    }

    function setScale(scaleIndex) {
        root.scaleIndex = scaleIndex
        if (mainSlider && mainSlider.setScale)
            mainSlider.setScale(scaleIndex)
    }

    function visibilityKeyForPlayer(player, index) {
        var hasIndex = index !== undefined && index !== null
        var resolvedIndex = hasIndex ? index : playersList.indexOf(player)
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
        updateExportCameraIds()
    }

    function updateExportCameraIds() {
        var ids = []
        for (var i = 0; i < playersList.length; ++i) {
            var player = playersList[i]
            if (!player)
                continue
            var key = visibilityKeyForPlayer(player, i)
            if (fullnessVisibility[key] === false)
                continue
            if (player.cameraId)
                ids.push(player.cameraId)
        }
        exportCameraIds = ids
    }

    function setExportBounds(startTime, endTime) {
        if (!(startTime instanceof Date) || isNaN(startTime.getTime()) ||
                !(endTime instanceof Date) || isNaN(endTime.getTime()))
            return

        var left = startTime
        var right = endTime
        if (right < left) {
            var temp = left
            left = right
            right = temp
        }

        exportStartTime = left
        exportEndTime = right
        exportBounds = { "left": left, "right": right }
    }

    onPlayersChanged: {
        var resolvedPlayers = []
        if (players) {
            if (Array.isArray(players)) {
                resolvedPlayers = players
            } else if (players.count !== undefined && players.get !== undefined) {
                for (var p = 0; p < players.count; ++p)
                    resolvedPlayers.push(players.get(p))
            } else if (players.length !== undefined) {
                for (var q = 0; q < players.length; ++q)
                    resolvedPlayers.push(players[q])
            } else {
                resolvedPlayers = [players]
            }
        }

        playersList = resolvedPlayers

        var frequency = {}
        var updatedVisibility = {}
        for (var i = 0; i < playersList.length; ++i) {
            var player = playersList[i]
            var rawKey = player && player.key2 ? player.key2 : "player"
            frequency[rawKey] = (frequency[rawKey] || 0) + 1
        }

        key2Frequency = frequency

        for (var j = 0; j < playersList.length; ++j) {
            var currentPlayer = playersList[j]
            var key = visibilityKeyForPlayer(currentPlayer, j)
            var existing = fullnessVisibility.hasOwnProperty(key) ? fullnessVisibility[key] : true
            updatedVisibility[key] = existing
        }
        fullnessVisibility = updatedVisibility
        updateExportCameraIds()
    }

    onSharedCurrentDateChanged: applyInitialBoundsFromSharedDate()
    onLocalCurrentDateChanged: applyInitialBoundsFromSharedDate()

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
        width: 380

        RowLayout {
            id: timeFieldLayout

            property string fromText: root.startDate ? Qt.formatDateTime(root.startDate, "dd.MM.yyyy hh:mm:ss") : ""
            property string toText: root.endDate ? Qt.formatDateTime(root.endDate, "dd.MM.yyyy hh:mm:ss") : ""
            property bool suppressFieldSync: false

            Layout.preferredHeight: root.timeFieldHeight
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 4

            function updateFieldsFromSlider() {
                if (!mainSlider || !mainSlider.ready)
                    return

                var left = mainSlider.leftTimeBorder
                var right = mainSlider.rightTimeBorder
                var haveBounds = left instanceof Date && right instanceof Date
                                && !isNaN(left.getTime()) && !isNaN(right.getTime())

                if (!haveBounds) {
                    fromText = ""
                    toText = ""
                    return
                }

                fromText = Qt.formatDateTime(left, "dd.MM.yyyy hh:mm:ss")
                toText = Qt.formatDateTime(right, "dd.MM.yyyy hh:mm:ss")
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
                            spacing: 8
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
                            C.IVButtonControl {
                                id: acceptButton
                                text: calendBody.startStr.length > 0 ?
                                      "Отобразить " + calendBody.startStr + " - " + calendBody.endStr :
                                      "Интервал не задан"
                                Layout.fillWidth: true
                                type: C.IVButton.Type.Primary
                                size: C.IVButton.Size.Big
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
                                    root.syncSliderViewBounds(root.startDate, root.endDate)
                                    timeFieldLayout.fromText = Qt.formatDateTime(root.startDate, "dd.MM.yyyy hh:mm:ss")
                                    timeFieldLayout.toText = Qt.formatDateTime(root.endDate, "dd.MM.yyyy hh:mm:ss")
                                    calendar.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        ScrollView {
            id: key2Scroll

            clip: true
            background: null
            Layout.fillWidth: true
            Layout.preferredHeight: root.playersListHeight
            ScrollBar.vertical.policy: playersList.length > root.maxVisiblePlayers ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

            Column {
                width: key2Scroll.availableWidth
                spacing: 0

                Repeater {
                    model: playersList

                    delegate: Item {
                        implicitHeight: root.playerRowHeight
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
                            implicitHeight: root.playerRowHeight
                            text: modelData && modelData.key2 ? modelData.key2 : ""
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
            id: actualTimeline

            Layout.preferredHeight: root.timelineHeaderHeight
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
                    toolTipText: Language.getTranslate("Add left period","Добавить период слева")
                    source: "new_images/add left period"
                    onClicked: {
                        root.startDate = root.adjustDate(root.startDate, root.scaleIndex, false)
                        root.syncSliderViewBounds(root.startDate, root.endDate)
                    }
                }

                Rectangle {
                    id: timelineTrack
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.margins: 4
                    radius: 4
                    color: IVColors.get("Colors/Background new/BgContextMenuThemed")

                    function borders() {
                        if (!mainSlider)
                            return null
                        var left = mainSlider.leftTimeBorder
                        var right = mainSlider.rightTimeBorder
                        if (!(left instanceof Date) || !(right instanceof Date))
                            return null
                        if (isNaN(left.getTime()) || isNaN(right.getTime()))
                            return null
                        if (right < left) {
                            var swap = left
                            left = right
                            right = swap
                        }
                        return { "left": left, "right": right }
                    }

                    function viewWindow(borders) {
                        if (!borders)
                            return null
                        var left = mainSlider.viewLeftTime instanceof Date ? mainSlider.viewLeftTime : borders.left
                        var right = mainSlider.viewRightTime instanceof Date ? mainSlider.viewRightTime : borders.right
                        if (isNaN(left.getTime()) || isNaN(right.getTime()))
                            return null
                        if (right < left) {
                            var swap = left
                            left = right
                            right = swap
                        }
                        left = left < borders.left ? borders.left : left
                        right = right > borders.right ? borders.right : right
                        return { "left": left, "right": right }
                    }

                    function ratioForTime(time, borders) {
                        if (!time || !time.getTime)
                            return null
                        var total = borders.right.getTime() - borders.left.getTime()
                        if (total <= 0)
                            return null
                        return (time.getTime() - borders.left.getTime()) / total
                    }

                    Rectangle {
                        id: visibleTimeline
                        radius: 4
                        color: IVColors.get("Colors/Text new/TxScroll")
                        height: parent.height
                        y: 0
                        property var borders: timelineTrack.borders()
                        property var view: timelineTrack.viewWindow(borders)
                        property real totalWidth: parent.width
                        visible: borders && view
                        x: {
                            if (!visible)
                                return 0
                            var ratio = timelineTrack.ratioForTime(view.left, borders)
                            return Math.max(0, Math.min(totalWidth, ratio * totalWidth))
                        }
                        width: {
                            if (!visible)
                                return 0
                            var leftRatio = timelineTrack.ratioForTime(view.left, borders)
                            var rightRatio = timelineTrack.ratioForTime(view.right, borders)
                            if (leftRatio === null || rightRatio === null)
                                return 0
                            return Math.max(0, (rightRatio - leftRatio) * totalWidth)
                        }
                    }

                    Rectangle {
                        id: sliderMarker
                        width: 2
                        height: parent.height
                        color: IVColors.get("Colors/Text new/TxAccent")
                        z: visibleTimeline.z + 1
                        property var borders: timelineTrack.borders()
                        readonly property var sliderDate: root.sharedCurrentDate ? root.sharedCurrentDate : root.localCurrentDate
                        visible: borders && sliderDate
                        x: {
                            if (!visible)
                                return 0
                            var ratio = timelineTrack.ratioForTime(sliderDate, borders)
                            if (ratio === null)
                                return 0
                            return Math.max(0, Math.min(parent.width, ratio * parent.width)) - width / 2
                        }
                    }

                    Rectangle {
                        id: exportRangeMarker
                        height: parent.height
                        color: "#9747FF"
                        opacity: 0.4
                        z: visibleTimeline.z + 1
                        property var borders: timelineTrack.borders()
                        visible: exportMode && borders && root.exportStartTime && root.exportEndTime
                        x: {
                            if (!visible)
                                return 0
                            var startTime = root.exportStartTime
                            var endTime = root.exportEndTime
                            if (endTime < startTime) {
                                var swap = startTime
                                startTime = endTime
                                endTime = swap
                            }
                            var leftRatio = timelineTrack.ratioForTime(startTime, borders)
                            if (leftRatio === null)
                                return 0
                            return Math.max(0, Math.min(parent.width, leftRatio * parent.width))
                        }
                        width: {
                            if (!visible)
                                return 0
                            var startTime = root.exportStartTime
                            var endTime = root.exportEndTime
                            if (endTime < startTime) {
                                var swap = startTime
                                startTime = endTime
                                endTime = swap
                            }
                            var leftRatio = timelineTrack.ratioForTime(startTime, borders)
                            var rightRatio = timelineTrack.ratioForTime(endTime, borders)
                            if (leftRatio === null || rightRatio === null)
                                return 0
                            var span = rightRatio - leftRatio
                            if (span < 0)
                                span = -span
                            return Math.max(2, span * parent.width)
                        }
                    }
                }

                C.IVButtonControl {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 40

                    radius: 0
                    size: C.IVButtonControl.Size.Small
                    type: C.IVButtonControl.Type.Secondary
                    source: "new_images/add right period"
                    toolTipText: Language.getTranslate("Add right period","Добавить период справа")
                    onClicked: {
                        var localTime = root.adjustDate(root.endDate, root.scaleIndex, true)
                        if (localTime > new Date()) {
                            root.endDate = new Date();
                        } else {
                            root.endDate = localTime;
                        }
                        root.syncSliderViewBounds(root.startDate, root.endDate);
                    }
                }
            }

        }

        MouseArea {
            id: commonPanelMa

            Layout.fillHeight: true
            Layout.fillWidth: true
            hoverEnabled: true
            clip: true
            propagateComposedEvents: true
            cursorShape: mainSlider && mainSlider.dragging ? Qt.ClosedHandCursor :
                         containsMouse ? Qt.OpenHandCursor :
                                         Qt.ArrowCursor

            property bool dragActive: false
            property bool didDrag: false
            property real lastDragX: 0
            property real dragDistance: 0
            property real dragThreshold: 3
            property real hoverX: mainSlider && mainSlider.hoverActive ? mainSlider.hoverX : mouseX
            property bool hoverActive: mainSlider && mainSlider.hoverActive ? true : containsMouse

            onPressed: {
                if (!mainSlider)
                    return
                if (exportMode && (leftHandle.containsMouse || rightHandle.containsMouse))
                    return
                dragActive = true
                didDrag = false
                dragDistance = 0
                lastDragX = mouseX
                mainSlider.startExternalDrag()
            }

            onPositionChanged: {
                if (!dragActive || !mainSlider)
                    return
                var deltaX = mouseX - lastDragX
                lastDragX = mouseX
                dragDistance += Math.abs(deltaX)
                if (dragDistance >= dragThreshold)
                    didDrag = true
                mainSlider.dragTimelineBy(deltaX)
            }

            onWheel: {
                if (!mainSlider)
                    return
                mainSlider.zoomBy(wheel.angleDelta.y, wheel.x)
                wheel.accepted = true
            }

            onReleased: {
                if (!dragActive || !mainSlider)
                    return
                dragActive = false
                mainSlider.endExternalDrag()

                if (didDrag)
                    return

                var mappedX = commonPanelMa.mouseX + mainSlider.viewportOffset()
                var clampedX = Math.min(mappedX, mainSlider.nowX)

                mainSlider.currentDate = mainSlider.xToTime(clampedX)
            }

            onDoubleClicked: {
                if (!mainSlider)
                    return
                if (dragActive) {
                    dragActive = false
                    didDrag = false
                    mainSlider.endExternalDrag()
                }
                exportMode = true
                var defaultWidth = 80
                var maxX = Math.min(mainSlider.nowX - mainSlider.viewportOffset(), commonPanelMa.width)
                if (!isFinite(maxX) || maxX <= 0)
                    maxX = commonPanelMa.width
                var startX = Math.max(0, Math.min(mouseX - defaultWidth / 2, maxX - defaultWidth))
                var endX = Math.min(startX + defaultWidth, maxX)
                exportSelection.setBounds(startX, endX)
            }

            Label {
                id: previewDate

                property var date: mainSlider.xToTime(commonPanelMa.hoverX +
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
                x: {
                    var targetCenter = translucentSliderRect.x + translucentSliderRect.width / 2
                    var minX = 0
                    var maxX = commonPanelMa.width - width
                    if (maxX < minX)
                        return minX
                    return Math.min(Math.max(targetCenter - width / 2, minX), maxX)
                }
                visible: commonPanelMa.hoverActive
                         && !(commonPanelMa.dragActive && commonPanelMa.didDrag)
                         && !(leftHandle.pressed || rightHandle.pressed)
                background: Rectangle{
                    color: IVColors.get("Colors/Background new/BgModalInverse")
                    border.color: "black"
                    border.width: 1
                    radius: 4
                }
            }

            Rectangle {
                id: translucentSliderRect
                visible: commonPanelMa.hoverActive
                         && !(commonPanelMa.dragActive && commonPanelMa.didDrag)
                         && !(leftHandle.pressed || rightHandle.pressed)
                width: 2
                height: parent.height
                z: mainSlider.z + 1
                x: commonPanelMa.hoverX
                opacity: 0.6
                color: IVColors.get("Colors/Background new/BgModalInverse")
            }

            Item {
                id: exportSelection

                anchors.fill: parent
                z: mainSlider ? mainSlider.z + 2 : 1
                visible: root.exportMode

                property real leftX: 0
                property real rightX: 0
                property real minWidth: 12
                property real handleWidth: 6

                function maxSelectableX() {
                    if (!mainSlider)
                        return commonPanelMa.width
                    var maxX = Math.min(mainSlider.nowX - mainSlider.viewportOffset(), commonPanelMa.width)
                    if (!isFinite(maxX) || maxX <= 0)
                        maxX = commonPanelMa.width
                    return maxX
                }

                function clampX(value) {
                    var maxX = maxSelectableX()
                    return Math.max(0, Math.min(value, maxX))
                }

                function setBounds(left, right) {
                    applyBounds(left, right, true, true)
                }

                function applyBounds(left, right, shouldUpdateTimes, shouldClamp) {
                    var nextLeft = left
                    var nextRight = right
                    if (shouldClamp) {
                        var clampedLeft = clampX(left)
                        var clampedRight = clampX(right)
                        if (clampedRight - clampedLeft < minWidth) {
                            clampedRight = Math.min(clampedLeft + minWidth, maxSelectableX())
                            if (clampedRight - clampedLeft < minWidth)
                                clampedLeft = Math.max(0, clampedRight - minWidth)
                        }
                        nextLeft = clampedLeft
                        nextRight = clampedRight
                    }
                    leftX = Math.min(nextLeft, nextRight)
                    rightX = Math.max(nextLeft, nextRight)
                    if (shouldUpdateTimes)
                        updateTimes()
                }

                function updateTimes() {
                    if (!mainSlider)
                        return
                    var leftTime = mainSlider.xToTime(leftX + mainSlider.viewportOffset())
                    var rightTime = mainSlider.xToTime(rightX + mainSlider.viewportOffset())
                    root.setExportBounds(leftTime, rightTime)
                }

                function syncFromTimes() {
                    if (!root.exportStartTime || !root.exportEndTime || !mainSlider)
                        return
                    var leftTime = root.exportStartTime
                    var rightTime = root.exportEndTime
                    var left = mainSlider.timeToX(leftTime) - mainSlider.viewportOffset()
                    var right = mainSlider.timeToX(rightTime) - mainSlider.viewportOffset()
                    if (!isFinite(left) || !isFinite(right))
                        return
                    applyBounds(left, right, false, false)
                }

                Rectangle {
                    id: exportFrame

                    x: exportSelection.leftX
                    z: mainSlider.z + 1
                    width: Math.max(exportSelection.minWidth, exportSelection.rightX - exportSelection.leftX)
                    height: parent.height
                    color: "#9747FF"
                    opacity: 0.2
                }

                Rectangle {
                    width: 1
                    height: parent.height
                    color: "#9747FF"
                    anchors.left: exportFrame.left
                }

                Rectangle {
                    width: 1
                    height: parent.height
                    color: "#9747FF"
                    anchors.right: exportFrame.right
                }

                MouseArea {
                    id: leftHandle
                    width: exportSelection.handleWidth
                    preventStealing: true
                    height: parent.height
                    x: exportSelection.leftX - width / 2
                    cursorShape: Qt.SizeHorCursor
                    property real pressLeftX: 0
                    property real pressParentX: 0
                    onPressed: {
                        mouse.accepted = true
                        pressLeftX = exportSelection.leftX
                        pressParentX = mouse.x + leftHandle.x
                    }
                    onPositionChanged: {
                        var currentParentX = mouse.x + leftHandle.x
                        var delta = currentParentX - pressParentX
                        var newLeft = pressLeftX + delta
                        var maxLeft = exportSelection.rightX - exportSelection.minWidth
                        exportSelection.leftX = exportSelection.clampX(Math.min(newLeft, maxLeft))
                        exportSelection.updateTimes()
                    }
                }

                MouseArea {
                    id: rightHandle
                    width: exportSelection.handleWidth
                    preventStealing: true
                    height: parent.height
                    x: exportSelection.rightX - width / 2
                    cursorShape: Qt.SizeHorCursor
                    property real pressRightX: 0
                    property real pressParentX: 0
                    onPressed: {
                        mouse.accepted = true
                        pressRightX = exportSelection.rightX
                        pressParentX = mouse.x + rightHandle.x
                    }
                    onPositionChanged: {
                        var currentParentX = mouse.x + rightHandle.x
                        var delta = currentParentX - pressParentX
                        var newRight = pressRightX + delta
                        var minRight = exportSelection.leftX + exportSelection.minWidth
                        exportSelection.rightX = exportSelection.clampX(Math.max(newRight, minRight))
                        exportSelection.updateTimes()
                    }
                }

                Connections {
                    target: mainSlider
                    onViewBoundsChanged: exportSelection.syncFromTimes()
                    onCurrentDateChanged: exportSelection.syncFromTimes()
                    onTimeline_modelChanged: exportSelection.syncFromTimes()
                }

                Connections {
                    target: root
                    onExportBoundsChanged: exportSelection.syncFromTimes()
                }
            }

            Item {
                id: sliderRect

                readonly property var sliderDate: root.sharedCurrentDate ? root.sharedCurrentDate : root.localCurrentDate
                readonly property real sliderX: (!mainSlider || !sliderDate)
                    ? -width / 2
                    : (mainSlider.timeToX(sliderDate) - mainSlider.viewportOffset()) - width / 2

                width: sliderTracer.implicitWidth
                x: sliderX

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

                CommonTimelineSlider {
                    id: mainSlider

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.sliderHeight

                    onReadyChanged: {
                        if (ready) {
                            timeFieldLayout.updateFieldsFromSlider()
                            if (root.pendingScaleIndex !== null) {
                                var scaleIndex = root.pendingScaleIndex
                                root.pendingScaleIndex = null
                                Qt.callLater(function() {
                                    root.setScale(scaleIndex)
                                })
                            }
                            if (root.pendingBounds) {
                                var suppressBounds = root.pendingBounds.suppressBounds === true
                                if (suppressBounds) {
                                    root.suppressBoundsPropagation = true
                                }
                                mainSlider.leftTimeBorder = root.pendingBounds.left
                                mainSlider.rightTimeBorder = root.pendingBounds.right
                                mainSlider.boundsChanged()
                                root.pendingBounds = null
                                if (suppressBounds) {
                                    Qt.callLater(function() {
                                        root.suppressBoundsPropagation = false
                                    })
                                }
                            }
                        }
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
                        root.localCurrentDate = currentDate
                        if (!root.suppressTimePropagation)
                            root.timeChanged(currentDate)
                        root.updateViewWindow()
                    }

                    onBoundsChanged: {
                        timeFieldLayout.updateFieldsFromSlider()
                        root.updateViewWindow()
                        if (!root.suppressBoundsPropagation)
                            root.boundsChanged(getSelectedInterval())
                    }

                    onCanAutoMoveChanged: {
                        if (canAutoMove)
                            root.syncSliderToFrameTime()
                    }
                }

                Connections {
                    target: mainSlider
                    onViewBoundsChanged: root.updateViewWindow()
                }

            Item {
                id: cameraBarsViewport
                Layout.fillWidth: true
                Layout.preferredHeight: root.playersListHeight
                clip: true

                ColumnLayout {
                    id: cameraBarsContent
                    width: parent.width
                    height: key2Scroll.contentItem ? key2Scroll.contentItem.implicitHeight : 0
                    spacing: 0
                    y: key2Scroll.contentItem ? -key2Scroll.contentItem.contentY : 0

                    Repeater {
                        model: playersList

                        delegate: CommonArchiveCameraBar {
                            Layout.preferredHeight: root.playerRowHeight
                            Layout.fillWidth: true
                            width: cameraBarsViewport.width
                            archivePlayer: modelData
                            key2: modelData && modelData.key2 ? modelData.key2 : null
                            timelineModel: mainSlider.timeline_model
                            viewStart: root.viewStart
                            viewEnd: root.viewEnd
                            fullnessOpacity: root.fullnessOpacityFor(modelData, index)
                        }
                    }
                }
            }
            }
        }
    }

    Component.onCompleted: {
        updateViewWindow()
        timeFieldLayout.updateFieldsFromSlider()
        applyInitialBoundsFromSharedDate()
    }
}

import QtQuick 2.9
import QtQml 2.3
import QtQuick.Controls 2.3
import iv.singletonLang 1.0
import iv.colors 1.0

Item {
    id: root

    property var leftTimeBorder: null
    property var rightTimeBorder: null
    property var viewLeftTime: null
    property var viewRightTime: null
    property var currentDate: null
    property var nowDateTime: new Date()
    property real nowX: 0
    property bool ready: false
    property bool canAutoMove: true
    property bool externalDragging: false
    readonly property bool dragging: externalDragging
    property real hoverX: 0
    property bool hoverActive: false
    property int timeline_model: 0
    property bool rebuildPending: false

    property var viewBounds: ({ "left": null, "right": null })
    property var bounds: ({ "first": viewLeftTime, "second": viewRightTime })
    property bool firstSet: leftTimeBorder instanceof Date
    property bool secondSet: rightTimeBorder instanceof Date
    property var firstBorderTime: leftTimeBorder
    property var secondBorderTime: rightTimeBorder

    property alias timelineModelView: tickModel

    signal updateCalendarDT
    signal scaleRequested(int scale)
    signal intervalIndicesRequested(int beforeIndex, int afterIndex)

    Timer {
        interval: 1000
        repeat: true
        onTriggered: root.nowDateTime = new Date()
        Component.onCompleted: start()
    }

    Timer {
        id: rebuildTimer
        interval: 16
        repeat: false
        onTriggered: {
            root.rebuildPending = false
            root.rebuildTicks()
        }
    }

    ListModel {
        id: tickModel
    }

    Rectangle {
        anchors.fill: parent
        color: IVColors.get("Colors/Background new/BgContextMenuThemed")
    }

    Repeater {
        model: tickModel

        Item {
            x: model.x
            width: 1
            height: parent.height

            Label {
                id: tickLabel
                text: model.label
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                font: IVColors.getFont("subtext")
                lineHeight: 14
                lineHeightMode: Text.FixedHeight
                visible: model.label !== ""
            }

            Rectangle {
                width: 1
                height: model.isMinor ? 3 : 6
                anchors.top: tickLabel.bottom
                anchors.horizontalCenter: tickLabel.horizontalCenter
                color: IVColors.get("Colors/Text new/TxSecondaryThemed")
            }
        }
    }

    onLeftTimeBorderChanged: resetViewToBorders()
    onRightTimeBorderChanged: resetViewToBorders()
    onWidthChanged: rebuildTicks()
    onNowDateTimeChanged: nowX = timeToX(nowDateTime)

    onCurrentDateChanged: {
        if (!root.currentDate || !root.currentDate.getTime)
            return
        if (!root.ready)
            return
        if (root.currentDate < root.leftTimeBorder)
            root.currentDate = root.leftTimeBorder
        if (root.currentDate > root.rightTimeBorder)
            root.currentDate = root.rightTimeBorder
        if (root.canAutoMove)
            centerViewOnDate(root.currentDate)
    }

    onCanAutoMoveChanged: {
        if (root.canAutoMove)
            centerViewOnDate(root.currentDate)
    }

    function normalizeBorders() {
        if (!(leftTimeBorder instanceof Date) || isNaN(leftTimeBorder.getTime()))
            return null
        if (!(rightTimeBorder instanceof Date) || isNaN(rightTimeBorder.getTime()))
            return null
        var left = leftTimeBorder
        var right = rightTimeBorder
        if (right < left) {
            var swap = left
            left = right
            right = swap
        }
        return { "left": left, "right": right }
    }

    function normalizeView() {
        var borders = normalizeBorders()
        if (!borders)
            return null
        var left = viewLeftTime instanceof Date && !isNaN(viewLeftTime.getTime()) ? viewLeftTime : borders.left
        var right = viewRightTime instanceof Date && !isNaN(viewRightTime.getTime()) ? viewRightTime : borders.right
        if (right < left) {
            var swap = left
            left = right
            right = swap
        }
        if (left < borders.left)
            left = borders.left
        if (right > borders.right)
            right = borders.right
        if (right < left)
            right = left
        return { "left": left, "right": right, "limits": borders }
    }

    function centerViewOnDate(date) {
        if (!(date instanceof Date) || isNaN(date.getTime()))
            return
        var borders = normalizeBorders()
        if (!borders)
            return
        var normalized = normalizeView()
        var rangeMs = normalized ? normalized.right.getTime() - normalized.left.getTime()
                                 : borders.right.getTime() - borders.left.getTime()
        if (rangeMs <= 0)
            return
        var leftMs = date.getTime() - rangeMs / 2
        var rightMs = leftMs + rangeMs
        var minLeft = borders.left.getTime()
        var maxRight = borders.right.getTime()
        if (leftMs < minLeft) {
            leftMs = minLeft
            rightMs = leftMs + rangeMs
        }
        if (rightMs > maxRight) {
            rightMs = maxRight
            leftMs = rightMs - rangeMs
        }
        viewLeftTime = new Date(leftMs)
        viewRightTime = new Date(rightMs)
        rebuildTicks()
    }

    function scaleRanges() {
        var minuteMs = 60 * 1000
        var hourMs = 60 * minuteMs
        var dayMs = 24 * hourMs
        return {
            "minuteMs": minuteMs,
            "hourMs": hourMs,
            "dayMs": dayMs,
            "weekMs": 7 * dayMs,
            "monthMs": 30 * dayMs,
            "yearMs": 365 * dayMs
        }
    }

    function rangeForModel(model) {
        var ranges = scaleRanges()
        switch (model) {
        case 0:
            return ranges.yearMs
        case 1:
            return ranges.monthMs
        case 2:
            return ranges.weekMs
        case 3:
            return ranges.dayMs
        case 4:
            return ranges.hourMs
        case 5:
            return 30 * ranges.minuteMs
        case 6:
            return 10 * ranges.minuteMs
        case 7:
            return ranges.minuteMs
        default:
            return ranges.weekMs
        }
    }

    function modelForRange(rangeMs) {
        var ranges = scaleRanges()
        if (rangeMs >= ranges.yearMs)
            return 0
        if (rangeMs >= ranges.monthMs)
            return 1
        if (rangeMs >= ranges.weekMs)
            return 2
        if (rangeMs >= ranges.dayMs)
            return 3
        if (rangeMs >= ranges.hourMs)
            return 4
        if (rangeMs >= 30 * ranges.minuteMs)
            return 5
        if (rangeMs >= 10 * ranges.minuteMs)
            return 6
        return 7
    }

    function tickConfigForModel(model) {
        var ranges = scaleRanges()
        switch (model) {
        case 0:
            return { "labelFormat": "MMMM", "mainStepUnit": "month", "baseStepMs": ranges.monthMs }
        case 1:
            return { "labelFormat": "dd.MM", "baseMainStepMs": ranges.dayMs }
        case 2:
            return {
                "labelFormat": "dd.MM",
                "baseMainStepMs": 2 * ranges.dayMs,
                "baseMinorStepMs": ranges.dayMs
            }
        case 3:
            return { "labelFormat": "hh:mm", "baseMainStepMs": ranges.hourMs }
        case 4:
            return {
                "labelFormat": "hh:mm",
                "baseMainStepMs": 2 * ranges.minuteMs,
                "baseMinorStepMs": ranges.minuteMs
            }
        case 5:
            return { "labelFormat": "hh:mm", "baseMainStepMs": ranges.minuteMs }
        case 6:
            return {
                "labelFormat": "hh:mm",
                "baseMainStepMs": 2 * ranges.minuteMs,
                "baseMinorStepMs": ranges.minuteMs
            }
        case 7:
            return {
                "labelFormat": "hh:mm:ss",
                "baseMainStepMs": 10 * 1000,
                "baseMinorStepMs": 1000,
                "minSpacing": 120
            }
        default:
            return { "labelFormat": "dd.MM", "baseMainStepMs": ranges.dayMs }
        }
    }

    function labelForDate(date, format) {
        return Qt.formatDateTime(date, format)
    }

    function alignToStep(date, stepMs) {
        var alignedMs = Math.floor(date.getTime() / stepMs) * stepMs
        return new Date(alignedMs)
    }

    function alignToMonth(date) {
        return new Date(date.getFullYear(), date.getMonth(), 1, 0, 0, 0, 0)
    }

    function addMonths(date, count) {
        return new Date(date.getFullYear(), date.getMonth() + count, 1, 0, 0, 0, 0)
    }

    function pickStepMultiplier(rangeMs, baseStepMs, minSpacing) {
        var spacing = minSpacing || 90
        var maxTicks = Math.max(2, Math.floor(root.width / spacing))
        var desiredStep = rangeMs / maxTicks
        var multipliers = [1, 2, 5, 10, 20, 50]
        for (var i = 0; i < multipliers.length; i++) {
            if (baseStepMs * multipliers[i] >= desiredStep)
                return multipliers[i]
        }
        return multipliers[multipliers.length - 1]
    }

    function rebuildTicks() {
        var normalized = normalizeView()
        if (!normalized || root.width <= 0) {
            tickModel.clear()
            root.viewBounds = { "left": null, "right": null }
            root.bounds = { "first": null, "second": null }
            root.ready = false
            root.nowX = 0
            return
        }

        var left = normalized.left
        var right = normalized.right
        var rangeMs = right.getTime() - left.getTime()
        if (rangeMs <= 0) {
            tickModel.clear()
            root.viewBounds = { "left": left, "right": right }
            root.bounds = { "first": left, "second": right }
            root.ready = false
            return
        }

        var resolvedModel = modelForRange(rangeMs)
        if (resolvedModel !== root.timeline_model)
            root.timeline_model = resolvedModel
        var config = tickConfigForModel(root.timeline_model)

        tickModel.clear()

        var endMs = right.getTime()
        if (config.mainStepUnit === "month") {
            var startDate = alignToMonth(left)
            var monthStep = config.baseStepMs ? pickStepMultiplier(rangeMs, config.baseStepMs, config.minSpacing) : 1
            while (startDate.getTime() < left.getTime())
                startDate = addMonths(startDate, monthStep)
            var cursor = startDate
            while (cursor.getTime() <= endMs) {
                var ratio = (cursor.getTime() - left.getTime()) / rangeMs
                var xPos = ratio * root.width
                tickModel.append({
                    "x": xPos,
                    "label": labelForDate(cursor, config.labelFormat),
                    "isMinor": false
                })
                cursor = addMonths(cursor, monthStep)
            }
        } else {
            var stepMultiplier = config.lockStep ? 1 : pickStepMultiplier(rangeMs, config.baseMainStepMs, config.minSpacing)
            var mainStepMs = config.baseMainStepMs ? config.baseMainStepMs * stepMultiplier : null
            var minorStepMs = config.baseMinorStepMs
                ? config.baseMinorStepMs * stepMultiplier
                : mainStepMs
            var start = alignToStep(left, minorStepMs)
            while (start.getTime() < left.getTime())
                start = new Date(start.getTime() + minorStepMs)
            for (var t = start.getTime(); t <= endMs; t += minorStepMs) {
                if (t < left.getTime())
                    continue
                var isMain = mainStepMs ? (t % mainStepMs === 0) : true
                var ratio = (t - left.getTime()) / rangeMs
                var xPos = ratio * root.width
                tickModel.append({
                    "x": xPos,
                    "label": isMain ? labelForDate(new Date(t), config.labelFormat) : "",
                    "isMinor": !isMain
                })
            }
        }

        root.viewBounds = { "left": left, "right": right }
        root.bounds = { "first": left, "second": right }
        root.ready = true
        root.nowX = timeToX(root.nowDateTime)

        if (!root.currentDate || !root.currentDate.getTime)
            root.currentDate = left
    }

    function scheduleRebuild() {
        if (root.rebuildPending)
            return
        root.rebuildPending = true
        rebuildTimer.restart()
    }

    function setBounds(first, second) {
        leftTimeBorder = first
        rightTimeBorder = second
    }

    function getSelectedInterval() {
        var first = bounds.first
        var second = bounds.second
        return { "left": Math.min(first, second), "right": Math.max(first, second) }
    }

    function getViewBounds() {
        return { "left": viewLeftTime, "right": viewRightTime }
    }

    function viewportOffset() {
        return 0
    }

    function updateViewBounds() {
        var normalized = normalizeView()
        if (!normalized) {
            viewBounds = { "left": null, "right": null }
            return
        }
        viewBounds = { "left": normalized.left, "right": normalized.right }
    }

    function startExternalDrag() {
        externalDragging = true
        root.canAutoMove = false
    }

    function dragTimelineBy(deltaX) {
        if (!root.ready || !isFinite(deltaX))
            return
        var normalized = normalizeView()
        if (!normalized)
            return
        var left = normalized.left
        var right = normalized.right
        var rangeMs = right.getTime() - left.getTime()
        if (rangeMs <= 0 || root.width <= 0)
            return
        var deltaMs = -deltaX / root.width * rangeMs
        var nextLeft = new Date(left.getTime() + deltaMs)
        var nextRight = new Date(right.getTime() + deltaMs)
        var limits = normalized.limits
        if (nextLeft < limits.left) {
            var shiftLeft = limits.left.getTime() - nextLeft.getTime()
            nextLeft = new Date(nextLeft.getTime() + shiftLeft)
            nextRight = new Date(nextRight.getTime() + shiftLeft)
        }
        if (nextRight > limits.right) {
            var shiftRight = limits.right.getTime() - nextRight.getTime()
            nextLeft = new Date(nextLeft.getTime() + shiftRight)
            nextRight = new Date(nextRight.getTime() + shiftRight)
        }
        viewLeftTime = nextLeft
        viewRightTime = nextRight
        scheduleRebuild()
    }

    function endExternalDrag() {
        externalDragging = false
    }

    function scaleForOffsets(beforeMs, afterMs) {
        return root.timeline_model
    }

    function setScale(new_timeline_model) {
        var normalized = normalizeView()
        if (!normalized)
            return
        var left = normalized.left
        var right = normalized.right
        var rangeMs = right.getTime() - left.getTime()
        if (rangeMs <= 0)
            return
        var targetRange = rangeForModel(new_timeline_model)
        var anchorRatio = root.width > 0 ? 0.5 : 0.5
        var anchorMs = left.getTime() + anchorRatio * rangeMs
        var nextLeftMs = anchorMs - anchorRatio * targetRange
        var nextRightMs = nextLeftMs + targetRange
        var limits = normalized.limits
        if (nextLeftMs < limits.left.getTime()) {
            nextLeftMs = limits.left.getTime()
            nextRightMs = nextLeftMs + targetRange
        }
        if (nextRightMs > limits.right.getTime()) {
            nextRightMs = limits.right.getTime()
            nextLeftMs = nextRightMs - targetRange
        }
        viewLeftTime = new Date(nextLeftMs)
        viewRightTime = new Date(nextRightMs)
        root.timeline_model = new_timeline_model
        rebuildTicks()
    }

    function getCurrDateIndex(today) {
        return 0
    }

    function incrementDate(view, date) {
        var minute = date.getMinutes()
        var hour = date.getHours()
        var day = date.getDate()
        var month = date.getMonth()
        var year = date.getFullYear()
        var new_date

        switch (view) {
        case 0:
            new_date = new Date(year + 1, 0, 1, 0, 0, 0, 0, 0, 0)
            return new_date
        case 1:
            new_date = new Date(year, month + 1, 1, 0, 0, 0, 0, 0)
            return new_date
        case 2:
            new_date = new Date(year, month, day + 7, 0, 0, 0, 0)
            return new_date
        case 3:
            new_date = new Date(year, month, day + 1, 0, 0, 0, 0)
            return new_date
        case 4:
            new_date = new Date(year, month, day, hour + 1, 0, 0, 0, 0, 0)
            return new_date
        case 5:
            minute = Math.floor(minute / 30) * 30
            new_date = new Date(year, month, day, hour, minute + 30, 0, 0, 0, 0)
            return new_date
        case 6:
            minute = Math.floor(minute / 10) * 10
            new_date = new Date(year, month, day, hour, minute + 10, 0, 0, 0, 0)
            return new_date
        case 7:
            new_date = new Date(year, month, day, hour, minute + 1, 0, 0)
            return new_date
        }
    }

    function decrementDate(view, date) {
        var minute = date.getMinutes()
        var hour = date.getHours()
        var day = date.getDate()
        var month = date.getMonth()
        var year = date.getFullYear()
        var new_date

        switch (view) {
        case 0:
            new_date = new Date(year - 1, 0, 1, 0, 0, 0, 0, 0, 0)
            return new_date
        case 1:
            new_date = new Date(year, month - 1, 1, 0, 0, 0, 0, 0)
            return new_date
        case 2:
            new_date = new Date(year, month, day - 7, 0, 0, 0, 0)
            return new_date
        case 3:
            new_date = new Date(year, month, day - 1, 0, 0, 0, 0)
            return new_date
        case 4:
            new_date = new Date(year, month, day, hour - 1, 0, 0, 0)
            return new_date
        case 5:
            minute = Math.floor(minute / 30) * 30
            new_date = new Date(year, month, day, hour, minute - 30, 0, 0, 0, 0)
            return new_date
        case 6:
            minute = Math.floor(minute / 10) * 10
            new_date = new Date(year, month, day, hour, minute - 10, 0, 0, 0, 0)
            return new_date
        case 7:
            new_date = new Date(year, month, day, hour, minute - 1, 0, 0)
            return new_date
        }
    }

    function xToTime(posX) {
        var normalized = normalizeView()
        if (!normalized || root.width <= 0)
            return new Date(0)
        var ratio = Math.max(0, Math.min(posX / root.width, 1))
        var timeMs = normalized.left.getTime() + ratio * (normalized.right.getTime() - normalized.left.getTime())
        return new Date(timeMs)
    }

    function timeToX(date) {
        var normalized = normalizeView()
        if (!normalized || root.width <= 0 || !date || !date.getTime)
            return 0
        var ratio = (date.getTime() - normalized.left.getTime()) / (normalized.right.getTime() - normalized.left.getTime())
        return ratio * root.width
    }

    function resetViewToBorders() {
        var borders = normalizeBorders()
        if (!borders) {
            viewLeftTime = null
            viewRightTime = null
            rebuildTicks()
            return
        }
        viewLeftTime = borders.left
        viewRightTime = borders.right
        rebuildTicks()
    }

    function zoomBy(deltaY, anchorX) {
        if (!root.ready || !isFinite(deltaY))
            return
        var normalized = normalizeView()
        if (!normalized)
            return
        var left = normalized.left
        var right = normalized.right
        var limits = normalized.limits
        var rangeMs = right.getTime() - left.getTime()
        if (rangeMs <= 0)
            return
        var steps = deltaY / 120
        if (steps === 0)
            return
        var zoomFactor = Math.pow(0.9, steps)
        var nextRange = Math.max(1000, rangeMs * zoomFactor)
        var maxRange = Math.min(rangeForModel(0), limits.right.getTime() - limits.left.getTime())
        if (nextRange > maxRange)
            nextRange = maxRange
        var minRange = rangeForModel(7)
        if (nextRange < minRange)
            nextRange = minRange
        var anchorRatio = root.width > 0 ? Math.max(0, Math.min(anchorX / root.width, 1)) : 0.5
        var anchorMs = left.getTime() + anchorRatio * rangeMs
        var nextLeftMs = anchorMs - anchorRatio * nextRange
        var nextRightMs = nextLeftMs + nextRange
        if (nextLeftMs < limits.left.getTime()) {
            nextLeftMs = limits.left.getTime()
            nextRightMs = nextLeftMs + nextRange
        }
        if (nextRightMs > limits.right.getTime()) {
            nextRightMs = limits.right.getTime()
            nextLeftMs = nextRightMs - nextRange
        }
        viewLeftTime = new Date(nextLeftMs)
        viewRightTime = new Date(nextRightMs)
        rebuildTicks()
    }
}

import QtQuick 2.7
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtQml 2.3

import iv.colors 1.0
import iv.singletonLang 1.0
import iv.controls 1.0 as C

Row {
    id: root

    property var archiveStreamer
    property real playbackSpeed: 1.0
    property int  direction: 0
    property bool archiveIsPlaying: archiveStreamer ? !archiveStreamer.paused : false
    property var  archiveTime
    property bool needToUpdateArchive: true
    property string cameraId
    property string archiveId

    readonly property bool hasArchiveTargets: archiveStreamer && (archiveStreamer.hasPlayers !== undefined
                                                    ? archiveStreamer.hasPlayers
                                                    : (!!root.cameraId && !!root.archiveId))

    signal clearPendingUpdate()

    spacing: 1

    onArchiveIsPlayingChanged: {
        if (!archiveIsPlaying) {
            direction = 0
            return
        }

        if (archiveStreamer && archiveStreamer.playbackSpeed !== undefined) {
            if (archiveStreamer.playbackSpeed < 0)
                direction = -1
            else if (archiveStreamer.playbackSpeed > 0)
                direction = 1
        }
    }

    onPlaybackSpeedChanged: {
        if (speedPopup && speedPopup.dragging) return
        _commitPlaybackSpeed()
    }

    function _effectiveSpeed() {
        return direction * playbackSpeed
    }

    function _ensureStartedOrResumed() {
        if (root.needToUpdateArchive) {
            archiveStreamer.startStreamAt(cameraId, archiveTime, archiveId)
            root.clearPendingUpdate()
        } else {
            archiveStreamer.resumeStream()
        }
    }

    function _commitPlaybackSpeed() {
        archiveStreamer.playbackSpeed = _effectiveSpeed()
        if (archiveIsPlaying) {
            _ensureStartedOrResumed()
        }
    }

    function _playForward() {
        direction = 1
        archiveStreamer.playbackSpeed = _effectiveSpeed()
        _ensureStartedOrResumed()
    }

    function _playBackward() {
        direction = -1
        archiveStreamer.playbackSpeed = _effectiveSpeed()
        _ensureStartedOrResumed()
    }

    function _pause() {
        direction = 0
        archiveStreamer.pauseStream()
    }

    C.IVButtonControl {
        id: btnBackward

        width: 24
        height: 24
        radius: 0
        topLeftRadius: 4
        bottomLeftRadius: 4
        iconDirection: C.IVButtonControl.Direction.Up
        size: C.IVButtonControl.Size.Small
        type: C.IVButtonControl.Type.Secondary
        checkable: true
        checked: root.direction < 0
        enabled: (root.playbackSpeed > 0) && root.hasArchiveTargets
        source: "new_images/" + (checked ? "pause" : "play")
        toolTipText: checked
                     ? Language.getTranslate("Pause", "Пауза")
                     : Language.getTranslate("Reverse playback", "Проигрывание назад")

        onClicked: {
            if (!enabled) return
            if (root.direction === -1) root._pause()
            else root._playBackward()
        }
    }

    C.IVButtonControl {
        id: speedBtn

        width: 40
        height: 24
        radius: 0
        size: C.IVButtonControl.Size.Small
        type: C.IVButtonControl.Type.Secondary
        checkable: true
        text: "x" + root.playbackSpeed.toFixed(2)
        checked: speedPopup.opened
        onClicked: speedPopup.opened ? speedPopup.close() : speedPopup.open()

        Popup {
            id: speedPopup

            property var marks:  [0, 0.5, 1, 2, 4]
            property bool dragging: false
            readonly property int segments: marks.length - 1

            x: (parent.width - width)/2
            y: -height - 8
            width: 350
            height: 32
            closePolicy: Popup.CloseOnPressOutsideParent | Popup.CloseOnReleaseOutsideParent

            onClosed: {
                if (dragging) {
                    dragging = false
                    root._commitPlaybackSpeed()
                }
            }

            background: Rectangle {
                anchors.fill: parent
                radius: 80
                color: IVColors.get("Colors/Background new/BgFormOverVideo")
            }

            contentItem: Rectangle {
                id: body
                anchors.fill: parent
                anchors.margins: 8
                radius: 4
                color: IVColors.get("Colors/Background new/BgFormSecondaryThemed")

                RowLayout {
                    anchors.fill: parent
                    spacing: 1
                    Repeater {
                        model: speedPopup.marks
                        delegate: Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font: IVColors.getFont("Subtext")
                                color: IVColors.get("Colors/Text new/TxContrast")
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                Rectangle {
                    id: ind
                    height: 24
                    width: body.width / speedPopup.marks.length + 8
                    radius: 4
                    color: IVColors.get("Colors/Background new/BgBtnPrimary")
                    anchors.verticalCenter: parent.verticalCenter
                    x: speedPopup.speedToX(root.playbackSpeed)

                    Row {
                        anchors.centerIn: parent
                        spacing: 2

                        C.IVImage {
                            name: "new_images/play"
                            height: 16
                            width: height
                            color: IVColors.get("Colors/Text new/TxContrast")
                        }

                        Text {
                            text: root.playbackSpeed.toFixed(2)
                            font: IVColors.getFont("Subtext accent")
                            color: IVColors.get("Colors/Text new/TxContrast")
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        drag.target: ind
                        drag.threshold: 0
                        drag.minimumX: 0
                        drag.maximumX: body.width - ind.width

                        onPressed: speedPopup.dragging = true
                        onReleased: {
                            speedPopup.dragging = false
                            root._commitPlaybackSpeed()
                        }
                        onCanceled: {
                            speedPopup.dragging = false
                            root._commitPlaybackSpeed()
                        }
                        onPositionChanged: {
                            root.playbackSpeed = speedPopup.xToSpeed(ind.x)
                        }
                    }

                    Binding {
                        target: ind
                        property: "x"
                        value: speedPopup.speedToX(root.playbackSpeed)
                        when: !speedPopup.dragging
                    }
                }
            }

            function xToSpeed(xPos) {
                const travel = body.width - ind.width
                if (travel <= 0) return marks[0]
                const pos = xPos / travel
                const segPos = pos * segments
                let idx = Math.floor(segPos)

                if (idx < 0) idx = 0
                if (idx >= segments) idx = segments - 1

                const t = segPos - idx
                const from = marks[idx]
                const to = marks[idx + 1]
                return from + (to - from) * t
            }

            function speedToX(speed) {
                const travel = body.width - ind.width
                if (travel <= 0) return 0
                if (speed <= marks[0]) return 0
                if (speed >= marks[marks.length - 1]) return travel

                let i = 0
                while (i < segments && speed > marks[i + 1]) ++i
                const from = marks[i]
                const to = marks[i + 1]
                const t = (speed - from) / (to - from)
                return travel * ((i + t) / segments)
            }
        }
    }

    C.IVButtonControl {
        id: btnForward

        width: 24
        height: 24
        radius: 0
        topRightRadius: 4
        bottomRightRadius: 4
        size: C.IVButtonControl.Size.Small
        type: C.IVButtonControl.Type.Secondary
        checkable: true

        checked: root.direction > 0
        enabled: (root.playbackSpeed > 0) && root.hasArchiveTargets

        source: "new_images/" + (checked ? "pause" : "play")
        toolTipText: checked
                     ? Language.getTranslate("Pause", "Пауза")
                     : Language.getTranslate("Archive playback", "Проигрывание вперёд")

        onClicked: {
            if (!enabled) return
            if (root.direction === 1) root._pause()
            else root._playForward()
        }
    }
}

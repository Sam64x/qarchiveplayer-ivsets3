import QtQml 2.3
import QtQuick 2.11
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

import iv.viewers.archiveplayer 1.0 as ArchivePlayer
import iv.singletonLang 1.0
import iv.controls 1.0 as C

Item {
    id: root

    property var players: []
    property var playersCount: Math.max(1, players.length)
    property var archivePlayers: []
    property real isize: 1

    property var sharedCurrentDate: null
    property bool suppressTimeUpdates: false
    property bool needToUpdateArchive: true
    property bool isIntervalMode: false
    property var primarySlider: null
    property int commonScale: 0
    property bool hasFullscreenPlayer: false

    readonly property var primaryPlayer: archivePlayers.length > 0 ? archivePlayers[0] : null
    readonly property var primaryImagePipeline: primaryPlayer ? (primaryPlayer.imagePipeline || (primaryPlayer.idarchive_player && primaryPlayer.idarchive_player.imagePipeline) || null)  : null
    readonly property bool hasMultiplePlayers: archivePlayers.length > 1

    readonly property bool archiveIsPlaying: !multiArchiveStreamer.paused

    readonly property var rootRef: primaryPlayer ? primaryPlayer : null
    readonly property string archiveId: primaryPlayer && primaryPlayer.archiveId ? primaryPlayer.archiveId : ""
    readonly property string cameraId: primaryPlayer && primaryPlayer.cameraId ? primaryPlayer.cameraId : ""

    height: playersCount * (32 + 4) + 90 + 8

    ListModel { id: emptyModel }

    property var  _masterPlayhead: null
    property real _masterLastTickMs: 0
    property int  _masterTickIntervalMs: 40

    Timer {
        id: _masterSyncTimer
        interval: root._masterTickIntervalMs
        repeat: true
        running: false
        onTriggered: root._masterTick()
    }

    function _setMasterPlayhead(dt) {
        if (!dt) return
        if (dt.getTime) root._masterPlayhead = new Date(dt.getTime())
        else root._masterPlayhead = new Date(dt)
    }

    function _startMasterClock(optionalDt) {
        if (optionalDt) _setMasterPlayhead(optionalDt)
        if (!root._masterPlayhead && sharedCurrentDate)
            _setMasterPlayhead(sharedCurrentDate)
        root._masterLastTickMs = Date.now()
        _masterSyncTimer.start()
    }

    function _stopMasterClock() {
        _masterSyncTimer.stop()
        root._masterLastTickMs = 0
    }

    function _masterTick() {
        if (!multiArchiveStreamer.hasPlayers) return

        if (!root._masterPlayhead) {
            if (sharedCurrentDate) _setMasterPlayhead(sharedCurrentDate)
            else root._masterPlayhead = new Date()
        }

        var now = Date.now()
        if (!root._masterLastTickMs) root._masterLastTickMs = now
        var dt = now - root._masterLastTickMs
        root._masterLastTickMs = now

        var spd = Number(multiArchiveStreamer.playbackSpeed)
        if (isNaN(spd)) spd = 1

        if (dt > 0 && spd !== 0)
            root._masterPlayhead = new Date(root._masterPlayhead.getTime() + dt * spd)

        multiArchiveStreamer.syncTo(root._masterPlayhead)
    }

    function forEachPlayer(callback) {
        for (var i = 0; i < archivePlayers.length; ++i) {
            if (archivePlayers[i])
                callback(archivePlayers[i]);
        }
    }

    signal requestIntervalSync(var bounds)

    function currentFrameTime() {
        if (primaryPlayer && primaryPlayer.getFrameTime)
            return primaryPlayer.getFrameTime();
        return 0;
    }

    function currentIntervalBounds() {
        return primarySlider ? primarySlider.getSelectedInterval() : null;
    }

    function syncPrimaryPlayer() {
        if (!primaryPlayer) {
            if (primarySlider) {
                primarySlider.archivePlayer = null;
                primarySlider.key2 = '';
            }
            return;
        }

        if (primarySlider) {
            primarySlider.archivePlayer = primaryPlayer.idarchive_player;
            primarySlider.key2 = primaryPlayer.key2;
        }

        if (primaryPlayer.m_i_curr_scale !== undefined)
            commonScale = primaryPlayer.m_i_curr_scale;

        applyScaleToPlayers(commonScale);

        var frameTime = currentFrameTime();
        if (frameTime > 0) {
            sharedCurrentDate = new Date(frameTime);
            if (primarySlider)
                primarySlider.currentDate = sharedCurrentDate;
        }
    }

    function isArchivePlayerMin(candidate) {
        if (!candidate)
            return false;

        return candidate.idarchive_player !== undefined;
    }

    function sanitizePlayersList(source) {
        var list = [];
        if (!source)
            return list;

        var iterable = Array.isArray(source) ? source : [source];
        for (var i = 0; i < iterable.length; ++i) {
            var candidate = iterable[i];
            if (isArchivePlayerMin(candidate))
                list.push(candidate);
        }
        return list;
    }

    onPlayersChanged: {
        var sanitized = sanitizePlayersList(players);
        archivePlayers = sanitized.length === 0 && players && players.length ? players : sanitized;
        syncPrimaryPlayer();
        updateIntervalMode();
        updateFullscreenState();
    }

    function updateIntervalMode() {
        var inInterval = false;
        forEachPlayer(function(player) {
            if (player.isIntervalMode)
                inInterval = true;
        });
        isIntervalMode = inInterval;
    }

    function applyScaleToPlayers(scaleIndex) {
        commonScale = scaleIndex;
        forEachPlayer(function(player) {
            if (player.m_i_curr_scale !== undefined)
                player.m_i_curr_scale = scaleIndex;
        });

        if (commonTimeline && commonTimeline.setScale)
            commonTimeline.setScale(scaleIndex);
    }

    function updateFullscreenState() {
        var fullscreen = false;
        forEachPlayer(function(player) {
            if (player && player.isFullscreen)
                fullscreen = true;
        });
        hasFullscreenPlayer = fullscreen;
    }


    function setCalendarTime(time) {
        if (!time || suppressTimeUpdates)
            return;

        suppressTimeUpdates = true;
        if (archiveControls && archiveControls.calendarButton) {
            archiveControls.calendarButton.calendar.chosenDate = Qt.formatDate(time, "dd.MM.yyyy");
            archiveControls.calendarButton.calendar.chosenTime = Qt.formatTime(time, "hh:mm:ss");
        }
        suppressTimeUpdates = false;
    }

    function updatePlayersArchiveTime(time) {
        sharedCurrentDate = time;
        forEachPlayer(function(player) {
            if (player.applyCommonCurrentDate)
                player.applyCommonCurrentDate(time);
            else if (player.idarchive_player)
                player.idarchive_player.currentDate = time;

            if (player.archiveTime !== undefined)
                player.archiveTime = time;
            if (player.needToUpdateArchive !== undefined)
                player.needToUpdateArchive = true;
        });
    }

    function updateTimeFromCalendar() {
        if (suppressTimeUpdates)
            return;

        var chosenDateTime = archiveControls.calendarButton.calendar.chosenDate + " " + archiveControls.calendarButton.calendar.chosenTime;
        var time = Date.fromLocaleString(Qt.locale(), chosenDateTime, "dd.MM.yyyy hh:mm:ss");
        if (primarySlider)
            primarySlider.currentDate = time;
        updatePlayersArchiveTime(time);
        multiArchiveStreamer.requestPreviewAt(cameraId, time, archiveId);
        needToUpdateArchive = true;
    }

    function updateTimeFromSlider() {
        if (suppressTimeUpdates)
            return;

        var time = primarySlider ? primarySlider.currentDate : sharedCurrentDate;
        suppressTimeUpdates = true;
        setCalendarTime(time);
        suppressTimeUpdates = false;
        updatePlayersArchiveTime(time);

        if (multiArchiveStreamer.paused) {
            multiArchiveStreamer.requestPreviewAt(cameraId, time, archiveId);
            needToUpdateArchive = true;
        } else {
            multiArchiveStreamer.delayStart(cameraId, time, archiveId);
        }
    }

    function toggleIntervalMode() {
        forEachPlayer(function(player) {
            if (player.funcSwitchSelectIntervalMode)
                player.funcSwitchSelectIntervalMode();
        });
        updateIntervalMode();
    }

    QtObject {
        id: multiArchiveStreamer

        property bool paused: {
            var hasStream = false;
            var allPaused = true;
            forEachPlayer(function(player) {
                if (player.archiveStreamer) {
                    hasStream = true;
                    allPaused = allPaused && player.archiveStreamer.paused;
                }
            });
            return hasStream ? allPaused : true;
        }

        readonly property bool hasPlayers: archivePlayers.length > 0

        function enableExternalClock(enabled) {
            forEachPlayer(function(player) {
                if (player && player.archiveStreamer)
                    player.archiveStreamer.externalClock = enabled
            })
        }

        function syncTo(atLocalTime) {
            forEachPlayer(function(player) {
                if (player && player.archiveStreamer && player.archiveStreamer.externalSync)
                    player.archiveStreamer.externalSync(atLocalTime)
            })
        }

        property real playbackSpeed: primaryPlayer && primaryPlayer.archiveStreamer ? primaryPlayer.archiveStreamer.playbackSpeed : 1
        property bool exporting: primaryPlayer && primaryPlayer.archiveStreamer ? primaryPlayer.archiveStreamer.exporting : false

        onPlaybackSpeedChanged: {
            forEachPlayer(function(player) {
                if (player.archiveStreamer)
                    player.archiveStreamer.playbackSpeed = playbackSpeed;
            });
        }

        function pauseStream() {
            var playhead = root._masterPlayhead || sharedCurrentDate
            if (playhead)
                syncTo(playhead)
            _stopMasterClock()
            forEachPlayer(function(player) {
                if (player.archiveStreamer)
                    player.archiveStreamer.pauseStream();
            });
        }

        function resumeStream() {
            enableExternalClock(true)
            forEachPlayer(function(player) {
                if (player.archiveStreamer)
                    player.archiveStreamer.resumeStream();
            });
            _startMasterClock()
            needToUpdateArchive = false;
        }

        function startStreamAt(cameraId, time, archiveId) {
            var targetTime = time || sharedCurrentDate
            enableExternalClock(true)
            _startMasterClock(targetTime)
            forEachPlayer(function(player) {
                if (player.archiveStreamer)
                    player.archiveStreamer.startStreamAt(player.cameraId, targetTime, player.archiveId);
                if (player.needToUpdateArchive !== undefined)
                    player.needToUpdateArchive = false;
            });
            needToUpdateArchive = false;
        }

        function delayStart(cameraId, time, archiveId) {
            var targetTime = time || sharedCurrentDate
            enableExternalClock(true)
            _startMasterClock(targetTime)
            forEachPlayer(function(player) {
                if (player.archiveStreamer && player.archiveStreamer.delayStart)
                    player.archiveStreamer.delayStart(player.cameraId, targetTime, player.archiveId);
            });
            needToUpdateArchive = false;
        }

        function requestPreviewAt(cameraId, time, archiveId) {
            var targetTime = time || sharedCurrentDate
            _stopMasterClock()
            _setMasterPlayhead(targetTime)
            forEachPlayer(function(player) {
                if (player.archiveStreamer)
                    player.archiveStreamer.requestPreviewAt(player.cameraId, targetTime, player.archiveId);
            });
        }

        function stepFrameLeft() {
            forEachPlayer(function(player) {
                if (player.archiveStreamer && player.archiveStreamer.stepFrameLeft)
                    player.archiveStreamer.stepFrameLeft();
            });
        }

        function stepFrameRight() {
            forEachPlayer(function(player) {
                if (player.archiveStreamer && player.archiveStreamer.stepFrameRight)
                    player.archiveStreamer.stepFrameRight();
            });
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        visible: true

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 8
            spacing: 8 * root.isize

            ArchiveControls {
                id: archiveControls

                implicitHeight: 32 - parent.spacing*2
                Layout.alignment: Qt.AlignHCenter

                m_i_curr_scale: root.commonScale
                needToUpdateArchive: root.needToUpdateArchive
                archiveId: root.archiveId
                rootRef: root.rootRef
                imagePipeline: root.primaryImagePipeline
                cameraId: root.cameraId
                isIntervalMode: root.isIntervalMode
                archiveTime: root.sharedCurrentDate
                isCommonSets: true
                iv_arc_slider_new: primarySlider
                archiveStreamer: multiArchiveStreamer
                updateTimeFromSlider: root.updateTimeFromSlider
                updateTimeFromCalendar: root.updateTimeFromCalendar
                funcSwitchSelectIntervalMode: root.toggleIntervalMode

                onScaleChosen: root.applyScaleToPlayers(index)
                onClearPendingUpdate: {
                    root.needToUpdateArchive = false;
                    forEachPlayer(function(player) {
                        if (player.needToUpdateArchive !== undefined)
                            player.needToUpdateArchive = false;
                    });
                }
            }

            ColumnLayout {
                id: sliderStack

                width: parent.width
                spacing: 4

                CommonArchiveTimeline {
                    id: commonTimeline

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    isize: root.isize
                    players: root.archivePlayers
                    commonScale: root.commonScale
                    sharedCurrentDate: root.sharedCurrentDate

                    onTimeChanged: {
                        if (!date)
                            return;
                        root.sharedCurrentDate = date
                        root.updatePlayersArchiveTime(date)
                        root.setCalendarTime(date)
                        root.updateTimeFromSlider()
                    }

                    onBoundsChanged: {
                        var intervalBounds = bounds
                        forEachPlayer(function(player) {
                            if (player.applyCommonBounds)
                                player.applyCommonBounds(intervalBounds)
                            else if (player) {
                                var left = intervalBounds.left - intervalBounds.left % 1000
                                var right = intervalBounds.right - intervalBounds.right % 1000
                                if (player.m_uu_i_ms_begin_interval !== undefined)
                                    player.m_uu_i_ms_begin_interval = left
                                if (player.m_uu_i_ms_end_interval !== undefined)
                                    player.m_uu_i_ms_end_interval = right
                            }
                        });
                    }

                    Component.onCompleted: root.primarySlider = commonTimeline.slider
                }

                Binding {
                    target: root
                    property: "primarySlider"
                    value: commonTimeline ? commonTimeline.slider : null
                }
            }
        }
    }

    Component.onCompleted: {
        syncPrimaryPlayer()
        updateFullscreenState()
    }
}

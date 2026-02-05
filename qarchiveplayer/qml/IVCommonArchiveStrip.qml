import QtQml 2.3
import QtQuick 2.11
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

import iv.colors 1.0
import iv.plugins.loader 1.0
import iv.viewers.archiveplayer 1.0 as ArchivePlayer
import iv.singletonLang 1.0
import iv.controls 1.0 as C

Item {
    id: root

    property var players: []
    property int playersCount: Math.max(1, players.length)
    property var archivePlayers: []

    property var sharedCurrentDate: null
    property bool suppressTimeUpdates: false
    property bool needToUpdateArchive: true
    property bool isIntervalMode: false
    property var primarySlider: null
    property int commonScale: validateSettings(stripScale.value) !== null ? validateSettings(stripScale.value) : 4

    IvVcliSetting {
        id: stripScale
        name: 'archive.strip_scale'
    }

    function validateSettings(value){
        try {
            return JSON.parse(value)
        } catch (e) {
            return null
        }
    }
    onCommonScaleChanged: {
        if (commonTimeline && commonTimeline.setScale) {
            commonTimeline.setScale(commonScale);
        }
    }
    property bool hasFullscreenPlayer: false
    property bool _suppressArchiveTimeSync: false
    property real _stepSyncStartMs: 0
    property real _stepSyncLastFrameMs: 0

    readonly property var primaryPlayer: archivePlayers.length > 0 ? archivePlayers[0] : null
    readonly property var primaryImagePipeline: primaryPlayer ? (primaryPlayer.imagePipeline || (primaryPlayer.idarchive_player && primaryPlayer.idarchive_player.imagePipeline) || null)  : null
    readonly property bool hasMultiplePlayers: archivePlayers.length > 1

    readonly property bool archiveIsPlaying: !multiArchiveStreamer.paused
    readonly property int visiblePlayersCount: Math.min(playersCount, 4)

    property var rootRef
    readonly property string archiveId: primaryPlayer && primaryPlayer.archiveId ? primaryPlayer.archiveId : ""
    readonly property string cameraId: primaryPlayer && primaryPlayer.cameraId ? primaryPlayer.cameraId : ""

    height: visiblePlayersCount * (32 + 4) + 90 + 8

    property var  _masterPlayhead: null

    ArchivePlayer.PlaybackCoordinator {
        id: playbackCoordinator
    }

    Timer {
        id: _stepSyncTimer
        interval: 30
        repeat: true
        running: false
        onTriggered: root._stepSyncTick()
    }

    function _setMasterPlayhead(dt) {
        if (!dt) return
        if (dt.getTime) root._masterPlayhead = new Date(dt.getTime())
        else root._masterPlayhead = new Date(dt)
    }

    function _primaryFrameTimeMs() {
        if (!primaryPlayer || !primaryPlayer.getFrameTime)
            return 0
        var t = Number(primaryPlayer.getFrameTime())
        return isNaN(t) ? 0 : t
    }

    function _stepSyncTick() {
        if (!root.hasMultiplePlayers) {
            _stepSyncTimer.stop()
            return
        }
        var now = Date.now()
        var currentMs = _primaryFrameTimeMs()
        if (currentMs > 0 && currentMs !== _stepSyncLastFrameMs) {
            _stepSyncTimer.stop()
            multiArchiveStreamer.syncStepToMs(currentMs)
            return
        }
        if (now - _stepSyncStartMs > 1500) {
            _stepSyncTimer.stop()
            if (currentMs > 0)
                multiArchiveStreamer.syncStepToMs(currentMs)
        }
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

        if (primaryPlayer.archiveStreamer)
            playbackCoordinator.playbackSpeed = primaryPlayer.archiveStreamer.playbackSpeed;

        var initialDate = null
        if (primaryPlayer.archiveTime instanceof Date && !isNaN(primaryPlayer.archiveTime.getTime()))
            initialDate = primaryPlayer.archiveTime
        else {
            var frameTime = currentFrameTime();
            if (frameTime > 0)
                initialDate = new Date(frameTime);
        }
        if (initialDate) {
            updateSharedCurrentDate(initialDate);
            if (primarySlider)
                primarySlider.currentDate = initialDate;
        }

        syncFromPrimaryArchiveTime();
    }

    function isArchivePlayerMin(candidate) {
        if (!candidate)
            return false;

        return candidate.idarchive_player !== undefined;
    }

    function normalizePlayersList(source) {
        var list = [];
        if (!source)
            return list;

        if (Array.isArray(source))
            return source;

        if (source.count !== undefined && source.get !== undefined) {
            for (var i = 0; i < source.count; ++i)
                list.push(source.get(i));
            return list;
        }

        if (source.length !== undefined) {
            for (var j = 0; j < source.length; ++j)
                list.push(source[j]);
            return list;
        }

        list.push(source);
        return list;
    }

    function sanitizePlayersList(source) {
        var list = [];
        if (!source)
            return list;

        for (var i = 0; i < source.length; ++i) {
            var candidate = source[i];
            if (isArchivePlayerMin(candidate))
                list.push(candidate);
        }
        return list;
    }

    onPlayersChanged: {
        var normalized = normalizePlayersList(players);
        var sanitized = sanitizePlayersList(normalized);
        archivePlayers = sanitized.length === 0 && normalized.length ? normalized : sanitized;
        syncPrimaryPlayer();
        updateIntervalMode();
        updateFullscreenState();
        updateCoordinatorStreamers();
    }

    function updateCoordinatorStreamers() {
        var list = [];
        forEachPlayer(function(player) {
            if (player && player.archiveStreamer)
                list.push(player.archiveStreamer);
        });
        playbackCoordinator.setStreamers(list);
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

    function updateSharedCurrentDate(time) {
        if (!time)
            return;
        if (sharedCurrentDate && sharedCurrentDate.getTime && time.getTime &&
                sharedCurrentDate.getTime() === time.getTime()) {
            return;
        }
        sharedCurrentDate = time;
    }


    function setCalendarTime(time) {
        if (!time || suppressTimeUpdates)
            return;

        suppressTimeUpdates = true;
        if (archiveControls && archiveControls.calendarButton) {
            archiveControls.calendarButton.calendar.selectedDateTime = time;
        }
        suppressTimeUpdates = false;
    }

    function updatePlayersArchiveTime(time) {
        updateSharedCurrentDate(time);
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

        var time = archiveControls.calendarButton.calendar.selectedDateTime;
        if (!time)
            return;
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

    function syncFromPrimaryArchiveTime() {
        if (!primaryPlayer || !primaryPlayer.archiveTime || _suppressArchiveTimeSync)
            return;
        var time = primaryPlayer.archiveTime;
        _suppressArchiveTimeSync = true;
        updateSharedCurrentDate(time);
        if (primarySlider && (!primarySlider.currentDate
                              || primarySlider.currentDate.getTime() !== time.getTime()))
            primarySlider.currentDate = time;
        setCalendarTime(time);
        _suppressArchiveTimeSync = false;
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

        onPlaybackSpeedChanged: playbackCoordinator.playbackSpeed = playbackSpeed

        function pauseStream() {
            var playhead = root._masterPlayhead || sharedCurrentDate
            if (playhead)
                playbackCoordinator.setMasterTime(playhead)
            playbackCoordinator.pause();
        }

        function resumeStream() {
            if (sharedCurrentDate)
                playbackCoordinator.setMasterTime(sharedCurrentDate)
            playbackCoordinator.resume();
            needToUpdateArchive = false;
        }

        function startStreamAt(cameraId, time, archiveId) {
            var targetTime = time || sharedCurrentDate
            forEachPlayer(function(player) {
                if (player.archiveStreamer)
                    player.archiveStreamer.startStreamAt(player.cameraId, targetTime, player.archiveId);
                if (player.needToUpdateArchive !== undefined)
                    player.needToUpdateArchive = false;
            });
            playbackCoordinator.setMasterTime(targetTime)
            playbackCoordinator.resume();
            needToUpdateArchive = false;
        }

        function delayStart(cameraId, time, archiveId) {
            var targetTime = time || sharedCurrentDate
            forEachPlayer(function(player) {
                if (player.archiveStreamer && player.archiveStreamer.delayStart)
                    player.archiveStreamer.delayStart(player.cameraId, targetTime, player.archiveId);
            });
            playbackCoordinator.setMasterTime(targetTime)
            playbackCoordinator.resume();
            needToUpdateArchive = false;
        }

        function requestPreviewAt(cameraId, time, archiveId) {
            var targetTime = time || sharedCurrentDate
            _setMasterPlayhead(targetTime)
            playbackCoordinator.pause();
            forEachPlayer(function(player) {
                if (player.archiveStreamer)
                    player.archiveStreamer.requestPreviewAt(player.cameraId, targetTime, player.archiveId);
            });
        }

        function stepFrameLeft() {
            if (root.hasMultiplePlayers) {
                stepFrameLeftSync();
                return;
            }
            forEachPlayer(function(player) {
                if (player.archiveStreamer && player.archiveStreamer.stepFrameLeft)
                    player.archiveStreamer.stepFrameLeft();
            });
        }

        function stepFrameRight() {
            if (root.hasMultiplePlayers) {
                stepFrameRightSync();
                return;
            }
            forEachPlayer(function(player) {
                if (player.archiveStreamer && player.archiveStreamer.stepFrameRight)
                    player.archiveStreamer.stepFrameRight();
            });
        }

    function syncStepTo(time) {
        if (!time)
            return;
        _setMasterPlayhead(time);
        _suppressArchiveTimeSync = true;
        updatePlayersArchiveTime(time);
        _suppressArchiveTimeSync = false;
        forEachPlayer(function(player) {
            if (!player || player === primaryPlayer)
                return;
            var frameMs = 0;
            if (player.getFrameTime)
                frameMs = Number(player.getFrameTime());
            if (isNaN(frameMs))
                frameMs = 0;
            if (frameMs === 0 || frameMs !== time.getTime()) {
                if (player.archiveStreamer)
                    player.archiveStreamer.requestPreviewAt(player.cameraId, time, player.archiveId);
            }
        });
    }

        function syncStepToMs(ms) {
            if (!ms)
                return
            syncStepTo(new Date(ms))
        }

        function stepFrameLeftSync() {
            if (!root.hasMultiplePlayers) {
                pauseStream();
                stepFrameLeft();
                return;
            }
            root._stepSyncLastFrameMs = root._primaryFrameTimeMs();
            root._stepSyncStartMs = Date.now();
            _stepSyncTimer.start();
            pauseStream();
            playbackCoordinator.step(-1);
        }

        function stepFrameRightSync() {
            if (!root.hasMultiplePlayers) {
                pauseStream();
                stepFrameRight();
                return;
            }
            root._stepSyncLastFrameMs = root._primaryFrameTimeMs();
            root._stepSyncStartMs = Date.now();
            _stepSyncTimer.start();
            pauseStream();
            playbackCoordinator.step(1);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 8
        spacing: 8

        CommonArchiveControls {
            id: archiveControls

            implicitHeight: 32 - parent.spacing*2
            Layout.alignment: Qt.AlignHCenter

            m_i_curr_scale: root.commonScale
            needToUpdateArchive: root.needToUpdateArchive

            archiveId: root.archiveId
            rootRef: root.rootRef
            cameraId: root.cameraId
            archiveTime: root.sharedCurrentDate

            iv_arc_slider_new: commonTimeline
            archiveStreamer: multiArchiveStreamer
            commonTimeline: commonTimeline

            updateTimeFromCalendar: root.updateTimeFromCalendar

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

                players: root.archivePlayers
                commonScale: root.commonScale
                sharedCurrentDate: root.sharedCurrentDate

                onTimeChanged: {
                    if (!date)
                        return;
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

                Component.onCompleted: {
                    root.primarySlider = commonTimeline.slider;

                    ArchivePlayer.ExportManager.commonTimeline = this;
                }
                Component.onDestruction: {
                    ArchivePlayer.ExportManager.commonTimeline = null;
                }
            }

            Binding {
                target: root
                property: "primarySlider"
                value: commonTimeline ? commonTimeline.slider : null
            }
        }
    }

    Binding {
        target: ArchivePlayer.ExportManager
        property: "archiveId"
        value: archiveId
    }

    Component.onCompleted: {
        syncPrimaryPlayer()
        updateFullscreenState()
    }

    Connections {
        target: primaryPlayer
        onArchiveTimeChanged: root.syncFromPrimaryArchiveTime()
    }
}

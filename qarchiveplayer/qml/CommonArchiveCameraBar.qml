import QtQuick 2.9
import QtQml 2.1
import QtQuick.Controls 2.3
import iv.colors 1.0
import iv.controls 1.0
import iv.viewers.archiveplayer 1.0

Rectangle {
    id: root

    property var archivePlayer: null
    property var key2: null
    property int timelineModel: 0
    property var viewStart: null
    property var viewEnd: null
    property var dataStart: null
    property var dataEnd: null
    readonly property var safeViewStart: viewStart ? viewStart : new Date(0)
    readonly property var safeViewEnd: viewEnd ? viewEnd : new Date(0)
    readonly property var backend: archivePlayer && archivePlayer.idarchive_player
                                 ? archivePlayer.idarchive_player
                                 : archivePlayer
    property real isize: 1
    property bool clampNow: true

    property string fullnessColor: "rgba(53, 165, 92, 0.6)"
    property real fullnessOpacity: 1
    property color eventColor: IVColors.get("Colors/Background new/BgBtnCritical")
    property real fullnessRadius: 4
    property bool showEvents: true

    color: "transparent"
    border.color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
    border.width: 1

    FullnessModel { id: fullnessModel }
    EventsModel { id: eventsModel }

    FullnessProjectionModel {
        id: fullnessProjection
        source: fullnessModel
        startDate: root.safeViewStart
        endDate: root.safeViewEnd
        viewWidth: barCanvas.width
        minPx: 0
        clampNow: root.clampNow
    }

    EventsProjectionModel {
        id: eventsProjection
        source: eventsModel
        startDate: root.safeViewStart
        endDate: root.safeViewEnd
        viewWidth: barCanvas.width
        minPx: 0
    }

    function refreshModels() {
        if (!backend || !dataStart || !dataEnd)
            return;

        backend.getFullness(dataStart, dataEnd, key2, timelineModel);
        updateFullnessFromBackend();

        backend.getEvents(dataStart, dataEnd, 0, key2, timelineModel);
        updateEventsFromBackend();

        projectData();
    }

    function updateFullnessFromBackend() {
        if (!backend)
            return;
        fullnessModel.updateFromJson(backend.getFnJson(), timelineModel, fullnessModel.dateCheckSum);
        projectData();
    }

    function updateEventsFromBackend() {
        if (!backend)
            return;
        eventsModel.updateFromJson(backend.getEventsStr(), [], timelineModel, eventsModel.dateCheckSum);
        projectData();
    }

    function syncDataForView(forceFetch) {
        if (!viewStart || !viewEnd) {
            dataStart = null
            dataEnd = null
            return
        }
        if (!backend) {
            dataStart = null
            dataEnd = null
            return
        }

        var startMs = viewStart.getTime()
        var endMs = viewEnd.getTime()
        if (!isFinite(startMs) || !isFinite(endMs) || endMs <= startMs)
            return

        var spanMs = endMs - startMs
        var marginMs = Math.round(spanMs * 0.5)
        var desiredStart = new Date(Math.max(0, startMs - marginMs))
        var desiredEnd = new Date(endMs + marginMs)

        var needsFetch = forceFetch
        if (!dataStart || !dataEnd)
            needsFetch = true
        else if (startMs < dataStart.getTime() || endMs > dataEnd.getTime())
            needsFetch = true

        if (needsFetch) {
            dataStart = desiredStart
            dataEnd = desiredEnd
            refreshModels()
        } else {
            projectData()
        }
    }

    function projectData() {
        fullnessProjection.project();
        eventsProjection.project();
        barCanvas.requestPaint();
    }

    onViewStartChanged: syncDataForView(false)
    onViewEndChanged: syncDataForView(false)
    onTimelineModelChanged: syncDataForView(true)
    onArchivePlayerChanged: syncDataForView(true)
    onKey2Changed: syncDataForView(true)


    Canvas {
        id: barCanvas

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        height: 16 * root.isize
        width: parent.width

        onWidthChanged: root.projectData()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            ctx.globalAlpha = fullnessOpacity;
            ctx.fillStyle = fullnessColor;
            for (var i = 0; i < fullnessProjection.count; ++i) {
                var interval = fullnessProjection.get(i);
                var x = width * interval.s;
                var w = width * (interval.f - interval.s);
                var h = height;
                if (w <= 0)
                    continue;

                var r = Math.min(fullnessRadius, h / 2, w / 2);

                if (w < 2 * fullnessRadius) {
                    ctx.fillRect(x, 0, w, h);
                } else {
                    ctx.beginPath();
                    ctx.moveTo(x + r, 0);
                    ctx.lineTo(x + w - r, 0);
                    ctx.arcTo(x + w, 0, x + w, r, r);
                    ctx.lineTo(x + w, h - r);
                    ctx.arcTo(x + w, h, x + w - r, h, r);
                    ctx.lineTo(x + r, h);
                    ctx.arcTo(x, h, x, h - r, r);
                    ctx.lineTo(x, r);
                    ctx.arcTo(x, 0, x + r, 0, r);
                    ctx.closePath();
                    ctx.fill();
                }
            }
        }

        Connections {
            target: root
            onFullnessOpacityChanged: barCanvas.requestPaint()
        }
    }

    Item {
        id: eventsLayer

        anchors.fill: parent
        visible: root.showEvents

        Component {
            id: eventsDelegateComponent

            Item {
                id: eventDelegate

                width: 0
                height: 0

                property real margs: 0
                property var eventData: model

                Component.onCompleted: eventArea.opacity = 1
                onEventDataChanged: eventArea.opacity = 1
                Component.onDestruction: {
                    if (eventArea)
                        eventArea.destroy()
                }

                MouseArea {
                    id: eventArea

                    hoverEnabled: true
                    opacity: 0
                    x: root.width * eventDelegate.eventData.s - width / 2
                    height: barCanvas.height - 2 * eventDelegate.margs
                    width: height
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -3/2*height

                    Rectangle {
                        anchors.centerIn: parent
                        width: 16 * root.isize
                        height: 16 * root.isize
                        radius: 4
                        color: root.eventColor

                        IVImage {
                            anchors.centerIn: parent
                            width: 16 * root.isize
                            height: 16 * root.isize
                            name: "new_images/Event"
                            color: IVColors.get("Colors/Text new/TxContrast")

                            ToolTip {
                                property var s: eventDelegate.eventData.startDate
                                property string f: "yyyy.MM.dd hh:mm:ss.zzz"
                                property string dateString: Qt.formatDateTime(s, f)
                                text: dateString + "\n" + eventDelegate.eventData.comment
                                visible: eventArea.containsMouse
                                delay: 150
                            }
                        }
                    }

                    Behavior on opacity { NumberAnimation { duration: 150 }}
                }
            }
        }

        ListView {
            id: eventsListView
            anchors.fill: parent
            interactive: false
            orientation: ListView.Horizontal
            spacing: 0
            cacheBuffer: Math.max(1, width)
            model: root.showEvents ? eventsProjection : null
            delegate: eventsDelegateComponent
        }
    }

    Connections {
        target: fullnessModel

        onCountChanged: root.projectData()
        onDateCheckSumChanged: root.projectData()
    }

    Connections {
        target: eventsModel

        onCountChanged: root.projectData()
        onDateCheckSumChanged: root.projectData()
    }

    Connections {
        target: backend
        onFnJsonChanged: updateFullnessFromBackend()
        onEvJsonChanged: updateEventsFromBackend()
    }

    Connections {
        target: fullnessProjection

        onCountChanged: barCanvas.requestPaint()
    }

}

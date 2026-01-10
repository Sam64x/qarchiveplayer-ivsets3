import QtQuick 2.9
import QtQml 2.1
import QtQuick.Controls 2.3
import iv.colors 1.0
import iv.data 1.0

Rectangle {
    id: root

    property var archivePlayer: null
    property var key2: null
    property int timelineModel: 0
    property var viewStart: null
    property var viewEnd: null
    property real isize: 1
    property bool clampNow: true

    property color fullnessColor: IVColors.get("Colors/Text new/TxAccent")
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
        startDate: root.viewStart
        endDate: root.viewEnd
        viewWidth: barCanvas.width
        minPx: 0
        clampNow: root.clampNow
    }

    EventsProjectionModel {
        id: eventsProjection
        source: eventsModel
        startDate: root.viewStart
        endDate: root.viewEnd
        viewWidth: barCanvas.width
        minPx: 0
    }

    function refreshModels() {
        var backend = archivePlayer && archivePlayer.idarchive_player
                      ? archivePlayer.idarchive_player
                      : archivePlayer;

        if (!backend || !viewStart || !viewEnd)
            return;

        backend.getFullness(viewStart, viewEnd, key2, timelineModel);
        fullnessModel.updateFromJson(backend.getFnJson(), timelineModel, fullnessModel.dateCheckSum);

        backend.getEvents(viewStart, viewEnd, 0, key2, timelineModel);
        eventsModel.updateFromJson(backend.getEventsStr(), [], timelineModel, eventsModel.dateCheckSum);

        projectData();
    }

    function projectData() {
        fullnessProjection.project();
        eventsProjection.project();
        barCanvas.requestPaint();
    }

    onViewStartChanged: refreshModels()
    onViewEndChanged: refreshModels()
    onTimelineModelChanged: refreshModels()
    onArchivePlayerChanged: refreshModels()


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
    }

    Item {
        id: eventsLayer

        anchors.fill: parent
        visible: root.showEvents

        Repeater {
            model: eventsProjection.count

            delegate: MouseArea {
                readonly property var eventData: eventsProjection.get(index)

                width: markerSize
                height: markerSize
                hoverEnabled: true
                anchors.bottom: parent.bottom
                x: root.width * eventData.s - width / 2

                readonly property real markerSize: 16 * root.isize

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: 4
                    color: root.eventColor

                    ToolTip {
                        property var s: eventData.startDate
                        property string f: "yyyy.MM.dd hh:mm:ss.zzz"
                        property string dateString: Qt.formatDateTime(s, f)
                        text: dateString + "\n" + eventData.comment
                        visible: parent.parent.containsMouse
                        delay: 150
                    }
                }
            }
        }
    }

    Connections {
        target: fullnessModel

        onCountChanged: root.projectData()
        onDateCheckSumChanged: root.projectData()
    }

    Connections {
        target: fullnessProjection

        onCountChanged: barCanvas.requestPaint()
    }

}

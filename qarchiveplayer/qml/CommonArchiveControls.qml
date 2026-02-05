import QtQml 2.3
import QtQuick 2.11
import QtQuick.Window 2.2
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.0
import QtQml.Models 2.3
import QtQuick.Dialogs 1.2
import iv.guicomponents 1.0
import iv.calendar 1.0
import iv.archivecomponents.selectinterval 1.0
import iv.photocam 1.0
import QtQuick.Controls.Styles 1.4

import iv.singletonLang 1.0
import iv.viewers.archiveplayer 1.0

import iv.colors 1.0
import iv.controls 1.0 as C


RowLayout {
    id: root

    // Need to sync
    property var m_i_curr_scale
    property var needToUpdateArchive

    // Just Data
    property var archiveId
    property var rootRef
    property var cameraId
    property var archiveTime

    // Component reference
    property var iv_arc_slider_new
    property var archiveStreamer
    property var commonTimeline

    // Function Reference
    property var updateTimeFromCalendar

    property alias calendarButton: calendarButton

    signal scaleChosen(int index)
    signal clearPendingUpdate()

    IntervalScaleButton {
        m_i_curr_scale: root.m_i_curr_scale
        onScaleChosen: {
            root.scaleChosen(index)
        }
    }

    LabeledCalendarButton {
        id: calendarButton

        updateTimeFromCalendar: root.updateTimeFromCalendar
    }

    PlayerControls {
        archiveTime: root.archiveTime
        archiveId: root.archiveId
        cameraId: root.cameraId
        needToUpdateArchive: root.needToUpdateArchive
        archiveStreamer: root.archiveStreamer
        onClearPendingUpdate: root.clearPendingUpdate()
    }

    FrameRewindButtons {
        archiveStreamer: root.archiveStreamer
    }

    FrameTimeButton {
        iv_arc_slider_new: root.iv_arc_slider_new
    }

    ExportControls {
        visible: root.commonTimeline.exportMode
        commonTimeline: root.commonTimeline
        rootRef: root.rootRef
        cameraId: root.cameraId
        archiveId: root.archiveId
    }
}

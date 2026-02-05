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
import iv.viewers.archiveplayer 1.0
import QtQuick.Controls.Styles 1.4

import iv.singletonLang 1.0

import iv.colors 1.0
import iv.controls 1.0 as C


RowLayout {
    id: root

    // Need to sync
    property var m_i_curr_scale
    property var needToUpdateArchive

    // Just Data
    property var archiveId
    property var archiveIsPlaying
    property var rootRef
    property var cameraId
    property var isIntervalMode
    property var archiveTime

    // Component reference
    property var iv_arc_slider_new
    property var archiveStreamer

    // Function Reference
    property var updateTimeFromSlider
    property var funcSwitchSelectIntervalMode
    property var updateTimeFromCalendar
    property var imagePipeline

    // Show settings
    property bool isCommonSets: false

    property alias calendarButton: calendarButton
    property alias videoPlayerControls: videoPlayerControls
    property alias iv_butt_spb_events_skip: iv_butt_spb_events_skip
    property alias settingButtons: settingButtons
    property alias exportSettings: exportSettings

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
        id: videoPlayerControls
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

    IVSeparator {
        visible: !root.isCommonSets
    }

    FrameTimeButton {
        iv_arc_slider_new: root.iv_arc_slider_new
    }

    EventButtons {
        id: iv_butt_spb_events_skip
        visible: !root.isCommonSets
        iv_arc_slider_new: root.iv_arc_slider_new
        updateTimeFromSlider: root.updateTimeFromSlider
    }

    ScreenshotButton {
        visible: !root.isCommonSets
    }

    SettingsButton {
        id: settingButtons
        rootRef: root.rootRef
        visible: !root.isCommonSets
        imagePipeline: root.imagePipeline || (root.rootRef && root.rootRef.imagePipeline ? root.rootRef.imagePipeline : null)
    }


    RowLayout {
        spacing: 1
        visible: !root.isCommonSets && root.isIntervalMode && !root.archiveStreamer.exporting

        C.IVButtonControl {
            Layout.preferredWidth: 72
            Layout.preferredHeight: 24
            radius: 0
            topLeftRadius: 4
            bottomLeftRadius: 4
            text: "Выгрузить"
            size: C.IVButtonControl.Size.Small
            type: C.IVButtonControl.Type.Event
            onClicked: exportSettings.startExport()
        }

        ExportSettingsButton {
            id: exportSettings

            radius: 0
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            size: C.IVButtonControl.Size.Small
            type: C.IVButtonControl.Type.Event
            archiveId: root.archiveId
            cameraId: root.cameraId
            rootRef: root.rootRef
            iv_arc_slider_new: root.iv_arc_slider_new
            wsUrl: root.rootRef && root.rootRef.wsUrl ? root.rootRef.wsUrl : appInfo.wsUrl
        }

        C.IVButtonControl {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: 0
            topRightRadius: 4
            bottomRightRadius: 4
            source: "new_images/x-close"
            size: C.IVButtonControl.Size.Small
            type: C.IVButtonControl.Type.Event
            toolTipText: Language.getTranslate("Exit from interval selection", "Выйти из режима выбора интервала")
            enabled: true
            onClicked: root.funcSwitchSelectIntervalMode()
        }
    }
}

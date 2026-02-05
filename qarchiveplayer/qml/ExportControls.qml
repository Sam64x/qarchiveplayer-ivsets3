import QtQml 2.3
import QtQuick 2.11
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

import iv.colors 1.0
import iv.singletonLang 1.0
import iv.controls 1.0 as C

RowLayout {
    id: root

    spacing: 1

    property var commonTimeline
    property var rootRef
    property var cameraId
    property var archiveId

    C.IVButtonControl {
        Layout.preferredWidth: 72
        Layout.preferredHeight: 24
        radius: 0
        topLeftRadius: 4
        bottomLeftRadius: 4
        text: "Выгрузить"
        size: C.IVButtonControl.Size.Small
        type: C.IVButtonControl.Type.Event
        enabled: commonTimeline.exportCameraIds.length > 0
        onClicked: exportSettings.startExport()
    }

    ExportSettingsButton {
        id: exportSettings
        radius: 0
        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        size: C.IVButtonControl.Size.Small
        type: C.IVButtonControl.Type.Event
        enabled: root.commonTimeline.exportCameraIds.length > 0
        archiveId: root.archiveId
        cameraId: root.cameraId
        rootRef: root.rootRef
        wsUrl: root.rootRef && root.rootRef.wsUrl ? root.rootRef.wsUrl : appInfo.wsUrl
        externalFromTime: root.commonTimeline.exportBounds.left
        externalToTime: root.commonTimeline.exportBounds.right
        useExternalBounds: true
        exportCameraIds: root.commonTimeline.exportCameraIds
        applyBounds: function(fromTime, toTime) {
            root.commonTimeline.setExportBounds(fromTime, toTime)
        }
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
        onClicked: {
            if (commonTimeline.exportMode)
                commonTimeline.exportMode = false
            else
                root.toggleIntervalMode()
        }
    }
}

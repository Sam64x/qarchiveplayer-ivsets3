import QtQuick 2.7

import iv.photocam 1.0
import iv.controls 1.0 as C
import iv.singletonLang 1.0

C.IVButtonControl {
    id: root

    function normalizePath(path) {
        if (!path)
            return ""
        path = path.replace(/\\/g, "/")
        path = path.replace(/\/{2,}/g, "/")
        if (Qt.platform.os === "windows") {
            path = path.replace(/\//g, "\\")
        }
        return path
    }

    property string screenshotToolTip: Language.getTranslate("The picture is saved in", "Снимок сохранён в:") + normalizePath(appInfo.snapshotSaveDirectory)
    property bool screenshotDone: false

    implicitHeight: 24
    implicitWidth: 24
    size: C.IVButtonControl.Size.Small
    type: C.IVButtonControl.Type.Secondary
    source: "new_images/screenshot"
    toolTipText: screenshotDone ? screenshotToolTip : Language.getTranslate("Photo Camera", "Фотокамера")
    onClicked: {
        archiveStreamer.screenshot(appInfo.snapshotSaveDirectory)
        screenshotDone = true
        resetTimer.start()
    }

    Timer {
        id: resetTimer
        interval: 3000
        onTriggered: {
            screenshotDone = false
        }
    }
}

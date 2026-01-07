import QtQuick 2.7
import iv.singletonLang 1.0
import iv.controls 1.0 as C

Row {
    id: root
    spacing: 1

    property var archiveStreamer

    C.IVButtonControl {
        source: "new_images/backward-step"
        implicitHeight: 24
        implicitWidth: 24
        radius: 0
        topLeftRadius: 4
        bottomLeftRadius: 4
        size: C.IVButtonControl.Size.Small
        type: C.IVButtonControl.Type.Secondary
        toolTipText: Language.getTranslate("Backward step","Шаг назад")
        onClicked: {
            archiveStreamer.pauseStream()
            archiveStreamer.stepFrameLeft();
        }
    }

    C.IVButtonControl {
        source: "new_images/forward-step"
        implicitHeight: 24
        implicitWidth: 24
        radius: 0
        topRightRadius: 4
        bottomRightRadius: 4
        size: C.IVButtonControl.Size.Small
        type: C.IVButtonControl.Type.Secondary
        toolTipText: Language.getTranslate("Forward step","Шаг вперёд")
        onClicked: {
            archiveStreamer.pauseStream()
            archiveStreamer.stepFrameRight();
        }
    }
}

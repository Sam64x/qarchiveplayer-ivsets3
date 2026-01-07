import QtQuick 2.7

import iv.singletonLang 1.0
import iv.controls 1.0 as C

C.IVButtonControl {
    id: iv_butt_spb_to_curs_1

    property var iv_arc_slider_new

    source: "new_images/On center"
    implicitHeight: 24
    implicitWidth: 24
    size: C.IVButtonControl.Size.Small
    type: C.IVButtonControl.Type.Secondary
    toolTipText: Language.getTranslate("Return to frame time","Вернуться к времени кадра")
    onClicked: iv_arc_slider_new.canAutoMove = true
}


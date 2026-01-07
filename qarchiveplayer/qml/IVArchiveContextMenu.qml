import QtQuick 2.11
import QtQuick.Controls 2.4

import iv.colors 1.0
import iv.singletonLang 1.0
import iv.controls 1.0 as C

C.IVMenu {
    id: root

    property var functReturnToRealtime
    property var funcCloseSet

    implicitWidth: 300

    C.IVMenuItem {
        text: "Возврат в реалтайм"
        indicatorSource: "new_images/Archive mode play"
        onTriggered: {
            root.functReturnToRealtime()
        }
    }

    C.IVMenuItem {
        text: "Закрыть вкладку"
        indicatorSource: "new_images/x-close"
        onTriggered: {
            root.funcCloseSet()
        }
    }
}

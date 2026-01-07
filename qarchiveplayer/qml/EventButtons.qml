import QtQuick 2.7
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import iv.singletonLang 1.0
import iv.controls 1.0 as C

RowLayout {
    id: root

    property int type: -1
    property var iv_arc_slider_new
    property var updateTimeFromSlider
    property var archiveStreamer

    spacing: 1

    C.IVButtonControl {
        size: C.IVButtonControl.Size.Small
        type: C.IVButtonControl.Type.Secondary
        source: "new_images/chevron-left"
        Layout.preferredHeight: 24
        Layout.preferredWidth: 16
        topRightRadius: 0
        bottomRightRadius: 0
        toolTipText: Language.getTranslate("Go to previous","Перейти к предыдущему")
        onClicked: {
            archiveStreamer.pauseStream()
            var isFoundEvents = iv_arc_slider_new.toLeftEvents(parent.type);
            if (isFoundEvents)
            {
                updateTimeFromSlider()
            }
        }
    }

    C.IVButtonControl {
        id: eventsControl

        property var events: [
            {"type": 2, "name": Language.getTranslate("Events","События"), "source": "new_images/Event"},
            {"type": 6, "name": Language.getTranslate("Bookmarks","Метки"), "source": "new_images/flag-01"},
            {"type": -1, "name": Language.getTranslate("Events and bookmarks","События и метки"), "source": "new_images/Flag and event"},
            {"type": 0, "name": Language.getTranslate("Hidden","Скрыто"), "source": "new_images/flash-off"}
        ]

        property var currentEvent: {
            for (var i = 0; i < events.length; ++i)
                if (events[i].type === root.type)
                    return events[i];
            return null;
        }

        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        radius: 0
        checkable: true
        checked: eventsControlMenu.opened
        size: C.IVButtonControl.Size.Small
        type: C.IVButtonControl.Type.Secondary
        source: currentEvent.source
        toolTipText: currentEvent.name
        toolTipVisible: !eventsControlMenu.opened && eventsControl.toolTipText.length > 0 && eventsControl.hovered

        onClicked: {
            if (eventsControlMenu.opened)
                eventsControlMenu.close();
            else
                eventsControlMenu.open();
        }

        C.IVContextMenuControl {
            id: eventsControlMenu
            verticalPadding: 1
            horizontalPadding: 1
            y: -height - 8
            radius: 2
            component: Column {
                spacing: 1
                Repeater {
                    model: eventsControl.events
                    delegate: C.IVButtonControl {
                        autoExclusive: true
                        size: C.IVButtonControl.Size.Small
                        width: 24
                        height: 24
                        checkable: true
                        checked: modelData.type === root.type
                        source: modelData.source
                        onClicked: {
                            root.type = modelData.type
                        }
                    }
                }
            }
        }
    }

    C.IVButtonControl {
        size: C.IVButtonControl.Size.Small
        type: C.IVButtonControl.Type.Secondary
        source: "new_images/chevron-right"
        Layout.preferredHeight: 24
        Layout.preferredWidth: 16
        radius: 0
        topRightRadius: 4
        bottomRightRadius: 4
        toolTipText: Language.getTranslate("Go to next","Перейти к следующему")
        onClicked: {
            archiveStreamer.pauseStream()
            var isFoundEvents = iv_arc_slider_new.toRightEvents(parent.type);
            if (isFoundEvents) {
                updateTimeFromSlider()
            }
        }
    }
}

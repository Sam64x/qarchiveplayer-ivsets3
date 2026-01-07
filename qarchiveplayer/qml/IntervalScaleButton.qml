import QtQuick 2.7
import QtQuick.Controls 2.4

import iv.colors 1.0
import iv.photocam 1.0
import iv.controls 1.0 as C
import iv.singletonLang 1.0

C.IVButtonControl {
    id: root

    property var m_i_curr_scale
    signal scaleChosen(int index)

    property var lm_intervals: [
        {"name": Language.getTranslate("Year","Год")},
        {"name": Language.getTranslate("Month","Месяц")},
        {"name": Language.getTranslate("Week","Неделя")},
        {"name": Language.getTranslate("Day","День")},
        {"name": Language.getTranslate("Hour","Час")},
        {"name": Language.getTranslate("30 minutes","30 минут")},
        {"name": Language.getTranslate("10 minutes","10 минут")},
        {"name": Language.getTranslate("1 minute","1 минута")}
    ]

    implicitWidth: 88
    implicitHeight: 24
    leftPadding: 8
    rightPadding: 4
    radius: 4
    checkable: true
    chevroned: true
    checked: scaleMenu.opened
    layoutAlignment: Qt.AlignLeft
    size: C.IVButtonControl.Size.Small
    type: C.IVButtonControl.Type.Outline
    chevroneSource: "new_images/chevron-selector-vertical"
    borderColor: IVColors.get("Colors/Stroke new/StInputfieldThemed")
    text: lm_intervals[m_i_curr_scale].name

    C.IVContextMenuControl {
        id: scaleMenu
        horizontalPadding: 0
        verticalPadding: 4
        radius: 8

        component: Column {
            spacing: 1

            Repeater {
                model: root.lm_intervals
                delegate: C.IVButtonControl {
                    size: C.IVButtonControl.Size.Small
                    radius: 0
                    width: root.implicitWidth
                    height: 20
                    checkable: true
                    checked: index === root.m_i_curr_scale
                    text: modelData.name
                    onClicked: root.scaleChosen(index)
                }
            }
        }
    }

    onClicked: {
        if (scaleMenu.opened)
            scaleMenu.close();
        else
            scaleMenu.open();
    }
}

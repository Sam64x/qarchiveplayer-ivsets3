import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.colors 1.0
import iv.controls 1.0
import iv.sets.sets3 1.0
import iv.plugins.loader 1.0

Rectangle
{
    id:root
    width: content.width + margin*2
    height: 48 * root.isize
    radius: 12 * isize
    color: IVColors.get("Colors/Background new/BgFormOverVideo")
    visible: opacity > 0
    signal miniClicked()
    property var globalSignalsObject: null
    property string tabName: ""
    property real isize: 1
    property real margin: 8 * root.isize
    Behavior on opacity {
        NumberAnimation {
            duration: 200;
            easing.type: Easing.InOutQuad
        }
    }

    Connections
    {
        id: myConn
        target: root.globalSignalsObject
        onTabSelected5: root.tabName = tabname;
    }
    Row {
        id: content
        spacing: 8 * root.isize
        anchors.centerIn: parent
        height: parent.height - parent.margin
        Rectangle {
            id: dateTimeRect
            property int showDateW: (dateType.value === "true") ? 130*root.isize : 0
            property int showSecsW: (timeType.value === "true") ? 40*root.isize : 0
            height: parent.height
            width: 60*root.isize + showDateW + showSecsW
            color: "transparent"
            IvVcliSetting {id: dateType; name: 'interface.dateType'}
            IvVcliSetting {id: timeType; name: 'interface.timeType'}
            Row {
                anchors.centerIn: parent
                spacing: 8 * root.isize
                Text {
                    id: timeText
                    font: IVColors.getFont("Title accent")
                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                }
                Text {
                    id: dateText
                    visible: dateType.value === 'true'
                    font: IVColors.getFont("Title")
                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                }
            }
            Timer {
                id:dateTimeUpdateTimer
                interval: 90
                repeat: true
                running: true
                onTriggered: {
                    if (timeType.value === 'true')
                        timeText.text = Qt.formatTime(new Date(),"hh:mm:ss")
                    else
                        timeText.text = Qt.formatTime(new Date(),"hh:mm")

                    var date = Qt.formatDate(new Date(),"dd.MM.yy ddd")
                    dateText.text = date.toUpperCase();
                }
            }
        }
        IVMenuButton {
            id: collapse
            height: parent.height
            width: height
            source: "new_images/collapse2"
            toolTipText: "Показать панель вкладок"
            onClicked: {
                root.miniClicked()
            }
        }
    }
}

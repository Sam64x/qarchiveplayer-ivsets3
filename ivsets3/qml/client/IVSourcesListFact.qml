import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import QtGraphicalEffects 1.0
import iv.plugins.loader 1.0
import iv.sets.sets3 1.0
import QtQuick.Dialogs 1.1
import iv.colors 1.0
import iv.controls 1.0
Rectangle
{
    id:root
    //property ListModel model: ({})
    property bool enabled: true
    property int currentIndex: -1

    readonly property real isize: 1
    readonly property bool useAnimation: true
  //  readonly property int count: model.count
    property var customSets:null
    property var devices:null
    property var globSignalsObject:null
    property var  messageDialog: null
    radius: 8 * isize
    color: IVColors.get("Colors/Background new/BgFormTertiaryThemed")
    opacity: enabled ? 1 : 0.4
    ListView {
        id: lview
        anchors.fill: parent
        model: root.model
        interactive: false
        orientation: ListView.Horizontal
        currentIndex: root.currentIndex
        highlightFollowsCurrentItem: false
        highlight: Rectangle {
            width: root.width * 0.66 - gap
            height: root.height - gap
            color: "white"
            radius: 6 * root.isize
            y: gap/2
            x: lview.currentItem.x + gap/2
            anchors.verticalCenter: parent.verticalCenter
            property real gap: 2 * root.isize
            Behavior on x {
                enabled: root.useAnimation
                NumberAnimation {duration: 150}
            }
        }
        delegate: Rectangle {
            id: rect
            height: root.height
            width: rect.selected? root.width * 0.66:root.width * 0.165
            radius: 8
            color: "transparent"
            property bool selected: root.currentIndex === model.index
            onSelectedChanged: {
                buttText.color = IVColors.get(rect.selected ? "Colors/Text new/TxAccent" : "Colors/Text new/TxPrimaryThemed")
                icon.color = IVColors.get(rect.selected ? "Colors/Text new/TxAccent" : "Colors/Text new/TxPrimaryThemed")
                buttText.bold = rect.selected
            }
            Row {
                anchors.centerIn: parent
                anchors.margins: 12 * root.isize
                spacing: 10 * root.isize
                IVImage {
                    id: icon
                    asynchronous: true
                    name: (model.iconName === undefined || model.iconName === "") ? "" : model.iconName
                    color: IVColors.get(rect.selected ? "Colors/Text new/TxAccent" : "Colors/Text new/TxPrimaryThemed")
                    mipmap: true
                    fillMode: Image.PreserveAspectFit
                }
                Text {
                    id: buttText
                    text: model.text
                    font: IVColors.getFont(bold ? "Button accent" : "Button")
                    color: IVColors.get(rect.selected ? "Colors/Text new/TxAccent" : "Colors/Text new/TxPrimaryThemed")
                    property bool bold: false
                    visible:rect.selected?true:false
                    Behavior on color {
                        enabled: root.useAnimation
                        ColorAnimation {duration: 150}
                    }
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.enabled
                onEntered: {
                    if (!rect.selected)
                        buttText.bold = true
                }
                onExited: {
                    if (!rect.selected){
                        buttText.color = icon.color = IVColors.get("Colors/Text new/TxPrimaryThemed")
                        buttText.bold = false
                    }
                }
                onReleased: {
                    root.currentIndex = model.index
                }
            }
        }
    }
}

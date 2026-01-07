import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.4

import iv.sets.sets3 1.0
import iv.colors 1.0
import iv.controls 1.0


IVContextMenu {
    id: root
    bgColor: IVColors.get("Colors/Background new/BgContextMenuThemed")
    topPadding: shadowWidth + 8*root.isize
    leftPadding: shadowWidth + 16*root.isize
    rightPadding: shadowWidth + 16*root.isize
    property int maxH: parent.height - y - topPadding - bottomPadding - 100*root.isize
    signal ready(var include, var events)
    TreeModel {
        id: filterModel
        onReady: root.ready(include, events)
        Component.onCompleted: filterModel.init("eventTypes")
    }
    component: Component {
        Column {
            id: filterColumn
            spacing: 8 * root.isize
            width: 350 * root.isize
            Rectangle {
                color: "transparent"
                height: 40 * root.isize
                width: parent.width
                Text {
                    text: "Типы событий"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                    font: IVColors.getFont("Subtitle accent")
                }
                IVToggle {
                    checkState: filterModel.state
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    width: 32 * root.isize
                    height: 16 * root.isize
                    visible: filterDelay.searchText.length == 0
                    onClicked: filterModel.state = filterModel.state < 2 ? 2 : 0
                }
            }
            IVInputField {
                id: searchField
                width: parent.width
                source: "new_images/search"
                placeholderText: "Поиск по событиям"

                Timer {
                    id: filterDelay
                    property string searchText: ""
                    interval: 300
                    onTriggered: {
                        searchText = searchField.text
                        filterModel.search(searchText)
                    }
                }
                Connections {
                    target: root
                    onClosed: {
                        searchField.text = ""
                        filterDelay.restart()
                    }
                }
                onTextChanged: filterDelay.restart()
            }
            Flickable {
                id: filterLV
                width: parent.width
                interactive: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentHeight: filterContent.height
                Column {
                    id: filterContent
                    width: parent.width
                    spacing: 8 * root.isize
                    Repeater {
                        id: categoriesRepeater
                        model: filterModel.tree
                        // Категории
                        delegate: Column {
                            spacing: 4 * root.isize
                            width: parent.width
                            visible: modelData.visible
                            Text {
                                text: modelData.name
                                height: 24 * root.isize
                                width: parent.width
                                verticalAlignment: Text.AlignBottom
                                horizontalAlignment: Text.AlignBottom
                                color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                font: IVColors.getFont("Label")
                            }
                            Repeater {
                                model: modelData.childItems
                                // Группы
                                delegate: Column {
                                    id: grCol
                                    spacing: 4 * root.isize
                                    width: parent.width
                                    visible: modelData.visible
                                    Rectangle {
                                        id: groupHeader
                                        height: 32 * root.isize
                                        width: parent.width
                                        clip: true
                                        color: "transparent"
                                        MouseArea {
                                            id: groupHeaderMarea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onContainsMouseChanged: {
                                                if (containsMouse)
                                                    parent.color = IVColors.get("Colors/Background new/BgBtnSecondaryThemed")
                                                else
                                                    parent.color = "transparent"
                                            }
                                            onClicked: {
                                                modelData.isOpen = !modelData.isOpen
                                            }
                                        }
                                        IVImage {
                                            id: groupIcon
                                            width: 24 * root.isize
                                            height: width
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: modelData.icon === undefined || modelData.icon === "" ? "" : "new_images/"+modelData.icon
                                            color: IVColors.get(modelData.state === 2 ? "Colors/Text new/TxAccentThemed"
                                                                                      : "Colors/Text new/TxSecondaryThemed")
                                        }
                                        RowLayout {
                                            anchors {
                                                verticalCenter: parent.verticalCenter
                                                right: groupSwitch.left
                                                left: groupIcon.right
                                                margins: 4 * root.isize
                                            }
                                            Text {
                                                text: modelData.name
                                                font: IVColors.getFont("Button middle")
                                                color: groupHeaderMarea.containsMouse ? IVColors.get("Colors/Text new/TxAccentThemed") :
                                                       modelData.state > 0 ? IVColors.get("Colors/Text new/TxPrimaryThemed") :
                                                                           IVColors.get("Colors/Text new/TxSecondaryThemed")
                                            }
                                            Rectangle {
                                                color: "transparent"
                                                Layout.fillWidth: true
                                                height: 16 * root.isize
                                                IVImage {
                                                    id: chevronImg
                                                    width: parent.height
                                                    height: parent.height
                                                    name: "new_images/chevron-down"
                                                    rotation: modelData.isOpen ? 180 : 0
                                                    fillMode: Image.PreserveAspectFit
                                                    color: IVColors.get(modelData.state === 2 ? "Colors/Text new/TxAccentThemed"
                                                                                              : "Colors/Text new/TxSecondaryThemed")
                                                    Behavior on rotation {
                                                        NumberAnimation {
                                                            duration: 200
                                                            easing.type: Easing.InOutQuad
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        IVToggle {
                                            id: groupSwitch
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 32 * root.isize
                                            height: width/2
                                            checkState: modelData.state
                                            onClicked: modelData.state = modelData.state < 2 ? 2 : 0
                                            visible: parent.visible && filterDelay.searchText.length == 0
                                        }
                                        Rectangle {
                                            width: parent.width
                                            height: 1 * root.isize
                                            anchors.bottom: parent.bottom
                                            color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
                                        }
                                    }
                                    Column {
                                        spacing: 4 * root.isize
                                        width: parent.width
                                        visible: modelData.isOpen && modelData.visible
                                        Repeater {
                                            id: eventsRepeater
                                            model: modelData.childItems
                                            delegate: Rectangle {
                                                id: evdel
                                                height: 32 * root.isize
                                                clip: true
                                                color: "transparent"
                                                visible: parent.visible && modelData.visible
                                                anchors {
                                                    right: parent.right
                                                    left: parent.left
                                                    leftMargin: 32 * root.isize
                                                }
                                                MouseArea {
                                                    id: eventMarea
                                                    anchors.fill: parent
                                                    ToolTip {
                                                        text: modelData.name
                                                        visible: parent.containsMouse && eventName.truncated
                                                        timeout: 3000
                                                        delay: 300
                                                    }
                                                    onContainsMouseChanged: {
                                                        if (containsMouse) parent.color = IVColors.get("Colors/Background new/BgBtnSecondaryThemed")
                                                        else parent.color = "transparent"
                                                    }
                                                    onClicked: modelData.state = modelData.state < 2 ? 2 : 0
                                                    onVisibleChanged: {
                                                        hoverEnabled = visible
                                                    }
                                                }
                                                Text {
                                                    id: eventName
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.right: eventSwitch.left
                                                    clip: true
                                                    elide: Text.ElideRight
                                                    text: modelData.name
                                                    font: IVColors.getFont("Button middle")
                                                    color: eventMarea.containsMouse ? IVColors.get("Colors/Text new/TxAccentThemed") :
                                                           modelData.state > 1 ? IVColors.get("Colors/Text new/TxPrimaryThemed") :
                                                                                 IVColors.get("Colors/Text new/TxSecondaryThemed")
                                                }
                                                IVToggle {
                                                    id: eventSwitch
                                                    anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 32 * root.isize
                                                    height: width/2
                                                    checkState: modelData.state
//                                                    onCheckStateChanged: {
//                                                        var id = parseInt(modelData.id)
//                                                        var isOn = checkState > 0
//                                                        if (isOn !== root.eventInFilter(id)){
//                                                            root.addRemoveIdFilter(id)
//                                                        }
//                                                    }
                                                    onClicked: modelData.state = modelData.state < 2 ? 2 : 0
                                                }
                                                Rectangle {
                                                    width: parent.width
                                                    height: 1 * root.isize
                                                    anchors.bottom: parent.bottom
                                                    color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                onContentHeightChanged: {
                    height = Math.min(contentHeight, root.maxH)
                }
                Connections{
                    target: root
                    onOpened: {
                        filterLV.height = Math.min(filterLV.contentHeight, root.maxH)
                    }
                }
            }
            /*
            IVButton {
                width: parent.width
                height: 32 * root.isize
                visible: !filterModel.isAll
                text: "Показать все категории ("+filterModel.anotherTypesCount+")"
                onClicked: {
                    filterModel.isAll = true
                }
            }
            */
        }
    }
}

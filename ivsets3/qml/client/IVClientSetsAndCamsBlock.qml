import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import QtGraphicalEffects 1.0
import QtQuick.Dialogs 1.1

import iv.plugins.loader 1.0
import iv.sets.sets3 1.0
import iv.colors 1.0
import iv.controls 1.0

Rectangle {
    id: root

    property var globSignalsObject

    readonly property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1

    implicitWidth: 364
    implicitHeight: 700

    color: IVColors.get("Colors/Background new/BgContextMenuThemed")

    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }

    ColumnLayout {
        id: contentLayout
        anchors {
            fill: parent
            topMargin: 8
            leftMargin: 8
            rightMargin: 8
        }
        spacing: 4

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text:"Источники"
                    font: IVColors.getFont("Subtitle accent")
                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                }

                Item {
                    Layout.fillWidth: true
                }

                IVButton {
                    Layout.preferredWidth: 32 * root.isize
                    Layout.preferredHeight: 32 * root.isize

                    source: "new_images/x-close"
                    toolTipText: "Закрыть источники"
                    type: IVButton.Type.Helper
                    onClicked: {
                        root.globSignalsObject.setsAndCamsBlockOpened = false;
                    }
                }
            }

            // IVSegmentedControl {
            //     Layout.fillWidth: true
            //     Layout.preferredHeight: 40 * root.isize

            //     radius: 8 * root.isize
            //     currentIndex: 0

            //     model: ListModel {
            //         ListElement {
            //             type: "all"
            //             text: "Все"
            //         }
            //         ListElement {
            //             type: "added"
            //             text: "В наборе"
            //         }
            //     }

            //     IvVcliSetting {
            //         id: settingsType
            //         name: "settings.sets.type"
            //     }
            // }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                    font: IVColors.getFont("Subtext")
                    text:"Группировка"
                }

                IVSegmentedControlAdaptive {
                    id: cntAdaptive

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40 * root.isize

                    currentIndex: 0
                    model: ListModel {
                        ListElement {
                            type: "flat"
                            iconName: "new_images/list"
                            text: "Плоская"
                        }
                        ListElement {
                            type: "fact"
                            iconName: "new_images/fact_list"
                            text: "Фактическая"
                        }
                        ListElement {
                            type: "custom"
                            iconName: "new_images/list_custom"
                            text: "Пользовательская"
                        }
                        // ListElement {
                        //     type: "cameras"
                        //     iconName: "new_images/list_custom"
                        //     text: "Камеры"
                        // }
                    }
                    onCurrentIndexChanged: {
                        sourcesCurrent.value = cntAdaptive.currentIndex.toString();
                    }
                    Component.onCompleted: {
                        if (sourcesCurrent.value !== "") {
                            const currAdaptive = clamp(parseInt(sourcesCurrent.value), 0, model.count - 1);
                            cntAdaptive.currentIndex = currAdaptive;
                        }
                    }

                    function clamp(value, min, max) {
                        return Math.max(min, Math.min(value, max));
                    }

                    IvVcliSetting {
                        id: sourcesCurrent
                        name: "sourcesList.currentView"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                IVInputField {
                    id: searchField

                    Layout.fillWidth: true

                    size: IVInputField.Size.Small
                    source: "new_images/search-md"
                    placeholderText: "Найти по названию"
                }

                IVButtonControl {
                    Layout.preferredWidth: 32 * root.isize
                    Layout.preferredHeight: 32 * root.isize

                    type: IVButtonControl.Type.Helper
                    source: sourcesList.isSomeOpened ? "new_images/collapse2" : "new_images/collapse2_expand.svg"
                    toolTipText: sourcesList.isSomeOpened ? "Свернуть всё" : "Развернуть всё"

                    onClicked: {
                        sourcesList.switchExpandFlag();
                    }
                }
            }
        }

        IVSourcesListFlat {
            id: sourcesList

            Layout.fillWidth: true
            Layout.fillHeight: true

            globSignalsObject: root.globSignalsObject
            listType: cntAdaptive.model.get(cntAdaptive.currentIndex).type
            searchText: searchField.text
        }
    }
}

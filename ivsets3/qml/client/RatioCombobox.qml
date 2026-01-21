import QtQuick 2.11
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

import iv.sets.sets3 1.0
import iv.colors 1.0
import iv.controls 1.0


IVComboBox {
    id: root

    borderColor: IVColors.get("Colors/Text new/TxSecondaryThemed")
    chevroneColor: IVColors.get("Colors/Text new/TxSecondaryThemed")
    contentColor: IVColors.get("Colors/Text new/TxPrimaryThemed")
    contentFont: IVColors.getFont("Label")

    popupContentHorizontalMargins: 16
    popupContentVerticalMargins: 8
    popupContentSpacing: 8
    popup.width: 260
    popup.background: Item {
        Rectangle {
            id: rect
            anchors.fill: parent
            color: IVColors.get("Colors/Background new/BgContextMenuThemed")
            radius: 16
        }

        DropShadow {
            anchors.fill: rect
            source: rect
            verticalOffset: 10
            radius: 24
            spread: 0.3
            color: "#4D020720"
            samples: 32
        }
    }

    model: ListModel {
        ListElement {
            custom: false
            xRatio: "21"
            yRatio: "9"
        }
        ListElement {
            custom: false
            xRatio: "16"
            yRatio: "9"
        }
        ListElement {
            custom: false
            xRatio: "4"
            yRatio: "3"
        }
        ListElement {
            custom: true
            xRatio: ""
            yRatio: ""
        }
    }

    function updateCustomElement(xRatio, yRatio) {
        root.model.set(3, { xRatio: xRatio, yRatio: yRatio });
        if (currentIndex === 3 && (!xRatio || !yRatio)) {
            currentIndex = 2;
        }
    }

    function updateSet() {
        const currentItem = model.get(currentIndex)
        if (IVSetsManager.activeSet && currentItem.xRatio && currentItem.yRatio) {
            IVSetsManager.activeSet.xRatio = Number(currentItem.xRatio);
            IVSetsManager.activeSet.yRatio = Number(currentItem.yRatio);
        }
    }

    Connections {
        target: IVSetsManager
        onActiveSetChanged: {
            if (IVSetsManager.activeSet) {
                const setXRatio = String(IVSetsManager.activeSet.xRatio);
                const setYRatio = String(IVSetsManager.activeSet.yRatio);
                for (var i = 0; i < 3; i++) {
                    const listElement = root.model.get(i);
                    if (listElement.xRatio === setXRatio && listElement.yRatio === setYRatio) {
                        root.currentIndex = i;
                        return;
                    }
                }
                updateCustomElement(setXRatio, setYRatio)
                root.currentIndex = 3;
            }

        }
    }

    onCurrentIndexChanged: {
        updateSet();
    }

    contentItem: Text {
        verticalAlignment: Qt.AlignVCenter
        text: IVSetsManager.activeSet
        ? "%1 : %2".arg(IVSetsManager.activeSet.xRatio).arg(IVSetsManager.activeSet.yRatio)
        : "- : -"
        font: IVColors.getFont("Label")
        color: root.contentColor
    }

    delegate: MouseArea {
        width: ListView.view.width
        height: contentLayout.implicitHeight

        enabled: xRatio && yRatio

        onClicked: {
            root.currentIndex = index;
        }

        RowLayout {
            id: contentLayout
            width: parent.width

            IVCheckBoxControl {
                size: IVCheckBoxControl.Size.Default
                shape: IVCheckBoxControl.Shape.Radio
                checked: root.currentIndex === index
                enabled: xRatio && yRatio

                MouseArea {
                    anchors.fill: parent

                    enabled: xRatio && yRatio

                    onClicked: {
                        root.currentIndex = index;
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true

                sourceComponent: custom ? inputDelegate : labelDelegate

                onStatusChanged: {
                    if (item) {
                        item.xRatio = xRatio;
                        item.yRatio = yRatio;
                    }
                }
            }
        }
    }

    Component {
        id: labelDelegate
        Label {
            property int xRatio
            property int yRatio

            text: "%1 : %2".arg(xRatio).arg(yRatio)
            verticalAlignment: Qt.AlignVCenter
            font: IVColors.getFont("Text body")
            color: IVColors.get("Colors/Text new/TxPrimaryThemed")
        }
    }

    Component {
        id: inputDelegate
        RowLayout {
            id: ratioRoot

            property string xRatio
            property string yRatio

            spacing: 8

            function updateModel() {
                root.updateCustomElement(xRatioControl.text, yRatioControl.text);
                root.updateSet();
            }

            IVInputField {
                id: xRatioControl

                Layout.preferredWidth: parent.width / 2 - 10
                Layout.fillHeight: true

                text: xRatio
                validator: RegExpValidator {
                    regExp: /^(?:[1-9]\d{0,3}|10000)$/
                }

                onStateChanged: {
                    if (state === "focused") {
                        textInput.selectAll();
                    }
                    else if (state === "normal") {
                        ratioRoot.updateModel();
                    }
                }
            }

            Label {
                Layout.fillHeight: true

                text: ":"
                verticalAlignment: Qt.AlignVCenter
                font: IVColors.getFont("Text body")
                color: IVColors.get("Colors/Text new/TxPrimaryThemed")
            }

            IVInputField {
                id: yRatioControl

                Layout.preferredWidth: parent.width / 2 - 10
                Layout.fillHeight: true

                text: yRatio
                validator: RegExpValidator {
                    regExp: /^(?:[1-9]\d{0,3}|10000)$/
                }

                onStateChanged: {
                    if (state === "focused") {
                        textInput.selectAll();
                    }
                    else if (state === "normal") {
                        ratioRoot.updateModel();
                    }
                }
            }
        }
    }
}

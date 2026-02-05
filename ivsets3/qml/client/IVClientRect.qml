import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
//import QtQuick.Particles 2.0

import iv.plugins.loader 1.0
import iv.components.windows 1.0
import iv.sets.sets3 1.0
import iv.colors 1.0
import iv.controls 1.0

Rectangle {
    id: root

    property var oldWinFlags: null
    property string unique:"newclient"

    property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1

    implicitWidth: contentLayout.implicitWidth
    implicitHeight: contentLayout.implicitHeight

    color: IVColors.get("Colors/Background new/BgFormPrimaryThemed")

    focus: true
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Control) {
            globSignalsObject.ctrlPressed = true;
        }
    }
    Keys.onReleased: function(event) {
        if (event.key === Qt.Key_Control) {
            globSignalsObject.ctrlPressed = false;
        }
    }
    Component.onCompleted: {
        forceActiveFocus();
    }

    IVClientLeftMenu {
        id: leftMenu

        z: 1
        anchors {
            top: parent.top
            topMargin: tabsPanel.height
            left: parent.left
            bottom: parent.bottom
        }

        extended_menu: false
        globalSignalsObject: globSignalsObject
    }

    IVClientHeaderMini {
        id: miniHeader

        z: 1
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        opacity: Number(!tabsPanel.isVisible)

        onMiniClicked: {
            tabsPanel.isVisible = true
            root.Window.window.flags = root.oldWinFlags
        }
    }

    ColumnLayout {
        id: contentLayout

        anchors.fill: parent
        spacing: 0

        IVClientTabsPanel {
            id: tabsPanel

            property bool isVisible: true

            Layout.fillWidth: true
            Layout.preferredHeight: isVisible ? implicitHeight : 0

            visible: Layout.preferredHeight > 0
            globalSignalsObject: globSignalsObject

            onMiniClicked: {
                isVisible = false;
                root.oldWinFlags = root.Window.window.flags;
            }

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 200; easing.type: Easing.InOutQuad}
            }
        }

        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 0

            IVClientSetsAndCamsBlock {
                Layout.fillHeight: true
                Layout.preferredWidth: globSignalsObject.setsAndCamsBlockOpened ? implicitWidth : 0

                visible: Layout.preferredWidth > 0
                globSignalsObject: globSignalsObject

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }
            }

            IVClientMainRect {
                Layout.fillWidth: true
                Layout.fillHeight: true

                globalSignalsObject: globSignalsObject
            }

            IVClientSetsSettingsPanel {
                Layout.fillHeight: true
                Layout.preferredWidth: globSignalsObject.tabType === "set"
                                       && editPanelOpened.value === "true" ? implicitWidth : 0

                visible: Layout.preferredWidth > 0
                globalSignalsObject: globSignalsObject

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }
            }
        }
    }

    IvVcliSetting {
        id: editPanelOpened
        name: "editPanel.opened"
    }

    IvVcliSetting {
        id: sourcesOpened
        name: "sourcesList.opened"
        Component.onCompleted: {
            globSignalsObject.setsAndCamsBlockOpened = sourcesOpened.value === "true";
        }
    }

    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }

    QtObject {
        id: globSignalsObject

        property bool ctrlPressed: false

        readonly property alias clientRect: root

        signal setToArchive()
        signal setToRealtime()

        signal tabAdded5(string tabname, string type,string id,string viewType)
        signal tabSelected5(string tabname, string type,string id,string viewType)
        signal tabRemoved2(string tabname, string tabType)

        property string tabType: ""
        property string tabViewType: ""

        property string tabUniqId:""

        property bool leftMenuOpened: false
        property bool setsAndCamsBlockOpened: false

        ///Для поддержки старых сигналов
        signal command1(string command, var sender, var params)

        signal removeZoneContent(int indexInSet)

        onSetsAndCamsBlockOpenedChanged: {
            sourcesOpened.value = setsAndCamsBlockOpened ? "true" : "false";
        }
        onTabSelected5: function (tabName, type, setId, viewType) {
            tabType = type;
            tabViewType = viewType;
        }

        // Проверить на нужность
        signal tabAdded4(string tabname, string type,string id,string key2)
        signal tabSelected4(string tabname, string type,string id,string key2) // испускается только в onTabAdded4
    }
}

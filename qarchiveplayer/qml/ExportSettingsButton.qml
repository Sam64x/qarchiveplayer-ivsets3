import QtQuick 2.7
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtQuick.Dialogs 1.3

import ArchiveComponents 1.0
import iv.colors 1.0
import iv.calendar 1.0
import iv.singletonLang 1.0
import iv.controls 1.0 as C

C.IVButtonControl {
    id: root

    property bool sourceInherit: true
    property string selectedPath: appInfo.exportSaveDirectory
    property string selectedFormat: "mkv"
    property string cameraId: ""
    property string archiveId: ""
    property var funcSwitchSelectIntervalMode

    property int maxMemory: 1500
    property int maxMinutes: 60

    property bool exportMetadata: false
    property bool exportCameraInformation: false
    property bool exportPrimitives: false
    property bool exportImagePipeline: false

    property bool isMinutesLimit: true
    property bool isMemoryLimit: true

    property var imagePipeline
    property string wsUrl: appInfo ? appInfo.wsUrl : ""

    property var rootRef
    property var iv_arc_slider_new

    readonly property real rootWidth: rootRef.width
    readonly property real rootHeight: rootRef.height

    property var time_intervals: [
        {"name": Language.getTranslate("5 sec","5 сек")},
        {"name": Language.getTranslate("15 sec","15 сек")},
        {"name": Language.getTranslate("30 sec","30 сек")},
        {"name": Language.getTranslate("1 min","1 мин")},
        {"name": Language.getTranslate("5 min","5 мин")},
        {"name": Language.getTranslate("10 min","10 мин")},
        {"name": Language.getTranslate("15 min","15 мин")},
        {"name": Language.getTranslate("30 min","30 мин")}
    ]

    readonly property int timeBefore: rootRef ? rootRef.exportIntervalBeforeIndex : 2
    readonly property int timeAfter: rootRef ? rootRef.exportIntervalAfterIndex : 4

    readonly property int contentMargins: 8


    function normalizePath(path) {
        if (!path)
            return ""
        path = path.replace(/\\/g, "/")
        path = path.replace(/\/{2,}/g, "/")
        if (Qt.platform.os === "windows") {
            path = path.replace(/\//g, "\\")
        }
        return path
    }

    width: 24
    height: 24
    source: "new_images/settings-02"
    checkable: true
    checked: exportMenu.opened
    size: C.IVButtonControl.Size.Small
    type: C.IVButtonControl.Type.Tertiary
    toolTipText: Language.getTranslate("Show export settings", "Показать настройки экспорта")
    toolTipVisible: !exportMenu.opened && toolTipText.length > 0 && hovered

    onClicked: {
        if (exportMenu.opened)
            exportMenu.close()
        else
            exportMenu.open()
    }


    C.IVContextMenuControl {
        id: exportMenu

        bgColor: IVColors.get("Colors/Background new/BgContextMenuThemed")
        horizontalPadding: 0
        bottomPadding: 16

        readonly property real popupWidth: 410
        readonly property real controlWidth: popupWidth + exportMenu.leftPadding + exportMenu.rightPadding

        x: {
            exportMenu.opened;
            var cx = (root.width - exportMenu.controlWidth) / 2;
            var p = root.mapToItem(rootRef, 0, 0);
            var right = p.x + cx + exportMenu.controlWidth + exportMenu.leftPadding;
            var diff = Math.min(0, rootWidth - right);
            return cx + diff;
        }

        component: ColumnLayout {
            spacing: 0
            width: exportMenu.popupWidth
            height: Math.min(implicitHeight, rootHeight*0.7)

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16

                spacing: root.contentMargins

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48

                    Text {
                        text: Language.getTranslate("Export settings", "Настройки выгрузки")
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                        font: IVColors.getFont("Subtitle accent")
                    }
                }

                C.IVSegmentedControl {
                    visible: false
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    model: ListModel {
                        ListElement { text: "Выгрузка"; iconName: "" }
                        ListElement { text: "Настройки"; iconName: "" }
                    }
                    currentIndex: 0
                    onCurrentIndexChanged: {
                        exportStack.currentIndex = currentIndex
                        exportMenu.close()
                        exportMenu.open()
                    }
                }

                StackLayout {
                    id: exportStack

                    Layout.fillWidth: true
                    Layout.preferredHeight: currentIndex === 0 ? exportColumn.implicitHeight : settingsColumn.implicitHeight
                    currentIndex: 1

                    Flickable {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        contentWidth: width
                        contentHeight: exportColumn.implicitHeight
                        interactive: true
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: exportColumn

                            width: parent.width
                            spacing: root.contentMargins
                        }
                    }

                    Flickable {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        contentWidth: width
                        contentHeight: settingsColumn.implicitHeight
                        interactive: true
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: settingsColumn

                            width: parent.width
                            spacing: root.contentMargins

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 68
                                radius: 8
                                color: IVColors.get("Colors/Background new/BgFormTertiaryThemed")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: root.contentMargins
                                    anchors.rightMargin: root.contentMargins
                                    spacing: 4

                                    ColumnLayout {
                                        Text {
                                            Layout.preferredWidth: 165
                                            wrapMode: Text.WordWrap
                                            lineHeightMode: Text.FixedHeight
                                            lineHeight: 16
                                            text: "Интервал по умолчанию"
                                            font: IVColors.getFont("Text body accent")
                                            color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                        }
                                        Text {
                                            Layout.preferredWidth: 165
                                            wrapMode: Text.WordWrap
                                            lineHeightMode: Text.FixedHeight
                                            lineHeight: 16
                                            text: "Выделяется по двойному клику"
                                            font: IVColors.getFont("Subtext")
                                            color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                        }
                                    }

                                    C.IVImage {
                                        id: chevronImg
                                        Layout.preferredWidth: 24
                                        Layout.preferredHeight: 24
                                        name: "new_images/dots-vertical"
                                        color: IVColors.get("Colors/Text new/TxTertiaryThemed")
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    ColumnLayout {
                                        Layout.preferredWidth: 80

                                        Text {
                                            text: Language.getTranslate("Before", "До")
                                            color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                            font: IVColors.getFont("Label")
                                        }

                                        C.IVButtonControl {
                                            id: beforeComboBox

                                            implicitWidth: 80
                                            implicitHeight: 32
                                            leftPadding: 8
                                            rightPadding: 4
                                            radius: 4
                                            checkable: true
                                            chevroned: true
                                            checked: beforeMenu.opened
                                            layoutAlignment: Qt.AlignLeft
                                            size: C.IVButtonControl.Size.Small
                                            type: C.IVButtonControl.Type.Outline
                                            chevroneSource: "new_images/chevron-selector-vertical"
                                            borderColor: IVColors.get("Colors/Stroke new/StInputfieldThemed")
                                            text: root.time_intervals[root.timeBefore].name

                                            C.IVContextMenuControl {
                                                id: beforeMenu

                                                y: beforeMenu.verticalPadding + beforeComboBox.implicitHeight
                                                horizontalPadding: 0
                                                verticalPadding: 4
                                                radius: 8

                                                component: Column {
                                                    spacing: 1

                                                    Repeater {
                                                        model: root.time_intervals
                                                        delegate: C.IVButtonControl {
                                                            size: C.IVButtonControl.Size.Small
                                                            radius: 0
                                                            width: beforeComboBox.implicitWidth
                                                            height: 20
                                                            checkable: true
                                                            checked: index === root.timeBefore
                                                            text: modelData.name
                                                            onClicked: {
                                                                if (rootRef)
                                                                    rootRef.exportIntervalBeforeIndex = index
                                                                beforeMenu.close()
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            onClicked: {
                                                if (beforeMenu.opened)
                                                    beforeMenu.close();
                                                else
                                                    beforeMenu.open();
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.preferredWidth: 80

                                        Text {
                                            text: Language.getTranslate("After", "После")
                                            color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                            font: IVColors.getFont("Label")
                                        }

                                        C.IVButtonControl {
                                            id: afterComboBox

                                            implicitWidth: 80
                                            implicitHeight: 32
                                            leftPadding: 8
                                            rightPadding: 4
                                            radius: 4
                                            checkable: true
                                            chevroned: true
                                            checked: afterMenu.opened
                                            layoutAlignment: Qt.AlignLeft
                                            size: C.IVButtonControl.Size.Small
                                            type: C.IVButtonControl.Type.Outline
                                            chevroneSource: "new_images/chevron-selector-vertical"
                                            borderColor: IVColors.get("Colors/Stroke new/StInputfieldThemed")
                                            text: root.time_intervals[root.timeAfter].name

                                            C.IVContextMenuControl {
                                                id: afterMenu

                                                y: afterMenu.verticalPadding + afterComboBox.implicitHeight
                                                horizontalPadding: 0
                                                verticalPadding: 4
                                                radius: 8

                                                component: Column {
                                                    spacing: 1

                                                    Repeater {
                                                        model: root.time_intervals
                                                        delegate: C.IVButtonControl {
                                                            size: C.IVButtonControl.Size.Small
                                                            radius: 0
                                                            height: 20
                                                            width: afterComboBox.implicitWidth
                                                            checkable: true
                                                            checked: index === root.timeAfter
                                                            text: modelData.name
                                                            onClicked: {
                                                                if (rootRef)
                                                                    rootRef.exportIntervalAfterIndex = index
                                                                afterMenu.close()
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            onClicked: {
                                                if (afterMenu.opened)
                                                    afterMenu.close();
                                                else
                                                    afterMenu.open();
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "Путь для сохранения файла"
                                font: IVColors.getFont("Label")
                                color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                            }

                            Rectangle {
                                id: pathRect

                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: 8
                                color: "transparent"
                                border.width: 1
                                border.color: IVColors.get("Colors/Stroke new/StInputfieldThemed")

                                Text {
                                    leftPadding: root.contentMargins
                                    anchors.verticalCenter: parent.verticalCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    text: root.selectedPath ? "" : "Выберите путь"
                                    font: IVColors.getFont("Label")
                                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                }

                                Text {
                                    leftPadding: root.contentMargins
                                    anchors.verticalCenter: parent.verticalCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    text: root.normalizePath(root.selectedPath)
                                    font: IVColors.getFont("Label")
                                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                    elide: Text.ElideRight
                                    width: parent.width - 16
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: folderDialog.open()
                                }

                                FileDialog {
                                    id: folderDialog
                                    title: "Выберите папку для сохранения"
                                    folder: shortcuts.home
                                    selectFolder: true
                                    selectMultiple: false

                                    onAccepted: {
                                        root.selectedPath = fileUrl.toString().replace("file:///", "")
                                    }
                                }
                            }

                            RowLayout {
                                Layout.preferredWidth: parent.width
                                spacing: root.contentMargins

                                Text {
                                    leftPadding: root.contentMargins
                                    verticalAlignment: Qt.AlignVCenter
                                    text: "Формат файла"
                                    font: IVColors.getFont("Label")
                                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                }

                                ButtonGroup {
                                    id: checkboxGroup
                                    exclusive: true
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                C.IVCheckBoxControl {
                                    Layout.alignment: Qt.AlignRight
                                    text: "mkv"
                                    shape: C.IVCheckBoxControl.Shape.Radio
                                    ButtonGroup.group: checkboxGroup
                                    checked: true
                                    onCheckedChanged: if (checked) root.selectedFormat = text
                                }

                                C.IVCheckBoxControl {
                                    Layout.alignment: Qt.AlignRight
                                    text: "avi"
                                    shape: C.IVCheckBoxControl.Shape.Radio
                                    ButtonGroup.group: checkboxGroup
                                    onCheckedChanged: if (checked) root.selectedFormat = text
                                }

                                C.IVCheckBoxControl {
                                    Layout.alignment: Qt.AlignRight
                                    text: "mp4"
                                    shape: C.IVCheckBoxControl.Shape.Radio
                                    ButtonGroup.group: checkboxGroup
                                    onCheckedChanged: if (checked) root.selectedFormat = text
                                }
                            }

                            RowLayout {
                                Layout.preferredWidth: parent.width
                                spacing: root.contentMargins

                                Text {
                                    leftPadding: root.contentMargins
                                    verticalAlignment: Qt.AlignVCenter
                                    text: "Ограничивать по памяти"
                                    font: IVColors.getFont("Label")
                                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                }

                                C.IVCheckBoxControl {
                                    Layout.alignment: Qt.AlignRight
                                    checked: root.isMemoryLimit
                                    onCheckedChanged: root.isMemoryLimit = checked
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                enabled: root.isMemoryLimit
                                opacity: enabled ? 1 : 0.5
                                spacing: root.contentMargins

                                Text {
                                    leftPadding: root.contentMargins
                                    Layout.preferredWidth: 180
                                    wrapMode: Text.WordWrap
                                    text: "Максимальный размер файла (Mb)"
                                    font: IVColors.getFont("Label")
                                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                }

                                C.IVInputField {
                                    id: memoryField
                                    Layout.fillWidth: true
                                    text: "1500"

                                    onTextEdited: {
                                        isCorrect = memoryField.text >= 0 && memoryField.text <= 15000
                                    }

                                    onInputAccepted:{
                                        if (isCorrect) {
                                            root.maxMemory = Number(memoryField.text) || 0
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.preferredWidth: parent.width
                                spacing: root.contentMargins

                                Text {
                                    leftPadding: root.contentMargins
                                    verticalAlignment: Qt.AlignVCenter
                                    text: "Ограничивать по минутам"
                                    font: IVColors.getFont("Label")
                                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                }

                                C.IVCheckBoxControl {
                                    Layout.alignment: Qt.AlignRight
                                    checked: root.isMinutesLimit
                                    onCheckedChanged: root.isMinutesLimit = checked
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                enabled: root.isMinutesLimit
                                opacity: enabled ? 1 : 0.5
                                spacing: root.contentMargins

                                Text {
                                    leftPadding: root.contentMargins
                                    Layout.preferredWidth: 180
                                    wrapMode: Text.WordWrap
                                    text: "Максимальная длительность файла (минуты)"
                                    font: IVColors.getFont("Label")
                                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                }

                                C.IVInputField {
                                    id: minutesField
                                    Layout.fillWidth: true
                                    text: "60"

                                    onTextEdited: {
                                        isCorrect = minutesField.text >= 0 && minutesField.text <= 300
                                    }

                                    onInputAccepted:{
                                        if (isCorrect) {
                                            root.maxMinutes = Number(minutesField.text) || 0
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: metadataRectangle

                                Layout.preferredHeight: metadataColumn.implicitHeight + root.contentMargins*2
                                Layout.fillWidth: true
                                radius: 8
                                color: "transparent"
                                border.width: 1
                                border.color: IVColors.get("Colors/Stroke new/StInputfieldThemed")

                                ColumnLayout {
                                    id: metadataColumn

                                    anchors.fill: parent
                                    anchors.margins: root.contentMargins
                                    spacing: root.contentMargins

                                    RowLayout {
                                        Layout.preferredWidth: parent.width
                                        spacing: root.contentMargins

                                        Text {
                                            leftPadding: root.contentMargins
                                            verticalAlignment: Qt.AlignVCenter
                                            text: "Выгружать метаданные"
                                            font: IVColors.getFont("Label")
                                            color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                        }

                                        C.IVCheckBoxControl {
                                            Layout.alignment: Qt.AlignRight
                                            checked: root.exportMetadata
                                            onCheckedChanged: {
                                                root.exportMetadata = checked
                                                if (!root.exportMetadata) {
                                                    primitivesToggle.checked = false
                                                    infoToggle.checked = false
                                                    pipelineToggle.checked = false
                                                }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.preferredWidth: parent.width
                                        enabled: root.exportMetadata
                                        opacity: enabled ? 1 : 0.5

                                        Text {
                                            leftPadding: root.contentMargins
                                            verticalAlignment: Qt.AlignVCenter
                                            text: "Примитивы"
                                            font: IVColors.getFont("Label")
                                            color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                        }


                                        C.IVCheckBoxControl {
                                            id: primitivesToggle
                                            Layout.alignment: Qt.AlignRight
                                            checked: root.exportPrimitives
                                            onCheckedChanged: root.exportPrimitives = checked
                                        }
                                    }

                                    RowLayout {
                                        Layout.preferredWidth: parent.width
                                        enabled: root.exportMetadata
                                        opacity: enabled ? 1 : 0.5

                                        Text {
                                            leftPadding: root.contentMargins
                                            verticalAlignment: Qt.AlignVCenter
                                            text: "Информация о камере"
                                            font: IVColors.getFont("Label")
                                            color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                        }


                                        C.IVCheckBoxControl {
                                            id: infoToggle
                                            Layout.alignment: Qt.AlignRight
                                            checked: root.exportCameraInformation
                                            onCheckedChanged: root.exportCameraInformation = checked
                                        }
                                    }

                                    RowLayout {
                                        Layout.preferredWidth: parent.width
                                        enabled: root.exportMetadata
                                        opacity: enabled ? 1 : 0.5

                                        Text {
                                            leftPadding: root.contentMargins
                                            verticalAlignment: Qt.AlignVCenter
                                            text: "Обработка изображения"
                                            font: IVColors.getFont("Label")
                                            color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                        }


                                        C.IVCheckBoxControl {
                                            id: pipelineToggle
                                            Layout.alignment: Qt.AlignRight
                                            checked: root.exportImagePipeline
                                            onCheckedChanged: root.exportImagePipeline = checked
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            IVSeparator {
                Layout.topMargin: 16
                Layout.preferredHeight: 1
                Layout.fillWidth: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: root.contentMargins
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                spacing: root.contentMargins

                RowLayout {
                    id: timeFieldLayout

                    Layout.fillWidth: true
                    spacing: 4

                    property bool suppressFieldSync: false

                    readonly property var fromTimeRaw: iv_arc_slider_new.firstBorderTime
                    readonly property var toTimeRaw: iv_arc_slider_new.secondBorderTime
                    readonly property bool needSwap: fromTimeRaw > toTimeRaw
                    readonly property var fromTime: needSwap ? toTimeRaw : fromTimeRaw
                    readonly property var toTime: needSwap ? fromTimeRaw : toTimeRaw
                    readonly property string fromUtc: Qt.formatDateTime(fromTime, "dd.MM.yyyy hh:mm:ss")
                    readonly property string toUtc: Qt.formatDateTime(toTime,   "dd.MM.yyyy hh:mm:ss")

                    onFromUtcChanged: {
                        if (timeFieldLayout.suppressFieldSync)
                            return

                        fromField.text = timeFieldLayout.fromUtc
                        var ds = Date.fromLocaleString(Qt.locale(), timeFieldLayout.fromUtc, "dd.MM.yyyy hh:mm:ss")
                        fromField.isCorrect = (ds.toString() !== "Invalid Date" && ds < new Date())
                    }
                    onToUtcChanged: {
                        if (timeFieldLayout.suppressFieldSync)
                            return

                        toField.text = timeFieldLayout.toUtc
                        var ds = Date.fromLocaleString(Qt.locale(), timeFieldLayout.toUtc, "dd.MM.yyyy hh:mm:ss")
                        toField.isCorrect = (ds.toString() !== "Invalid Date" && ds < new Date())
                    }



                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1

                        Text {
                            text: Language.getTranslate("From", "С")
                            color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                            font: IVColors.getFont("Label")
                        }


                        C.IVInputField {
                            id: fromField
                            Layout.fillWidth: true
                            mask: "00.00.0000 00:00:00"

                            property string previousState: state

                            function applyFromInput() {
                                if (isCorrect) {
                                    timeFieldLayout.suppressFieldSync = true
                                    var ds = Date.fromLocaleString(Qt.locale(), text, "dd.MM.yyyy hh:mm:ss")
                                    var toDate = Date.fromLocaleString(Qt.locale(), timeFieldLayout.toUtc,
                                                                       "dd.MM.yyyy hh:mm:ss")
                                    iv_arc_slider_new.setBounds(ds, toDate)
                                    timeFieldLayout.suppressFieldSync = false
                                }
                            }

                            onTextEdited: {
                                var ds = Date.fromLocaleString(Qt.locale(), text, "dd.MM.yyyy hh:mm:ss")
                                isCorrect = (ds.toString() !== "Invalid Date" && ds < new Date())
                            }

                            onInputAccepted: {
                                applyFromInput()
                            }

                            onStateChanged: {
                                if (previousState === "focused" && state === "normal")
                                    applyFromInput()

                                previousState = state
                            }
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignBottom
                        Layout.preferredWidth: 9
                        Layout.preferredHeight: 40

                        Rectangle {
                            anchors.centerIn: parent
                            height: 1
                            width: 6
                            color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1

                        Text {
                            text: Language.getTranslate("To", "По")
                            color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                            font: IVColors.getFont("Label")
                        }

                        C.IVInputField {
                            id: toField
                            Layout.fillWidth: true
                            mask: "00.00.0000 00:00:00"

                            property string previousState: state

                            function applyToInput() {
                                if (isCorrect) {
                                    timeFieldLayout.suppressFieldSync = true
                                    var fromDate = Date.fromLocaleString(Qt.locale(), timeFieldLayout.fromUtc, "dd.MM.yyyy hh:mm:ss")
                                    var ds = Date.fromLocaleString(Qt.locale(), text, "dd.MM.yyyy hh:mm:ss")
                                    iv_arc_slider_new.setBounds(fromDate, ds)
                                    timeFieldLayout.suppressFieldSync = false
                                }
                            }

                            onTextEdited: {
                                var ds = Date.fromLocaleString(Qt.locale(), text, "dd.MM.yyyy hh:mm:ss")
                                isCorrect = (ds.toString() !== "Invalid Date" && ds < new Date())
                            }

                            onInputAccepted: {
                                applyToInput()
                            }

                            onStateChanged: {
                                if (previousState === "focused" && state === "normal")
                                    applyToInput()

                                previousState = state
                            }
                        }
                    }
                }

                C.IVButtonControl {
                    text: Language.getTranslate("Download", "Выгрузить")
                    Layout.fillWidth: true
                    size: C.IVButtonControl.Size.Big
                    type: C.IVButtonControl.Type.Primary
                    onClicked: {
                        if (ExportManager && ExportManager.startExportWithWsUrl && root.wsUrl.length > 0) {
                            var maxChunkFileSizeBytes = root.isMemoryLimit ? root.maxMemory * 1024 * 1024 : 0
                            var maxChunkDurationMinutes = root.isMinutesLimit ? root.maxMinutes : 0
                            var exportPrimitives = root.exportPrimitives
                            var exportCameraInformation = root.exportCameraInformation
                            var exportImagePipeline = root.exportImagePipeline
                            ExportManager.startExportWithWsUrl(root.wsUrl, root.cameraId, timeFieldLayout.fromTime,
                                                               timeFieldLayout.toTime, root.archiveId, root.selectedPath,
                                                               root.selectedFormat, maxChunkDurationMinutes,
                                                               maxChunkFileSizeBytes, exportPrimitives,
                                                               exportCameraInformation, exportImagePipeline,
                                                               root.imagePipeline)
                        } else if (ExportManager && ExportManager.startExport) {
                            var maxChunkFileSizeBytes = root.isMemoryLimit ? root.maxMemory * 1024 * 1024 : 0
                            var maxChunkDurationMinutes = root.isMinutesLimit ? root.maxMinutes : 0
                            var exportPrimitives = root.exportPrimitives
                            var exportCameraInformation = root.exportCameraInformation
                            var exportImagePipeline = root.exportImagePipeline
                            ExportManager.startExport(root.cameraId, timeFieldLayout.fromTime, timeFieldLayout.toTime, root.archiveId,
                                                      root.selectedPath, root.selectedFormat, maxChunkDurationMinutes,
                                                      maxChunkFileSizeBytes, exportPrimitives, exportCameraInformation,
                                                      exportImagePipeline, root.imagePipeline)
                        }
                        exportMenu.close()
                    }
                }
            }
        }
    }
}

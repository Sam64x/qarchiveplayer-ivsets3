import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Dialogs 1.1
import QtQuick.Window 2.3

import iv.plugins.loader 1.0
import iv.sets.sets3 1.0
import iv.components.windows 1.0
import iv.colors 1.0
import iv.controls 1.0

Rectangle
{
    id:root
    color: mainColor
    height: 48
    visible: globalSignalsObject.getEditorStatus()
    property var mainColor: IVColors.get("Colors/Background new/BgContextMenuThemed")
    property var globalSignalsObject: null
    property string editingTabName: ""

    onVisibleChanged: {
        if (visible){
            tabNameField.text = root.editingTabName
        }
    }

    signal miniClicked()
    signal menuClicked();

    IVCustomSets {
        id: customSets
    }
    Connections
    {
        id: globConn
        target: root.globalSignalsObject
        onTabEditedOn:{
            root.visible = true
        }
        onTabEditedOff:{
            root.visible = false
        }
        onSetColsChanged:{
            colsSlider.value = cols;
        }
        onSetRowsChanged:{
            rowsSlider.value = rows;
        }
        onRatioXChanged:{
            aspectXSlider.value = ratioX
        }
        onRatioYChanged:{
            aspectYSlider.value = ratioY
        }
        onTabSelected5:{
            root.editingTabName = tabname
        }
    }
    MessageDialog {
        id: messageDialogSave
        width: 200
        height: 80
        title: "Сохранение набора"
        property string setName: ""
        visible: false
        standardButtons: StandardButton.Apply
        onApply:
        {
        }
    }
    RowLayout {
        id: leftBlock
        anchors {
            bottom: parent.bottom
            top: parent.top
            left: parent.left
            margins: 4
        }
        Layout.alignment: Qt.AlignVCenter
        spacing: 4
        IVButton {
            id: toLeftRect
            type: IVButton.Type.Helper
            Layout.fillHeight: true
            width: 24
            source: "new_images/chevron-left-big"
            toolTipText: "Отменить редактирование"
            onClicked: {
                root.globalSignalsObject.tabEditedOff();
                if (root.globalSignalsObject.setsAndCamsBlockOpened){
                    root.globalSignalsObject.hideSetsAndCams()
                }
            }
        }
        IVInputField {
            id: tabNameField
            Layout.fillHeight: true
            width: 281
            height: parent.height
            placeholderText: root.editingTabName
            text: root.editingTabName
            onTextChanged: {
                var isEmpty = text.length == 0
                var regex = /[^A-Za-zА-Яа-я 0-9.]/g
                var isCorrect = text.match(regex) === null && text.charAt(0) !== " "

                if (isEmpty || !isCorrect) tabNameField.isCorrect = false
                else tabNameField.isCorrect = true
            }
        }
        IVButton {
            id: saveSet
            type: IVButton.Type.Helper
            Layout.fillHeight: true
            width: 24
            source: "new_images/save-02"
            toolTipText: "Сохранить набор"
            function saveSet2()
            {
//                var local_sets = customSets.getLocalSetsList();
//                var remote_sets = customSets.getRemoteSetsList();
                var sets = customSets.getSetsList();
                if (tabNameField.text === "New tab")
                {
                    messageDialogSave.text = "Недопустимое имя набора. Пожалуйста, выберете другое имя."
                    messageDialogSave.open();
                    return;
                }
                //console.error("SAVE SET = " ,root.editingTabName ,  tabNameField.text)
                var lowerNewSetName = tabNameField.text.toLowerCase();
                if (tabNameField.text === root.editingTabName)
                {
                    for (var i2=0;i2<sets.length;i2++)
                    {
                        if (sets[i2]["setName"].toLowerCase() === lowerNewSetName &&  sets[i2]["isuser"] ===0) {
                            messageDialogSave.text = "Имя набора совпадает с уже созданным набором. Пожалуйста, выберете другое имя."
                            messageDialogSave.open();
                            return;
                        }
                    }
                    //console.error("SAVE SET2 = " ,root.editingTabName ,  tabNameField.text)
                    root.globalSignalsObject.setSaved("");
                }
                else
                {
                    //console.error("SAVE SET3 = " ,root.editingTabName ,  tabNameField.text)


                    for (var i1=0;i1<sets.length;i1++)
                    {
                        if (sets[i1]["setName"].toLowerCase() === lowerNewSetName)
                        {
                            messageDialogSave.text = "Имя набора совпадает с уже созданным набором. Пожалуйста, выберете другое имя."
                            messageDialogSave.open();
                            return;
                        }
                    }

                    root.globalSignalsObject.setSaved(tabNameField.text)
                    //root.globalSignalsObject.setAdded(tabNameField.text)

                }
            }

            onClicked:
            {
                saveSet.saveSet2();
            }
        }
    }

    RowLayout {
        id: centerBlock
        anchors {
            bottom: parent.bottom
            top: parent.top
            left:leftBlock.right
            //horizontalCenter: parent.horizontalCenter
            margins: 4
        }
        Layout.alignment: Qt.AlignVCenter
        spacing: 4
        IVButton {
            id: camButton
            type: IVButton.Type.Tertiary
            Layout.fillHeight: true
            width: 40
            source: "new_images/cctv"
            toolTipText: "Камеры"
            onClicked: {
                if (!root.globalSignalsObject.setsAndCamsBlockOpened){
                    root.globalSignalsObject.showSetsAndCams()
                }
                else{
                    root.globalSignalsObject.hideSetsAndCams()
                }
            }
        }
        IVButton {
            id: setsPresetButton
            type: IVButton.Type.Tertiary
            Layout.fillHeight: true
            width: 64
            source: "new_images/grids/" + presetsNames[currPreset]
            toolTipText: "Сетка"
            checkable: true
            checked: gridsMenu.opened
            property int currPreset: 5
            property var presetsNames: [
                "Grid 1", "Grid 1_2", "Grid 1_3", "Grid 2", "Grid 3",
                "Grid 4", "Grid 5", "Grid Custom"
            ]
            onClicked:{
                if (checked) gridsMenu.close()
                else gridsMenu.open()
            }
            IVContextMenu {
                id: gridsMenu
                x: (parent.width-width)/2
                y: parent.height
                component: Column {
                    width: 40*root.isize
                    Repeater {
                        model: setsPresetButton.presetsNames
                        delegate: IVButton {
                            width: parent.width
                            checkable: true
                            checked: index === setsPresetButton.currPreset
                            source: "new_images/grids/"+modelData
                            onClicked: {

                                setsPresetButton.currPreset = index
                                root.globalSignalsObject.setPreset(setsPresetButton.currPreset);
                            }
                        }
                    }
                }
            }
        }
        IVSlider {
            id: rowsSlider
            type: IVButton.Type.Segmented
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            width: 140
            text: "Строк"
            minValue: 1
            value: 32
            maxValue: 128
            onValueChanged:{
                root.globalSignalsObject.setColsRowsChanged(colsSlider.value,rowsSlider.value);
            }
        }
        IVSlider {
            id: colsSlider
            type: IVButton.Type.Segmented
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            width: 140
            text: "Столбцы"
            minValue: 1
            value: 32
            maxValue: 128
            onValueChanged:{
                root.globalSignalsObject.setColsRowsChanged(colsSlider.value,rowsSlider.value);
            }
        }
        IVSlider {
            id: aspectXSlider
            type: IVButton.Type.Segmented
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            width: 180
            text: "Соотношение сторон (ш)"
            minValue: 1
            value: 16
            maxValue: 30
            onValueChanged:{
                root.globalSignalsObject.ratioChanged(aspectXSlider.value, aspectYSlider.value);
            }
        }
        IVSlider {
            id: aspectYSlider
            type: IVButton.Type.Segmented
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            width: 180
            text: "Соотношение сторон (в)"
            minValue: 1
            value: 9
            maxValue: 30
            onValueChanged:{
                root.globalSignalsObject.ratioChanged(aspectXSlider.value, aspectYSlider.value);
            }
        }
    }

    RowLayout {
        id: rightBlock
        anchors {
            bottom: parent.bottom
            top: parent.top
            right: parent.right
            margins: 4
        }
        Layout.alignment: Qt.AlignVCenter
        spacing: 8
        IVButton {
            id: monitorButt
            width: 56
            Layout.fillHeight: true
            type: IVButton.Type.Secondary
            source: "new_images/monitor-01"
            enabled: false
            onClicked: {
                //
            }
        }
        IVButton {
            id: previewButt
            width: 90
            Layout.fillHeight: true
            type: IVButton.Type.Secondary
            text: "Превью"
            enabled: false
            toolTipText: "Превью набора"
            onClicked: {
                //
            }
        }
    }
}

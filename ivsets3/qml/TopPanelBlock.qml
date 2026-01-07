import QtQuick 2.11
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.sets.sets3 1.0
Rectangle
{
    id:root
    /*
     1) ComboBox
     2) save btn
     3) rename btn
     4) delete btn
     5) cols rows
     6) presets
     7) monitor menu
    */
    color: "white"
    property var globSignalsObject: null
    anchors.fill: parent
    RowLayout
    {
        id:mRowLayout
        anchors.fill: parent
        spacing: 3
//        Label
//        {
//            id:pressetsLabel
//            width: contentWidth
//            height: 20
//            text:"Выберите пресет: "
//            font.pixelSize: 16
//        }

        Image
        {
            id:pressetImage1
            source: "file:///"+applicationDirPath + "/images/pressets/presset1.png"
            width: 24
            height: 24
            property real scalePower: 1
            scale: pressetImage1.scalePower
            ToolTip.text: "Пресет 1"
            ToolTip.delay: 1000
            ToolTip.visible:  mar1.containsMouse
            fillMode: Image.PreserveAspectFit
            MouseArea
            {
                anchors.fill: parent
                hoverEnabled: true
                id:mar1
                onClicked:
                {
                    root.globSignalsObject.setPresset1();
                }
                onEntered:
                {
                   // pressetImage1.source = "file:///"+applicationDirPath + "/images/pressets/presset1.png"
                    pressetImage1.scalePower = 0.8
                }
                onExited:
                {
                    pressetImage1.source = "file:///"+applicationDirPath + "/images/pressets/presset1.png"
                    pressetImage1.scalePower = 1
                }
            }
        }
        Image
        {
            id:pressetImage2
            source: "file:///"+applicationDirPath + "/images/pressets/presset2.png"
            width: 24
            height: 24
            property real scalePower: 1
            scale: pressetImage2.scalePower
            ToolTip.text: "Пресет 2"
            ToolTip.delay: 1000
            ToolTip.visible:  mar2.containsMouse
            MouseArea
            {
                anchors.fill: parent
                hoverEnabled: true
                id:mar2
                onClicked:
                {
                    root.globSignalsObject.setPresset2();
                }
                onEntered:
                {
                    //pressetImage2.source = "file:///"+applicationDirPath + "/images/black/plus.svg";
                    pressetImage2.scalePower = 0.8;
                }
                onExited:
                {
                    pressetImage2.source = "file:///"+applicationDirPath + "/images/pressets/presset2.png";
                    pressetImage2.scalePower = 1;
                }
            }
        }
        Image
        {
            id:pressetImage3
            source: "file:///"+applicationDirPath + "/images/pressets/presset3.png"
            width: 24
            height: 24
            property real scalePower: 1
            scale: pressetImage3.scalePower
            ToolTip.text: "Пресет 3"

            ToolTip.delay: 1000
            ToolTip.visible:  mar3.containsMouse
            MouseArea
            {
                anchors.fill: parent
                hoverEnabled: true
                id:mar3
                onClicked:
                {
                    root.globSignalsObject.setPresset3();
                }
                onEntered:
                {
                    //pressetImage3.source = "file:///"+applicationDirPath + "/images/black/plus.svg"
                    pressetImage3.scalePower = 0.8
                }
                onExited:
                {
                    pressetImage3.source = "file:///"+applicationDirPath + "/images/pressets/presset3.png"
                    pressetImage3.scalePower = 1
                }
            }
        }
        Image
        {
            id:setsCopyImage
            source: "file:///"+applicationDirPath + "/images/blue/save_as.svg"
            width: 64
            height: 64
            property real scalePower: 1
            scale: setsCopyImage.scalePower
            ToolTip.text: "Дублировать набор с новым именем"
            ToolTip.delay: 1000
            ToolTip.visible:  mar4.containsMouse
            MouseArea
            {
                anchors.fill: parent
                hoverEnabled: true
                id:mar4
                onClicked:
                {
                    root.globSignalsObject.setCopy("");
                }
                onEntered:
                {
                    setsCopyImage.source = "file:///"+applicationDirPath + "/images/black/save_as.svg"
                    setsCopyImage.scalePower = 0.8
                }
                onExited:
                {
                    setsCopyImage.source = "file:///"+applicationDirPath + "/images/blue/save_as.svg"
                    setsCopyImage.scalePower = 1
                }
            }

        }
        Image
        {
            id:setsSaveImage
            source: "file:///"+applicationDirPath + "/images/blue/save.svg"
            width: 64
            height: 64
            property real scalePower: 1
            scale: setsSaveImage.scalePower
            ToolTip.text: "Сохранить набор"
            ToolTip.delay: 1000
            ToolTip.visible:  mar5.containsMouse
            MouseArea
            {
                anchors.fill: parent
                hoverEnabled: true
                id:mar5
                onClicked:
                {
                    root.globSignalsObject.setSaved2();
                }
                onEntered:
                {
                    setsSaveImage.source = "file:///"+applicationDirPath + "/images/black/save.svg"
                    setsSaveImage.scalePower = 0.8
                }
                onExited:
                {
                    setsSaveImage.source = "file:///"+applicationDirPath + "/images/blue/save.svg"
                    setsSaveImage.scalePower = 1
                }
            }

        }
        Item {
            id: fillWidthItem
            Layout.fillWidth: true
        }
    }
}

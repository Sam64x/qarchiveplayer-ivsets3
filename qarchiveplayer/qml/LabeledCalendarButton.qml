import QtQml 2.1
import QtQuick 2.7
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4

import iv.colors 1.0
import iv.calendar 1.0
import iv.controls 1.0 as C
import iv.singletonLang 1.0

Row {
    property alias calendar: calendar

    spacing: 0

    Canvas {
        width: 141
        height: 24
        onPaint: {
            var ctx = getContext("2d");
            var w = width;
            var h = height;

            var tl = 4;
            var tr = 0;
            var br = 0;
            var bl = 4;

            var outlineWidth = 1;
            var outlineColor = IVColors.get("Colors/Stroke new/StInputfieldThemed");

            ctx.clearRect(0, 0, w, h);

            ctx.lineWidth = outlineWidth;
            ctx.strokeStyle = outlineColor;
            ctx.fillStyle = "transparent";

            var half = outlineWidth / 2;

            ctx.beginPath();

            ctx.moveTo(tl + half, half);

            ctx.lineTo(w - tr - half, half);
            if (tr > 0) {
                ctx.arcTo(w - half, half,  w - half, tr + half, tr);
            } else {
                ctx.lineTo(w - half, half);
            }

            ctx.lineTo(w - half, h - br - half);
            if (br > 0) {
                ctx.arcTo(w - half, h - half, w - br - half, h - half, br);
            } else {
                ctx.lineTo(w - half, h - half);
            }

            ctx.lineTo(bl + half, h - half);
            if (bl > 0) {
                ctx.arcTo(half, h - half,     half, h - bl - half, bl);
            } else {
                ctx.lineTo(half, h - half);
            }

            ctx.lineTo(half, tl + half);
            if (tl > 0) {
                ctx.arcTo(half, half,tl + half, half, tl);
            } else {
                ctx.lineTo(half, half);
            }

            ctx.closePath();

            ctx.fill();
            if (outlineWidth > 0) {
                ctx.stroke();
            }
        }

        Label {
            leftPadding: 8
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Qt.AlignVCenter
            text: calendar.chosenDate + "  " + calendar.chosenTime.split(/[:]/)[0] + ":" + calendar.chosenTime.split(/[:]/)[1] + ":" + calendar.chosenTime.split(/[:]/)[2]
            font: IVColors.getFont("Label")
            color: IVColors.get("Colors/Text new/TxPrimaryThemed")
        }
    }

    C.IVButtonControl {
        source: "new_images/calendar-selector"
        height: 24
        width: 24
        radius: 0
        topRightRadius: 4
        bottomRightRadius: 4
        size: C.IVButtonControl.Size.Small
        type: C.IVButtonControl.Type.Secondary
        toolTipText: calendar.opened ? "" : Language.getTranslate("Calendar","Календарь")

        checkable: true
        checked: calendar.opened

        onClicked: {
            if (calendar.opened)
                calendar.close();
            else
                calendar.open();
        }

        C.IVContextMenuControl {
            id: calendar
            verticalPadding: 16
            bgColor: IVColors.get("Colors/Background new/BgContextMenuThemed")

            property date _now: new Date()
            property date _nowMinus5: new Date(_now.getTime() - 5 * 60 * 1000)

            property string chosenDate: Qt.formatDate(_nowMinus5, "dd.MM.yyyy")
            property string chosenTime: Qt.formatTime(_nowMinus5, "hh:mm:ss")


            signal setCurrTimeCommand
            signal nessUpdateCalendarDecr
            signal nessUpdateCalendar
            signal setNewDate(var newDate)

            function getTimestamp(){
                var dateTime = chosenDate + " " + chosenTime
                var parts = dateTime.split(/[. :]/)
                var dateObject = new Date(parts[2], parts[1] - 1, parts[0],
                                          parts[3], parts[4], parts[5])
                return dateObject.getTime()
            }
            component: Component {
                ColumnLayout {
                    id: col
                    spacing: 8
                    C.IVInputField {
                        id: dateInputField
                        Layout.fillWidth: true
                        text: chosenDate + " " + chosenTime
                        name: "Перейти к"
                        mask: "00.00.0000 00:00:00"
                        onTextEdited: {
                            var ds = Date.fromLocaleString(Qt.locale(), text, "dd.MM.yyyy hh:mm:ss")
                            isCorrect = (ds.toString() !== "Invalid Date" && ds < new Date())
                        }
                        onInputAccepted:{
                            if (isCorrect) {
                                var ds = Date.fromLocaleString(Qt.locale(), text, "dd.MM.yyyy hh:mm:ss")
                                calendBody.currentDate = ds
                            }
                        }
                    }
                    C.IVCalendar {
                        id: calendBody
                        width: 390 * root.isize
                        selectable: false
                        currentDate: new Date(calendar.getTimestamp())
                        onCurrentDateChanged: {
                            calendar.chosenDate = Qt.formatDate(currentDate, "dd.MM.yyyy")
                            calendar.chosenTime = Qt.formatTime(currentDate, "hh:mm:ss")
                            dateInputField.text = Qt.formatDateTime(currentDate, "dd.MM.yyyy hh:mm:ss")
                            if (!root.b_input_time_outside_cahange) updateTimeFromCalendar()
                        }
                        Connections {
                            target: calendar
                            onSetNewDate: calendBody.currentDate = newDate
                        }
                    }
                }
            }
        }
    }
}

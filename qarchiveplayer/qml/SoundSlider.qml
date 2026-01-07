import QtQuick 2.7
import iv.singletonLang 1.0
import iv.colors 1.0
import iv.controls 1.0 as C

Rectangle {
    id: root

    property int volume: 50

    implicitWidth: 24
    implicitHeight: 109
    radius: 8
    color: IVColors.get("Colors/Background new/BgFormOverVideo")

    Rectangle {
          id: track

          anchors {
              top: parent.top
              horizontalCenter: parent.horizontalCenter
              topMargin: 4
          }

          implicitHeight: 80
          implicitWidth: 16
          color: IVColors.get("Colors/Background new/BgFormSecondaryThemed")
          radius: 4

          Rectangle {
              anchors {
                  horizontalCenter: parent.horizontalCenter
                  bottom: parent.bottom
              }
              width:  parent.width
              height: parent.height * root.volume / 100.0
              radius: 4
              color: IVColors.get("Colors/Background new/BgBtnContrast")
          }

          MouseArea {
              anchors.fill: parent
              onPressed: updateVolume(mouse.y)
              onPositionChanged: if (pressed) updateVolume(mouse.y)

              function updateVolume(localY) {
                  var h = track.height
                  var v = Math.round(100 * (h - localY) / h)
                  v = Math.max(0, Math.min(100, v))
                  if (root.volume !== v) {
                      root.volume = v
                }
            }
        }
    }

    C.IVButtonControl {
        source: "new_images/"+(!checked ? "soundsOn" : "soundsOff")
        anchors.bottom: parent.bottom
        implicitHeight: 24
        implicitWidth: 24
        size: C.IVButtonControl.Size.Small
        type: C.IVButtonControl.Type.Flat
        checkable: true
        toolTipText: !checked ? Language.getTranslate("Sounds on", "Вкл звук") :
                               Language.getTranslate("Sounds off","Выкл звук")
    }
}


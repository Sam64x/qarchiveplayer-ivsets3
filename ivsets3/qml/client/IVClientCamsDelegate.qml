import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.sets.sets3 1.0
import QtQuick.Dialogs 1.1

Rectangle
{
    id:root
    color: "#d9d9d9"
    property string textColor: "black"
    property int innerIndex: -1
    property int currentIndex: -1
    property var globSignalsObject: null
    visible: model.isVisible
    height: model.isVisible? (root.typeOfDelegate ==="row"? 30:150) : 0
    width: parent.width//-10
    property string typeOfDelegate: "row"
    Loader
    {
        anchors.fill: parent
        id:tmpLoad
        source: switch(root.typeOfDelegate)
        {
            case "preview": return "IVClientPreviewCam.qml"
            case "row": return "IVClientRowCam.qml"
        }
        onStatusChanged:
        {
            if(tmpLoad.status === Loader.Ready)
            {
                tmpLoad.item.globSignalsObject = root.globSignalsObject;
//                try
//                {
//                    if(model.type === "camera")
//                    {
//                        var obbj = model.params
//                    }
//                }
//                catch(except)
//                {
//                    console.error("IVClientCamsDel parse errror = ",except)
//                }

                tmpLoad.item.params = params;
                tmpLoad.item.qmlPath = qmlPath;
                tmpLoad.item.type = type;
                tmpLoad.item.key2 = key2;
            }
        }
    }
}

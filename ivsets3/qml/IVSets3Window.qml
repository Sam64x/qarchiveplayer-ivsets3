import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import QtQml 2.3
import iv.sets.sets3 1.0

ApplicationWindow
{
    id: root
    color: "white"
    //anchors.fill: parent
    width: 800
    height: 600
    visible: false
    property string setName: ""
    property int winIndex: -1
    property string outProperties:""
    property int deinit: 0
    onDeinitChanged:
    {
        if(root.deinit === 1)
        {
            root.x = 0;
            root.y = 0;
            root.width = 0;
            root.height = 0;

        }
    }

    onOutPropertiesChanged:
    {
        var settingsObj = JSON.parse(root.outProperties);
        var x__ = settingsObj["x"];
        var y__ = settingsObj["y"];
        var width__ = settingsObj["width"];
        var height__ = settingsObj["height"];
        var topmost_ = settingsObj["topmost"];
        var vis = settingsObj["visible"];
        if(topmost_)
        {
            root.flags = Qt.WindowStaysOnTopHint;
        }
        if(vis)
        {
            //root.visible = true;
        }
        else
        {
            //root.visible = false;
        }

        root.x = x__;
        root.y = y__;
        root.width = width__;
        root.height = height__;

    }

    IVSets3
    {
        anchors.fill: parent
        setName:root.setName
    }
}

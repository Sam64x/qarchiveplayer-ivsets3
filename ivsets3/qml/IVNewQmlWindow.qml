import QtQuick 2.11
import QtQuick.Controls 2.1
import QtQuick.Window 2.11

ApplicationWindow  {
    id: root
    visible: true
    property string path: ""
    property var params: ({})
    height: 720
    width: 1280
    minimumHeight: 100
    minimumWidth: 100
    title: "Новое окно (Видеоклиент)"
    Loader {
        id: content
        anchors.fill: parent
        asynchronous: true
        source: path
        active: path.length > 0
    }
    onParamsChanged: {
        if (params.height !== undefined) height = params.height
        if (params.width !== undefined) width = params.width
        if (params.minimumHeight !== undefined) minimumHeight = params.minimumHeight
        if (params.minimumWidth !== undefined) minimumWidth = params.minimumWidth
        if (params.flags !== undefined) flags = params.flags
        if (params.title !== undefined) title = params.title

        var p = {}
        p.height = height
        p.width = width
        p.minimumHeight = minimumHeight
        p.minimumWidth = minimumWidth
        p.flags = flags
        p.title = title
        console.log("New window p:", JSON.stringify(p))
    }
    onClosing: {
        content.source = ""
        root.destroy()
    }
    Component.onCompleted: {
        //flags |= Qt.WindowStaysOnTopHint
    }
    Component.onDestruction: {
        //console.log("Window", title, root, "onDestruction")
    }
}

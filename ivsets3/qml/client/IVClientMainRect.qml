import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.sets.sets3 1.0
import iv.colors 1.0
import iv.controls 1.0

Rectangle
{
    id:root
    anchors.fill: parent
    color: mainColor
    property var mainColor: IVColors.get("Colors/Background new/BgFormPrimaryThemed")
    property string qmlfile: "/qtplugins/iv/sets/sets3/IVClientSetsZone.qml"
    onQmlfileChanged:
    {
        console.log("qrqwrwqrqwr qmlfile", qmlfile)
        mainLoader.create1();
    }

    property var globalSignalsObject: null
    Component.onCompleted:
    {
        mainLoader.create1();
    }
    Component.onDestruction:
    {
        mainLoader.destroy1();
    }

    Connections
    {
        id:myConn
        target:root.globalSignalsObject
        onSettingsLoad:
        {
            //root.qmlfile = "/qtplugins/iv/comcomp/IVSettingsTab.qml"
        }
        onSetsLoad:
        {
            root.qmlfile = "/qtplugins/iv/sets/sets3/IVClientSetsZone.qml"
        }
    }


    Loader {
        id:mainLoader
        anchors.fill: parent
        asynchronous: false
        property var componentMain: null
        function create1()
        {
            var qmlFile2 = 'file:///' + applicationDirPath +  root.qmlfile;
            mainLoader.source = qmlFile2;
        }
        function refresh()
        {
            mainLoader.destroy1();
            mainLoader.create1();
        }
        function destroy1()
        {
            if(mainLoader.status !== Loader.Null)
                mainLoader.source = "";
        }
        onStatusChanged:
        {
            if (mainLoader.status === Loader.Ready)
            {
                mainLoader.componentMain = mainLoader.item;
                mainLoader.componentMain.isSets = true;
                mainLoader.componentMain.globSignalsObject = root.globalSignalsObject;
                mainLoader.componentMain.anchors.fill = mainLoader;

            }
            if(mainLoader.status === Loader.Error)
            {
                console.error("mainLoader error");
            }
            if(mainLoader.status === Loader.Null)
            {

            }
        }
    }
}

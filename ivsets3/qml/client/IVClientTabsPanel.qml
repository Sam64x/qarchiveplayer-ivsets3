import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import QtGraphicalEffects 1.0

import iv.singletonLang 1.0
import iv.sets.sets3 1.0
import iv.components.windows 1.0
import iv.plugins.users 1.0
import iv.plugins.loader 1.0
import iv.colors 1.0
import iv.controls 1.0

Rectangle
{
    id: root
    color: IVColors.get("Colors/Background new/BgContextMenuThemed")
    height: 48*root.isize
    property bool useAnimation: false
    property var globalSignalsObject: null
    property string userName: ""
    signal miniClicked
    signal menuClicked
    property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1
    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }
    IvVcliSetting
    {
        id: archive_fix2
        name: 'archive.fixVisible'
        Component.onCompleted:
        {
            if(archive_fix2.value === "true")
            {
                archImage.setViewType("archive");
            }
            else
            {
                archImage.setViewType("realtime");
            }
        }
    }
    property bool isMapInit: false

//    Timer
//    {
//        id:mapTimer
//        interval: 1000
//        triggeredOnStart: false
//        running: false
//        repeat: false
//        onTriggered:
//        {
//             customSets.initMap();
//        }
//    }
    IvVcliSetting {
        id:hideSets
        name: 'settings.hide_new_sets'
    }
    IvVcliSetting {
        id: eventsMaps
        name: 'settings.openMapFromEvents'
    }
    IvVcliSetting {
        id: maxTabsLimit
        name: 'dev.maxTabs'
        Component.onCompleted: getMaxTabsLimit()
    }
    IVCustomSets {
        id:customSets
        Component.onCompleted:
        {
//            if(eventsMaps.value === "true")
//            {
              customSets.initWs();
//                mapTimer.start();
//            }

        }
        onEventMapChanged:
        {
            root.globalSignalsObject.tabAdded4(mapName,"map","",key2);
        }
    }
    Timer {
        id:setsTimer22

        running: false
        triggeredOnStart: false
        interval:500
        repeat: false
        onTriggered:
        {
            var opTabs = openedTabsSettings.value;
            openedTabsModel.clear();
            try
            {
                var tabsArray = JSON.parse(opTabs);
                if(tabsArray.length>0)
                {
                    for(var i =0;i<tabsArray.length;i++)
                    {
                        if(archive_fix2.value === "true")
                        {
                            openedTabsModel.append({type:tabsArray[i].type,name:tabsArray[i].name,tabId:tabsArray[i].tabId,view:"archive"})
                        }
                        else
                        {
                            openedTabsModel.append({type:tabsArray[i].type,name:tabsArray[i].name,tabId:tabsArray[i].tabId,view:tabsArray[i].view})
                        }
                    }
                    var trimResult = trimTabsToLimit();
                    if(trimResult.trimmed)
                    {
                        openedTabsSettings.value = getStringFromModel(openedTabsModel);
                    }
                    var isFound = false;
                    var activeTabName = activeTabSettings.value;
                    root.globalSignalsObject.clearView();
                    for(var i1=0;i1<openedTabsModel.count;i1++)
                    {
                        var tabItem = openedTabsModel.get(i1);
                        if(tabItem.name ===activeTabName )
                        {
                            tabsListView.currentIndex = i1;
                            root.globalSignalsObject.tabSelected5(tabItem.name,tabItem.type,tabItem.tabId,tabItem.view);
                            isFound = true;
                            break;
                        }
                    }
                    if(!isFound)
                    {
                        if(openedTabsModel.count>0)
                        {
                            tabsListView.currentIndex = trimResult.index >=0 ? trimResult.index : 0;
                            var tabItem2 = openedTabsModel.get(tabsListView.currentIndex);
                            activeTabSettings.value = tabItem2.name;
                            root.globalSignalsObject.tabSelected5(tabItem2.name,tabItem2.type,tabItem2.tabId,tabItem2.view);
                        }
                    }
                }
            }
            catch(exception)
            {
            }
        }
    }

    IvVcliSetting {
        id:openedTabsSettings
        name: root.Window.window.unique?root.userName+"#"+root.Window.window.unique+"#tabs#openedTabs":""
        onValueChanged:
        {

        }
    }
    IvVcliSetting {
        id:setsTimerSettings
        name:root.Window.window.unique?root.userName+"#"+root.Window.window.unique+"#tabs#setsTimer":""
    }
    IvVcliSetting {
        id:activeTabSettings
        name:root.Window.window.unique?root.userName+"#"+root.Window.window.unique+"#tabs#activeTab":""
    }
    IvVcliSetting{
        id: systemFrame
        name: 'interface.system_frame'
    }

    Timer {
        id:setsTimer
        property bool isFirstStart: true
        running: setsTimerSettings.value==="1"?true:false
        triggeredOnStart: false
        interval:5000
        repeat: true
        onTriggered:
        {
            //console.error("timer triggered = ",tabsListView.currentIndex ,openedTabsModel.count)
            var tabCount = openedTabsModel.count;
            var currIndex = tabsListView.currentIndex;

            if(currIndex<tabCount-1)
            {
                tabsListView.currentIndex++
                var cuurTab = openedTabsModel.get(tabsListView.currentIndex);
                root.globalSignalsObject.tabSelected5(cuurTab.name,cuurTab.type,cuurTab.id,cuurTab.view);
            }
            else
            {
                tabsListView.currentIndex=0
                var cuurTab = openedTabsModel.get(tabsListView.currentIndex);
                root.globalSignalsObject.tabSelected5(cuurTab.name,cuurTab.type,cuurTab.id,cuurTab.view);
            }



//            if(tabsListView.currentIndex === openedTabsModel.count-1)
//            {
//                tabsListView.currentIndex = 0;
//                if(openedTabsModel.get(tabsListView.currentIndex).isExist)
//                {
//                    root.globalSignalsObject.tabSelected(openedTabsModel.get(tabsListView.currentIndex).name,tabsListView.currentIndex);
//                }
//                else
//                {
//                    var name = openedTabsModel.get(tabsListView.currentIndex).name;
//                    var type1 = openedTabsModel.get(tabsListView.currentIndex).type;
//                    var ind1 = openedTabsModel.get(tabsListView.currentIndex).ndex
//                    var qmlPath2 = openedTabsModel.get(tabsListView.currentIndex).qmlPath;
//                    var params2 = openedTabsModel.get(tabsListView.currentIndex).params;
//                    root.globalSignalsObject.tabSelectedOnceCam(name,ind1,type1,params2,qmlPath2);
//                }
//            }
//            else
//            {
//                tabsListView.currentIndex = tabsListView.currentIndex+1;
//                if(openedTabsModel.get(tabsListView.currentIndex).isExist)
//                {

//                    root.globalSignalsObject.tabSelected(openedTabsModel.get(tabsListView.currentIndex).name,tabsListView.currentIndex);
//                }
//                else
//                {
//                    var name = openedTabsModel.get(tabsListView.currentIndex).name;
//                    var type1 = openedTabsModel.get(tabsListView.currentIndex).type;
//                    var ind1 = openedTabsModel.get(tabsListView.currentIndex).ndex
//                    var qmlPath2 = openedTabsModel.get(tabsListView.currentIndex).qmlPath;
//                    var params2 = openedTabsModel.get(tabsListView.currentIndex).params;
//                    root.globalSignalsObject.tabSelectedOnceCam(name,ind1,type1,params2,qmlPath2);
//                }
//            }
        }
    }

    Connections {
        id:globConn
        target: root.globalSignalsObject
        onUserChanged:
        {
            root.userName = userName;
            setsTimer22.restart();
        }
        onTabRemoveLeft:
        {
            //console.error("onTabRemoveLeft ",openedTabsModel.count);
            //console.error("onTabRemoveLeft ",tabsListView.currentIndex);
            var modelIndex = 0;
            for(var i = 0;i<openedTabsModel.count;i++ )
            {
                if(openedTabsModel.get(i).name === tabname)
                {
                    modelIndex = i;
                }
            }
             //console.error("onTabRemoveLeft ",modelIndex);
            openedTabsModel.remove(0,modelIndex);
            var tmpStr = getStringFromModel(openedTabsModel);
            openedTabsSettings.value = tmpStr;
        }
        onTabRemoveRight:
        {
            var modelIndex = 0;
            for(var i = 0;i<openedTabsModel.count;i++ )
            {
                if(openedTabsModel.get(i).name === tabname)
                {
                    modelIndex = i;
                }
            }
            var count = openedTabsModel.count-modelIndex-1;
            //console.error("onTabRemoveRight ",openedTabsModel.count);
            //console.error("onTabRemoveRight ",tabsListView.currentIndex);
            //console.error("onTabRemoveLeft ",modelIndex);

            openedTabsModel.remove(modelIndex+1,count);


            var tmpStr = getStringFromModel(openedTabsModel);
            openedTabsSettings.value = tmpStr;
        }


        onTabEditedOn:{
            root.visible = false
        }
        onTabEditedOff:{
            root.visible = true
        }
        onSetSaved:
        {
//            if(setname!== "")
//            {
//                for(var i1=0;i1<openedTabsModel.count;i1++)
//                {
//                    var tabItem = openedTabsModel.get(i1);
//                    console.error("TABS PANEL onSetSaved",tabItem.name);
//                    if(tabItem.name === setname)
//                    {
//                        openedTabsModel.setProperty(i1,"name",setname);
//                        var tmpStr = getStringFromModel(openedTabsModel);
//                        openedTabsSettings.value = tmpStr;
//                    }



//                }
//            }
        }
        onSetNameChanged:
        {
            //(string setname,string newSetName)
            var count = openedTabsModel.count
            var i1;
            //console.error("TABS PANEL onSetNameChanged",setname,newSetName )
            for(i1=0;i1<count;i1++)
            {
                var tabItem = openedTabsModel.get(i1);
                //console.error("TABS PANEL onSetNameChanged2 ",tabItem.name,tabItem.type )
                if(tabItem.name=== setname)
                {
                    openedTabsModel.setProperty(i1,"name",newSetName);
                    tabsListView.currentIndex = i1;
                    var tabItem2 = openedTabsModel.get(i1);
                    //console.error("TABS PANEL onSetNameChanged3 ",tabItem2.name,tabItem2.type )
                    break;
                }
            }
            var tabItem22 = openedTabsModel.get(i1);
            activeTabSettings.value = tabItem22.name;
            var tmpStr = getStringFromModel(openedTabsModel);
            openedTabsSettings.value = tmpStr;





        }

        onSetsCompleted:
        {
            var activeTabName = activeTabSettings.value;
            for(var i1=0;i1<openedTabsModel.count;i1++)
            {
                var tabItem = openedTabsModel.get(i1);
                if(tabItem.name ===activeTabName )
                {
                    tabsListView.currentIndex = i1;
                    //root.globalSignalsObject.tabSelected3(tabItem.name,tabItem.type,tabItem.tabId);
                }
            }
            if(tabsListView.currentIndex>=0)
            tabsListView.positionViewAtIndex(tabsListView.currentIndex, ListView.End);
        }
        onTabRemoved2:
        {
//            var oldIndex = index;

//            if(index === -1)
//            {
//                index = tabsListView.currentIndex;
//            }
            //openedTabsModel.remove(index,1);
            //console.error("TAB REMOVED TAB NAME = ", tabname);

            var count = openedTabsModel.count
            var i1;
            for(i1=0;i1<count;i1++)
            {
                var tabItem = openedTabsModel.get(i1);
                if(tabItem.name=== tabname)
                {
                    //console.error("TAB REMOVED TAB NAME FOUND = ", tabname , i1, openedTabsModel.count);
                    openedTabsModel.remove(i1,1);
                    break;
                }
            }
            if(openedTabsModel.count===0)
            {
                root.globalSignalsObject.clearView();
                //return;
            }

            if(i1>=0 && openedTabsModel.count>0)
            {
                if(i1<openedTabsModel.count)
                {
                    tabsListView.currentIndex = i1;
                }
                else
                {
                    tabsListView.currentIndex = (i1-1)<0?0:i1-1;
                }


                var currItem = openedTabsModel.get(tabsListView.currentIndex);
                //console.error("TAB REMOVED TAB NAME FOUND2 = ",tabsListView.currentIndex,i1);
                //console.error("TAB REMOVED TAB NAME FOUND3 = ",currItem.name,currItem.type);
                root.globalSignalsObject.tabSelected3(currItem.name,currItem.type,currItem.id);
                activeTabSettings.value = currItem.name;
            }
            var tmpStr = getStringFromModel(openedTabsModel);
            openedTabsSettings.value = tmpStr;
            //console.error("onTabRemoved----------------------111111111111111111")
        }
//        onTabAdded3:
//        {
////            if(hideSets.value === "true")
////            {
////                root.globalSignalsObject.tabSelected3(tabname,type,id);
////                return;
////            }

//            console.error("FFFFFFFFFFFFFFF onTabAdded3 = ",tabname,type,id);
//            var isFound = false;
//            for(var i =0;i<openedTabsModel.count;i++ )
//            {
//                var tabName_ =  openedTabsModel.get(i).name;
//                var tabid_ =  openedTabsModel.get(i).tabId;
//                var _view = "realtime";
//                if(tabName_ === tabname && tabid_ === id)
//                {
//                    tabsListView.currentIndex = i;
//                    root.globalSignalsObject.tabSelected5(tabName_,type,id,_view);
//                    return;
//                }
//            }
//             console.error("onTabAdded----------------------111111111111111111",tabname,type,id)

//            openedTabsModel.append({type: type,name:tabname,tabId:id,view:"realtime"});
//            console.error("onTabAdded22222----------------------111111111111111111",tabname,type,id,openedTabsModel.count)
//            //tabsListView.currentIndex = openedTabsModel.count-1;
//            root.globalSignalsObject.tabSelected5(tabname,type,id,"realtime");
//            //activeTabSettings.value = tabname;
//            var tmpStr = getStringFromModel(openedTabsModel);
//            openedTabsSettings.value = tmpStr;
//            console.error("onTabAdded22222----------------------111111111111111111",tabname,type,id,tmpStr)
//            //for(var i =0;i<openedTabsModel.count;i++ )
//            //{
//                 //console.error("onTabAdded tabname = " , i, openedTabsModel.get(i).name , tmpStr);

//            //}
//            //console.error("onTabAdded----------------------111111111111111111")
//            //save new tab list
//        }
        onTabAdded4:
        {
            var isFound = false;
            for(var i =0;i<openedTabsModel.count;i++ )
            {
                var tabName_ =  openedTabsModel.get(i).name;
                var tabid_ =  openedTabsModel.get(i).tabId;
                if(tabName_ === tabname && tabid_ === id)
                {
                    tabsListView.currentIndex = i;
                    root.globalSignalsObject.tabSelected4(tabName_,type,id,key2);
                    return;
                }
            }

            openedTabsModel.append({type: type,name:tabname,tabId:id});
            var trimResult4 = trimTabsToLimit(openedTabsModel.count-1);
            tabsListView.currentIndex = trimResult4.index;
            root.globalSignalsObject.tabSelected4(tabname,type,id,key2);
            //activeTabSettings.value = tabname;
            var tmpStr = getStringFromModel(openedTabsModel);
            openedTabsSettings.value = tmpStr;
            //for(var i =0;i<openedTabsModel.count;i++ )
            //{
                 //console.error("onTabAdded tabname = " , i, openedTabsModel.get(i).name , tmpStr);

            //}
            //console.error("onTabAdded----------------------111111111111111111")
            //save new tab list
        }
        onTabAdded5:
        {
            var isFound = false;
            for(var i =0;i<openedTabsModel.count;i++ )
            {
                var tabName_ =  openedTabsModel.get(i).name;
                var tabid_ =  openedTabsModel.get(i).tabId;
                var _view =  openedTabsModel.get(i).view;
                if(tabName_ === tabname && tabid_ === id)
                {
                    var tt = openedTabsModel.get(i);
                    tabsListView.currentIndex = i;
                    //tt.viewType = viewType;
                    tabsListView.currentItem.viewType = viewType;
                    //console.error("FFFFFFFFFFFFFFF onTabAdded666 = ",tt.viewType);
                    //openedTabsModel.setData(i,{"view":viewType});
                    openedTabsModel.setProperty(i,"view",viewType);

                    //openedTabsModel.sync();
                    root.globalSignalsObject.tabSelected5(tabName_,type,id,viewType);
                    var tmpStr = getStringFromModel(openedTabsModel);
                    openedTabsSettings.value = tmpStr;
                    return;
                }
            }
            openedTabsModel.append({type: type,name:tabname,tabId:id,view:viewType});
            var trimResult5 = trimTabsToLimit(openedTabsModel.count-1);
            tabsListView.currentIndex = trimResult5.index;
            var currentTab = openedTabsModel.get(tabsListView.currentIndex);
            root.globalSignalsObject.tabSelected5(currentTab.name,currentTab.type,currentTab.tabId,currentTab.view);
            activeTabSettings.value = currentTab.name;
            var tmpStr = getStringFromModel(openedTabsModel);
            openedTabsSettings.value = tmpStr;
            //for(var i =0;i<openedTabsModel.count;i++ )
            //{
                 //console.error("onTabAdded tabname = " , i, openedTabsModel.get(i).name , tmpStr);

            //}
            //console.error("onTabAdded----------------------111111111111111111")
            //save new tab list
            //root.globalSignalsObject.setsCompleted();
            if(tabsListView.currentIndex>=0)
            tabsListView.positionViewAtIndex(tabsListView.currentIndex, ListView.End);
        }


        onTabSelected5:
        {
            activeTabSettings.value = tabname;
            //console.error("ACTIVE TAB234 = ",activeTabSettings.value );

        }

//        onTabAdded:
//        {
//            var isFound = false;
//            for(var i =0;i<openedTabsModel.count;i++ )
//            {
//                var tabName_ =  openedTabsModel.get(i).name;
//                if(tabName_ === tabname)
//                {
//                    tabsListView.currentIndex = i;
//                    root.globalSignalsObject.tabSelected(tabName_,i);
//                    return;
//                }
//            }

//            openedTabsModel.append({type: "set",param: {},name:tabname,qmlPath:"/qtplugins/iv/sets/sets3/IVClientSetsZone.qml",isExist:true});
//            tabsListView.currentIndex = openedTabsModel.count-1;
//            root.globalSignalsObject.tabSelected(tabname,tabsListView.currentIndex);
//            var tmpStr = getStringFromModel(openedTabsModel);
//            openedTabsSettings.value = tmpStr;
// console.error("onTabAdded----------------------111111111111111111")
//            //save new tab list
//        }

    }

    ListModel {
        id: openedTabsModel
        onCountChanged:
        {

        }
        Component.onCompleted: {

        }
    }

    Rectangle {
        id: tabsRect
        color: "transparent"
        visible: hideSets.value !== "true"
        clip: true
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: rightArea.left
            left: parent.left
            bottomMargin: 8
            topMargin: 8
        }
        Rectangle{
            id: innerTabsRect
            color: "transparent"
            anchors.centerIn: parent
            height: parent.height
            width: contentWidth > parent.width ? parent.width : contentWidth
            property real spacing: 4
            property real contentWidth: (playMap.width+
                                         playRect.width +
                                         toLeftRect.width +
                                         tabsListView.contentWidth +
                                         toRightRect.width +
                                         newTabButton.width +
                                         6*spacing)
            IvVcliSetting{
                id: autoScroll
                name: 'sets.autoScroll'
            }
            IVButton {
                id: playMap
                width: 48*root.isize
                visible:eventsMaps.value==="true"?true:false
                height: parent.height
                anchors {
                    left: parent.left
                    leftMargin: innerTabsRect.spacing
                }
                source: "new_images/" + (root.isMapInit ? "pause" : "play")
                toolTipText: "Автооткрытие карт"
                onClicked:
                {
                    if(root.isMapInit)
                    {
                        root.isMapInit = false;
                        customSets.deinitMap();
                    }
                    else
                    {
                        root.isMapInit = true;
                        customSets.initMap();
                    }
                }
            }
            IVButton {
                id: playRect
                width: 48*root.isize
                visible:autoScroll.value==="true"?true:false
                height: parent.height
                anchors {
                    left: playMap.visible?playMap.right:parent.left
                    leftMargin: innerTabsRect.spacing
                }
                source: "new_images/" + (setsTimer.running ? "pause" : "play")
                toolTipText: "Листание вкладок"
                Canvas {
                    id: canvas
                    property int percentage: 0
                    property var mainColor: IVColors.get("Colors/Text new/TxPrimaryThemed")
                    width: height
                    height: parent.height
                    anchors.centerIn: parent
                    rotation: -90
                    visible: opacity > 0
                    opacity: setsTimer.running ? 1 : 0
                    Timer {
                        id: canvasTimer
                        interval: 500
                        property int addPart: 100*interval/(setsTimer.interval-interval)
                        repeat: true
                        onTriggered: canvas.percentage += addPart
                    }

                    Connections {
                        target: setsTimer
                        onRunningChanged: {
                            if (setsTimer.running) canvasTimer.start()
                            else canvasTimer.stop()
                            canvas.percentage = 0
                        }
                        onTriggered: canvas.percentage = 0
                    }
                    Behavior on percentage {
                        NumberAnimation {duration:  canvasTimer.interval}
                    }
                    Behavior on opacity {
                        NumberAnimation {duration: 600; easing.type: Easing.InOutQuad}
                    }
                    onMainColorChanged: canvas.requestPaint()
                    onPercentageChanged: canvas.requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var centerX = width / 2;
                        var centerY = height / 2;
                        var radius = width/2 - 2;
                        var angle = (percentage / 100) * 2 * Math.PI;
                        ctx.beginPath();
                        ctx.arc(centerX, centerY, radius, 0, angle, false);
                        ctx.lineWidth = 3 * root.isize;
                        ctx.strokeStyle = mainColor;
                        ctx.stroke();
                    }
                }
                onClicked: {
                    if (setsTimer.running) setsTimer.stop();
                    else setsTimer.start();
                }
            }
            SmoothedAnimation
            {
                target: tabsListView
                property: "contentX"
                running: toLeftRect.clicked
                to: 0
                velocity: 1500
            }
            SmoothedAnimation
            {
                target: tabsListView
                property: "contentX"
                running: toRightRect.clicked
                to: tabsListView.contentWidth - tabsListView.width
                velocity: 1500
            }
            IVButton {
                id: toLeftRect
                width: 28*root.isize
                height: parent.height
                visible: innerTabsRect.contentWidth >= tabsRect.width
                anchors {
                    left: playRect.right
                    leftMargin: innerTabsRect.spacing
                }
                source: "new_images/chevron-left-big"
                toolTipText: "Влево"
                onClicked:
                {

                   // anim.running = false;
                   // var pos = tabsListView.contentX;
                    //var destPos;
                    //var el = Math.round(tabsListView.contentX / tabsListView.currentItem.width);
                    //tabsListView.positionViewAtIndex(el, ListView.Beginning)
                   // var destPos = tabsListView.contentX -  tabsListView.width/2;
                    //console.error("TO LEFT ",destPos)
                    //if(destPos<0)
                    //{
                    //    destPos = 0;
                    //}
                    if(!tabsListView.atXBeginning)
                    {
                        tabsListView.flick(1500,0);
                    }
                    //console.error("TO LEFT2",destPos)
                    //anim.from = pos;
                    //anim.to = destPos;
                    //anim.running = true;
                    //console.error("TO LEFT ",tabsListView.contentX, tabsListView.currentItem.width , el)
                }
            }
            ListView {
                id:tabsListView
                anchors {
                    left: toLeftRect.right
                    right: newTabButton.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: innerTabsRect.spacing
                    rightMargin: innerTabsRect.spacing
                }
                model:openedTabsModel
                orientation: ListView.Horizontal
                currentIndex: -1
                spacing: 5
                clip: true
                snapMode: ListView.SnapToItem
                boundsBehavior: ListView.StopAtBounds
                MouseArea
                {
                    anchors.fill: parent
                    hoverEnabled: false
                    propagateComposedEvents: true
                    id:scrollMA
                    onWheel:
                    {
                        if(wheel.angleDelta.y / 120>0)
                        {
                            if(!tabsListView.atXEnd)
                            {
                                tabsListView.flick(-1500,0);
                            }
                        }
                        else
                        {
                            if(!tabsListView.atXBeginning)
                            {
                                tabsListView.flick(1500,0);
                            }
                        }
                    }
                    onPositionChanged:
                    {
                        mouse.accepted = false;
                    }
                }

                onCurrentIndexChanged: {
                    // root.globalSignalsObject.tabSelected(openedTabsModel.get(tabsListView.currentIndex).name,tabsListView.currentIndex);
                }
                delegate: Component
                {
                    IVClientTabDelegate
                    {
                        id:tabDelegate
                        viewType:model.view
                        tabName: model.name
                        innerIndex: model.index
                        type:model.type
                        tabId:model.tabId
                        currentIndex: tabsListView.currentIndex
                        globalSignalsObject: root.globalSignalsObject
                        onTabClicked: tabsListView.currentIndex = index;
                        modelSize:tabsListView.count
                    }
                }
                onContentWidthChanged: {
                    //forceLayout()
                }
            }
            IVButton {
                id: newTabButton
                width: 48*root.isize
                height: parent.height
                type: IVButton.Type.Secondary
                visible: true
                anchors {
                    right: toRightRect.left
                    rightMargin: innerTabsRect.spacing
                }
                source: "new_images/plus"
                toolTipText: "Новая вкладка"
                onClicked:
                {
                    root.globalSignalsObject.tabAdded5("New tab", "set","","");

                    if (!root.globalSignalsObject.setsAndCamsBlockOpened)
                        root.globalSignalsObject.showSetsAndCams()
                }
            }
            IVButton {
                id: toRightRect
                width: 28*root.isize
                height: parent.height
                visible: innerTabsRect.contentWidth >= tabsRect.width
                anchors {
                    right: parent.right
                    rightMargin: innerTabsRect.spacing
                }
                source: "new_images/chevron-right-big"
                toolTipText: "Вправо"
                onClicked:
                {


                    if(!tabsListView.atXEnd)
                    {
                        tabsListView.flick(-1500,0);
                    }
                }
            }
        }
    }
    IvVcliSetting {
        id: archOnly
        name: 'sourse_switch_archive_only'
        onValueChanged:
        {
            if(archOnly.value === "false")
            {
                archive_fix2.value === "";
            }
        }
    }

    Row
    {
        id: leftArea
        z: 25
        height: 40*root.isize
        spacing: 8*root.isize
        anchors
        {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: 8
        }

        IVImage
        {
            //anchors.centerIn: parent
            width: archOnly.value ==="true"?28*root.isize:0
            height: archOnly.value ==="true"?28*root.isize:0
            name: "new_images/archive"
            color: archive_fix2.value === "true"?"red":"white"
            visible: archOnly.value ==="true"?true:false
            y:6
            id:archImage
            function setViewType(viewType)
            {
                var tt = null;
                for(var i =0;i<openedTabsModel.count;i++ )
                {
                    //var tt = openedTabsModel.get(i);
//                    var tabName = model.get(i).name;
//                    var tabtypes = model.get(i).type;
//                    var tabid = model.get(i).tabId;
//                    var tabView = model.get(i).view;
                    openedTabsModel.setProperty(i,"view",viewType);
                    if(activeTabSettings.value === openedTabsModel.get(i).name)
                    {
                        tt = openedTabsModel.get(i);

                    }

                }
                if(tt !== null)
                {
                    root.globalSignalsObject.tabSelected5(tt.name,tt.type,tt.tabId,tt.view);
                }

            }

            MouseArea
            {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton

                IVToolTip {
                    id: arc_real_ToolTip
                    text: archive_fix2.value === "true"?Language.getTranslate("Archive", "Архив"):Language.getTranslate("Realtime", "Реалтайм")
                    visible: parent.containsMouse
                }

                onClicked:
                {
                    //console.error("AAA clicked" , archive_fix2.value)
                    //console.error("AAA clicked33" ,archOnly.value)
                    if(archive_fix2.value === "true")
                    {
                        archive_fix2.value = "false";
                        archImage.setViewType("realtime");
                    }
                    else
                    {
                        //console.error("AAA clicked1.5" , archive_fix2.value)
                        archive_fix2.value = "true";
                        archImage.setViewType("archive");
                    }
                    //console.error("AAA clicked2" , archive_fix2.value)
                }
            }
        }
    }

    ///тут кнопка перехода в архив
    Row
    {
        id: rightArea
        z: 25
        height: 40*root.isize
        spacing: 8*root.isize
        anchors
        {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: 8
        }

//        IVImage
//        {
            //anchors.centerIn: parent
//            width: archOnly.value ==="true"?28*root.isize:0
//            height: archOnly.value ==="true"?28*root.isize:0
//            name: "new_images/archive"
//            color: archive_fix2.value === "true"?"red":"white"
//            visible: archOnly.value ==="true"?true:false
//            y:6
//            id:archImage
//            function setViewType(viewType)
//            {
//                var tt = null;
//                for(var i =0;i<openedTabsModel.count;i++ )
//                {
                    //var tt = openedTabsModel.get(i);
//                    var tabName = model.get(i).name;
//                    var tabtypes = model.get(i).type;
//                    var tabid = model.get(i).tabId;
//                    var tabView = model.get(i).view;
//                    openedTabsModel.setProperty(i,"view",viewType);
//                    if(activeTabSettings.value === openedTabsModel.get(i).name)
//                    {
//                        tt = openedTabsModel.get(i);

//                    }

//                    console.error("CLICKED ARCH = ",openedTabsModel.get(i).name,openedTabsModel.get(i).view , viewType);
//                }
//                if(tt !== null)
//                {
//                    root.globalSignalsObject.tabSelected5(tt.name,tt.type,tt.tabId,tt.view);
//                }

//            }

//            MouseArea
//            {
//                anchors.fill: parent
//                hoverEnabled: true
//                acceptedButtons: Qt.LeftButton
//                onClicked:
//                {
                    //console.error("AAA clicked" , archive_fix2.value)
                    //console.error("AAA clicked33" ,archOnly.value)
//                    if(archive_fix2.value === "true")
//                    {
//                        archive_fix2.value = "false";
//                        archImage.setViewType("realtime");
//                    }
//                    else
//                    {
                        //console.error("AAA clicked1.5" , archive_fix2.value)
//                        archive_fix2.value = "true";
//                        archImage.setViewType("archive");
//                    }
//                    //console.error("AAA clicked2" , archive_fix2.value)
//                }
//            }
//        }
//        IVCircleButton {
//            id: archAlways
//            text: "Управление"
//            source: "new_images/archive"
//            enabled: archOnly.value === "true"
//            activated:archOnly.value === "true"
//            visible:archOnly.value === "true"
//            width: 40*root.isize
//            height: 40*root.isize
//            onClicked:
//            {
//                if(archive_fix.value === "true")
//                {
//                    archive_fix.value = "false";
//                }
//                else
//                {
//                    archive_fix.value === "true";
//                }

//            }
//        }
        /*
        IVExportButton {
            id: recordsButton
            anchors.verticalCenter: parent.verticalCenter
            height: 32
            width: 73
            type: IVExportButton.Type.Open
            toolTipText: "Список выгрузок"
            onClicked: {
                exportHistory.open()
            }
            opened: exportHistory.opened
        }
        IVExportHistory {
            id: exportHistory
            x: recordsButton.x + recordsButton.width/2
            y: recordsButton.y + recordsButton.height*0.8
            model: ListModel {
                id: exportModel
                function updateModel(){

                }

                Component.onCompleted: {
                    var countRecords = 0;
                    for (var i = 0; i < 7; i++) {
                        var key2, status, previewSource = "123/qgqgegf.jpg"

                        // Выставляем key2
                        switch (Math.floor(Math.random() * 3)) {
                        case 0: key2 = "Street camera"; break
                        case 1: key2 = "PTZ long name camera"; break
                        case 2: key2 = "Internal camera"; break
                        }

                        // Выставляем статус
                        switch (Math.floor(Math.random() * 4)) {
                        case 0: status = "recording"; break
                        case 1: status = "recorded"; break
                        case 2: status = "saved"; break
                        case 3: status = "error"; break
                        }
                        if (status === "recording" && recordsButton.type !== IVExportButton.Type.Recording){
                            recordsButton.type = IVExportButton.Type.Recording
                        }
                        if (status !== "saved"){
                            countRecords++;
                        }

                        var t = Math.floor(Math.random() * 60 * 60 * 99)
                        var duration = ""
                        var d = Math.floor(t/(60*60*99))
                        duration += (d < 10 ? "0"+d : d)
                        duration += ":"
                        d = Math.floor(t/(60*60)) % 60
                        duration += (d < 10 ? "0"+d : d)
                        duration += ":"
                        d = Math.floor(t/(60)) % 60
                        duration += (d < 10 ? "0"+d : d)

                        var sizeMB = status > 0 ? 0 : Math.floor(Math.random() * 500)
                        var currDate = ""
                        currDate += new Date().getTime() - Math.floor(Math.random() * 100000000000)

                        append({"previewSource": previewSource,
                                   "key2": key2,
                                   "duration": duration,
                                   "sizeMB": sizeMB,
                                   "status": status,
                                   "forDate": currDate
                               })
                    }
                    recordsButton.recordsCount = countRecords
                }
            }
        }

        */
        Rectangle {
            id: dateTimeRect
            property int showDateW: (dateType.value === "true") ? 130*root.isize : 0
            property int showSecsW: (timeType.value === "true") ? 40*root.isize : 0
            height: parent.height
            width: 60 + showDateW + showSecsW
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"
            IvVcliSetting {id: dateType; name: 'interface.dateType'}
            IvVcliSetting {id: timeType; name: 'interface.timeType'}
            Row {
                anchors.centerIn: parent
                spacing: 8 * root.isize
                Text {
                    id: timeText
                    font: IVColors.getFont("Title accent")
                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                }
                Text {
                    id: dateText
                    visible: dateType.value === 'true'
                    font: IVColors.getFont("Title")
                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                }
            }
            Timer {
                id:dateTimeUpdateTimer
                interval: 90
                repeat: true
                running: true
                onTriggered: {
                    if (timeType.value === 'true')
                        timeText.text = Qt.formatTime(new Date(),"hh:mm:ss")
                    else
                        timeText.text = Qt.formatTime(new Date(),"hh:mm")

                    var date = Qt.formatDate(new Date(),"dd.MM.yy ddd")
                    dateText.text = date.toUpperCase();
                }
            }
        }
        Rectangle {
            id:loginRect
            width: 40*root.isize
            height: 40*root.isize
            radius: 8*root.isize
            anchors.verticalCenter: parent.verticalCenter
            color: IVColors.get("Colors/Background new/BgFormPrimaryThemed")
            state: "normal"
            states: [
                State {
                    name: "normal"
                    PropertyChanges { target: miniName; color: IVColors.get("Colors/Text new/TxAccentThemed")}
                    PropertyChanges { target: loginRect; color: IVColors.get("Colors/Background new/BgFormTertiaryThemed")}
                },
                State {
                    name: "hovered"
                    PropertyChanges { target: miniName; color: IVColors.get("Colors/Text new/TxAccentThemed")}
                    PropertyChanges { target: loginRect; color: IVColors.get("Colors/Background new/BgBtnTertiaryThemed-hover")}
                },
                State {
                    name: "pressed"
                    PropertyChanges { target: miniName; color: IVColors.get("Colors/Text new/TxContrast")}
                    PropertyChanges { target: loginRect; color: IVColors.get("Colors/Background new/BgBtnCheck")}
                }
            ]
            IvUser {
                id: usr_man
                onAuthOnChanged: loginRect.checkVis()
                property bool firstChange: true
                Component.onCompleted: {
                    loginRect.checkVis()
                    usr_man.updateLogin()
                    usr_man.updateWSPort()
                }
                onUserLoginChanged: {
                    if (authMenu.opened && usr_man.connectOn) authMenu.close()
                    if (firstChange && rememberUsr.value === "false") {
                        usr_man.logoff()
                    }
                    firstChange = false
                }
            }
            IvVcliSetting{
                id: usrLBS
                name: 'user.loginBannerStatic'
                onValueChanged: loginRect.checkVis()
            }
            IvVcliSetting {
                id: rememberUsr
                name: 'user.constant'
                Component.onCompleted: {
                    value = (value !== "false") ? "true" : "false"
                }
            }

            Text {
                id: miniName
                text: getName()
                anchors.centerIn: parent
                font: IVColors.getFont("Title")

                function getName(){
                    var name = loginToolTip.text
                    for (var i = 0; i < usr_man.userLogin.length; i++)
                    {
                        if (name[i] === ' ' && i <usr_man.userLogin.length-1) {
                            name = name.slice(0,1) + usr_man.userLogin[i+1]
                            name.toUpperCase()
                            return name
                        }
                    }
                    name[0].toUpperCase()
                    return name.slice(0,2)
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                IVToolTip {
                    id: loginToolTip
                    text: (usr_man.userLogin === "guest") ? "Гость" : usr_man.userLogin
                    visible: parent.containsMouse
                }
                onExited: parent.state = "normal"
                onEntered: parent.state = "hovered"
                onPressed: parent.state = "pressed"
                onReleased: {
                    parent.state = "hovered"
                    //console.error("usr_man.userLogin = " , usr_man.userLogin)
                    if (usr_man.userLogin === "guest")
                    {

                        authMenu.open()
                    }
                    else
                    {
                        userMenu.open()
                        //console.error("userMenu.open()" , usr_man.userLogin , userMenu.opened , userMenu.width, userMenu.height , userMenu.x , userMenu.y)
                        //console.error("userMenu.open()" , parent.width , userMenu.width , userMenu.shadowWidth)
                    }
                }
            }
            IVContextMenu {
                id: userMenu
                x: -376//parent.width - width + shadowWidth
                y:parent.height + 6*root.isize - shadowWidth
                //z:1000
                rightPadding: shadowWidth + 24*root.isize
                leftPadding: shadowWidth + 24*root.isize
                topPadding: shadowWidth + 24*root.isize
                bottomPadding: shadowWidth + 24*root.isize
                property string userName: usr_man.userLogin
                property string userPhotoSrc: ""
                property string userCompany: ""
                property string userProfession: ""
                component: Component {
                    Column {
                        width: 352 * root.isize
                        spacing: 16 * root.isize
                        RowLayout {
                            width: parent.width
                            spacing: 16 * root.isize
                            Rectangle {
                                id: userImageRect
                                color: IVColors.get("Colors/Background new/BgListPrimaryThemed")
                                radius: 8*root.isize
                                width: 80 * root.isize
                                height: 80 * root.isize
                                clip: true
                                IVImage {
                                    anchors.centerIn: parent
                                    name: userMenu.userPhotoSrc.length === 0 ? "new_images/user-01" : ""
                                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                    visible: status === Image.Ready && userMenu.userPhotoSrc.length === 0
                                }
                                Image {
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    source: userMenu.userPhotoSrc
                                    visible: status === Image.Ready && userMenu.userPhotoSrc.length > 0
                                    sourceSize: Qt.size(width, height)
                                }
                                Canvas {
                                    anchors.fill: parent
                                    antialiasing: true
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.fillStyle = userMenu.bgColor
                                        ctx.beginPath()
                                        ctx.rect(0, 0, width, height)
                                        ctx.fill()
                                        ctx.beginPath()
                                        ctx.globalCompositeOperation = 'source-out'
                                        ctx.roundedRect(0, 0, width, height, userImageRect.radius, userImageRect.radius)
                                        ctx.fill()
                                    }
                                }
                            }
                            Column {
                                Layout.fillWidth: true
                                spacing: 4 * root.isize
                                Text {
                                    text: userMenu.userName
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    font: IVColors.getFont("Button accent")
                                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                    visible: text.length > 0
                                }
                                Text {
                                    text: userMenu.userProfession
                                    font: IVColors.getFont("Label")
                                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                    visible: text.length > 0
                                }
                                Text {
                                    text: userMenu.userCompany
                                    font: IVColors.getFont("Label")
                                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                    visible: text.length > 0
                                }
                            }
                        }
                        RowLayout {
                            width: parent.width
                            spacing: 16 * root.isize
                            IVButton {
                                Layout.fillWidth: true
                                type: IVButton.Type.Secondary
                                text: "Настройки"
                                source: "new_images/settings"
                                enabled: false
                            }
                            IVButton {
                                Layout.fillWidth: true
                                type: IVButton.Type.Primary
                                text: "Выйти"
                                onClicked: {
                                    usr_man.logoff()
                                    userMenu.close()
                                }
                            }
                        }
                    }
                }
            }

            IVContextMenu {
                id: authMenu
                parent: ApplicationWindow.overlay
                modal: true
                x: parent !== null ? (parent.width - width) / 2 : 0
                y: parent !== null ? (parent.height - height) / 2 : 0
                rightPadding: shadowWidth + 24*root.isize
                leftPadding: shadowWidth + 24*root.isize
                topPadding: shadowWidth + 24*root.isize
                bottomPadding: shadowWidth + 24*root.isize
                component: Component {
                    Column {
                        width: 352 * root.isize
                        spacing: 16 * root.isize
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Вход"
                            font: IVColors.getFont("Title accent")
                            color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                        }
                        IVInputField {
                            id: loginField
                            width: parent.width
                            isize:root.isize
                            enabled: !connectToSrvTimer.running
                            name: "Логин"
                            placeholderText: "Введите логин"
                            onTextEdited: {
                                isCorrect = true
                            }
                        }
                        RowLayout {
                            width: parent.width
                            IVInputField {
                                id: passwordField
                                Layout.fillWidth: true
                                enabled: !connectToSrvTimer.running
                                name: "Пароль"
                                hidden: true
                                isize:root.isize
                                placeholderText: "Введите пароль"
                                onTextEdited: {
                                    isCorrect = true
                                }
                            }
                            IVButton {
                                width: 32
                                Layout.alignment: Qt.AlignBottom
                                enabled: !connectToSrvTimer.running
                                type: IVButton.Type.Helper
                                size: IVButton.Size.Middle
                                source: passwordField.hidden ? "new_images/eye-off" :
                                                               "new_images/eye"
                                onClicked: {
                                    passwordField.hidden = !passwordField.hidden
                                }
                            }
                        }
                        IVInputField {
                            id: serverField
                            width: parent.width
                            enabled: !connectToSrvTimer.running
                            name: "Сервер"
                            isize:root.isize
                            placeholderText: "Введите ip адрес"
                            onTextEdited: {
                                isCorrect = true
                            }
                        }
                        IVCheckbox {
                            text: "Запомнить меня"
                            checkState: rememberUsr.value !== "false" ? 2 : 0
                            tristate: false
                            type: IVCheckbox.Type.Contrast
                            enabled: !connectToSrvTimer.running
                            onClicked: {
                                if (checkState < 2) rememberUsr.value = "true"
                                else rememberUsr.value = "false"
                            }
                        }
                        IVButton {
                            id: loginButton
                            width: parent.width
                            property bool login: loginField.text.length > 0
                            property bool password: passwordField.text.length > 0
                            property bool ip: serverField.text.length > 0
                            enabled: login && password && ip && !connectToSrvTimer.running
                            text: connectToSrvTimer.running ? "Идет подключение"+connectToSrvTimer.txt :
                                                              login && password && ip ? "Войти" : "Необходимо заполнить все поля"

                            type: IVButton.Type.Primary
                            onClicked: {
                                errorString.text = ""
                                loginField.isCorrect = true
                                passwordField.isCorrect = true
                                serverField.isCorrect = true

                                loginField.setFocused(false)
                                passwordField.setFocused(false)
                                serverField.setFocused(false)

                                connectToSrvTimer.restart()
                                usr_man.setIp(serverField.text)
                            }
                        }
                        Rectangle {
                            visible: errorString.text.length > 0
                            width: parent.width
                            height: errorContent.height + 32
                            radius: 8
                            clip: true
                            color: IVColors.get("Colors/Statuse new/Critical")
                            Row {
                                id: errorContent
                                anchors.centerIn: parent
                                width: parent.width - 32
                                spacing: 16
                                IVImage {
                                    id: authErrorIcon
                                    name: "new_images/" + "alert-triangle.svg"
                                    width: 24
                                    height: 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: IVColors.get("Colors/Text new/TxContrast")
                                }
                                Text {
                                    id: errorString
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - parent.spacing - authErrorIcon.width
                                    wrapMode: Text.WordWrap
                                    font: IVColors.getFont("Label accent")
                                    color: IVColors.get("Colors/Text new/TxContrast")
                                }
                            }
                            Behavior on height {
                                enabled: root.useAnimation
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                        Timer {
                            id: connectToSrvTimer
                            property string txt: ""
                            property int timeout: 5000
                            repeat: true
                            interval: 250
                            onTriggered: {
                                if (txt.length > 3) txt = ""
                                else txt += "."

                                if (timeout > 0) timeout -= interval
                                else {
                                    //idLog.error('user login error=' + "Ошибка подключения к серверу");
                                    serverField.isCorrect = false
                                    errorString.text = Language.getTranslate("Error connecting to server", "Ошибка подключения к серверу")
                                            + " " + serverField.text;
                                    //txtIp.text = usr_man.getIp()
                                    timeout = 5000
                                    stop()
                                }
                            }
                        }
                        Connections {
                            target: usr_man
                            onConnectOnChanged: {
                                if (connectToSrvTimer.running)
                                {
                                    //if (root.globalSignalsObject) root.globalSignalsObject.setsListUpdate();
                                    if (usr_man.connectOn)
                                    {
                                        if (usr_man.authOn)
                                        {
                                            if (usr_man.login(loginField.text, passwordField.text, rememberUsr.value === "true")){
                                                loginField.text = passwordField.text = ""
                                                authMenu.close()
                                            }
                                            else if (loginField.text === '' || passwordField.text === ''){
                                                //idLog.error('user login error=' + "Введите логин и пароль");
                                                errorString.text = Language.getTranslate("Enter login and password",
                                                                                         "Введите логин и пароль");
                                            }
                                            else {
                                                //idLog.error('user login error=' + usr_man.error);
                                                switch (usr_man.error) {
                                                case "Неверный логин или пароль":
                                                    errorString.text = Language.getTranslate("Wrong login or password",
                                                                                             "Неверный логин или пароль");
                                                    loginField.isCorrect = false
                                                    passwordField.isCorrect = false
                                                    break;
                                                default:
                                                    errorString.text = usr_man.error;
                                                }
                                            }
                                        }
                                        else {
                                            authMenu.close()
                                        }
                                        //currIpLb.text = usr_man.getIp();
                                    }
                                    connectToSrvTimer.stop()
                                }
                            }
                        }
                        Connections {
                            target: authMenu
                            onClosed: {
                                errorString.text = ""
                                loginField.isCorrect = true
                                passwordField.isCorrect = true
                                serverField.isCorrect = true
                            }
                        }

                        Keys.onPressed: {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            {
                                var a = loginField.text.length > 0
                                var b = passwordField.text.length > 0
                                var c = serverField.text.length > 0

                                if (!a) loginField.isCorrect = false
                                if (!b) passwordField.isCorrect = false
                                if (!c) serverField.isCorrect = false
                                if (a && b && c)
                                {
                                    errorString.text = ""

                                    loginField.setFocused(false)
                                    passwordField.setFocused(false)
                                    serverField.setFocused(false)

                                    connectToSrvTimer.restart()
                                    usr_man.setIp(serverField.text)
                                }
                            }
                            if (event.key === Qt.Key_Tab) {
                                if (loginField.state === "focused")
                                    passwordField.setFocused()
                                else if (passwordField.state === "focused")
                                    serverField.setFocused()
                                else if (serverField.state === "focused")
                                    loginField.setFocused()
                            }
                        }
                    }
                }
            }

            function checkVis() {
                var a = usrLBS.value === 'true'
                var b = usr_man.authOn
                if (a || b) visible = true
                else visible = usr_man.authOn
            }
            /*
            Loader {
                id:loginLoader
                anchors.fill: parent
                asynchronous: false
                property var componentLogin: null
                function create1()
                {
                    var qmlFile2 = 'file:///' + applicationDirPath +  "/qtplugins/iv/plugins/users/IVUserLoginBanner.qml";
                    //console.error("QML FILE 2 ====================================== ",qmlFile2);
                    loginLoader.source = qmlFile2;
                }
                function refresh()
                {
                    loginLoader.destroy1();
                    loginLoader.create1();
                }
                function destroy1()
                {
                    if(loginLoader.status !== Loader.Null)
                        loginLoader.source = "";
                }
                onStatusChanged:
                {
                    if (loginLoader.status === Loader.Ready)
                    {
                        loginLoader.componentLogin = loginLoader.item;
                        //loginLoader.componentMain.globSignalsObject = root.globalSignalsObject;
                        loginLoader.componentLogin.anchors.fill = loginLoader;
                        //console.error("USER LOGIN BANNED IS CREATED")
                    }
                    if(loginLoader.status === Loader.Error)
                    {
                        //console.error("loginLoader error");
                    }
                    if(loginLoader.status === Loader.Null)
                    {

                    }
                }
            }
            Component.onCompleted: {
                loginLoader.create1();
            }
            */
        }
        IvAccess {
          id: clientClose
          access: "{closing_system}"
        }
        IvAccess {
          id: clientResize
          access: "{change_the_size_and_position_of_the_window}"
        }
        IvAccess {
          id: clientHideTab
          access: "{hide_tabsbar}"
        }
        IVButton {
            id: hideRect
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            width: height
            visible:clientHideTab.isAllowed
            type: IVButton.Type.Helper
            source: "new_images/arrow-narrow-top-alignment"
            toolTipText: "Скрыть панель вкладок"
            onClicked: {
                root.miniClicked()
            }
        }
        Row {
            height: 32*root.isize
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            IVButton {
                id: minimizeBt
                visible: clientResize.isAllowed?systemFrame.value !== "true":false
                height: parent.height
                width: parent.height
                anchors.verticalCenter: parent.verticalCenter
                type: IVButton.Type.Helper
                source: "new_images/minus"
                toolTipText: "Свернуть"
                onClicked: {
                    root.Window.window.visibility = Window.Minimized
                }
            }
            IVButton {
                id: expandBt
                visible: clientResize.isAllowed?systemFrame.value !== "true":false
                height: parent.height
                width: parent.height
                anchors.verticalCenter: parent.verticalCenter
                type: IVButton.Type.Helper
                source: "new_images/collapse expand"
                toolTipText: (root.Window.window.visibility === Window.Maximized ||
                              root.Window.window.visibility === Window.FullScreen) ? "Свернуть в окно" :
                                                                                     "Развернуть"
                onClicked:{
                    var a = root.Window.window.visibility === Window.Maximized
                    var b = root.Window.window.visibility === Window.FullScreen
                    if (a || b)
                    {
                        root.Window.window.visibility = Window.Windowed
                    }
                    else
                    {
                        root.Window.window.visibility = Window.Maximized
                    }
                }
            }
            IVButton {
                id: closeBt
                visible: clientClose.isAllowed?systemFrame.value !== "true":false
                height: parent.height
                width: parent.height
                anchors.verticalCenter: parent.verticalCenter
                type: IVButton.Type.Helper
                source: "new_images/x-close"
                toolTipText: "Закрыть"
                onClicked: {
                    Qt.callLater(root.Window.window.close);
                }
            }
        }
    }


    NumberAnimation { id: anim; target: tabsListView; property: "contentX"; duration: 200 }

    function getMaxTabsLimit() {
        var limit = parseInt(maxTabsLimit.value);
        if(isNaN(limit))
        {
            limit = 8;
        }

        if(limit < 1)
        {
            limit = 1;
        }
        else if(limit > 128)
        {
            limit = 128;
        }

        var normalizedValue = limit.toString();
        if(maxTabsLimit.value !== normalizedValue)
        {
            maxTabsLimit.value = normalizedValue;
        }
        return limit;
    }

    function trimTabsToLimit(preferredIndex) {
        var limit = getMaxTabsLimit();
        var index = preferredIndex !== undefined ? preferredIndex : tabsListView.currentIndex;
        var trimmed = false;
        var activeRemoved = false;

        while(openedTabsModel.count > limit)
        {
            var removedTab = openedTabsModel.get(0);
            openedTabsModel.remove(0,1);
            trimmed = true;
            if(index > 0)
            {
                index--;
            }
            if(tabsListView.currentIndex > 0)
            {
                tabsListView.currentIndex = tabsListView.currentIndex - 1;
            }
            if(activeTabSettings.value === removedTab.name)
            {
                activeRemoved = true;
            }
        }

        if(openedTabsModel.count === 0)
        {
            index = -1;
        }
        else if(index >= openedTabsModel.count)
        {
            index = openedTabsModel.count - 1;
        }

        if(activeRemoved && openedTabsModel.count>0)
        {
            activeTabSettings.value = openedTabsModel.get(Math.max(index,0)).name;
        }

        return {index:index, trimmed:trimmed, activeRemoved:activeRemoved};
    }

    function getStringFromModel(model) {
        var modelCount = model.count;
        var tabsArray = [];
        for(var i = 0; i<modelCount;i++)
        {
            var tabName = model.get(i).name;
            var tabtypes = model.get(i).type;
            var tabid = model.get(i).tabId;
            var tabView = model.get(i).view;
            //console.error("getStringFromModel ", tabName , tabtypes , i);
            var tabsObj = {};
            tabsObj.name = tabName;
            tabsObj.type = tabtypes;
            tabsObj.tabId = tabid;
            tabsObj.view = tabView;
            tabsArray.push(tabsObj);
        }
        var tabsStr = JSON.stringify(tabsArray);
        return tabsStr;
    }

    Component.onCompleted: {
        //dateTimeLoader.create1();
        //loginLoader.create1();
    }
}

import QtQuick 2.9
import QtQuick.Window 2.2

//import QtQuick 2.9
//import QtQuick.Controls 2.2
//import QtQuick.Window 2.3
//import QtQml.Models 2.1
//import iv.semantica 1.0
//import iv.plugins.loader 1.0

Window {
    visible: true
    width: 640
    height: 480
    title: qsTr("Hello World")
    property var counter:0

    /*Rectangle{
        id:rootRect
        width: parent.width
        height: 200
        color: "green"
    ListModel {
        id: contactModel
    }

        Component {
            id: intervalsDelegate
            Rectangle {
                width: grid.width
                height: grid.height
                color: portrait
                Column {
                    anchors.fill: parent
                    //Image { source: portrait; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: name; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }
        }

        ListView {
            id: grid
            anchors.fill: parent
            //cellWidth: 80; cellHeight: 80
            width: parent.width
            height: 80
            //verticalLayoutDirection: Grid.TopToBottom
            orientation: Qt.Horizontal;
            //layoutDirection: Qt.LeftToRight
            flickableDirection: Flickable.HorizontalFlick
            //highlightRangeMode: ListView.StrictlyEnforceRange
            snapMode:ListView.NoSnap

            model: contactModel
            delegate: intervalsDelegate
            highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
            focus: true

            add: Transition {
                    NumberAnimation { properties: "x,y"; from: 100; duration: 1000 }
            }

            displaced: Transition {
                NumberAnimation
                {
                    properties: "x,y"; duration: 600
                    //onStopped: root.start()
                }
            }

            Component.onCompleted: {

                //positionViewAtIndex(3, ListView.Center)
                grid.currentIndex = 3;
                //contentX = originX

                console.info("random color = ", Qt.rgba(Math.random(), Math.random(), Math.random()).toString());

                contactModel.append({name:"Январь", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString()});
                contactModel.append({name:"Февраль", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString()});
                contactModel.append({name:"Март", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString()});
                contactModel.append({name:"Апрель", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString()});
                contactModel.append({name:"Май", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString()});
                contactModel.append({name:"Июнь", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString()});
                contactModel.append({name:"Июль", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString()});

                contentX=grid.width*3;

                console.info("contentX = ", contentX)
            }

            onCurrentIndexChanged: {
                console.info("currentIndex = ", currentIndex);
                currentIndex=0;
            }

            onContentXChanged: {
                console.info("contentX1 = ", contentX)
                console.info("originX1 = ", originX)
                console.info("contactModel.count1 = ", contactModel.count)

                if (contentX > grid.width*4)
                {
                    console.info("=========================================== ")

                    console.info("originX22 = ", originX)
                    console.info("contactModel.count = ", contactModel.count)
                    contactModel.insert(0, {name:counter.toString(),portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString()});
                    console.info("originX33 = ", originX)
                    contactModel.remove(count-1,1);
                    console.info("originX44 = ", originX)
                    console.info("contentX = ", contentX)
                    contentX = originX+grid.width*3;
                    //originX = 0;

                    console.info("contentX grid.width = ", grid.width)
                    console.info("contentX after remove = ", contentX)
                    console.info("currentIndex = ", currentIndex)
                    counter++;
                    console.info("=========================================== ")
                }

                if ((contentX < 0) && contentX < grid.width*4)
                                {
                                    console.info("=========================================== ")

                                    console.info("originX = ", originX)
                                    console.info("contactModel.count = ", contactModel.count)
                                    contactModel.insert(0,{name:counter.toString(),portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString()});
                                    contactModel.remove(count-1,1);
                                    console.info("contentX = ", contentX)
                                    contentX += grid.width;
                                    //originX = 0;

                                    console.info("contentX grid.width = ", grid.width)
                                    console.info("contentX after remove = ", contentX)
                                    console.info("currentIndex = ", currentIndex)
                                    counter++;
                                    console.info("=========================================== ")
                                }
            }
        }
    }*/


    //================================================================================================

    Rectangle {
            visible: true
            property string semanticaAddress: ""
            //property IVComponent2 ivComponent:null
            id: root
            property var parentComponent: null
            color:"yellow"//"transparent"
            readonly property int dpi: Screen.pixelDensity * 25.4
            function dp1(x){ return x; }
            anchors.fill: parent
            property var semaProperties: null
            property int xRatio: 16
            property int yRatio: 9
            property var _index_play_deleg:0
            property var _coord_play: 0
            property var _slider_value: 0
            //property bool isDebug:  debugVcli.value === "true"?true:false


            on_Slider_valueChanged: {
                var s_val = _slider_value / (100000/grid.width);
                if (s_val > _coord_play)
                {
                    _coord_play = s_val;
                    grid.contentX += s_val - _coord_play;
                }
                else
                {
                    _coord_play = s_val;
                    grid.contentX -= _coord_play - s_val;
                }
            }

            Timer {
                id: timer_play
                repeat: true
                interval: 40
                onTriggered: {
                    grid.contentX += 3;
                }
            }

            Rectangle
            {
                id:waitRect
                width: parent.width
                height: 7
                anchors.top: parent.top
                color: "white"
                z:10
                visible: false
                Rectangle
                {
                    id:animRect
                    height: parent.height
                    width: parent.width
                    color: "green"

                }
            }
            NumberAnimation
            {
                id:animWait
                target: animRect
                property: "width"
                from: animRect.width
                to: 0
                duration: 30000
            }


            //IvVcliSetting
            //{
            //    id: debugVcli
            //    name: 'debug.enable'
            //    onValueChanged:
            //    {
            //        root.isDebug = debugVcli.value === "true"?true:false
            //    }
            //}
            //Iv7Log
            //{
            //  id: idLog
            //  name: 'qtplugins.iv.semantica'
            //}

            Component.onCompleted:
            {

            }
            function start()
            {
                grid.contentY = 0;
                //if(root.semaProperties.ratioEnabled)
                //if (ture)
                //{

                    ////var _rect = gridPositionToRect2(root.width,root.height,0,1,root.semaProperties.xRatio,root.semaProperties.yRatio);
                    ////grid.cellWidth = Qt.binding(function(){ return((_rect.height/root.semaProperties.lineCount)/root.semaProperties.yRatio)*root.semaProperties.xRatio});
                    //var _rect = gridPositionToRect2(root.width,root.height,0,1,root.xRatio,root.yRatio);
                    //grid.cellWidth = Qt.binding(function(){ return(_rect.height/root.yRatio)*root.xRatio});
                    ////grid.cellHeight = Qt.binding(function(){ return  _rect.height/root.semaProperties.lineCount});
                    //grid.cellHeight = Qt.binding(function(){ return  _rect.height});
                    //grid.cellInLine = Math.round( _rect.width / grid.cellWidth )
                    //grid.width = Qt.binding(function(){ return grid.cellWidth*grid.cellInLine});
                    ////grid.height = Qt.binding(function(){ return root.semaProperties.lineCount*grid.cellHeight});
                    //grid.height = Qt.binding(function(){ return 1*grid.cellHeight});
                    //grid.anchors.centerIn = commRect;
                //}
                //else
                //{
                console.info("******** start ********")
                    //grid.anchors.fill = commRect;
                    ////grid.cellHeight = Qt.binding(function(){ return  commRect.height/root.semaProperties.lineCount});
                    ////grid.cellWidth = ((commRect.height/root.semaProperties.lineCount)/root.semaProperties.yRatio)*root.semaProperties.xRatio
                    //grid.cellHeight = Qt.binding(function(){ return  commRect.height});
                    ////grid.cellWidth = ((commRect.height/1)/root.semaProperties.yRatio)*root.semaProperties.xRatio
                    //grid.cellWidth = ((commRect.height/1)/root.yRatio)*root.xRatio
                    //grid.cellInLine = Math.round( commRect.width / grid.cellWidth )
                    //grid.cellWidth = Qt.binding(function(){return commRect.width/grid.cellInLine});

                //grid.anchors.fill = commRect;
                //grid.cellHeight = Qt.binding(function(){ return  commRect.height/root.semaProperties.lineCount});
                //grid.cellWidth = ((commRect.height/root.semaProperties.lineCount)/root.semaProperties.yRatio)*root.semaProperties.xRatio
                //grid.cellInLine = Math.round( commRect.width / grid.cellWidth )
                //grid.cellWidth = Qt.binding(function(){return commRect.width/grid.cellInLine});

                grid.anchors.fill = commRect;
                grid.cellHeight = 80//Qt.binding(function(){ return  commRect.height});
                grid.cellWidth = commRect.height; //(commRect.height/root.yRatio)*root.xRatio
                grid.cellInLine = 1;//Math.round( commRect.width / grid.cellWidth )
                grid.cellWidth = commRect.width;//Qt.binding(function(){return commRect.width/grid.cellInLine});

                //}
            }
            ListModel
            {
                id: colorModel
            }

            /*Semantica
            {
                id:sema
                eventsFilter: semaProperties.eventsFilter
                property bool isNeedWait: false
                property var waitDate: 0
                property bool isUserClicked: false
                property bool firstTime: true
                property var rect: semaProperties.rect
                onSemanticaAddressChanged:
                {
                    root.semanticaAddress = sema.semanticaAddress;

                }
                onWaitDateChanged:
                {
                    //animWait
                    if(waitDate === 0)
                    {
                        waitRect.visible = false;
                        animWait.stop();
                    }
                    else
                    {
                        animWait.stop();
                        waitRect.visible = true;
                        animRect.width = waitRect.width
                        animWait.start();

                    }
                }

                onEventsCompleted:
                {
                    //idLog.debug("<IVSemantica.qml> onEventsCompleted {");

                    if(sema.firstTime)
                    {
                        grid.contentY = 0;
                        var i1;


                        for(i1 =0;i1<20;i1++)
                        {
                            grid.g_rightadd();
                        }
                        sema.firstTime = false;
                    }
                }
                onSemaDestroy:
                {

                }
                onFullRefresh:
                {
                    //idLog.trace("<IVSemantica.qml> onFullRefresh {");
                    if(root.parentComponent !== null)
                    {
                        //idLog.trace("<IVSemantica.qml> onFullRefresh =");
                        root.parentComponent.fullRefresh();
                    }
                    //idLog.trace("<IVSemantica.qml> onFullRefresh }");
                }
            }*/
            property int zuu:2000000;
            property var min1: -1999950
            property var max1:2000100
            function gridPositionToRect2(rect_width,rect_height,index,count,nw,nh)
            {
                if(nh===0 || nw===0)
                {
                    nh=9;
                    nw=16;
                };
                var calculated_rectangle = {};
                if((count<1)||(count>64))
                {
                    calculated_rectangle["x"] = 1;
                    calculated_rectangle["y"] = 1;
                    calculated_rectangle["width"] = rect_width;
                    calculated_rectangle["height"] = rect_height;
                    return calculated_rectangle;
                }
                if(index>=count)
                    index=0;
                var cROW=1,cCOL=1;
                while(cROW*cCOL<count) // 1914 858
                {
                    var cH1=parseFloat(rect_height/(cROW+1));
                    var cW1=parseFloat(rect_width/(cCOL+1));
                    /*if(cH1*nw/nh>cW1)
                    {
                        cCOL++;
                    }
                    else
                    {
                        cROW++;
                    }*/
                    if(cH1*nw/nh<=cW1)
                    {
                        cCOL++;
                    }
                    else
                    {
                        cROW++;
                    };
                }
                var cH=parseInt(rect_height/cROW);
                var cW=parseInt(rect_width/cCOL);
                if(parseFloat(cH*nw/nh)>cW)
                {
                    cH=parseInt(cW*nh/nw);
                }
                else
                {
                    cW=parseInt(cH*nw/nh);
                }
                calculated_rectangle["width"] = cW;
                calculated_rectangle["height"] = cH;

                return calculated_rectangle;
            }
            Rectangle
            {
                anchors.fill: parent
                color: "#6495ed"//"transparent"
                id:commRect

                ListModel {
                    id: contactModel
                }

                //GridView
                ListView
                {
                    id:grid
                    //anchors.centerIn: parent
                    //height:commRect.height
                    //width: commRect.width
                    anchors.fill: parent

                    verticalLayoutDirection: Grid.TopToBottom
                    layoutDirection: Qt.LeftToRight
                    //flow: Grid.TopToBottom
                    //snapMode: GridView.SnapToRow
                    cacheBuffer:0
                    clip: true
                    model: colorModel//110
                    flickableDirection: Flickable.HorizontalFlick
                    property int curcol:2000000;

                    //=====================================================
                    width: parent.width
                    height: 80
                    //verticalLayoutDirection: Grid.TopToBottom
                    orientation: Qt.Horizontal;
                    //layoutDirection: Qt.LeftToRight
                    //flickableDirection: Flickable.HorizontalFlick
                    //highlightRangeMode: ListView.StrictlyEnforceRange
                    snapMode:ListView.NoSnap
                    property var prevContentX: 0
                    property var delta_contentX: 0

                    onWidthChanged: {
                        //delta_contentX = contentX;
                    }

                    function getWidth()
                    {
                        var width = 0;
                        //width = ((height/root.semaProperties.lineCount)/root.semaProperties.yRatio)*root.semaProperties.xRatio;
                        width = ((height/1)/root.yRatio)*root.xRatio;
                        return width;
                    }

                    function g_leftadd()
                    {
                        var c = 0;
                        if(colorModel.count>0)
                        {
                           c = colorModel.get(0).col1-1;
                        }
                        var _rows1 = 1;//root.semaProperties.lineCount;
                        //for(var r=_rows1-1;r>=0;r--)
                        //{
                            //var indeEV = 2000000- r*grid.cellInLine + c;
                            //var evtid = sema.getEvtID(indeEV);

                            //colorModel.insert(0,
                            //        {
                            //           "col1":c,
                            //           "row1":r//,
                            //           //"evtid":evtid
                            //        })
                            colorModel.insert(0, {name:counter.toString(), portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString(), "col1":c});
                            counter++;
                            console.error("insert to model")
                        //};

                    }
                    function g_leftrem()
                    {
                        var _rows1 = 1;//root.semaProperties.lineCount;
                        colorModel.remove(0,_rows1);
                    }
                    function g_rightrem()
                    {
                        var _rows1 = 1;//root.semaProperties.lineCount;
                        colorModel.remove(colorModel.count-_rows1,_rows1);
                    }
                    function g_rightadd()
                    {

                        var c = 0;
                        if(colorModel.count>0)
                        {
                            c = colorModel.get(colorModel.count-1).col1+1;
                            //c=0;
                        }
                        console.info("rigth append c =", c)
                        //var _rows1 = 1;//root.semaProperties.lineCount;
                        //for(var r=0;r<_rows1;r++)
                        //{
                            //var indeEV = 2000000 - r*grid.cellInLine + c;
                            //var evtid = sema.getEvtID(indeEV);
                            //if(evtid === 0)
                            //{
                            //    console.info("<radd> ubludok, matb tvou, a nu idi suda, ti hochesh trahnutb moyo sobytie, da ya sam tebya trahnu!!!! " +indeEV.toString() )
                            //}

                            //colorModel.append(
                            //        {
                            //           "col1":c,
                            //           "row1":r//,
                                       //"evtid":evtid
                            //       })
                            console.info("rigth append")
                            colorModel.append({name:counter.toString(), portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString(), "col1":c});
                            counter++;
                        //};

                    }
                    ////////////////////////////////////////////

                    function checkmodel()
                    {
                        //var c,c0=colorModel.get(0).col1,c1;
                        var c,c0=1,c1;
                        for(c=0;c<colorModel.count/3;c++)
                        {
                            c1=colorModel.get(c*3).col1;
                            //c1=1;
                            if(c1!==c0-c)
                            {
                                console.log("error1152 ",c1,c0-c,c0,c);
                                return;
                            }
                        }
                    }
                    ////////////////////////////////////////////
                    function g_left()
                    {
                        var I1=curcol+20,c;
                        var item;
                        var cnt=0;
                        while(1)
                        {
                            item =colorModel.get(0);
                            if(!item)
                            {
                                //idLog.trace("error 5624");
                                return;
                            }
                            if(item.col1<=I1)break;
                            //idLog.trace(" remleft="+item.col1);
                            g_leftrem();
                            cnt++;
                        }
                        item=colorModel.get(0);
                        if(!item)
                        {
                            //idLog.trace("error 5124");
                            return;
                        };
                        var I2=item.col1;
                        //idLog.trace("removed "+cnt+" tryaddleft="+I2+" "+I1);
                        for(c=I2+1;c<I1;c++)
                        {
                            //idLog.trace(" addleft="+c);
                            g_leftadd()
                        };

                    }
                    function g_right()
                    {
                        var I4=curcol-12-20,c;
                        var item,cnt=0;
                        while(1)
                        {
                            item =colorModel.get(colorModel.count-1);
                            if(!item)
                            {
                                //idLog.trace("error 56624");
                                return;
                            }
                            if(item.col1>=I4)break;
                            //idLog.trace(" remright="+item.col1);
                            g_rightrem();
                            cnt++;
                        }
                        item=colorModel.get(colorModel.count-1);
                        if(!item)
                        {
                            //idLog.trace("error 25124");
                            return;
                        };
                        var I3=item.col1;
                        //idLog.trace(" removed "+cnt+" tryaddright="+I3+" "+I4);
                        for(c=I3-1;c>=I4;c--)
                        {
                            //idLog.trace(" addright="+c);
                            g_rightadd()
                        };
                    }
                    property int cellInLine: Math.round(grid.width/grid.cellWidth)
                    ////////////////////////////////////////////
                    //Timer
                    //{
                    //    id:positionTimer
                    //    interval: 50
                    //    triggeredOnStart: false
                    //    running: true
                    //    repeat: true
                    //    onTriggered:
                    //    {
                    //        if(colorModel.count<1)
                    //            return;
                    //        var _cil = grid.cellInLine;
                    //        var _lines = 1;//root.semaProperties.lineCount;
                    //        var _position =2000000 + colorModel.get(0).col1 - parseInt((grid.contentX - grid.originX) / grid.cellWidth ) ; //+2000000?
                    //        if(_position !== grid.curcol)
                    //        {
                    //            //idLog.trace("<position> position timer cellInLime = " + _cil.toString() + " lines = " + _lines.toString() + "curr col = "+_position.toString());
                    //        }
                    //        grid.curcol = _position;
                            //sema.imhere( grid.curcol ,_cil,_lines);
                    //    }
                    //}
                    ////////////////////////////////////////////
                    property var sema_getNew:2000000
                    //Timer
                    //{
                    //    id:sema_getNewTimer
                    //    interval: 5*1000//root.semaProperties.isAutoMode?250:root.semaProperties.triggerTime*1000
                    //    triggeredOnStart: false
                    //    running: true
                    //    repeat: true
                    //    onTriggered:
                    //    {
                            //grid.sema_getNew=sema.getNew();
                    //    }
                    //}

                    //Timer
                    //{
                    //    id:newEvtTimer
                    //    interval: 100
                    //    triggeredOnStart: false
                    //    running: true
                    //    repeat: true
                    //    onTriggered:
                    //    {
                    //        if(colorModel.count<1)
                    //            return;
                            ///#666
                            //console.error("sema.isNeedWait = ",sema.isNeedWait)
                            //if( sema.isNeedWait)return;
                            //if(sema.waitDate)
                            //{
                            //    var curr = sema.getTimeNow2();
                            //    if(curr<sema.waitDate) return;
                                //{
                                //idLog.trace("<position> left timer refresh after 30 sec");
                            //    sema.waitDate = 0;
                            //    root.parentComponent.fullRefresh();
                                //}
                            //    return;
                            //}
                            ///#666
                            //if(grid.contentX-grid.originX<20)
                            //{
                               // sema.isUserClicked = false;
                           //     var max1= grid.sema_getNew - 2000000;
                           //     var col1=colorModel.get(0).col1;
                           //     if(col1<max1)
                           //     {
                           //       var i = max1-col1;
                           //       while(i>0)
                           //       {
                                      //idLog.trace(" add left timer");
                                      //idLog.trace("<position>  add left timer contextX = "+ grid.contentX + " originX = "+grid.originX + " max1 = "+max1.toString() + " col1 = "+ col1);
                           //           grid.g_leftadd();
                           //           grid.g_rightrem();
                           //           i--;
                           //       }
                           //     }
                            //}
                    //    }
                    //}
                    add: Transition {
                        NumberAnimation
                        {
                            property: "width"
                            from: 0
                            to: grid.cellWidth
                            duration: 600
                            onStopped: root.start()
                        }
                    }

                    displaced: Transition {
                        NumberAnimation
                        {
                            properties: "x,y"; duration: 600
                            onStopped: root.start()
                        }
                    }
                    onContentXChanged:
                    {
                        console.info("--------------- onContentXChanged contentX", grid.contentX);
                        console.info("--------------- onContentXChanged prevContentX", grid.prevContentX);
                        console.info("--------------- grid.contentWidth = ",grid.contentWidth);
                        console.info("--------------- grid.originX = ",grid.originX);
                        console.info("--------------- grid.width = ", grid.width);
                        //console.info("--------------- colorModel.count = ", colorModel.count);
                        //console.info("--------------- grid.currentIndex = ", grid.currentIndex);
                        //console.info("--------------- indexAt = ", grid.indexAt(grid.width/2, grid.height/2));
                        if(grid.contentWidth<grid.width+3000)
                            return;
                        var min1= colorModel.get(0).col1;//sema.getOld()-2000000;
                        var max1= colorModel.get(colorModel.count-1).col1;//grid.sema_getNew - 2000000;
                        var s1=grid.contentX+grid.width;
                        var s2=grid.originX+grid.contentWidth;
                        var s3=(grid.originX+grid.contentWidth)-grid.width;

                        if(grid.contentX<=grid.originX+1000)
                        {
                            console.info("--------------- onContentXChanged 1");
                            //idLog.trace(" move l contentX="+grid.contentX+" width="+grid.width
                            //            +" s1="+s1+" < s2="+s2+" originX"+grid.originX
                            //            +" contentWidth="+grid.contentWidth+ " s3"+s3);
                            var col1=colorModel.get(0).col1;
                            //var col1=1;
                            if(col1<max1)
                            {
                              //idLog.trace("<position> onContentXChanged add left");
                              grid.g_leftadd();
                              grid.g_rightrem();
                            }
                            else
                            {
                                if(grid.contentX<grid.originX)
                                {
                                    //sema.waitDate = 0;
                                    grid.contentX=grid.originX;
                                }
                            };

                        }
                        if(s1+1000>s2)
                        {
                            console.info("--------------- onContentXChanged 2");
                            //idLog.trace(" move rcontentX="+grid.contentX+" width="+grid.width
                            //            +" s1="+s1+" < s2="+s2+" originX"+grid.originX
                            //            +" contentWidth="+grid.contentWidth+ " s3"+s3);

                            var col2=colorModel.get(colorModel.count-1).col1;
                            //var col2 = 1;
                            console.info("--------------- col2 = ", col2);
                            console.info("--------------- min1 = ", min1);
                            if(col2>min1)
                            {
                              //idLog.trace("<position> onContentXChanged add right");
                              grid.g_rightadd();
                              grid.g_leftrem();
                            }
                            else
                            {
                                if(grid.contentX>s3)
                                {
                                    grid.contentX=s3;
                                }
                            };
                        }

                        var idx = 0
                        var item_x = 0
                        var item_x1 = 0
                        if ( grid.atXBeginning ) {
                            idx = 0
                        }
                        else if ( grid.atXEnd ) {
                            idx = colorModel.count - 1
                        }
                        else {
                            idx = grid.indexAt( grid.contentX + grid.width / 2, grid.y + grid.height / 2 )
                            //center_x = grid.originX - grid.width / 2;
                            item_x = grid.itemAt( grid.contentX + grid.width / 2, grid.y + grid.height / 2 )
                            //item_x1 = (grid.contentX + grid.originX) * (grid.height / grid.contentHeight)
                        }

                        if (prevContentX < contentX)
                        {
                            console.info("play right");
                        }
                        else
                        {
                            console.info("play left")
                        }

                        //var pipec = center.mapToItem(item_x, grid.width/2, grid.height/2)
                        //var pipec = mapToItem(item_x, grid.contentX+grid.width/2, grid.y+grid.height/2)
                        //console.info("pipec = ", pipec.x - ((grid.contentX/grid.width)*grid.width))
                        //console.info("~~~~~~~~~~~~~~~~~~~~~ idx = ", idx)
                        //console.info("~~~~~~~~~~~~~~~~~~~~~ x = ", grid.contentX + grid.width / 2)
                        //console.info("~~~~~~~~~~~~~~~~~~~~~ item_x = ", item_x.x)
                        //console.info("~~~~~~~~~~~~~~~~~~~~~ item.parent.x = ", item_x.parent.x)
                        //console.info("~~~~~~~~~~~~~~~~~~~~~ grid.visibleArea.xPosition = ", grid.visibleArea.xPosition*grid.width)
                        //console.info("~~~~~~~~~~~~~~~~~~~~~ item_x1 = ", item_x1)
                        //console.info("--------------- grid.originX = ",grid.originX);
                        //console.info("~~~~~~~~~~~~~~~~~~~~~ grid.count = ", colorModel.count);
                        //console.info("--------------- onContentXChanged = ", grid.contentX);
                        //console.info("--------------- grid.contentWidth = ",grid.contentWidth);
                        //console.info("~~~~~~~~~~~~~~~ name = ", colorModel.get(idx).name)

                        //root._index_play_deleg = idx;
                        //root._coord_play = pipec.x - ((grid.contentX/grid.width)*grid.width);
                        //root._slider_value = (100000/grid.width)*root._coord_play;
                        //console.info("_index_play_deleg = ", root._index_play_deleg);
                        //console.info("_coord_play = ", root._coord_play);
                        //console.info("_slider_value = ", root._slider_value);
                        //m_univreaderex_asc.setSliderValue709(_slider_value);
                        grid.prevContentX=grid.contentX;
                    }

                    onMovingChanged:
                    {
                        //idLog.trace(" contentX="+grid.contentX+" originX="+grid.originX
                        //            +" contentWidth="+grid.contentWidth+" width="+grid.width+" "+visibleArea.xPosition);
                    }
                    //delegate:IVSemanticaDelegate
                    //{
                    //    ivComponent:root.ivComponent
                    //    width:grid.cellWidth
                    //    height:grid.cellHeight
                    //    semantica:sema
                    //    semaProperties:root.semaProperties
                    //    unique1:root.semaProperties.unique
                    //    row2:model.row1
                    //    col2:model.col1
                    //    cellInLine:grid.cellInLine
                    //    isDebug:root.isDebug
                    //}
                    delegate:intervalsDelegate
                    Component {
                        id: intervalsDelegate

                        Rectangle {
                            id: rect1
                            width: grid.width
                            height: grid.height
                            color: portrait
                            onVisibleChanged:{
                                console.info("visible = ", visible)
                            }
                            Text {
                                text: name
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 72
                            }

                            MouseArea{
                                id: mouse_arr
                                anchors.fill: parent
                                hoverEnabled: true

                                onReleased: {
                                    console.info("MouseArea onReleased pipec = ");
                                    //var pipec = mapToItem(item_x, grid.contentX+grid.width/2, grid.y+grid.height/2)
                                    //console.info("MouseArea onReleased pipec = ", pipec);
                                }

                                onPositionChanged: {
                                    //var pipec = mapToItem(item_x, grid.contentX+grid.width/2, grid.y+grid.height/2)
                                    //console.info("MouseArea onReleased pipec = ", pipec);
                                    //console.info("MouseArea onPositionChanged pipec = ");
                                }

                                onPressAndHoldIntervalChanged: {
                                    console.info("MouseArea onPressAndHoldIntervalChanged pipec = ");
                                }
                                onPressAndHold: {
                                    console.info("MouseArea onPressAndHoldIntervalChanged pipec = ");
                                }

                                onEntered: {
                                    console.info("MouseArea onEntered pipec = ");
                                }
                            }
                        }
                    }

                    Component.onCompleted: {

                        //positionViewAtIndex(3, ListView.Center)
                        grid.currentIndex = 3;
                        //contentX = originX

                        console.info("grid width = ", grid.width);
                        console.info("grid height = ", grid.height);
                        console.info("random color = ", Qt.rgba(Math.random(), Math.random(), Math.random()).toString());

                        colorModel.append({name:"Январь", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString(), "col1":0});
                        colorModel.append({name:"Февраль", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString(), "col1":1});
                        colorModel.append({name:"Март", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString(), "col1":2});
                        colorModel.append({name:"Апрель", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString(), "col1":3});
                        colorModel.append({name:"Май", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString(), "col1":4});
                        colorModel.append({name:"Июнь", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString(), "col1":5});
                        colorModel.append({name:"Июль", portrait: Qt.rgba(Math.random(), Math.random(), Math.random()).toString(), "col1":6});

                        contentX=grid.width*3;
                        delta_contentX = contentX;
                        //timer_play.start();

                        console.info("contentX = ", contentX)
                    }

                    function getVisibleIndexRange() {
                            var center_x = grid.x + grid.width / 2
                            return [indexAt( center_x, grid.y + grid.contentY + 10),
                                    indexAt( center_x, grid.y + grid.contentY + grid.height - 10)]
                        }

                    Rectangle {
                        id: center
                        width: 4
                        x: parent.width / 2 - center.width / 2
                        height: parent.height
                        color: "yellow"
                    }
                }

            }
        }

}

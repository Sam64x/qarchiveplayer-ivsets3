import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import QtQuick.Window 2.1
import iv.plugins.loader 1.0
import iv.guicomponents 1.0
import iv.components.windows 1.0
import iv.plugins.users 1.0
import iv.singletonLang 1.0
Rectangle
{
    id:rootRect
    z: 95
    width: parent.width
    height: 28*isize
    color: "transparent"
    property variant m_idLog2_btp: null
    property variant m_idLog3_btp: null
    IvAccess {
      id: acc
      access: "{sets_edit}"
    }
    property real isize: interfaceSize.value !== ""?parseFloat(interfaceSize.value):1
    IvVcliSetting
    {
        id: interfaceSize
        name: 'interface.size'
    }
    IvVcliSetting {
      id: integration_flag
      name: 'cmd_args.mode'
     }
    IvVcliSetting{
        id: fastEdits
        name: 'sets.fastEdits'
    }
    IvVcliSetting
    {
        id:isSetEdit
        name:"is_set_edits"
    }
    property var parentComponent: null
    property bool mouseOnPane: false
    opacity: (rootRect.mouseOnPane? 1.0 : 0.0)
    property bool isFastEdits: fastEdits.value ==="true" || isSetEdit.value === "true"
    property bool _isVisible:acc.isAllowed ?  rootRect.isFastEdits ?
                                                 true: isSetEdit.value === "true"?
                                                     true :integration_flag.value === "SDK"?
                                                         rootRect.parentComponent.viewer_command_obj.myGlobalComponent.ivSetsArea?
                                                                                                                    false:true:false :false
    visible:  _isVisible
    Iv7Log {
        id: idLogQtDebug
        name: 'qt_debug'
    }

    onParentComponentChanged: {
//        idLogQtDebug.error('onParentComponentChanged ' + rootRect + ' IVButtonTopPanel.qml {');
        //idWindowResize.visible = integration_flag.value === "SDK"
//        idLogQtDebug.error('onParentComponentChanged ' + rootRect + ' IVButtonTopPanel.qml }');
    }

    Rectangle
    {
        id:videoButtonRect
        anchors.fill: rootRect
        color: "black"
        opacity: rootRect.mouseOnPane? 0.4 : 0.0
        IVWindowResize {
            id: idWindowResize
            anchors.fill: parent
            enableResize: false
            visible:  integration_flag.value === "SDK"
                     // && rootRect.parentComponent.viewer_command_obj.myGlobalComponent.ivSetsArea ===null
                     // && rootRect.parentComponent.viewer_command_obj.myGlobalComponent.ivSetsArea === undefined
        }
    }
    RowLayout
    {
        id:buttonRightRowLayout
        spacing: 1
        width: parent.width/2
        height: parent.height
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        layoutDirection:Qt.RightToLeft
        Rectangle
        {
            visible: rootRect._isVisible
            width: 28* rootRect.isize
            height: 28* rootRect.isize
            Layout.alignment: Qt.AlignVCenter
            color: "transparent"
            IVImageButton
            {
                id: closeCameraButton
                anchors.verticalCenter: parent.verticalCenter
                txt_tooltip: Language.getTranslate("Close camera", "Закрыть камеру")
                on_source: 'file:///' + applicationDirPath + '/images/white/clear.svg'
                //size: "small"
                width: parent.width
                height: parent.height
                onClicked:
                {
                    var control = rootRect.parentComponent.viewer_command_obj.myGlobalComponent.ivSetsArea;
                    if(control !== null && control !== undefined)
                    {

                        rootRect.parentComponent.viewer_command_obj.command_to_viewer('sets:area:removecamera2');
                    }
                    else
                    {
                        console.error(" control = null")
                        rootRect.parentComponent.viewer_command_obj.command_to_viewer('windows:hide');
                    }

                    //parentComponent.ivComponent.commandToParent('sets:area:removecamera2', {});
                }
            }
        }
        Item
        {
            Layout.fillWidth: true
        }
    }
}

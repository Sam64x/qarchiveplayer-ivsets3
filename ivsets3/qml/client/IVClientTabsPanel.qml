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

Rectangle {
    id: root

    property bool useAnimation: false
    property var globalSignalsObject: null
    property real isize: interfaceSize.value !== "" ? parseFloat(interfaceSize.value) : 1

    signal miniClicked

    implicitWidth: contentLayout.implicitWidth
    implicitHeight: 48 * root.isize

    color: IVColors.get("Colors/Background new/BgContextMenuThemed")

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: 0

        Row {
            id: leftArea

            Layout.fillHeight: true
            spacing: 8 * root.isize

            Rectangle {
                width: 72 * root.isize
                height: root.implicitHeight

                color: globalSignalsObject.leftMenuOpened
                       ? IVColors.get("Colors/Background new/BgFormPrimaryThemed")
                       : IVColors.get("Colors/Background new/BgContextMenuThemed")

                Behavior on color {
                    ColorAnimation {duration: 150}
                }

                IVButton {
                    width: 56 * root.isize
                    height: 40 * root.isize
                    anchors.centerIn: parent

                    source: "white/menu"
                    toolTipText: "Меню"

                    onClicked: {
                        globalSignalsObject.leftMenuOpened ^= true
                    }
                }
            }

            IVButtonControl {
                width: archOnly.value === "true" ? 28 * root.isize : 0
                height: archOnly.value === "true" ? 28 * root.isize : 0
                anchors.verticalCenter: parent.verticalCenter

                visible: archOnly.value === "true"
                source: "new_images/archive"
                contentColor: archive_fix2.value === "true" ? "red" : "white"
                toolTipText: archive_fix2.value === "true"
                             ? Language.getTranslate("Archive", "Архив")
                             : Language.getTranslate("Realtime", "Реалтайм")

                onClicked: {
                    if (archive_fix2.value === "true") {
                        archive_fix2.value = "false";
                        tabs.setViewType("realtime");
                    }
                    else {
                        archive_fix2.value = "true";
                        tabs.setViewType("archive");
                    }
                }

                IvVcliSetting {
                    id: archive_fix2
                    name: 'archive.fixVisible'
                }
            }
        }

        Item {
            Layout.fillWidth: true
            visible: hideSets.value === "true"
        }

        IVClientTabs {
            id: tabs

            Layout.fillWidth: true

            globalSignalsObject: root.globalSignalsObject
            visible: hideSets.value !== "true"

            IvVcliSetting {
                id: hideSets
                name: 'settings.hide_new_sets'
            }
        }

        Row {
            id: rightArea

            Layout.preferredHeight: 40 * root.isize
            Layout.rightMargin: 8
            spacing: 8 * root.isize

            IVButton {
                readonly property bool isEditPanelOpened: editPanelOpened.value === "true"

                implicitWidth: 56 * root.isize
                implicitHeight: parent.height
                anchors.verticalCenter: parent.verticalCenter

                visible: globalSignalsObject.tabType === "set"
                source: "new_images/settings-04"
                type: isEditPanelOpened ? IVButton.Type.Primary : IVButton.Type.Helper
                toolTipText: isEditPanelOpened
                             ? Language.getTranslate("Hide Right Panel", "Свернуть правую панель")
                             : Language.getTranslate("Expand Right Panel", "Развернуть правую панель")

                onClicked: {
                    editPanelOpened.value = isEditPanelOpened ? "false" : "true";
                }

                IvVcliSetting {
                    id: editPanelOpened
                    name: "editPanel.opened"
                }
            }

        	ActiveExportsButton {}
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

            IVButtonControl {
                id: loginButton

                readonly property string shortName: {
                    var name = toolTipText
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

                implicitWidth: 40 * root.isize
                implicitHeight: 40 * root.isize
                anchors.verticalCenter: parent.verticalCenter

                visible: usrLBS.value === 'true' || usr_man.authOn
                text: shortName
                toolTipText: (usr_man.userLogin === "guest") ? "Гость" : usr_man.userLogin

                textFont: IVColors.getFont("Title")
                contentNormalColor: IVColors.get("Colors/Text new/TxAccentThemed")
                contentHoveredColor: IVColors.get("Colors/Text new/TxAccentThemed")
                contentPressedColor: IVColors.get("Colors/Text new/TxContrast")
                backgroundNormalColor: IVColors.get("Colors/Background new/BgFormTertiaryThemed")
                backgroundHoveredColor: IVColors.get("Colors/Background new/BgBtnTertiaryThemed-hover")
                backgroundPressedColor: IVColors.get("Colors/Background new/BgBtnCheck")

                onReleased: {
                    if (usr_man.userLogin === "guest") {
                        authMenu.open()
                    }
                    else {
                        userMenu.open()
                    }
                }

                IvUser {
                    id: usr_man

                    property bool firstChange: true

                    onUserLoginChanged: {
                        if (authMenu.opened && usr_man.connectOn) authMenu.close()
                        if (firstChange && rememberUsr.value === "false") {
                            usr_man.logoff()
                        }
                        firstChange = false
                    }

                    Component.onCompleted: {
                        usr_man.updateLogin()
                        usr_man.updateWSPort()
                    }
                }

                IvVcliSetting{
                    id: usrLBS
                    name: 'user.loginBannerStatic'
                }

                IvVcliSetting {
                    id: rememberUsr
                    name: 'user.constant'
                    Component.onCompleted: {
                        value = (value !== "false") ? "true" : "false"
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

                IvAccess {
                  id: clientHideTab
                  access: "{hide_tabsbar}"
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

                    IvAccess {
                      id: clientClose
                      access: "{closing_system}"
                    }
                }

                IvAccess {
                  id: clientResize
                  access: "{change_the_size_and_position_of_the_window}"
                }
            }
        }
    }

    IvVcliSetting {
        id: interfaceSize
        name: 'interface.size'
    }

    IvVcliSetting {
        id: systemFrame
        name: 'interface.system_frame'
    }

    IvVcliSetting {
        id: archOnly
        name: 'sourse_switch_archive_only'
        onValueChanged: {
            if (archOnly.value === "false") {
                archive_fix2.value === "";
            }
        }
    }
}

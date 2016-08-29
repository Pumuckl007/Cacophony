import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import QtQuick.LocalStorage 2.0
import "DiscordInterface.js" as Discord

import Cacophony 1.0 as Cacophony

/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    id: mainView
    objectName: "mainView"
    applicationName: "cacophony.007pumuckl"
    anchorToKeyboard: true

    width: units.gu(100)
    height: units.gu(75)

    Cacophony.VoiceConnection {
        id:voiceConnection
    }

    function update(){
        console.log(myType.helloWorld)
    }

    AdaptivePageLayout {
        id: pageLayout
        primaryPage: friendsAndServersPage
        anchors.fill: parent

        ChatPage{
            id: chatPage
        }

        FriendsAndServers {
            id: friendsAndServersPage
        }

        Server {
            id: serverPage
        }

        ServerUsers {
            id: serverUsersPage
        }

        VoiceChannel {
            id: voiceChannelPage;
        }
    }

    Component {
        id: dialog
        Dialog {
            id: dialogue
            title: "Login"
            text: ""
            TextField{
                id:username
                focus: true
                placeholderText: i18n.tr("Username/Token");
            }
            TextField{
                id:password
                echoMode: TextInput.Password
                placeholderText: i18n.tr("Password");
                focus: true
            }
            Button {
                id:login
                text: "Login"
                color:UbuntuColors.green
                onClicked: {
                    if(discord().login(username.text, password.text) >= 0){
                        username.visible = false;
                        password.text = "";
                        password.visible = false;
                        login.visible = false;
                        activityIndicator.visible = true;
                        activityIndicator.running = true;
                    } else {
                        dialogue.text = i18n.tr("Invalid username, password, or token.");
                        password.text = "";
                    }
                }
            }
            ActivityIndicator {
                    id: activityIndicator
                    running: false
                    visible:false
            }
            Component.onCompleted: {
                var popUtil = PopupUtils;
                Discord.addEventListener(Discord.BAD_LOGIN, function(){
                    dialogue.text = i18n.tr("Invalid username, password, or token.");
                    username.visible = true;
                    password.visible = true;
                    login.visible = true;
                    activityIndicator.visible = false;
                    activityIndicator.running = false;
                });
                Discord.addEventListener(Discord.LOGIN_SUCCESSFUL, function(){
                    activityIndicator.visible = false;
                    activityIndicator.running = false;
                    popUtil.close(dialogue);
                });
            }
        }
    }

    function discord(){
        return Discord
    }

    function done(){
        PopupUtils.open(dialog);
    }

    Component.onCompleted: {
        Discord.init(mainView, voiceConnection);
        var db = LocalStorage.openDatabaseSync("cacophony", "0.1", "Cacheing/Saving", 100000);
        Discord.setDB(db)
        done();
    }
}


import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
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

    function discord(){
        return Discord
    }

    function done(){
        PopupUtils.open(dialog);
    }

    Timer{
        id: timerDebug
        interval: 4000;
        repeat: false;
        onTriggered: {
            voiceConnection.writePackets();
        }
        running: false;
    }

    Component.onCompleted: {
        //myType.encodeDecodeTest();
        //voiceConnection.ssrc = 10;
        //voiceConnection.port= 39338;
        //voiceConnection.url = "example.com";
        Discord.init(mainView, voiceConnection);
        //voiceConnection.decodeTest();
        //Discord.addEventListener(Discord.CHANGE_CHANNEL, done);
    }
}


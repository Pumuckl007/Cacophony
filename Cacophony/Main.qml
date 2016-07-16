import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import "DiscordInterface.js" as Discord

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
    }

    function discord(){
        return Discord
    }

    function done(){
        PopupUtils.open(dialog);
    }


    Component.onCompleted: {
        //Discord.init(mainView);
        Discord.addEventListener(Discord.CHANGE_CHANNEL, done);
    }
}


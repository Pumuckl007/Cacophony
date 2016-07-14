import QtQuick 2.4
import Ubuntu.Components 1.3
import Qt.WebSockets 1.0
import Ubuntu.Components.Popups 1.3
import "DiscordInterface.js" as Discord

/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    id: mainView
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "cacophony.007pumuckl"

    width: units.gu(100)
    height: units.gu(75)

    Page {
        header: PageHeader {
            id: pageHeader
            title: i18n.tr("Cacophony")
            StyleHints {
                foregroundColor: UbuntuColors.orange
                backgroundColor: UbuntuColors.porcelain
                dividerColor: UbuntuColors.slate
            }
        }

        Label {
            id: label
            objectName: "label"
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: pageHeader.bottom
                topMargin: units.gu(2)
            }

            text: ""
        }

        Component {
             id: dialog
             Dialog {
                 id: dialogue
                 title: "Connection Ready!"
                 text: "Send a message now?"
                 Button {
                     text: "Sure"
                     onClicked: {
                         PopupUtils.close(dialogue)
                         Discord.sendMessageToCurrentChannel("Hello Channel");
                     }
                 }
                 Button {
                     text: "Not Now"
                     color: UbuntuColors.orange
                     onClicked: {
                         PopupUtils.close(dialogue)
                     }
                 }
             }
        }

        Button {
            id: button
            objectName: "button"
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: label.bottom
                topMargin: units.gu(2)
            }
            width: parent.width
            text: i18n.tr("Send Message!")
            onClicked: {
                Discord.sendMessageToCurrentChannel("HI?");
            }
        }
    }

    function done(){
        PopupUtils.open(dialog);
    }

    function message(event, object){
        label.text += "<" + object.author.username + "> " + object.content + "\n";
    }

    Component.onCompleted: {
        Discord.init(mainView);
        Discord.addEventListener(Discord.CHANGE_CHANNEL, done);
        Discord.addEventListener(Discord.MESSAGE_CREATED, message);
    }
}


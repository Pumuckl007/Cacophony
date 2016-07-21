import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

Page {
    property string channelName
    id: voiceChannels
    header: PageHeader {
        id: channelNameHeader
        title: channelName
        StyleHints {
            foregroundColor: UbuntuColors.orange
            backgroundColor: UbuntuColors.porcelain
            dividerColor: UbuntuColors.slate
        }
        trailingActionBar.actions: [
            Action {
                iconName:"ok";
                text: i18n.tr("Join")
                onTriggered: {

                }
            },
            Action {
                id:silence
                iconName:"speaker";
                text: i18n.tr("Silence")
                onTriggered: {
                    if(silence.iconName === "speaker"){
                        silence.iconName = "speaker-mute"
                    } else {
                        silence.iconName = "speaker";
                    }
                }
            },
            Action {
                id:mute
                iconName:"microphone";
                text: i18n.tr("Mute")
                onTriggered: {
                    if(mute.iconName === "microphone"){
                        mute.iconName = "microphone-mute"
                    } else {
                        mute.iconName = "microphone";
                    }
                }
            }
        ]
    }

    Rectangle {
        id: wrapper
        anchors.top: channelNameHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        UbuntuListView{
            id: channelsView
            anchors.fill: parent
            clip: true

            model: ListModel{
                id: voiceChatters
            }

            delegate: FriendDisplay {}

            Component.onCompleted: {
                var max = Math.random()*10+1;
                for(var i = 0; i<max; i++){
                    var string = "User " + i;
                    voiceChatters.append({username:string});
                }
            }
        }
    }


}


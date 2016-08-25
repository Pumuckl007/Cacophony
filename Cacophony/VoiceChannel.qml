import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

Page {
    property string channelName
    property string channelId;
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
                    console.log(channelId);
                    discord().joinVoiceChannel(channelId);
                }
            },
            Action {
                id:silence
                iconName:"speaker";
                text: i18n.tr("Silence")
                onTriggered: {
                    discord().deafen();
                }
            },
            Action {
                id:mute
                iconName:"microphone";
                text: i18n.tr("Mute")
                onTriggered: {
                    discord().mute();
                }
            },
            Action {
                id: connectionQuality
                iconName: "gsm-3g-none";
                text: i18n.tr("Connection Info");
                onTriggered: {

                }
            }

        ]

        Component.onCompleted: {
            discord().addEventListener(discord().VOICE_CONNECTION_UPDATE, function(event, vc){
                silence.iconName = vc.deaf ? "speaker-mute" : "speaker";
                mute.iconName = vc.mute ? "microphone-mute" : "microphone";
            });
            discord().addEventListener(discord().PING_UPDATED, function(event, vc){
                console.log("yeah " + vc.ping);
                if(vc.ping < 25){
                    connectionQuality.iconName = "gsm-3g-full-secure";
                } else if(vc.ping < 50){
                    connectionQuality.iconName = "gsm-3g-high-secure";
                } else if(vc.ping < 100){
                    connectionQuality.iconName = "gsm-3g-medium-secure";
                } else if(vc.ping < 250){
                    connectionQuality.iconName = "gsm-3g-low-secure";
                } else {
                    connectionQuality.iconName = "gsm-3g-none";
                }
            });
        }
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


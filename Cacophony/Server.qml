import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

Page {
    property string serverName
    property string serverId
    id: mainPage
    header: PageHeader {
        id: yourStatusHeader
        title: serverName
        StyleHints {
            foregroundColor: UbuntuColors.orange
            backgroundColor: UbuntuColors.porcelain
            dividerColor: UbuntuColors.slate
        }
        trailingActionBar.actions: [
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
                iconName:"info";
                text: i18n.tr("Info")
                onTriggered: {
                    pageLayout.addPageToNextColumn(serverPage ,serverUsersPage, {serverName: serverName, serverId: serverId});
                    serverUsersPage.updateFriendModel();
                }
            }

        ]
    }

    Component.onCompleted: {
        discord().addEventListener(discord().VOICE_CONNECTION_UPDATE, function(event, vc){
            silence.iconName = vc.deaf ? "speaker-mute" : "speaker";
            mute.iconName = vc.mute ? "microphone-mute" : "microphone";
        });
    }

    function updateChannelsModel(event, checkServerId){
        if(checkServerId && serverId !== checkServerId)
            return;
        channelsModel.clear();
        channelsModel.append({type:"devider"});
        var channels = discord().channelsMap[serverId];
        for(var i = 0; i<channels.length; i++){
            if(channels[i].type === "text"){
                channelsModel.insert(0, channels[i]);
            } else {
                channelsModel.append(channels[i]);
            }
        }
    }

    Rectangle {
        id: wrapper
        anchors.top: yourStatusHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        UbuntuListView{
            id: channelsView
            anchors.fill: parent
            clip: true

            model: ListModel{
                id: channelsModel
            }

            delegate: ChannelDisplay {}

            Component.onCompleted: {
                //Need to add the variables used here or else list elements won't be able to accsses them
                channelsModel.append({type:"devider", name:"null", id:"-1"});
                discord().addEventListener(discord().SERVER_CHANNELS,updateChannelsModel);
            }
        }

        BottomEdgeHint {
            iconName: "add"
            text: i18n.tr("New Channel")
            onClicked: newChannel.open();
        }

        NewChannel{
            id: newChannel
            model: channelsModel
        }
    }


}


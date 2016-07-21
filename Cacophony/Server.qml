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

    function updateChannelsModel(event, checkServerId){
        if(checkServerId && serverId !== checkServerId)
            return;
        console.log("Server id" + serverId);
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


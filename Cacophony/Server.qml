import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

Page {
    property string serverName
    id: mainPage
    header: PageHeader {
        id: yourStatusHeader
        title: i18n.tr("Server:") + serverName
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
                    pageLayout.addPageToNextColumn(serverPage ,serverUsersPage, {serverName: serverName});
                }
            }

        ]
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
                var max = Math.random()*100;
                for(var i = 0; i<max; i++){
                    var string = "Channel " + i;
                    channelsModel.append({name:string});
                }
            }
        }

        BottomEdgeHint {
            iconName: "add"
            text: i18n.tr("New Channel")
            onClicked: newChannel.open();
        }

        NewChannel{
            id: newChannel
        }
    }


}


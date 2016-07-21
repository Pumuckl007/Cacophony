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
        title: serverName + i18n.tr(" : Users")
        StyleHints {
            foregroundColor: UbuntuColors.orange
            backgroundColor: UbuntuColors.porcelain
            dividerColor: UbuntuColors.slate
        }
    }

    function updateFriendModel(event, checkServerId){
        if(serverId && (!checkServerId || checkServerId === serverId)){
            var users = discord().guilds[serverId].users;
            friendsModel.clear();
            for(var i = 0; i<users.length; i++){
                friendsModel.append(users[i].user);
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
            id: friendsView
            anchors.fill: parent
            clip: true

            model: ListModel{
                id: friendsModel
            }

            delegate: FriendDisplay { }

            Component.onCompleted: {
                friendsModel.append({username:"Nobody", id:"0", discriminator: "0", previousPage: serverUsersPage});
                discord().addEventListener(discord().SERVER_USERS_UPDATED, updateFriendModel);
            }
        }
    }


}


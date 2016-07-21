import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

Page {
    id: mainPage
    header: PageHeader {
        id: userNameHeader
        title: i18n.tr("Your Username")
        StyleHints {
            foregroundColor: UbuntuColors.orange
            backgroundColor: UbuntuColors.porcelain
            dividerColor: UbuntuColors.slate
        }
    }

    UbuntuListView{
        id: serversView
        anchors.top: userNameHeader.bottom
        anchors.left: parent.left
        width: units.gu(10)
        anchors.bottom: parent.bottom
        clip: true
        spacing: units.gu(1)

        model: ListModel{
            id: serversModel
        }
        delegate: ServerDisplay { }

    }

    Rectangle {
        id: divider
        color: UbuntuColors.lightGrey;
        anchors.top: userNameHeader.bottom
        anchors.left: serversView.right
        width: 1
        anchors.bottom: parent.bottom
    }

    UbuntuListView{
        id: friendsView
        anchors.top: userNameHeader.bottom
        anchors.left: divider.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true

        model: ListModel{
            id: friendsModel
        }

        delegate: FriendDisplay { }
    }

    Component.onCompleted: {
        discord().addEventListener(discord().USER_CHANGED, function(event, user){
            userNameHeader.title = user.username;
        });
        discord().addEventListener(discord().NEW_GUILD, function(event, server){
            serversModel.append({name: server.name, id:server.id});
        });
    }
}


import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

Page {
    id: mainPage
    header: PageHeader {
        id: yourStatusHeader
        title: i18n.tr("Your Username")
        StyleHints {
            foregroundColor: UbuntuColors.orange
            backgroundColor: UbuntuColors.porcelain
            dividerColor: UbuntuColors.slate
        }
    }

    UbuntuListView{
        id: serversView
        anchors.top: yourStatusHeader.bottom
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
        anchors.top: yourStatusHeader.bottom
        anchors.left: serversView.right
        width: 1
        anchors.bottom: parent.bottom
    }

    UbuntuListView{
        id: friendsView
        anchors.top: yourStatusHeader.bottom
        anchors.left: divider.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true

        model: ListModel{
            id: friendsModel
        }

        delegate: FriendDisplay { }

        Component.onCompleted: {
            for(var i = 0; i<40; i++){
                var string = "Mr. " + Math.random();
                friendsModel.append({name:string});
                serversModel.append({name: "ID: " + i});
            }
        }
    }

}


import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

Page {
    property string serverName
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
                for(var i = 0; i<40; i++){
                    var string = "Mr. " + Math.random();
                    friendsModel.append({name:string});
                }
            }
        }
    }


}


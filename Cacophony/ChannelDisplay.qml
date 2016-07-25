import QtQuick 2.0
import Ubuntu.Components 1.3

ListItem {
  id: channel
  width: parent.width;
  height:units.gu(4);
  color: UbuntuColors.porcelain
  onClicked: {
      if(type === "text"){
        pageLayout.addPageToNextColumn(serverPage ,chatPage, {channelName: name, shouldDisplayVoiceChannels:true, idOfChannel:id});
        discord().setCurrentChannel(id);
        chatPage.reload();
      }
      else if(type === "voice")
          selected = true
  }

  Text {
    height: units.gu(4);
    id: channelName
    text: (type === "devider") ? i18n.tr("Voice Channels") : (type === "text") ? i18n.tr("#") + name : name
    font.weight: (type === "devider") ? Font.Bold : (selected) ? Font.DemiBold : Font.Normal;
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  trailingActions: actions


  ListItemActions {
      id: actions;
      Action {
          id: deleteChannel
          iconName: "delete";
          property color color: UbuntuColors.red;
          property color iconColor: "white"
          property color iconColorPressed: "grey"
      }
      Action {
          id: info
          iconName: "info";
          onTriggered: {
              pageLayout.addPageToNextColumn(serverPage ,voiceChannelPage, {channelName: channelName.text});
          }
      }

      actions: (type === "devider") ? [] : (type === "voice") ? [info, deleteChannel] : [deleteChannel]
      delegate: Item {
        width: units.gu(6);
        Rectangle {
            color: action.color ? action.color : "black";
            visible: action.color ? true : false
            width: units.gu(6);
            height: units.gu(4);
        }

        Icon {
            id: icon
            name: action.iconName
            width: units.gu(4)
            height: width
            color: action.iconColor ? (pressed ? action.iconColorPressed : action.iconColor ) : (pressed ? "grey" : "darkgrey")
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
      }
  }
}

import QtQuick 2.0
import Ubuntu.Components 1.3

ListItem {
  id: serverDisplay
  width: parent.width;
  height:serverLabel.height;
  color: "white"

  divider.visible: false

  onClicked : {
      pageLayout.addPageToNextColumn(friendsAndServersPage, serverPage, {serverName: name, serverId: id});
      serverPage.updateChannelsModel()
  }

  Text {
    id: serverLabel
    text: {
        var strings = name.split(" ");
        var returnString = ""
        for(var i = 0; i<strings.length; i++){
            if(strings[i].length > 0){
                returnString += strings[i][0];
            }
        }
        return returnString;
    }
    width: parent.width
    font.weight: Font.Bold;
    horizontalAlignment: Text.AlignHCenter
  }
}


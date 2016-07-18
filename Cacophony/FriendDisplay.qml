import QtQuick 2.0
import Ubuntu.Components 1.3

ListItem {
  id: chatDisplay
  width: parent.width;
  height:units.gu(4);
  color: UbuntuColors.porcelain

  Text {
    height: units.gu(4);
    id: userNameLabel
    text: name + ""
    font.weight: Font.Bold;
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  trailingActions: actions

  ListItemActions {
      id: actions;
        actions: [
          Action {
              iconName: "message";
          },
          Action {
              iconName: "info";
              property color color: UbuntuColors.red;
              property color iconColor: "white"
              property color iconColorPressed: "grey"
          }
        ]
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


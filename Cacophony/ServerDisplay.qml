import QtQuick 2.0

Rectangle {
  id: serverDisplay
  width: parent.width;
  height:serverLabel.height;

  Text {
    id: serverLabel
    text: name
    font.weight: Font.Bold;
    horizontalAlignment: Text.AlignHCenter
  }
}


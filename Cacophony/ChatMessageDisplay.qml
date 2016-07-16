import QtQuick 2.0

Rectangle {
  id: delegateItem
  width: parent.width;
  height:contentLabel.height;

  Text {
    id: userNameLabel
    text: author.username
    font.weight: Font.Bold;
  }

  Text {
    id: contentLabel
    anchors.leftMargin: units.gu(1)
    anchors.left: userNameLabel.right
    anchors.right: parent.right
    text: content
    wrapMode: Text.Wrap
  }
}


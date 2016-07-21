import QtQuick 2.0
import Ubuntu.Components 1.3

Panel{
    property variant model
    id: panel
    anchors {
        right: parent.right
        bottom: parent.bottom
    }
    width: parent.width
    height: parent.height

    Rectangle {
        anchors.fill: parent
        color: Theme.palette.normal.overlay
        Rectangle {
            id: margin
            height: units.gu(1)
        }

        ComboButton {
            id: channelType
            text: i18n.tr("Channel Type")
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: margin.bottom
            expandedHeight: -1
            width: parent.width*9/10
            onClicked: {
                channelType.expanded = !channelType.expanded;
            }

            Column {
                   Rectangle {
                       id: textChannelRect
                       height: units.gu(4)
                       width: parent.width
                       property bool selected: false
                       color: selected ? UbuntuColors.lightGrey : "white";
                        Text{
                            id: textChannel
                            text: i18n.tr("Text Channel")
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                        }
                        MouseArea {
                            anchors.fill: parent;
                            onClicked: {
                               channelType.text = textChannel.text;
                               textChannelRect.selected = true;
                               voiceChannelRect.selected = false;
                                channelType.expanded = false;
                            }
                        }
                   }
                   Rectangle {
                       height: 1
                       width: parent.width
                       color: UbuntuColors.lightGrey
                   }

                   Rectangle {
                       id: voiceChannelRect
                       height: units.gu(4)
                       width: parent.width
                       property bool selected: false
                       color: selected ? UbuntuColors.lightGrey : "white";
                       Text{
                            id: voiceChannel
                            text: i18n.tr("Voice Channel")
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                       }
                       MouseArea {
                            anchors.fill: parent;
                            onClicked: {
                               channelType.text = voiceChannel.text;
                               voiceChannelRect.selected = true;
                               textChannelRect.selected = false;
                                channelType.expanded = false;
                            }
                       }
                   }
            }
        }

        TextField {
            id: channelName
            anchors.top: channelType.bottom;
            anchors.topMargin: units.gu(3)
            placeholderText: i18n.tr("Channel Name")
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width*9/10
        }

        Rectangle {
            id: marginTwo
            anchors.top: channelName.bottom
            height: units.gu(3)
        }

        Rectangle {
            id: createAndCancle
            width: parent.width*9/10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: marginTwo.bottom
            Button{
                id: create
                width: parent.width*9/20
                text: i18n.tr("Create")
                color: UbuntuColors.green
                onClicked: {
                    if(textChannelRect.selected){
                        model.set(0, {name:channelName.text, type:"text", active:"false"})
                    } else {
                        model.append({name:channelName.text, type:"voice", active:"false"});
                    }
                    channelType.text = i18n.tr("Channel Type");
                    textChannelRect.selected = false;
                    voiceChannelRect.selected = false;
                    channelName.text = "";
                    panel.close();
                }
            }
            Rectangle {
                id: padding
                width: parent.width/10
                anchors.left: create.right
            }

            Button{
                width: parent.width*9/20
                anchors.left: padding.right
                text: i18n.tr("Cancle")
                onClicked: {
                    channelType.text = i18n.tr("Channel Type");
                    textChannelRect.selected = false;
                    voiceChannelRect.selected = false;
                    channelName.text = "";
                    panel.close();
                }
            }
        }
    }
}

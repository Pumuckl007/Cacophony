import QtQuick 2.0
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem

Page {
    id: mainPage
    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Cacophony")
        StyleHints {
            foregroundColor: UbuntuColors.orange
            backgroundColor: UbuntuColors.porcelain
            dividerColor: UbuntuColors.slate
        }
    }

    UbuntuListView{
        id: messageView
        anchors.top: pageHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: send.top
        verticalLayoutDirection: ListView.BottomToTop
        clip: true
        spacing: units.gu(1)

        model: ListModel{
            id: chatMessages
        }
        delegate: ChatMessageDisplay { }

    }

    Component {
         id: dialog
         Dialog {
             id: dialogue
             title: "Connection Ready!"
             text: "You may now send messages!"
             Button {
                 text: "Okay"
                 color: UbuntuColors.orange
                 onClicked: {
                     PopupUtils.close(dialogue)
                 }
             }
         }
    }

    Button {
        id: send
        objectName: "send"
        anchors {
            right: parent.right
            bottom: parent.bottom
            bottomMargin: units.gu(4)
        }
        width: units.gu(8)
        text: i18n.tr("Send")
        height: units.gu(3);
        onClicked: {
            discord().sendMessageToCurrentChannel(message.text);
            message.text = "";
        }
    }

    TextField {
        id: message
        objectName: "message"
        placeholderText: i18n.tr("Message")
        anchors {
            left: parent.left
            bottom: parent.bottom
            bottomMargin: units.gu(4)
            right: send.left
        }
        height: units.gu(3);
        onAccepted: {
            discord().sendMessageToCurrentChannel(message.text);
            message.text = "";
        }
        onTextChanged: {
            console.log(discord());
            discord().setTypeing();
        }
    }

    Component.onCompleted:{
        discord().addEventListener(discord().MESSAGE_CREATED, messageRecived);
        messageRecived(null, {author:{username:"MEEEEEEEE"},content:"test"});
    }

    function messageRecived(event, object){
        chatMessages.insert(0, {author:object.author, content: object.content});
    }
}


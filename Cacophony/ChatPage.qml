import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3

Page {
    property string channelName : i18n.tr("Untitled");
    property string idOfChannel;
    property bool shouldDisplayVoiceChannels : true;
    id: mainPage
    header: PageHeader {
        id: pageHeader
        title: channelName
        StyleHints {
            foregroundColor: UbuntuColors.orange
            backgroundColor: UbuntuColors.porcelain
            dividerColor: UbuntuColors.slate
        }
        trailingActionBar.actions: (shouldDisplayVoiceChannels) ? [silence, mute] : []
    }

    Action {
        id:silence
        iconName:"speaker";
        text: i18n.tr("Silence")
        onTriggered: {
            if(silence.iconName === "speaker"){
                silence.iconName = "speaker-mute"
            } else {
                silence.iconName = "speaker";
            }
        }
    }
    Action {
        id:mute
        iconName:"microphone";
        text: i18n.tr("Mute")
        onTriggered: {
            if(mute.iconName === "microphone"){
                mute.iconName = "microphone-mute"
            } else {
                mute.iconName = "microphone";
            }
        }
    }

    function reload(){
        chatMessages.clear();
        var messages = discord().messageMap[idOfChannel];
        if(!messages)
            return
        for(var i = messages.length; i >= 0; i--){
            chatMessages.append(messages[i]);
        }
        if(chatMessages.count < 10){
            discord().loadMoreMessageForCurrentChannel();
        }
    }


    UbuntuListView{
        id: messageView
        property bool refreshing : false
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

        pullToRefresh {
            enabled: true
            refreshing: refreshing
            onRefresh: {
                discord().loadMoreMessageForCurrentChannel();
                refreshing = true;
            }
        }

    }

    Button {
        id: send
        objectName: "send"
        anchors {
            right: parent.right
            bottom: parent.bottom
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
            right: send.left
        }
        height: units.gu(3);
        onAccepted: {
            discord().sendMessageToCurrentChannel(message.text);
            message.text = "";
        }
        onTextChanged: {
            discord().setTypeing();
        }
    }

    Component.onCompleted:{
        discord().addEventListener(discord().MESSAGE_CREATED, messageRecived);
        discord().addEventListener(discord().MORE_MESSAGE, moreMessages);
    }

    function messageRecived(event, object){
        if(object.channel_id === idOfChannel)
            chatMessages.insert(0, object);
    }

    function moreMessages(event, channelId){
        messageView.refreshing = false;
        if(channelId === idOfChannel){
            var messages = discord().messageMap[idOfChannel];
            if(!messages)
                return;
            if(chatMessages.count > 0){
                var lastMessageId = chatMessages.get(chatMessages.count-1).id;
                var i = 0;
                while(messages[i].id !== lastMessageId && i<messages.length){
                    i++;
                }
                for(var k = i-1; k>=0; k--){
                    chatMessages.append(messages[k]);
                }
            } else {
                for(var i = messages.length-1; i >= 0; i--){
                    chatMessages.append(messages[i]);
                }
            }
        }
    }
}


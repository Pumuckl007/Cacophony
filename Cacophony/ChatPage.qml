import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Components.ListItems 1.3

Page {
    property string channelName : i18n.tr("Untitled");
    property string idOfChannel;
    property bool shouldDisplayVoiceChannels : true;
    property var typingUsers : [];
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
        text: i18n.tr("Deafen")
        onTriggered: {
            discord().deafen();
        }
    }
    Action {
        id:mute
        iconName:"microphone";
        text: i18n.tr("Mute")
        onTriggered: {
            discord().mute();
        }
    }

    function reload(){
        chatMessages.clear();
        typingUsers = [];
        refreshTyping();
        var messages = discord().messageMap[idOfChannel];
        if(!messages)
            return
        for(var i = messages.length; i >= 0; i--){
            if(messages[i])
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
        anchors.bottom: usersTyping.top
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

    Text {
        id: usersTyping
        text: "No one"
        anchors {
            right: parent.right;
            left: parent.left;
            bottom: send.top
        }
        height: units.gu(2);
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
        discord().addEventListener(discord().TYPING_START, startTyping);
        discord().addEventListener(discord().TYPING_STOP, endTyping);
        discord().addEventListener(discord().VOICE_CONNECTION_UPDATE, function(event, vc){
            silence.iconName = vc.deaf ? "speaker-mute" : "speaker";
            mute.iconName = vc.mute ? "microphone-mute" : "microphone";
        });
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

    function startTyping(event, info){
        if(info.channel_id !== idOfChannel)
            return
        if(discord().dMs[info.user_id]){
            var channel = discord().dMs[info.user_id];
            typingUsers.push([channel.recipient.username, channel.recipient.id]);
            refreshTyping();
            return;
        }
        var users = discord().guilds[discord().serverMap[idOfChannel]].users;
        for(var i = 0; i<users.length; i++){
            if(users[i].user.id === info.user_id){
                typingUsers.push([users[i].user.username, info.user_id]);
                refreshTyping();
                return;
            }
        }
    }

    function endTyping(event, user_id){
        var indexToDelete = -1;
        for(var i = 0; i<typingUsers.length; i++){
            if(typingUsers[i][1] === user_id){
                indexToDelete = i;
                break;
            }
        }
        if(indexToDelete !== -1){
            typingUsers.splice(indexToDelete, indexToDelete+1);
        }
        refreshTyping();
    }

    function refreshTyping(){
        var text = ""
        if(typingUsers.length < 1){
            usersTyping.text = text;
            return;
        }
        if(typingUsers.length > 2){
            var comma = i18n.tr(",");
            for(var i = 0; i<typingUsers.length - 1; i++){
               text += typingUsers[i][0] + comma + " ";
            }
            text += i18n.tr("and") + " " + typingUsers[i][0] + i18n.tr("are typing.");
        } else if(typingUsers.length === 2){
            text = typingUsers[0][0] + " " + i18n.tr("and") + " " + typingUsers[1][0] + " " + i18n.tr("are typing.");
        } else {
            text += typingUsers[0][0] + i18n.tr(" is typing.");
        }
        usersTyping.text = text;
    }
}


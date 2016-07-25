.import QtQml 2.2 as QTQML
var BASE_URL = "https://discordapp.com/api";
var GATEWAY_VERSION = 5.0;
var TYPING_TIMER_INTERVAL = 50;

//Event Strings
//Fired when a channel is changed. Event contains the channel object.
var CHANGE_CHANNEL = "CHANGE_GUILD";
//Fired when a message is created. Event contains message object.
var MESSAGE_CREATED = "MESSAGE_CREATED";
//Fired when a guild is added
var NEW_GUILD = "NEW_GUILD"
//Fired whenever an update to the user data occurs
var USER_CHANGED = "USER_CHANGED"
//Fired when a server's channels are fetched
var SERVER_CHANNELS = "SERVER_CHANNELS"
//Fired when the server users are recived
var SERVER_USERS_UPDATED = "SERVER_USERS_UPDATED"
//Fired when more message are recived in bulk
var MORE_MESSAGE = "MORE_MESSAGES";
//Fired when direct messages are loaded
var DIRECT_MESSAGES_LOADED = "DIRECT_MESSAGES_LOADED";
//Fired when typing starts/stops for user
var TYPING_START = "TYPING_START";
var TYPING_STOP = "TYPING_STOP";

var token = "";
var websocket;
var websocketParrent;
var heartbeatTimer;
var seqs = "";
var user;
var channelsMap = [];
var serverMap = [];
var currentChannelId;
var listeners = [];
var lastTypeingTime = 0;
var guilds = [];
var messageMap = [];
var typeingMap = [];


var setWebsocket = function(websocket){
    websocket.active = true;
    websocket.sendTextMessage("Echo, #" + number);
    number ++;
}

var init = function(parrent){
    getGateway(initContinue1);
    websocketParrent = parrent;
    addEventListener(NEW_GUILD, newGuildQuerry);
    var typingTimer = Qt.createQmlObject("import QtQuick 2.0; Timer {}", websocketParrent);
    typingTimer.triggered.connect(typingUpdate);
    typingTimer.interval = TYPING_TIMER_INTERVAL;
    typingTimer.repeat = true;
    typingTimer.start();
}

var initContinue1 = function(url){
    websocket = createWebsocket(JSON.parse(url).url);
//    console.log(websocket.status);
//    websocket.setProperty("onStatusChanged", function(){
//        console.log(websocket.status);
//    });

//    for(var i in websocket){
//        console.log("Websocket Propert: " + i);
//    }
}

var getGateway = function(callback){
    aPIRequest("GET", BASE_URL + "/gateway", callback);
}

var createWebsocket = function(url){
    var ws = Qt.createComponent("Websocket.qml");
    if(ws.status === QTQML.Component.Ready)
        ws = ws.createObject(websocketParrent, {url:url + "/?encoding=json&v=6", active:true, stsChanged:{func: statusChanged}, txtRecived:{func: messageRecived}});
    else
        console.log("Error: " + ws.errorString());
    return ws;
}

var messageRecived = function(message){
    var msg = JSON.parse(message);
    if(msg.op === 0){
        handleEvent(msg);
        seqs += msg.s;
    } else if(msg.op === 10){
        heartbeatTimer = Qt.createQmlObject("import QtQuick 2.0; Timer {}", websocketParrent);
        heartbeatTimer.triggered.connect(heartbeat);
        heartbeatTimer.interval = msg.d.heartbeat_interval;
        heartbeatTimer.repeat = true;
        heartbeatTimer.start();
    } else {
        console.log("Message with uncaught code " + msg.op + " recived!");
    }
}

var statusChanged = function(){
    if(!websocket)
        return
    if(websocket.status === 1){
        startHandshake();
    }
    console.log("Websocket status Change: " + websocket.status);
}

var startHandshake = function(){
    var identity = {
            "op":2,
            "d": {
                "token": token,
                "v": GATEWAY_VERSION,
                "compress": false,
                "large_threshold": 250,
                "properties": {
                    "$os": "Ubuntu Touch",
                    "$browser":"Cacophony",
                    "$device": "Cacophony",
                    "$referrer":"",
                    "$referring_domain":""
                },
            }
        };
    websocket.sendTextMessage(JSON.stringify(identity));
}

var heartbeat = function(){
    var heartBeat = {
        "op": 1,
        "d": seqs
    }
    seqs = "";
    websocket.sendTextMessage(JSON.stringify(heartBeat));
}

var handleEvent = function(object){
    if(object.t === "READY"){
        user = object.d.user;
        fireEvent(USER_CHANGED, user);
        aPIRequest('get', BASE_URL + "/users/@me/guilds", function(json){
            var newGuilds = JSON.parse(json);
            for(var i = 0; i<newGuilds.length; i++){
                handleEvent({t:"GUILD_CREATE", d:newGuilds[i]});
            }
        });
    } else if(object.t === "GUILD_CREATE"){
        if(guilds[object.d.id])
            return;
        var channels = (channelsMap[object.d.id]) ? channelsMap[object.d.id] : []
        var notAdd = false;
        for(var i = 0; i<channels.length; i++){
            notAdd |= channels[i].id === object.d.id;
        }
        if(!notAdd){
            channels.push(object.d);
        }
        guilds[object.d.id] = object.d;
        currentChannelId = object.d.id;
        fireEvent(CHANGE_CHANNEL, {channel: currentChannelId});
        channelsMap[object.d.id] = channels;
        fireEvent(NEW_GUILD, object.d);
    } else if(object.t === "MESSAGE_CREATE"){
        fireEvent(MESSAGE_CREATED, object.d);
        if(typeingMap[object.d.author.id] && typeingMap[object.d.author.id] >= 0){
            fireEvent(TYPING_STOP, object.d.author.id);
        }

        typeingMap[object.d.author.id] = -1;
        if(messageMap[object.d.channel_id]){
            messageMap[object.d.channel_id].push(object.d);
        } else {
            messageMap[object.d.channel_id] = [object.d];
        }
    } else if(object.t === "TYPING_START"){
        if(!typeingMap[object.d.user_id] || typeingMap[object.d.user_id] < 0)
            fireEvent(TYPING_START, object.d);
        typeingMap[object.d.user_id] = 10000;
    } else if(object.t === "GUILD_MEMBER_ADD"){
        guilds[serverMap[object.t.channel_id]].users.push(object.d);
        fireEvent(SERVER_USERS_UPDATED, serverMap[object.t.channel_id]);
    } else {
        console.log("Uncaught event " + object.t);
    }
}

var aPIRequest = function(type, url, callback, fourth){
    var xmlhttp = new XMLHttpRequest();
    xmlhttp.onreadystatechange=function(error) {
        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
            if(callback && typeof callback === 'function')
                callback(xmlhttp.responseText);
        }
    }
    xmlhttp.open(type, url, true);
    xmlhttp.setRequestHeader('user-agent', "DiscordBot (https://github.com/Pumuckl007/Cacophony, 0.1)" );
    xmlhttp.setRequestHeader('content-type', 'application/json');
    if(token)
        xmlhttp.setRequestHeader('authorization', (user ? (user.bot ? "Bot " : "") : "") + token);
    if(callback && typeof callback !== 'function')
        xmlhttp.send(makeMessage(callback));
    else if(callback && fourth){
        xmlhttp.send(makeMessage(fourth));
    } else
        xmlhttp.send();
}

var makeMessage = function(message){
    var msg = {
        content: String(message),
        tts: false,
        nonce: Math.floor(Math.random() * Number.MAX_SAFE_INTEGER)
    }
    return JSON.stringify(msg);
}

var sendMessage = function(message, channel){
    aPIRequest('post', BASE_URL + "/channels/" + channel + "/messages", message);
}

var sendMessageToCurrentChannel = function(message){
    sendMessage(message, currentChannelId);
}

var setTypeing = function(){
    var time = Date.now();
    if(time - 5000 > lastTypeingTime){
        lastTypeingTime = time;
        aPIRequest('post', BASE_URL + "/channels/" + currentChannelId + "/typing", null);
    }
}

var newGuildQuerry = function(event, guild){
    aPIRequest('get', BASE_URL + "/guilds/" + guild.id + "/channels", function(json){
            var channels = JSON.parse(json);
            channelsMap[guild.id] = channels;
            for(var i = 0; i<channels.length; i++){
                serverMap[channels[i].id] = guild.id
            }

            fireEvent(SERVER_CHANNELS, guild.id);
        });
    aPIRequest('get', BASE_URL + "/guilds/" + guild.id + "/members?limit=1000", function(json){
        var users = JSON.parse(json);
        guilds[guild.id].users = users;
        fireEvent(SERVER_USERS_UPDATED, guild.id);
    }, {limit:1000});
}

var setCurrentChannel = function(id){
    currentChannelId = id;
    fireEvent(CHANGE_CHANNEL, {channel: currentChannelId});
}

var loadMoreMessageForCurrentChannel = function(){
    var channelIdToUse = currentChannelId;
    var firstId = (messageMap[currentChannelId]) ? messageMap[currentChannelId][0].id : false;
    var callBack = function(json){
        var messages = JSON.parse(json);
        if(messages.length === 0){
            fireEvent(MORE_MESSAGE, channelIdToUse);
            return;
        }
        messages.reverse();
        var previousMessage = messageMap[channelIdToUse];
        if(previousMessage)
            messageMap[channelIdToUse] = messages.concat(previousMessage);
        else
            messageMap[channelIdToUse] = messages;
        fireEvent(MORE_MESSAGE, channelIdToUse);
    }
    if(firstId){
        aPIRequest('get', BASE_URL + "/channels/" + currentChannelId + "/messages?before=" + firstId, callBack);
    } else {
        aPIRequest('get', BASE_URL + "/channels/" + currentChannelId + "/messages", callBack);
    }
}

var typingUpdate = function(){
    var deletes = [];
    for(var i in typeingMap){
        typeingMap[i] -= TYPING_TIMER_INTERVAL;
        if(typeingMap[i] < 0){
            deletes.push(i);
        }
    }
    for(i = 0; i<deletes.length; i++){
        fireEvent(TYPING_STOP, deletes[i]);
        delete typeingMap[deletes[i]];
    }
}

var addEventListener = function(event, func){
    if(listeners[event]){
        listeners[event].push(func);
    } else {
        listeners[event] = [func];
    }
}

var fireEvent = function(event, args){
    if(!listeners[event])
        return;
    for(var i = 0; i<listeners[event].length; i++){
        listeners[event][i](event, args);
    }
}

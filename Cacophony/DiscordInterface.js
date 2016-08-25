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
//Fired when DMs are added to or removed
var DMS_CHANGED = "DMS_CHANGED";
//Fired when any update to a voice channel happend
var VOICE_CONNECTION_UPDATE = "VOICE_CONNECTION_UPDATE";
//Fired when the ping is updated
var PING_UPDATED = "PING_UPDATED";

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
var dMs = {};
var currentVoiceConnection;
var voiceUDPConnection;

var init = function(parrent, voiceUDP){
    getGateway(initContinue1);
    websocketParrent = parrent;
    addEventListener(NEW_GUILD, newGuildQuerry);
    var typingTimer = Qt.createQmlObject("import QtQuick 2.0; Timer {}", websocketParrent);
    typingTimer.triggered.connect(typingUpdate);
    typingTimer.interval = TYPING_TIMER_INTERVAL;
    typingTimer.repeat = true;
    typingTimer.start();
    voiceUDPConnection = voiceUDP;
    voiceConnection.dNSFinished.connect(function(){
        voiceConnection.connectAndDiscover();
    });
    voiceConnection.discoveryFinished.connect(function(){
        if(currentVoiceConnection){
            currentVoiceConnection.discoveryFinished();
        }
    })
}

var initContinue1 = function(url){
    websocket = createWebsocket(JSON.parse(url).url);
}

var getGateway = function(callback){
    aPIRequest("GET", BASE_URL + "/gateway", callback);
}

var createWebsocket = function(url, stsChanged, msgRecived){
    var ws = Qt.createComponent("Websocket.qml");
    if(ws.status === QTQML.Component.Ready)
        if(stsChanged){
            ws = ws.createObject(websocketParrent, {url:url, active:true, stsChanged:{func: stsChanged}, txtRecived:{func: msgRecived}});
        }else{
            ws = ws.createObject(websocketParrent, {url:url + "/?encoding=json&v=6", active:true, stsChanged:{func: statusChanged}, txtRecived:{func: messageRecived}});
        }
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
    } else if(msg.op === 11){
        console.log(message);
    }else {
        console.log("Message with uncaught code " + msg.op + " recived!");
    }
}

var completeVoiceInitilization = function(){
    var endpoint = currentVoiceConnection.endpoint.trim();
    if(endpoint.indexOf(":80", endpoint.length - 3)){
        currentVoiceConnection.endpoint = endpoint.substring(0, endpoint.length-3);
    }

    console.log("Connecting Voice Websocket to: wss://" + currentVoiceConnection.endpoint);
    currentVoiceConnection.jSONWS = createWebsocket("wss://" + currentVoiceConnection.endpoint, currentVoiceConnection.jSONSocketStsChange, currentVoiceConnection.jSONRecived);
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
        getDMs();
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
    } else if(object.t === "CHANNEL_CREATE"){
        if(object.d.guild_id){
            var channel = object.d;
            if(channelsMap[channel.guild_id])
                channelsMap[channel.guild_id].push(channel);
            else
                channelsMap[channel.guild_id] = [channel];
            serverMap[channel.id] = channel.guild_id;
            fireEvent(SERVER_CHANNELS, channel.guild_id);
        }
    } else if(object.t === "VOICE_STATE_UPDATE"){
        if(object.d.user_id !== user.id){
            return;
        }
        currentVoiceConnection.sessionId = object.d.session_id;
        currentVoiceConnection.initilizationsLeft --;
        if(currentVoiceConnection.initilizationsLeft < 1){
            completeVoiceInitilization();
        }
    } else if(object.t === "VOICE_SERVER_UPDATE"){
        if(object.d.guild_id !== currentVoiceConnection.guildId){
            return;
        }
        currentVoiceConnection.token = object.d.token;
        currentVoiceConnection.endpoint = object.d.endpoint;
        currentVoiceConnection.initilizationsLeft --;
        if(currentVoiceConnection.initilizationsLeft < 1){
            completeVoiceInitilization();
        }
    }else {
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
        xmlhttp.send(JSON.stringify(callback));
    else if(callback && fourth){
        xmlhttp.send(JSON.stringify(fourth));
    } else
        xmlhttp.send();
}

var makeMessage = function(message){
    var msg = {
        content: String(message),
        tts: false,
        nonce: Math.floor(Math.random() * Number.MAX_SAFE_INTEGER)
    }
    return msg;
}

var sendMessage = function(message, channel){
    aPIRequest('post', BASE_URL + "/channels/" + channel + "/messages", makeMessage(message));
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

var getDMs = function(){
    aPIRequest('get', BASE_URL + "/users/@me/channels", function(json){
        var dmsArray = JSON.parse(json);
        for(var i = 0; i<dmsArray.length; i++){
            dMs[dmsArray[i].recipient.id] = dmsArray[i];
        }
        fireEvent(DMS_CHANGED, dMs);
    });
}

var joinDM = function(userId, callback){
    if(!dMs[userId]){
        aPIRequest('post', BASE_URL + "/users/@me/channels", function(json){
            var channel = JSON.parse(json);
            dMs[channel.recipient.id] = channel;
            callback(channel);
            currentChannelId = channel.id;
            loadMoreMessageForCurrentChannel();
        }, {recipient_id: userId});
    } else {
        var channel = dMs[userId]
        callback(channel);
        currentChannelId = channel.id;
        loadMoreMessageForCurrentChannel();
    }
}

var newChannel = function(server, name, type, bitrate){
    console.log(BASE_URL + "/guilds/" + server + "/channels");
    aPIRequest('post', BASE_URL + "/guilds/" + server + "/channels",
               {name: name, type:type, bitrate: (bitrate) ? bitrate : 64000});
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

var joinVoiceChannel = function(channelId){
    var msg = {
        op: 4,
        d: {guild_id:serverMap[channelId],
            channel_id:channelId,
            self_mute: false,
            self_deaf: false}
    };
    websocket.sendTextMessage(JSON.stringify(msg));
    currentVoiceConnection = new VoiceConnection(channelId, serverMap[channelId]);
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

var VoiceConnection = function(channelId, guildId){
    var self = this;
    this.channelId = channelId;
    this.guildId = guildId;
    this.mute = false;
    this.deaf = false;
    this.initilizationsLeft = 2;
    this.ping = 0;
    this.jSONSocketStsChange = function(){
        if(!self.jSONWS){
            return;
        }
        console.log("Audio websocket status changed to: " + self.jSONWS.status);
        if(self.jSONWS.status === 1){
            var message = {
                op: 0,
                d: {
                    server_id: self.guildId,
                    user_id: user.id,
                    session_id: self.sessionId,
                    token: self.token
                }
            }
            self.jSONWS.sendTextMessage(JSON.stringify(message));
            message = {
                op: 5,
                d: {
                    speaking: true,
                    delay: 5
                }
            }
            self.jSONWS.sendTextMessage(JSON.stringify(message));
        } else if(self.jSONWS.status === 4) {
            console.log("Websocket error is: " + self.jSONWS.errorString);
        }
    }
    this.jSONRecived = function(json){
        var msg = JSON.parse(json);
        if(msg.op === 2){
            var info = msg.d;
            self.ssrc = info.ssrc;
            self.port = info.port;
            var found = false;
            for(var i = 0; i<info.modes.length; i++){
                found |= info.modes[i] === "xsalsa20_poly1305";
            }
            self.mode = found ? "xsalsa20_poly1305" : info.modes[i];
            if(!found){
                console.log("Could not find xsalsa20_poly1305 mode, using: " + self.mode);
            }
            self.heartbeatInterval = info.heartbeat_interval;
            self.heartbeatTimer = Qt.createQmlObject("import QtQuick 2.0; Timer {}", websocketParrent);
            self.heartbeatTimer.triggered.connect(self.heartbeat);
            self.heartbeatTimer.interval = self.heartbeatInterval;
            self.heartbeatTimer.repeat = true;
            self.heartbeatTimer.start();
            voiceConnection.ssrc = self.ssrc;
            voiceConnection.port = self.port;
            voiceConnection.url = self.endpoint;
        } else if(msg.op === 4){
            self.mode = msg.d.mode;
            var string = "";
//            for(var k in msg.d.secret_key){
//                var local = msg.d.secret_key[k].toString(16);
//                if(local.length === 0){
//                    local = "00";
//                } else if(local.length === 1){
//                    local = "0" + local;
//                }
//                string += local;
//            }
//            console.log(string);
            voiceConnection.key = JSON.stringify(msg.d.secret_key);
            voiceConnection.startVoiceTransmission();
        } else if(msg.op === 3){
            self.ping = Date.now()-Number(msg.d);
            console.log("Ping " + self.ping);
            fireEvent(PING_UPDATED, self);
        } else {
            console.log("Uncaught message: " + json);
        }
    }
    this.discoveryFinished = function(){
        var address = voiceConnection.getLocalAddress() + "";
        var port = voiceConnection.getLocalPort() + 0;
        self.localAddress = address;
        self.localPort = port;
        var message = {
            op: 1,
            d: {
                protocol: "udp",
                data: {
                    address: address,
                    port: port,
                    mode: self.mode
                }
            }
        }
        self.jSONWS.sendTextMessage(JSON.stringify(message));
    }

    this.heartbeat = function(){
        var heartBeat = {
            "op": 3,
            "d": Date.now()
        }
        self.jSONWS.sendTextMessage(JSON.stringify(heartBeat));
    }

    this.sendUpdate = function(){
        var message = {
            op: 5,
            d: {
                speaking: !self.mute,
                delay:5
            }
        }
        self.jSONWS.sendTextMessage(JSON.stringify(message));
        console.log(JSON.stringify(message));
    }

    return this;
}

var mute = function(){
    if(currentVoiceConnection){
        currentVoiceConnection.mute ^= true;
        voiceConnection.mute(currentVoiceConnection.mute);
        currentVoiceConnection.sendUpdate();
        fireEvent(VOICE_CONNECTION_UPDATE, currentVoiceConnection);
    }
}

var deafen = function(){
    if(currentVoiceConnection){
        currentVoiceConnection.deaf ^= true;
        voiceConnection.deafen(currentVoiceConnection.deaf);
        fireEvent(VOICE_CONNECTION_UPDATE, currentVoiceConnection);
    }
}



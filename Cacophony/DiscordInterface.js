var BASE_URL = "https://discordapp.com/api";
var GATEWAY_VERSION = 5.0;

//Event Strings
//Fired when a channel is changed. Event contains the channel object.
var CHANGE_CHANNEL = "CHANGE_GUILD";
//Fired when a message is created. Event contains message object.
var MESSAGE_CREATED = "MESSAGE_CREATED";

var token = "";
var websocket;
var websocketParrent;
var heartbeatTimer;
var seqs = "";
var user;
var channels = [];
var currentChannel;
var listeners = [];
var lastTypeingTime = 0;


var setWebsocket = function(websocket){
    websocket.active = true;
    websocket.sendTextMessage("Echo, #" + number);
    number ++;
}

var init = function(parrent){
    getGateway(initContinue1);
    websocketParrent = parrent;
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
    if(ws.status === Component.Ready)
        ws = ws.createObject(websocketParrent, {url:url, active:true, stsChanged:{func: statusChanged}, txtRecived:{func: messageRecived}});
    else
        console.log(ws.errorString());
    return ws;
}

var messageRecived = function(message){
    var msg = JSON.parse(message);
    if(msg.op === 0){
        handleEvent(msg);
        seqs += msg.s;
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
    console.log(JSON.stringify(identity));
    websocket.sendTextMessage(JSON.stringify(identity));
}

var heartbeat = function(){
    console.log("Heartbeat");
    var heartBeat = {
        "op": 1,
        "d": seqs
    }
    seqs = "";
    websocket.sendTextMessage(JSON.stringify(heartBeat));
}

var handleEvent = function(object){
    if(object.t === "READY"){
        if(heartbeatTimer){
            heartbeatTimer.stop();
        }
        else {
            heartbeatTimer = Qt.createQmlObject("import QtQuick 2.0; Timer {}", websocketParrent);
            heartbeatTimer.triggered.connect(heartbeat);
        }
        heartbeatTimer.interval = object["d"].heartbeat_interval;
        heartbeatTimer.repeat = true;
        heartbeatTimer.start();
        user = object.d.user;
        console.log(JSON.stringify(user));
    } else if(object.t === "GUILD_CREATE"){
        var notAdd = false;
        for(var i = 0; i<channels.length; i++){
            notAdd |= channels[i].id === object.d.id;
        }
        if(!notAdd){
            channels.push(object.d);
        }
        currentChannel = object.d;
        fireEvent(CHANGE_CHANNEL, {channel: currentChannel.id});
    } else if(object.t === "MESSAGE_CREATE"){
        fireEvent(MESSAGE_CREATED, object.d);
    } else {
        console.log("Uncaught event " + object.t);
    }
}

var aPIRequest = function(type, url, callback){
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
    else
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
    sendMessage(message, currentChannel.id);
}

var setTypeing = function(){
    var time = Date.now();
    if(time - 5000 > lastTypeingTime){
        lastTypeingTime = time;
        aPIRequest('post', BASE_URL + "/channels/" + currentChannel.id + "/typing", null);
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

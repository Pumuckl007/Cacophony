var BASE_URL = "https://discordapp.com/api";
var GATEWAY_VERSION = 5.0;
var token = "";
var websocket;
var websocketParrent;
var deviceInfo;


var setWebsocket = function(websocket){
    websocket.active = true;
    websocket.sendTextMessage("Echo, #" + number);
    number ++;
}

var init = function(parrent, devInfo){
    deviceInfo = devInfo;
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
    var xmlhttp = new XMLHttpRequest();
    var url = BASE_URL + "/gateway";

    xmlhttp.onreadystatechange=function() {
        if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
            callback(xmlhttp.responseText);
        }
    }
    xmlhttp.open("GET", url, true);
    xmlhttp.send();
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
    console.log(message);
}

var statusChanged = function(){
    if(!websocket)
        return
    if(websocket.status === 1){
        startHandshake();
    }
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
                    "$os": deviceInfo.productName(),
                    "$browser":"Cacophony",
                    "$device":deviceInfo.manufacturer() + " " + deviceInfo.model(),
                    "$referrer":"",
                    "$referring_domain":""
                },
            }
        };
    console.log(JSON.stringify(identity));
    console.log();
}

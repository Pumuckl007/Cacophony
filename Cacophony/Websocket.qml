import QtQuick 2.4
import Qt.WebSockets 1.0

WebSocket {
    id: gatewayWebsocket
    url: "wss://gateway.discord.gg/"
    property variant stsChanged: null
    property variant txtRecived: null
    onTextMessageReceived: {
        gatewayWebsocket.txtRecived.func(message, gatewayWebsocket);
    }
    onStatusChanged: {
        gatewayWebsocket.stsChanged.func(gatewayWebsocket);
    }
    active: false
}


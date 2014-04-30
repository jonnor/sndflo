
// Adapter code between NoFlo WS/.JSON/.FBP protocol,
// and the OSC protocol spoken by the SuperCollider runtime


// FIXME: Consider using http://automata.cc/osc-web ?

// FIXME: use CoffeScript instead of JavaScript
// TODO: create an abstraction around node.js dependencies, so that this code can also run Chrome app
// TODO: Create end-to-end tests using

// TODO: figure out how we can stream audio to webapp from SuperCollider. WebRTC? RTP? WS+WebAudio

var osc = require("osc-min");
var udp = require("dgram");
var http = require('http');
var websocket = require('websocket');

var outport = 57120;
var inport = outport+1;
var wsPort = 3569;



var wsConnection = undefined;
var sendsock = udp.createSocket("udp4");

var handleWsMessage = function(message) {
    if (message.type == "utf8") {
        //console.log("WS:", message);
        var msg = JSON.parse(message.utf8Data);
        var path = "/" + msg.protocol + "/" + msg.command;
        var p = msg.payload;

        // TODO: support all graph and network commands
        // console.log(path, p);

        var args = undefined;
        if (path == "/component/list") {
            args = [ JSON.stringify(msg.payload) ];

        } else if (path == "/graph/clear") {

        } else if (path == "/graph/addnode") {

        } else if (path == "/graph/removenode") {

        } else if (path == "/graph/addedge") {

        } else if (path == "/graph/removeedge") {

        } else if (path == "/graph/addinitial") {

        } else if (path == "/graph/removeinitial") {

        } else {
            console.log("Unknown Websocket command", path);
        }

        var buf = osc.toBuffer({ address: path, args: args });
        var success = sendsock.send(buf, 0, buf.length, outport, "localhost");
    } else {
        console.log("Invalid WS message type", message.type);
    }
}

var handleWsRequest = function(request) {
    var connection = request.accept('noflo', request.origin);
    connection.on('message', handleWsMessage);

    if (wsConnection) {
        wsConnection.removeAllListeners('message');
    }
    wsConnection = connection;
};

var udpCallback = function(msg, rinfo) {
    var error;
    try {
        var data = osc.fromBuffer(msg);
        console.log("UDP receive: ", data);
        if (wsConnection) {
            //var prot =
            //wsConnection(
        }

    } catch (err) {
        error = err;
        return console.log("invalid OSC packet", err);
    }
};


var recvsock = udp.createSocket("udp4", udpCallback)
var httpServer = http.createServer();
var wsServer = new websocket.server({ httpServer: httpServer });

wsServer.on('request', handleWsRequest);

recvsock.bind(inport);

httpServer.listen(wsPort, function(err) {
    if (err) {
        throw err;
    }

    console.log("Listening at WebSocket port", wsPort,
                "\nOSC server port", inport,
                "\nConnecting to SuperCollider at", outport);
});




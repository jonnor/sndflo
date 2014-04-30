# Adapter code between NoFlo WS/.JSON/.FBP protocol,
# and the OSC protocol spoken by the SuperCollider runtime

# FIXME: Consider using http://automata.cc/osc-web ?
# TODO: create an abstraction around node.js dependencies, so that this code can also run Chrome app
# TODO: Create end-to-end tests using mocha
# TODO: figure out how we can stream audio to webapp from SuperCollider. WebRTC? RTP? WS+WebAudio

osc = require 'osc-min'
udp = require 'dgram'
http = require 'http'
websocket = require 'websocket'
EventEmitter = (require 'events').EventEmitter

class WebSocketOscFbpAdapter extends EventEmitter

    constructor: () ->
        @httpServer = http.createServer()
        @wsServer = new websocket.server { httpServer: @httpServer }

        @wsServer.on 'request', (request) ->
            connection = request.accept 'noflo', request.origin
            connection.on 'message', (msg) ->
                handleWsMessage connection, msg

        @oscSockets =
            send: udp.createSocket "udp4"
            receive: udp.createSocket "udp4", @handleUdpMessage

        # TODO: move out?
        @receivePort = 57121
        @sendPort = @receivePort+1

    start: (wsPort, callback) ->
        @oscSockets.receive.bind @receivePort
        @httpServer.listen wsPort, callback

    stop: () ->
        # FIXME: reverse effects of start()

    handleUdpMessage : (msg, rinfo) ->
        try
            data = osc.fromBuffer msg
            console.log "UDP receive: ", data
        catch err
            console.log "invalid OSC packet", err

    handleWsMessage = (connection, message) ->
        if message.type == "utf8"
            #console.log "WS:", message
            msg = JSON.parse message.utf8Data
            path = "/fbp" + msg.protocol + "/" + msg.command
            p = msg.payload

            console.log path, p

            args = [ JSON.stringify msg.payload ]
            buf = osc.toBuffer { address: path, args: args }
            success = sendsock.send buf, 0, buf.length, outport, "localhost"
        else
            console.log "Invalid WS message type", message.type

main = () ->

    wsPort = 3569

    server = new WebSocketOscFbpAdapter()
    server.start wsPort, (err) ->
        if (err)
            throw err
        console.log "Listening at WebSocket port", wsPort,
                    "\nOSC server port", server.receivePort,
                    "\nConnecting to SuperCollider at", server.sendPort

module.exports =
    main: main
    Adapter: WebSocketOscFbpAdapter

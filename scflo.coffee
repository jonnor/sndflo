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

        @wsServer.on 'request', (request) =>
            connection = request.accept 'noflo', request.origin
            connection.on 'message', (msg) =>
                @handleWsMessage connection, msg

        @oscSockets =
            send: udp.createSocket "udp4"
            receive: udp.createSocket "udp4", @handleUdpMessage

        @wsConnection = null  # FIXME: handle multiple

    start: (wsPort, oscPort, callback) ->
        @sendPort = oscPort
        @receivePort = @sendPort+2

        @oscSockets.receive.bind @receivePort
        @httpServer.listen wsPort, callback

    stop: () ->
        # FIXME: reverse effects of start()

    handleUdpMessage: (msg, rinfo) =>

        try
            data = osc.fromBuffer msg
            @handleOscMessage data
        catch err
            console.log "invalid OSC packet", err

    handleOscMessage: (data) ->
        respond = (m) =>
            if not @wsConnection?
                throw new Error 'No WebSocket connection!'
            @wsConnection.send JSON.stringify m

        if data.address == '/fbp/ui/message'
            if data.args.length == 1 and data.args[0].type == 'string'
                # Note: We could just have sent the JSON encoded string on, but
                # right now decode and re-encode it to be able to detect errors earlier
                msg = null
                try
                    msg = JSON.parse data.args[0].value
                catch err
                    console.log 'Invalid JSON received on OSC:', data.args[0].value

                respond msg
            else
                console.log 'Unexpected OSC arguments: ', data.args

        else
            console.log 'Unexpected OSC address: ', data.address

    handleWsMessage: (connection, message) ->
        @wsConnection = connection

        if message.type == "utf8"
            msg = JSON.parse message.utf8Data
            path = "/fbp/runtime/message"
            args = [ JSON.stringify msg ]
            buf = osc.toBuffer { address: path, args: args }
            success = @oscSockets.send.send buf, 0, buf.length, @sendPort, "localhost"
        else
            console.log "Invalid WS message type", message.type

main = () ->

    wsPort = 3569
    oscPort = 57120

    server = new WebSocketOscFbpAdapter()
    server.start wsPort, oscPort, (err) ->
        if (err)
            throw err
        console.log "Listening at WebSocket port", wsPort,
                    "\nOSC server port", server.receivePort,
                    "\nConnecting to SuperCollider at", server.sendPort

module.exports =
    main: main
    Adapter: WebSocketOscFbpAdapter

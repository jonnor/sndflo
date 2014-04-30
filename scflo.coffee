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

        # TODO: move out?
        @sendPort = 57120
        @receivePort = @sendPort+1

    start: (wsPort, callback) ->
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
        respond = (protocol, command, payload) =>
            if not @wsConnection?
                throw new Error 'No WebSocket connection!'
            m = 
                protocol: protocol
                command: command
                payload: payload
            @wsConnection.send JSON.stringify m

        address = data.address.split '/'
        if address.length == 4 and address[0] == '' and address[1] == 'fbp'
            payload = null
            if data.args.length == 1 and data.args[0].type == 'string'
                try
                    payload = JSON.parse data.args[0].value
                catch err
                    console.log 'Invalid JSON received on OSC:', data.args[0].value
            else
                console.log 'Unexpected OSC arguments: ', data.args

            respond address[2], address[3], payload
        else
            console.log 'Unexpected OSC address: ', data.address, address

    handleWsMessage: (connection, message) ->
        @wsConnection = connection

        if message.type == "utf8"
            #console.log "WS:", message
            msg = JSON.parse message.utf8Data
            path = "/fbp/" + msg.protocol + "/" + msg.command
            p = msg.payload



            # console.log path, p
  
            args = [ JSON.stringify msg.payload ]
            buf = osc.toBuffer { address: path, args: args }

            success = @oscSockets.send.send buf, 0, buf.length, @sendPort, "localhost"
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

#     sndflo - Flowhub.io sound processing runtime based on SuperCollider
#     (c) 2014 Jon Nordby
#     sndflo may be freely distributed under the MIT license

# Adapter code between NoFlo WS/.JSON/.FBP protocol,
# and the OSC protocol spoken by the SuperCollider runtime

osc = require 'osc-min'
udp = require 'dgram'
http = require 'http'
websocket = require 'websocket'
EventEmitter = (require 'events').EventEmitter
fs = require 'fs'
child_process = require 'child_process'
flowhub = require 'flowhub-registry'

class WebSocketOscFbpAdapter extends EventEmitter

    constructor: () ->
        @httpServer = http.createServer()
        @wsServer = new websocket.server { httpServer: @httpServer }

        @wsServer.on 'request', (request) =>
            subProtocol = if (request.requestedProtocols.indexOf("noflo") isnt -1) then "noflo" else null
            connection = request.accept subProtocol, request.origin
            connection.on 'message', (msg) =>
                @handleWsMessage connection, msg

        @oscSockets =
            send: udp.createSocket "udp4"
            receive: udp.createSocket "udp4", @handleUdpMessage

        @wsConnection = null  # FIXME: handle multiple

    start: (wsPort, oscPort, callback) ->
        @sendPort = oscPort
        @receivePort = @sendPort+2
        @wsPort = wsPort

        @oscSockets.receive.bind @receivePort
        @httpServer.listen @wsPort, callback

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

class SuperColliderProcess
    constructor: (debug, verbose, graph) ->
        @process = null
        @started = false
        @debug = debug
        @errors = []
        @verbose = verbose
        @graph = graph

    start: (desiredPort, callback) ->
        if @debug
            console.log 'Debug mode: setup runtime yourself!'
            return success 0

        exec = 'sclang'
        args = ['-u', desiredPort.toString(), 'sndflo-runtime.scd']
        args.push @graph if @graph

        console.log exec, args.join ' ' if @verbose
        @process = child_process.spawn exec, args
        @process.on 'error', (err) ->
            throw err
        @process.on 'exit', (code, signal) ->
            if code != 0
                callback new Error 'Runtime exited with non-zero code: ' + code + ' :' +signal

        stderr = ""
        @process.stderr.on 'data', (d) =>
            console.log d.toString() if @verbose
            output = d.toString()
            stderr += output
            lines = output.split '\n'
            for line in lines
                err = line.trim()
                @errors.push err if err

        stdout = ""
        @process.stdout.on 'data', (d) =>
            console.log d.toString() if @verbose
            stdout += d.toString()
            failString = 'ERROR: server failed to start'
            readyExp = /sndflo-runtime running on port (\d+)/i
            readyMatch = stdout.match readyExp
            if readyMatch
                if not @started
                    errors = @popErrors()
                    port = readyMatch[1]
                    @started = true
                    callback null, port, process.pid
            if stdout.indexOf(failString) != -1 or stderr.indexOf(failString) != -1
                callback new Error 'Failed to start up', null, null

    stop: ->
        if @debug
            return
        @process.kill()

    popErrors: ->
        errors = @errors
        @errors = []
        return errors

# Handles both the SuperCollider setup and the OSC<->WebSocket bridging
class Runtime extends EventEmitter
    constructor: (options) ->
        defaults =
            port: 3569
            oscPort: 57120
            verbose: false
            debug: false
            graph: null
            label: "unlabeled sndflo runtime"
            user: null
            id: null
            host: 'localhost'
            ping: 5*60 # seconds
            secret: 'not-secret' # FIXME: random
        @options = {}
        for k,v of defaults
            @options[k] = v
        for k,v of options
            @options[k] = v

        @adapter = new WebSocketOscFbpAdapter()
        @supercollider = new SuperColliderProcess @options.debug, @options.verbose, @options.graph

        @rt = null
        if @options.user
            @rt = new flowhub.Runtime
                label: @options.label
                id: @options.id
                user: @options.user
                secret: @options.secret
                protocol: 'websocket'
                type: 'sndflo'
                address: 'ws://' + @options.host + ':' + @options.port
        @registryPinger = null

    register: (callback) ->
        @rt.register (err, ok) =>
            return callback err if err
            @rt.ping()
            if @options.ping > 0
                @registryPinger = setInterval () =>
                    @rt.ping()
                , @options.ping*1000
            return callback null

    start: (callback) ->
        @supercollider.start @options.oscPort, (err, port, pid) =>
            return callback err, null if err
            internal = parseInt(port)
            console.log 'internal port', internal if @options.verbose
            @adapter.start @options.port, internal, (err) =>
                return callback err, null if err
                if @rt
                    @register (err) ->
                        return console.log 'Failed to register Flowhub runtime: ' + err if err
                        console.log 'Registered with Flowhub, should be accessible in UI'
                return callback null, internal

    stop: (callback) ->
        if @registryPinger
            clearInterval @registryPinger
            @registryPinger = null
        @supercollider.stop()
        @adapter.stop()

main = () ->
    program = require 'commander'
    program
        .option '-p, --port <PORT>', 'WebSocket port'
        .option '-i, --host <HOSTNAME>', 'WebSocket hostname'
        .option '-u, --user <UUID>', 'Flowhub user id to register for'
        .option '-r, --id <UUID>', 'Flowhub runtime id to use'
        .option '-v, --verbose', 'Verbose logging'
        .parse(process.argv)

    runtime = new Runtime program
    runtime.start (err) ->
        if (err)
            throw err
        console.log "Listening at WebSocket port", runtime.adapter.wsPort,
                    "\nOSC send/receive ports: ", runtime.adapter.sendPort, runtime.adapter.receivePort

module.exports =
    main: main
    Adapter: WebSocketOscFbpAdapter
    SuperColliderProcess: SuperColliderProcess
    Runtime: Runtime


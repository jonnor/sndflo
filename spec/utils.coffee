#     sndflo - Flowhub.io sound processing runtime based on SuperCollider
#     (c) 2014 Jon Nordby
#     sndflo may be freely distributed under the MIT license

fs = require 'fs'
child_process = require 'child_process'
EventEmitter = (require 'events').EventEmitter
websocket = require 'websocket'

# XXX: duplicated from imgflo
class MockUi extends EventEmitter

    constructor: ->
        @client = new websocket.client()
        @connection = null

        @components = {}
        @runtimeinfo = {}
        @networkrunning = false
        @networkoutput = {}

        @client.on 'connect', (connection) =>
            @connection = connection
            @connection.on 'error', (error) =>
                throw error
            @connection.on 'message', (message) =>
                @handleMessage message
            @emit 'connected', connection

    handleMessage: (message) ->
        if not message.type == 'utf8'
            throw new Error "Received non-UTF8 message: " + message

        d = JSON.parse message.utf8Data
        if d.protocol == "component" and d.command == "component"
            id = d.payload.name
            @components[id] = d.payload
            @emit 'component-added', id, @components[id]
        else if d.protocol == "runtime" and d.command == "runtime"
            @runtimeinfo = d.payload
            @emit 'runtime-info-changed', @runtimeinfo
        else if d.protocol == "network" and d.command == "started"
            @networkrunning = true
            @emit 'network-running', @networkrunning
        else if d.protocol == "network" and d.command == "stopped"
            @networkrunning = false
            @emit 'network-running', @networkrunning
        else if d.protocol == "network" and d.command == "output"
            @networkoutput = d.payload
            @emit 'network-output', @networkoutput
        else if d.protocol == "runtime" and d.command == "ports"
            @emit 'runtime-ports-changed', d.payload
        else
            console.log 'UI received unknown message', d

    connect: (port) ->
        @client.connect "ws://localhost:#{port}/", "noflo"
    disconnect: ->
        #

    send: (protocol, command, payload) ->
        msg = 
            protocol: protocol
            command: command
            payload: payload || {}
        @sendMsg msg

    sendMsg: (msg) ->
        @connection.sendUTF JSON.stringify msg


class SuperColliderProcess
    constructor: (debug, verbose, graph) ->
        @process = null
        @started = false
        @debug = debug
        @errors = []
        @verbose = verbose
        @graph = graph

    start: (port, success) ->
        if @debug
            console.log 'Debug mode: setup runtime yourself!'
            return success 0

        exec = 'sclang'
        args = ['-u', port.toString(), 'sndflo-runtime.scd']
        args.push @graph if @graph

        console.log exec, args.join ' ' if @verbose
        @process = child_process.spawn exec, args
        @process.on 'error', (err) ->
            throw err
        @process.on 'exit', (code, signal) ->
            if code != 0
                throw new Error 'Runtime exited with non-zero code: ' + code + ' :' +signal

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
            readyString = 'sndflo-runtime running on port'
            failString = 'ERROR: server failed to start'
            if stdout.indexOf(readyString) != -1
                if not @started
                    errors = @popErrors()

                    @started = true
                    success process.pid
            if stdout.indexOf(failString) != -1 or stderr.indexOf(failString) != -1
                throw new Error 'Failed to start up'

    stop: ->
        if @debug
            return
        @process.kill()

    popErrors: ->
        errors = @errors
        @errors = []
        return errors


exports.MockUi = MockUi
exports.SuperColliderProcess = SuperColliderProcess

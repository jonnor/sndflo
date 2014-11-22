#     sndflo - Flowhub.io sound processing runtime based on SuperCollider
#     (c) 2014 Jon Nordby
#     sndflo may be freely distributed under the MIT license

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
        else if d.protocol == "component" and d.command == "source"
            @emit 'component-source-changed', d.payload
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

exports.MockUi = MockUi

#     imgflo - Flowhub.io Image-processing runtime
#     (c) 2014 The Grid
#     imgflo may be freely distributed under the MIT license

fs = require 'fs'
child_process = require 'child_process'
EventEmitter = (require 'events').EventEmitter

websocket = require 'websocket'
chai = require 'chai'

scflo = require '../scflo.coffee'


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
    constructor: (debug) ->
        @process = null
        @started = false
        @debug = debug
        @errors = []

    start: (port, success) ->
        if @debug
            console.log 'Debug mode: setup runtime yourself!'
            return success 0

        exec = 'sclang'
        args = ['-u', port.toString(), 'sndflo-runtime.scd']
        @process = child_process.spawn exec, args
        @process.on 'error', (err) ->
            throw err
        @process.on 'exit', (code, signal) ->
            if code != 0
                throw new Error 'Runtime exited with non-zero code: ' + code

        @process.stderr.on 'data', (d) =>
            output = d.toString()
            lines = output.split '\n'
            for line in lines
                err = line.trim()
                @errors.push err if err

        stdout = ""
        @process.stdout.on 'data', (d) =>
            stdout += d.toString()
            if stdout.indexOf 'Receiving notification messages from server' != -1
                if not @started
                    errors = @popErrors()
                    if errors.length > 0
                        throw new Error 'Failed to start up: ' + errors.toString()

                    @started = true
                    success process.pid

    stop: ->
        if @debug
            return
        @process.kill()

    popErrors: ->
        errors = @errors
        @errors = []
        return errors
    

debug = false
oscPort = 57230
wsPort = 3888

if process.env.SCFLO_DEBUG_TEST?
    debug = true
    oscPort = 57120

describe 'NoFlo runtime API,', () ->
    runtime = new SuperColliderProcess debug
    adapter = new scflo.Adapter
    ui = new MockUi

    before (done) ->
        adapter.start wsPort, oscPort, (err) ->
            throw err if err
            runtime.start oscPort, ->
                ui.connect wsPort
                ui.on 'connected', () ->
                    done()
    after ->
        adapter.stop()
        runtime.stop()
        ui.disconnect()

    describe 'runtime info', ->
        info = null
        it 'should be returned on getruntime', (done) ->
            ui.send "runtime", "getruntime"
            ui.once 'runtime-info-changed', () ->
                info = ui.runtimeinfo
                chai.expect(info).to.be.an 'object'
                done()
        it 'type should be "sndflo"', ->
            chai.expect(info.type).to.equal "sndflo"
        it 'protocol version should be "0.4"', ->
            chai.expect(info.version).to.be.a "string"
            chai.expect(info.version).to.equal "0.4"
        it 'capabilities should be include "protocol:component"', ->
            chai.expect(info.capabilities).to.be.an "array"
            chai.expect(info.capabilities.length).to.equal 1
            chai.expect((info.capabilities.filter -> 'protocol:component')[0]).to.be.a "string"

    describe 'sending component list', ->
        it 'should return at least 3 components', (done) ->
            ui.send "component", "list"
            ui.on 'component-added', (name, definition) ->
                numberOfComponents = Object.keys(ui.components).length
                if numberOfComponents == 3
                    done()
        it 'should contain AudioOut', ->
            chai.expect(ui.components['synth/AudioOut']).to.be.an 'object'

        describe 'AudioOut component', ->
            component = 'synth/AudioOut'
            it 'should have a "in" bus port', ->
                input = ui.components[component].inPorts.filter (p) -> p.id == 'in'
                chai.expect(input.length).to.equal 1
                chai.expect(input[0].type).to.equal "bus"
            it 'should have icon "fa-music"', ->
                chai.expect(ui.components[component].icon).to.equal 'music'
            it 'should have description', ->
                chai.expect(ui.components[component].description).to.equal 'Play out on soundcard'

    describe 'building graph', ->
        # TODO: find a way to verify results. Output to file?
        it 'should not crash', (done) ->
            ui.send "graph", "clear"
            ui.send "graph", "addnode", {id: 'in', component: 'synth/SawWave'}
            ui.send "graph", "addnode", {id: 'filter', component: 'synth/LowPassFilter'}
            ui.send "graph", "addnode", {id: 'out', component: 'synth/AudioOut'}
            ui.send "graph", "addedge", {src: {node: 'in', port: 'out'}, tgt: {node: 'filter', port: 'in'}}
            ui.send "graph", "addedge", {src: {node: 'filter', port: 'out'}, tgt: {node: 'out', port: 'in'}}
            ui.send "graph", "addinitial", {src: {data: 220}, tgt: {node: 'in', port: 'freq'}}
            ui.send "graph", "addinitial", {src: {data: 330}, tgt: {node: 'filter', port: 'freq'}}

            ui.send "runtime", "getruntime"
            ui.once 'runtime-info-changed', ->
                done()

    describe 'starting the network', ->
        it 'should respond with network started', (done) ->
            ui.send "network", "start"
            ui.once 'network-running', (running) ->
                done() if running

    describe 'stopping the network', ->
        it 'should respond with network stopped', (done) ->
            ui.send "network", "stop"
            ui.once 'network-running', (running) ->
                done() if not running


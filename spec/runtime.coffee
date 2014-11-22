#     sndflo - Flowhub.io sound processing runtime based on SuperCollider
#     (c) 2014 Jon Nordby
#     sndflo may be freely distributed under the MIT license

chai = require 'chai'
scflo = require '../scflo.coffee'
utils = require './utils'

debug = false
oscPort = 57230
wsPort = 3888

if process.env.SCFLO_TESTS_DEBUG?
    debug = true
    oscPort = 57120

verbose = process.env.SCFLO_TESTS_VERBOSE?
graph = 'graphs/sawsynth.json'

rtoptions =
    wsPort: wsPort
    oscPort: oscPort
    debug: debug
    verbose: verbose
    graph: graph

describe 'FBP runtime API,', () ->
    ui = new utils.MockUi
    runtime = new scflo.Runtime rtoptions

    before (done) ->
        @timeout 6000
        runtime.start (err) ->
            throw err if err
            ui.connect wsPort
            ui.on 'connected', () ->
                done()
    after ->
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
        it 'capabilities should include "protocol:component"', ->
            chai.expect(info.capabilities).to.be.an "array"
            chai.expect(info.capabilities).to.include 'protocol:component'
        it 'capabilities should include "protocol:graph"', ->
            chai.expect(info.capabilities).to.include 'protocol:graph'
        it 'capabilities should include "protocol:network"', ->
            chai.expect(info.capabilities).to.include 'protocol:network'
        it 'capabilities should include "protocol:runtime"', ->
            chai.expect(info.capabilities).to.include 'protocol:runtime'
        it 'capabilities should include "component:getsource"', ->
            chai.expect(info.capabilities).to.include 'component:getsource'
        it 'capabilities should include "component:setsource"', ->
            chai.expect(info.capabilities).to.include 'component:setsource'

    describe 'initial ports information', ->
        info = null
        it 'should be returned on getruntime', (done) ->
            ui.send "runtime", "getruntime"
            ui.once 'runtime-ports-changed', (i) ->
                info = i
                chai.expect(info).to.be.an 'object'
                done()
        it 'should have intial graph', ->
            chai.expect(info.graph).to.equal 'default/main'
        it 'should have inports', ->
            chai.expect(info.inPorts).to.be.an 'array'
            chai.expect(info.inPorts).to.have.length 2
        it 'should have outports', ->
            chai.expect(info.outPorts).to.be.an 'array'
            chai.expect(info.outPorts).to.have.length 0

    describe.skip 'sending packet in', ->
        graphName = 'default/main'
        it 'gives packet out', (done) ->
            ui.on 'runtime-packet', (data) ->
                chai.expect(data.event).to.equal 'data'
                chai.expect(data.graph).to.equal graphName
                chai.expect(data.port).to.equal 'output'
                chai.expect(data.payload).to.contain 'http://localhost'
                chai.expect(data.payload).to.contain '/process'
                done()
            ui.send 'runtime', 'packet',
                event: 'data'
                graph: graphName
                port: 'x'
                payload: 32

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

    describe 'tearing down graph', ->
        # TODO: find a way to verify results.
        it 'should not crash', (done) ->

            ui.send "graph", "removeinitial", {tgt: {node: 'in', port: 'freq'}}
            ui.send "graph", "removeinitial", {tgt: {node: 'filter', port: 'freq'}}
            ui.send "graph", "removeedge", {src: {node: 'in', port: 'out'}, tgt: {node: 'filter', port: 'in'}}
            ui.send "graph", "removeedge", {src: {node: 'filter', port: 'out'}, tgt: {node: 'out', port: 'in'}}
            ui.send "graph", "removenode", {id: 'in'}
            ui.send "graph", "removenode", {id: 'filter'}
            ui.send "graph", "removenode", {id: 'out'}

            ui.send "runtime", "getruntime"
            ui.once 'runtime-info-changed', ->
                done()

    describe 'component:getsource', ->
        it 'should respond with compoent code', (done) ->
            ui.send "component", "getsource", { name: "synth/AudioOut" }
            ui.once 'component-source-changed', (info) ->
                chai.expect(info.name).to.equal "synth/AudioOut"
                chai.expect(info.language).to.equal 'supercollider'
                chai.expect(info.code).to.contain 'SynthDef("AudioOut"'
                done()

    describe 'component:source', ->
        code = """
        SynthDef("AudioOut2", {
            arg in=SndFloLibrary.silentIn, out=0;
            Out.ar(out, In.ar(in))
        },
            metadata: (
                description: "Uploaded over FBP"
            )
        )
        """
        it 'should respond with component change', (done) ->
            ui.send "component", "source", { name: "synth/AudioOut2", code }
            ui.once 'component-added', (name, definition) ->
                chai.expect(name).to.equal "synth/AudioOut2"
                chai.expect(definition.description).to.equal 'Uploaded over FBP'
                chai.expect(definition.icon).to.equal 'music'
                chai.expect(definition.inPorts).to.have.length 1
                chai.expect(definition.outPorts).to.have.length 1
                done()

    describe 'starting the network', ->
        it 'should respond with network started', (done) ->
            setTimeout ->
                ui.send "network", "start"
                ui.once 'network-running', (running) ->
                    done() if running
            , 100

    describe 'stopping the network', ->
        it 'should respond with network stopped', (done) ->
            setTimeout ->
                ui.send "network", "stop"
                ui.once 'network-running', (running) ->
                    done() if not running
            , 300

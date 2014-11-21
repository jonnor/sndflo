#     imgflo - Flowhub.io Image-processing runtime
#     (c) 2014 The Grid
#     imgflo may be freely distributed under the MIT license

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

describe 'FBP runtime API,', () ->
    runtime = new utils.SuperColliderProcess debug, verbose
    ui = new utils.MockUi
    adapter = new scflo.Adapter

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

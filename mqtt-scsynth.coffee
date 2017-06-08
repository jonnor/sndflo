
sc = require 'supercolliderjs'
sc.ServerPlus = require('./node_modules/supercolliderjs/lib/server/ServerPlus').default
bluebird = require 'bluebird'

main = () ->
  options =
    host: 'localhost'
    port: 57110
    scsynth: '/usr/bin/scsynth'
    sclang: '/usr/bin/sclang'
    langPort: 57210
    env:
      'SC_JACK_DEFAULT_OUTPUTS': 'system'
      'SC_JACK_DEFAULT_INPUTS': 'system'

  # NOTE: Convenience API does not seem to pass options.sclang through properly
  # so we instantiate the instances directly instead

  lang = new sc.lang.SCLang(options);
  compiler = new sc.lang.SynthDefCompiler(lang);

  # NOTE: name inside SynthDef must match
  defs =
    'sine':
      source: """
      SynthDef("sine", {
	      arg amp = 0.2, pitch=80, out=0;
	      var sin;
	      sin = SinOsc.ar(pitch.midicps, 0);
	      Out.ar(out, sin*amp);
      });
      """

  server = new sc.ServerPlus options

  server.stdout.subscribe (o) ->
    console.log 'stdout', o

  server.receive.subscribe (m) ->
    console.log 'OSC received', m 

  group = server.group()
  server.boot().then () ->
    return server.connect()
  .then () ->
    return lang.boot()
  .then () ->
    console.log('connected');
    return compiler.compileAndSend(defs, server)
  .then () ->
    console.log('compiled')
    #def = compiler.get('sine')
    #console.log 'c', def.name
    #return server.synth(def, {}, group) # XXX: seems to

    nodeId = server.state.nextNodeID()
    addAction = sc.msg.AddActions.TAIL
    opts = {}
    m = sc.msg.synthNew('sine', nodeId, addAction, group.id, opts)
    server.send.msg m
  .then (s) ->
    console.log 'created synth', s 
  .catch (err) ->
    console.error err
    process.exit 1

main()

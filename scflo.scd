s.boot

(
var syn, sound;

syn = SynthDef.new("example1", {
  Out.ar(0, SinOsc.ar(440));
});

syn.load(s);

sound = Synth.new("example1");
sound.set(\freq, 220);
)


(
SynthDef("help-notRand", {
    Out.ar(0, SinOsc.ar(rrand(400, 800), 0, 0.2) * Line.kr(1, 0, 1, doneAction: 2));
}).send(s);

)

b = Synth.new("help-notRand")


// TODO: figure out how to wrap into components
(
var uGens = Dictionary[
    "SinOsc" -> SinOsc,
    "Out" -> Out
];

// FIXME: figure out how to create SynthDef programatically
var ug = uGens["Out"].ar(0, uGens["SinOsc"].ar(440));
SynthDef("u", {
    // Out.ar(0, SinOsc.ar(440));
    uGens["Out"].ar(0, uGens["SinOsc"].ar(440))
    //ug; does not work, why not? Seems to already have been evaluated to 0
}).send(s);
//ug;
)

c = Synth.new("u");


// TODO: create components for SC Nodes / Synths

// Protocol
// Each command sends a OSC reply to recvPort+1
(
var listComponents = { |msg, time, addr, recvPort|
    "got message: ".post; msg.postln;
    a = NetAddr(addr.ip, recvPort+1);
    // TODO: send entire component list
    a.sendMsg("/component/component", "SinOsc");
};
OSCdef(\componentList).clear;
OSCdef(\componentList, listComponents, "/component/list");

OSCdef(\sk).clear

// TODO: add rest of required API

// self-test response
/*OSCdef(\sk).clear;
OSCdef(\sl, { |msg, time, addr, recvPort|
    "response:".post; msg.postln;
    },
    "/component/component", NetAddr("127.0.0.1", NetAddr.langPort), NetAddr.langPort+1);

NetAddr("127.0.0.1", NetAddr.langPort).sendMsg("/component/list", "dim");
*/
)

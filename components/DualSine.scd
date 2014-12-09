SynthDef("DualSine", {
    arg out=SndFloLibrary.silentOut,
        freq=440, freq1=440, vol=1, vol1=1;
    var f = SinOsc.ar(freq, mul: vol);
    var f1 = SinOsc.ar(freq1, mul: vol1);
    Out.ar(out, f + f1, vol)
},
    metadata: (
        description: "Mix two channels using Balance2",
        specs: (
            a: SndFlo.inAudioBusSpec,
            b: SndFlo.inAudioBusSpec,
            out: SndFlo.outAudioBusSpec,
            mix: ControlSpec(-1, 1, default: 0),
        )
    )
)

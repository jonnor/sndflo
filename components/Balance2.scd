SynthDef("Balance2", {
    arg a=SndFloLibrary.silentIn,
        b=SndFloLibrary.silentIn,
        out=SndFloLibrary.silentOut,
        mix=0;
    var stereo = Balance2.ar(In.ar(a), In.ar(b), mix);
    var o = stereo[0] + stereo[1];
//    var o = In.ar(a) + In.ar(b);
    Out.ar(out, o)
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

SynthDef("AudioOut", {
    arg in=SndFloLibrary.silentIn, out=0;
    Out.ar(out, In.ar(in))
},
    metadata: (
        description: "Play out on soundcard"
    )
)

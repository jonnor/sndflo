SndFlo {

    *outAudioBusSpec {
        ^ControlSpec(units: "Out2AudioBus", default: SndFloLibrary.silentOut);
    }
    *inAudioBusSpec {
        ^ControlSpec(units: "InAudioBus", default: SndFloLibrary.silentIn);
    }

}
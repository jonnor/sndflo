Data-flow programming for SuperCollider?
========================================
sndflo allows to program [SuperCollider](http://supercollider.sourceforge.net) using
the [Flowhub](http://flowhub.io) visual data-flow IDE.

Status
------
Proof-of-concept working for wiring up Synth's.


Install
--------
**Note: Only tested on GNU/Linux.**
Should work fine on other platforms with minor adjustments in install.

Prerequities

* [SuperCollider](http://supercollider.sourceforge.net/downloads/) (version 3.5 or later)
* [node.js](http://nodejs.org/download/)

Install

    git clone https://github.com/jonnor/sndflo.git
    cd sndflo

    # Install as SuperCollider extension
    mkdir -p ~/.local/share/SuperCollider/Extensions || true
    ln -s `pwd` ~/.local/share/SuperCollider/Extensions/sndflo

Running
---------

    node scflo.js --verbose --user MY_FLOWHUB_UUID

Will start up SuperCollider, loading the sndflo runtime and FBP protocol bridge.
On success should output something like 

    Listening at WebSocket port 3569 
    OSC send/receive ports:  57120 57122
    Registered with Flowhub, should be accessible in UI

Go to [http://app.flowhub.io](http://app.flowhub.io), refresh the runtime list.
You should see our sndflo runtime listed, be able to create projects for 'sndflo' and connect.

Note: on GNU/Linux sclang might fail with a segfault if X11 is not available.
You can use `xvfb-run` to work around this.

Vision
---------
* Program audio pipelines visually, by Synth's wiring together with Busses
* Program synths visually, by creating SynthDefs by combining UGens
* Do not replace sclang, integrate with it
    * Allow to use SynthDefs created in sclang in visual pipelines
    * Allow to drive visually created Synth pipelines using sclang Events/Patterns
* Seamless integration with other FBP
    * MicroFlo for communicating with microcontrollers (sensing/acting)
    * NoFlo for general-purpose use, and generating composition/scores
    * Combined audio processing with [noflo-webaudio](https://github.com/automata/noflo-webaudio)
* Program scores visually, using Streams and Patterns

Usecases
-------
* Generative & algorithmic composed music
* Reactive and interactive art installations
* Audio effect pipelines, processing sound inputs
* Audio and music analysis, feature extraction



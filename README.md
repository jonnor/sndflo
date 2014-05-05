Data-flow programming for SuperCollider?
========================================
This is an experimental project, exploring how one
can program [SuperCollider](http://supercollider.sourceforge.net) using
[Flowhub](http://flowhub.io). This will hopefully allow to do
audio synthesis, sound processing and algorithmic using a visual data-flow
programming model.

Status
------
Proof-of-concept working for wiring up Synth's.


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

Running
--------
Only for the foolhardy so far :)

* Symlink the git repo into your extensions directory
* See the files sndflo-runtime.scd and scflo.js


The different architectural levels
---------------------------

There are several, very related, pieces of SuperCollider that are
interesting to attempt to make available to FBP and Flowhub.
From the most fine-grained to the most high-level:
1. SynthDefs, composed of UGens 
2. Synths, composed using Busses
3. Patterns, composed of Streams and Events
4. Inter-process audio pipelines, composed of multiple JACK clients

1) Can be implemented using the [Synth Definition File Format](http://doc.sccode.org/Reference/Synth-Definition-File-Format.html).

2) WIP, implemented in sclang as SuperCollider classes.
Could also be implemented by sending OSC node control messages to scsynth directly.

3) Implementation strategy unknown

Flow-based programming for algorithmic composition
--------------------------------

Tools like the Event/Stream/Pattern system in SuperCollider make
it possible to create complex algorithmic compositions.
However, they are extremely hard to understand, largely because
it is hard to see how each operation transforms its input on
non-trivial data.

Visualization of each step would be a major advantage.
Even better would be if there were tools which would show whish inputs
correspond to which outputs...
Can one 'tag' each piece of input data and carry this metadata onwards
until final destination, and be able to reconstruct a mapping between inputs<->outputs from this, and visualize it?

The outputs are likely to be many-dimensonal, so advanced visualization
techniques may be needed to illustrate the data...
In SC, can the outputs be represented as a timed stream of
scalar attributes with different synth/node targets?
If time is explicitly modelled, how to handle casual realtime events?
Perhaps just timestamp the in-data, play event at timestamp+delay comp.
Will one need both absolute and relative timebases (offsets).

There are many strong parallels between algorithmic audio composition
and generative visual design. More traditional "sequencing" type composition
has parallels to animation and keyframing. So maybe some of the concepts and
practices used in noflo-canvas and similar can be reappropriated?
And of course, for combined audiovisual works, having both audio and visuals be
created/driven the same way is a killer feature!


## Communicating directly to scsynth (server)
The SuperCollider frontend (sclang) communicates with the server using commands sent over OSC (Open Sound Control).
This would make it possible to create synths and audio processing pipelines directly, without

References

* [Supercollider Tutorial - Node Messaging or Direct Server Commands](https://www.youtube.com/watch?v=ZZ1Lwq9hGg4).
`s.queryAllNodes` can be used to show current node-tree on server.
* [SuperCollider Server Command Reference](http://doc.sccode.org/Reference/Server-Command-Reference.html), describes
all the messages and their OSC format.
* [supercolliderjs](https://www.npmjs.com/package/supercolliderjs) JavaScript library for talking to scsynth server,
and executing functions in the sclang interpreter.


## SuperCollider and MsgFlo

To communicate with other systems, sndflo currently use the FBP runtime protocol and the 'remote subgraph' feature in NoFlo.
This imposes a strict hierachicy where NoFlo (in browser or node.js) must be on the upper level.
Especially problematic when one wants to have multiple consumers of the same data, like a virtual device display in a browser.

Since then MsgFlo has been created, which is specifically for connecting together different systems, using standard message brokers.

scsynth -> MsgFlo bridge (using MQTT). Creates a Participant, and exposes inports for certain node/synth properties.
Probably needs ability load synthdefs and/or instantiate a set of synths. Maybe by executing a `.scd` file.
Should connect to a running scsynth server.
Primary usage probably as a commandline tool, with arguments/options configuring the particular use.
Should be possible to have multiple using the same scsynth server.

Could also allow a 'bundled' input, where one can send a JSON object with key/value pairs to set a bunch of properties at once.

Typical uses would be to:

* create interactive installations. Ex: trigger/influence sound from sensors
* adjust processing parameters based on user input
* create custom musical instruments

Streaming to browser
---------------------
For an integrated solution in Flowhub, we need to be able to send the live sound stream
over to the browser with low latency.
We could send audio frames over WebSocket and stuff it directly into a WebAudio element.
This would enable processing the stream also on the clientside with webaudio.

As SuperCollider does not have WS support, perhaps a WebSocket bridge for JACK (as a client)
would be a way to go. This would also enable other applications than SuperCollider to us it.
Could be implemented using glib,libsoup and libjack?
Or could have a C++ module for node.js, and use its WebSocket support..

It is also useful in embedded interactive installations to be able to output both to
From these perspectives, perhaps this runtime is more "audioflo" than specifically "scflo",
and also include launching and wiring the various JACK clients needed?



JACK and FBP
--------------
[JACK](http://jackaudio.org/) is a sound-server which can connect audio and MIDI between
different processes. It is used by default with SuperCollider on Linux.
Ideally one would be able to wire together JACK clients (like SC) from Flowhub

JACK bindings
* https://github.com/metachronica/node-jack-connector
* http://sourceforge.net/projects/py-jack/

Streaming
* http://sourceforge.net/projects/jackrtp/
* http://gstreamer.freedesktop.org/documentation/rtp.html
* http://gstreamer.freedesktop.org/data/doc/gstreamer/head/gst-plugins-good-plugins/html/gst-plugins-good-plugins-jackaudiosink.html

Random
---------

* https://trac.assembla.com/pkaudio/wiki/SuperCollider
* https://pypi.python.org/pypi/SC/0.2


Related
========

* https://github.com/mohayonao/CoffeeCollider
* http://overtone.github.io


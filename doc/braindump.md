
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


JACK and FBP
--------------
[JACK](http://jackaudio.org/) is a sound-server which can connect audio and MIDI between
different processes. It is used by default with SuperCollider on Linux.
Ideally one would be able to wire together JACK clients (like SC) from NoFlo

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



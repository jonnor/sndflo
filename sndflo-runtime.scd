var f = {
    "sndflo-runtime STAAAAAAAAARTING".postln;
    r = SndFloRuntime.new(s, NetAddr.localAddr);

    "sndflo-runtime running on port %".postf(NetAddr.localAddr.port);

    if (thisProcess.argv.size == 1, {
        // Load first arg as default graph
        r.network = SndFloNetwork.new(r.library);
        g = thisProcess.argv[0].parseYAMLFile;
        Task.new({
            s.sync; // make sure library is loaded
            r.network.loadGraph(g);
            r.network.start(true);
        }).play;
    });
};

Server.killAll();
Task.new({
    1.wait;
    //s.waitForBoot(f);
    s.boot;
    s.doWhenBooted(f);
}).play;

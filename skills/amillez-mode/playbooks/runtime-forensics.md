### Runtime forensics

**You own the diagnosis. Instrument the live process, don't theorize from source.** The deliverable is a cited diagnosis, not a fix.

1. Capture the live signal on the matching surface: a CPU profile for a spinning process, a heap snapshot for a leak, a trace or screen recording for a visual glitch. For Expo and React Native, drive the app on a simulator or emulator with Argent and use its profiling skills (Hermes CPU profile, React profiler, heap snapshot), falling back to Xcode Instruments or the Android Studio profiler for native frames. For web and Node, use DevTools or `node --inspect`. Use the project's `verify-<app>` skill to reach the state that shows the symptom. A real artifact, not a guess.
2. Reduce the artifact to the smoking gun: the function on the hot path, the retainer chain from the leaked object to a GC root, the loop firing without input. Parse large artifacts in a subagent ([Guard the Context Window](../principles/guard-the-context-window.md)), keep the reduced finding in the main thread. For the reduction itself, follow [Trace forensics](trace-forensics.md) steps 2 to 4.
3. Prove the mechanism before believing it. Inject instrumentation into the running app to confirm the hypothesis cheaply: a log line or counter picked up by Fast Refresh, a debugger evaluate against the Hermes or V8 runtime, or a temporary patch without a full rebuild. Revert every probe once it has answered.
4. Map the finding back to source: file, symbol, the line that allocates or schedules.
5. For a visual glitch, save the recording or screenshots and have a GPT 6 Luna Max verification session confirm the glitch frames against the expected behavior. Keep the media out of the tree.
6. Tear down what you started: simulators, emulators, Metro and dev servers, matching Expo CLI processes, debuggers, profilers.
7. Throughput checkpoint stays one line: `throughput checkpoint: n/a, read-only forensics`.

**Reply:** the signal captured, the reduced finding, how you proved the mechanism, the source location, artifact paths. No fix unless asked. Hand back to [Bug fix](bug-fix.md) or [Perf issue](perf-issue.md) once the cause is known.

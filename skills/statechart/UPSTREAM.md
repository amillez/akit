# statechart upstream

`statechart` is our copy of poteto's `statechart` skill from pstack. [`create-formal-verification-skill`](../create-formal-verification-skill/UPSTREAM.md) tells the verify skill it generates to read every TLA+ result with it.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/statechart/` (`SKILL.md`, `references/`, `scripts/`) |
| Compared against | `c742dd61706fbacc1b95f1a20b7b988cf096ce6c` (pstack `0.15.36`). The directory last changed in `519d36aa98955bf680db01bcde5fdfba686dc901` (2026-10-26), which fixed a test. Before it, `34b1b7c96f09f81a21a6c78f65b7833f7dcb5b24` replaced the node scripts with the TypeScript compiler, and `740d2c0786246cafac41906198f656b135194d3b` kept qualified action names in property traces. Ours is that tree without `scripts/test/` (Local change 1). |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the skill text, the compiler under `scripts/`, and `references/render.md` are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Tests and fixtures not vendored.** Upstream's `scripts/test/` (about 3.6 MB on disk, 376 files) is left out. It holds the TLC corpus, the `.test.ts` files, `ConfigOracle.java`, and the chart fixtures. Nothing the launcher runs imports from it, and every install would otherwise copy it twice per host, once to `~/.claude/skills` and once to `~/.agents/skills`. Every other file is byte-for-byte upstream, frontmatter and exec bits included, so the skill keeps `disable-model-invocation: true` and `/statechart` loads it. `scripts/package.json` is upstream's, so its `test` script and `fast-check` dev dependency point at the missing `test/` folder. Only `UPSTREAM.md` and `LICENSE-pstack` are ours.
2. **Runtime.** `scripts/statechart` runs `statechart.ts` with Node 22.18+, Bun 1.1.5+, or Deno 2.0+, with no build step. It finds TLC through mise (`tla2tools` 1.7.4 and `java@temurin-25`), or through `TLA2TOOLS` (path to `tla2tools.jar`) and `JAVA` (Java 11 or later) when `TLA2TOOLS` is set. `agent-m1` has Node 22 and Java 21 but no mise as of 2026-10-29, so a bare first run there exits 2 with "Cannot find TLC: mise install failed", and a run with `TLA2TOOLS` and `JAVA` set works.
3. **Size.** Ours is 31 upstream files, about 216 KB on disk with `UPSTREAM.md` and `LICENSE-pstack`.

## Check a revisit

Run upstream's tests from a cursor/plugins checkout at the new pin, since ours has no `scripts/test/`. Copy `pstack/skills/statechart/` to a scratch folder outside both repos, so `node_modules/` stays out of git. Then run, in the copy:

```bash
cd scripts
npm install --no-audit --no-fund
TLA2TOOLS=/path/to/tla2tools.jar JAVA=java npm test
```

Without `TLA2TOOLS`, the tests that run TLC skip. On macOS, also set `TMPDIR` to a folder with no symlink in its path. The default sits under `/var`, a symlink to `/private/var`, so the symlinked-launcher test in `cli.test.ts` builds a relative link one level short and fails with ENOENT. On 2026-10-29 on `agent-m1`, the suite passed 366 of 367 with the default `TMPDIR`, and that one test passed with `TMPDIR` under `/private/tmp`.

To check our copy, run one corpus model from the upstream checkout, such as `pstack/skills/statechart/scripts/test/corpus/CounterAction/`, with our `scripts/statechart`, and `cmp` its `report.md` and `chart.mmd` against the copies saved next to the model.

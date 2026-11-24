# statechart upstream

`statechart` is our copy of poteto's `statechart` skill from pstack. [`create-formal-verification-skill`](../create-formal-verification-skill/UPSTREAM.md) tells the verify skill it generates to read every TLA+ result with it.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/statechart/` (`SKILL.md`, `references/`, `scripts/`) |
| Compared against | `0b46ec399d55f2829e88822998f53b84944837d3` (pstack `0.15.46`, 2026-11-19). Against `0.15.42` it changes six files outside `scripts/test/`, all from #1292. `SKILL.md` says how to run on native Windows, where the POSIX launcher cannot run. `scripts/frontends/dot.ts` adds `splitLines`, and `scripts/run.ts` uses it, so TLC output with `\r\n` line ends parses the same as `\n`. `scripts/run.ts` also hides child windows on Windows, runs Java with UTF-8 stdout and stderr, and moves `killGroup` to the new `scripts/kill.ts`, which calls `taskkill` on Windows. `scripts/statechart.ts` replaces its `/bin/sh` janitor with the new `scripts/janitor.ts`, a Node script that kills the check's process group and removes its temporary folders when the launcher dies, and sets `TEMP` and `TMP` next to `TMPDIR`. Earlier, `bf0c7cd80abdbf7fe47b634978a7d1b4071f71a7` (`0.15.42`) drew one arrow to a parent state's border when every arrow into it comes from the same source, and reran SANY to report parse errors with line and column. Ours is that tree without `scripts/test/` (Local change 1) and with two bug fixes (Local change 4). We run on macOS and Linux only, so the Windows paths are vendored but untested on our hosts. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the skill text, the compiler under `scripts/`, and `references/render.md` are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Tests and fixtures not vendored.** Upstream's `scripts/test/` (about 3.7 MB on disk, 377 files) is left out. It holds the TLC corpus, the `.test.ts` files, `ConfigOracle.java`, and the chart fixtures. Nothing the launcher runs imports from it, and every install would otherwise copy it twice per host, once to `~/.claude/skills` and once to `~/.agents/skills`. Every other file except the two in Local change 4 is byte-for-byte upstream, frontmatter and exec bits included, so the skill keeps `disable-model-invocation: true` and `/statechart` loads it. `scripts/package.json` is upstream's, so its `test` script and `fast-check` dev dependency point at the missing `test/` folder. Only `UPSTREAM.md` and `LICENSE-pstack` are ours.
2. **Runtime.** `scripts/statechart` runs `statechart.ts` with Node 22.18+, Bun 1.1.5+, or Deno 2.0+, with no build step. It finds TLC through mise (`tla2tools` 1.7.4 and `java@temurin-25`), or through `TLA2TOOLS` (path to `tla2tools.jar`) and `JAVA` (Java 11 or later) when `TLA2TOOLS` is set. Relative paths in both resolve against the folder where you run the command, and a bare `JAVA` name such as `java` uses `PATH`. `agent-m1` has Node 22 and Java 21 but no mise as of 2026-10-29, so a bare first run there exits 2 with "Cannot find TLC: mise install failed", and a run with `TLA2TOOLS` and `JAVA` set works.
3. **Size.** Ours is 33 upstream files, about 230 KB on disk with `UPSTREAM.md` and `LICENSE-pstack`.
4. **Two bug fixes.** Both defects are in upstream at the pin. `0.15.46` fixed neither. Its `region-check.ts` is unchanged since `0.15.42`, and its `findTlc` still returns the paths as given. Drop a fix once upstream has its own.
   - `scripts/passes/region-check.ts`. Upstream's `regionsLie` builds every combination of initial region states and of simultaneous moves before it compares them with the model, so a two-state model with 32 regions runs out of memory and writes nothing. Ours iterates a lazy `product` and returns at the first combination the model lacks. The report message stays the same, and the chart falls back to parent states.
   - `scripts/run.ts`. Upstream's `findTlc` returns `TLA2TOOLS` and `JAVA` as given, but Java runs with a temporary folder as its working directory, so relative paths fail. Ours resolves them first, in the mise branch too. The SANY rerun from `0.15.42` uses the same paths, so the fix covers it. Ours is upstream's `run.ts` plus that one hunk in `findTlc`, which `0.15.46` left untouched, so the hunk applies as before.

## Check a revisit

Run upstream's tests from a cursor/plugins checkout at the new pin, since ours has no `scripts/test/`. Copy `pstack/skills/statechart/` to a scratch folder outside both repos, so `node_modules/` stays out of git. Then run, in the copy:

```bash
cd scripts
npm install --no-audit --no-fund
TLA2TOOLS=/path/to/tla2tools.jar JAVA=java npm test
```

Without `TLA2TOOLS`, the tests that run TLC skip. On macOS, also set `TMPDIR` to a folder with no symlink in its path. The default sits under `/var`, a symlink to `/private/var`, so the symlinked-launcher test in `cli.test.ts` builds a relative link one level short and fails with ENOENT. On 2026-10-29 on `agent-m1`, the suite passed 366 of 367 with the default `TMPDIR`, and that one test passed with `TMPDIR` under `/private/tmp`.

To check the bug fixes, run `./scripts/test-statechart.sh` from the akit root. It runs the launcher on real TLC. Without `TLA2TOOLS`, it downloads the pinned jar. On 2026-11-02, upstream's suite also passed 367 of 367 on a copy with these two fixes. Its SIGINT and SIGTERM tests named `while the command writes its files` failed now and then at a load average above 40, with and without the fixes, so rerun them alone before you trust a failure.

On 2026-11-16 on `agent-m1`, at `0.15.42` with our `scripts/` copied over upstream's, upstream's suite passed 373 of 373 with `TMPDIR` under `/private/tmp`, and `./scripts/test-statechart.sh` passed all 19 checks.

On 2026-11-23 on `agent-m1`, at `0.15.46` with our `scripts/` copied over upstream's, upstream's suite passed 407 of 407 with `TMPDIR` under `/private/tmp`. The 34 new tests run each corpus model on TLC output with Windows line ends, plus one `messages.test.ts` case. The render tests install `pele` and `mermaid` with npm into `~/.cache/statechart/`, so set `npm_config_cache` to a writable folder when the host's npm cache is not. `./scripts/test-statechart.sh` passed all 19 checks. A long TLC check stopped with SIGINT, and another with SIGKILL to the launcher, left no Java, worker, or janitor process and no temporary or staging folder on macOS.

To check our copy, run one corpus model from the upstream checkout, such as `pstack/skills/statechart/scripts/test/corpus/CounterAction/`, with our `scripts/statechart`, and `cmp` its `report.md` and `chart.mmd` against the copies saved next to the model.

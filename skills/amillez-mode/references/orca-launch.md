# Orca launches

Every coding session starts through Orca, with or without orchestration, so Agustín and every bot can reach it. This covers Claude Code (`--agent claude`), the Grok CLI at xhigh (`--agent grok`), and Codex (`--agent codex`). A review runs inside the same Orca worktree session as the main agent, as a second agent tab. Never start a session with a direct `claude`, `claude -p`, `codex exec`, or `grok -p` call. Host routing lives in [agent-use-policy §1](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#1-coding-host-routing). Pick the lane and its flags from the lane table in [`SKILL.md`](../SKILL.md#subagents-and-model-lanes).

Commands verified with Orca 1.4.237 on `agent-m1` on 2026-10-24. Check `orca agent launch --help` when they drift. The Grok CLI has its own stamp in [Launch the Grok lane](#launch-the-grok-lane).

## Start a session in a worktree

Pick the host first per [Pick a host](#pick-a-host). Orca holds one project per repo, registered once by its main clone. Each session is a worktree under that project. `akit`, `ai-eng-practices`, `rn-bedrock`, and `favvy-app` are already registered. Register a new repo once with `orca repo add --path ~/agent-work/<repo> --json`. Never `orca repo add` a worktree path. That adds a second entry to the repo's project and can rename the project after the worktree. Orca has no `orca repo rm`, so an entry added by mistake stays until `orca project setup-delete --setup <repo id> --force --json` removes it.

```bash
W=$(orca worktree create --repo name:<repo> --name <slug> --no-parent --json | jq -r .result.worktree.path)
git -C "$W" branch -m agent/<bot>/<slug>
orca agent launch --agent claude --worktree path:$W \
  --model claude-opus-5-5 --effort high --surface terminal \
  --prompt "Use amillez-mode first. <brief>" --json
```

- Orca cuts the worktree from the repo's default base at `~/orca/workspaces/<repo>/<slug>`, on branch `amillez/<slug>`. Rename the branch before the launch. Orca follows the rename.
- Orca marks the new path trusted in `~/.claude.json` at launch, so Claude Code starts without the trust prompt.
- Claude Code can still show a folder-trust dialog on a repo that contains `.claude/settings.json`. Choose "continue without" and send the brief again.
- Write `path:` selectors with an absolute path. Orca does not expand `~`, so `path:~/...` returns `selector_not_found`.
- A worker never approves a shell `rm -rf` prompt. It deletes the exact temp paths instead.
- `--no-parent` keeps the session top-level instead of a child of the caller's worktree.
- `result.outcome.handle` in the launch reply is the terminal handle. Read the banner with `orca terminal read --terminal <handle> --screen --json` and check that it shows the expected model.
- `--surface terminal` makes the launch a terminal even when the Chat UI setting is on, so the `orca terminal` commands below work on it.
- `--model` takes the full id from the lane table, never an alias. `--effort` requires `--model`. Leave both off the Grok lane, per [Launch the Grok lane](#launch-the-grok-lane).
- `orca worktree create` also takes `--agent`, `--model`, `--effort`, `--surface`, and `--prompt` to start the agent in one step. The agent then starts on `amillez/<slug>`, before any rename.
- Large work runs as an Orca Run instead, with workers started by `orca orchestration worker-start` per the [`orchestrate-agents`](../../orchestrate-agents/SKILL.md) skill.

## Launch the Grok lane

Use the Grok lane when Claude Code usage is above 70%. The lane runs the Grok CLI at xhigh in an Orca terminal. Orca can't pass the effort, so `~/.grok/config.toml` sets the default. `agent-m1` and the M4 both have this block, with backups at `~/.grok/config.toml.bak-20261102`.

```toml
[models]
default_reasoning_effort = "xhigh"
```

```bash
orca agent launch --agent grok --worktree path:$W --surface terminal \
  --prompt "Use amillez-mode first. <brief>" --json
```

- Leave `--model` and `--effort` off. Orca rejects `--model` for Grok with "does not support launch-time model selection", and `--effort` requires `--model`.
- `~/.grok/docs/user-guide/26-config-reference.md` defines `models.default_reasoning_effort`, and `05-configuration.md` shows the key in a `GROK_CONFIG` example. This key is the way to get xhigh through Orca, and the banner then shows `Grok 4.7 (xhigh) · always-approve`. Without the setting, the CLI default is `high`.
- Orca starts the CLI as `grok --permission-mode bypassPermissions -- <prompt>` on `agent-m1` and on the M4. `ps` showed this command on both hosts on 2026-11-02.
- The first launch per repo can show a one-time "Do you trust the contents of this directory?" prompt, even with bypass. Answer it with `orca terminal send --terminal <handle> --text y`. No trust prompt appeared in the 2026-11-02 `orca agent launch` tests.
- A direct call passes the model and xhigh on the command. A coding session still starts through Orca, so use the direct call only to check the CLI.

```bash
grok -p "reply OK" -m grok-4.7 --reasoning-effort xhigh --always-approve
```

| Item | Verified value |
| --- | --- |
| Binary | `~/.local/bin/grok` links to `~/.grok/bin/grok`. Version 1.0.70 (`f50904eaee6c`), installer `internal`. `grok update` updates it |
| Config home | `~/.grok` |
| Login | `grok login`. `grok models` prints "You are logged in with grok.com" |
| Auth check | `agent models`. It exits 0 and prints the login and the models. `agent` resolves through `~/.local/bin/agent` to `~/.grok/bin/agent`, so `~/.local/bin` must be on PATH. Verified on `agent-m1` on 2026-11-06 |
| Models | `grok-4.7` only, which is the default. No `grok-4.7-xhigh` id exists |
| Effort | `--reasoning-effort xhigh`, or the alias `--effort xhigh`. The accepted levels are `xhigh`, `high`, `medium`, and `low`. The default is `high` |
| Headless | `grok -p "<prompt>"`, `--prompt-file`, `--max-turns`, and `--output-format` with `plain`, `json`, `streaming-json`, or `streaming-messages-json`. `grok agent` takes `stdio`, `headless`, or `serve` |
| Permissions | `--always-approve`, `--permission-mode` with `bypassPermissions`, `default`, `acceptEdits`, `auto`, `dontAsk`, or `plan`, and `--sandbox <profile>` |

These facts were verified on `agent-m1` on 2026-11-02. The Orca smoke test ran `orca worktree create` with `--agent grok --surface terminal --prompt`, and the agent answered.

The Grok CLI on the M4 is version 1.0.70 (`f50904eaee6c`) `[stable]` at `~/.grok/bin/grok`. It is logged in with grok.com, and its model is `grok-4.7`. These facts were verified on 2026-11-02.

With the config block set, an Orca smoke test on each host showed the banner `Grok 4.7 (xhigh) · always-approve`, and the agent replied. Both tests ran on 2026-11-02.

The table lists each Grok launch path tested on 2026-11-02. `agent-m1` ran Orca CLI 1.4.237. The M4 ran Orca 1.4.246, and the tests in the M4 column ran `orca` locally on the M4, not through `--environment m4`.

| Path | `agent-m1` | The M4, run locally |
| --- | --- | --- |
| `orca agent launch --agent grok --worktree path:$W --surface terminal --prompt "<brief>" --json` | Passed. The agent wrote its output file and replied | Passed. The agent wrote its output file and replied |
| `orca orchestration run-create`, `task-create --run <id>`, then `worker-start --run <id> --task <id> --agent grok --worktree current --json` | Passed through `worker_done`. `worker-show` and the task both report completed | Verified up to the file write. The free usage limit blocked `worker_done` |
| `orca terminal create --worktree path:$W --command "grok --permission-mode bypassPermissions" --json`, `orca terminal wait --for tui-idle`, then `orca terminal send --text "<brief>" --enter` | Passed end to end | The banner showed and the brief arrived. The free usage limit blocked the reply |

- On `agent-m1`, `worker-start` returned state `ready` and stage `input_accepted`. Its `launch.effective` showed agent `grok`, with `model` and `effort` both null. The banner showed `Grok 4.7 (xhigh) · always-approve`.
- The free usage limit belongs to the M4's Grok account. The CLI printed "You hit your free usage limit" with a SuperGrok upgrade prompt. In the worker test, Orca escalated "Worker stopped on an error without reporting" with `stopReason` `errored`.
- On Orca 1.4.246, `run-create --json` and `task-create --json` return different JSON shapes. `task-create` gives `.result.taskId`, not `.result.task.id`.
- `orca agent launch --environment m4 --agent grok` from `agent-m1` fails, per [Run on the M4](#run-on-the-m4).

## Close a session

Close the session as soon as its PR merges or the work is abandoned. Leave no terminal, worktree, or branch behind.

```bash
for h in $(orca terminal list --worktree path:$W --json | jq -r '.result.terminals[].handle'); do
  orca terminal close --terminal "$h" --tab --json
done
orca artifacts delete <id> --json
orca worktree rm --worktree name:<slug> --json
git -C ~/agent-work/<repo> worktree list
git -C ~/agent-work/<repo> branch --list agent/<bot>/<slug>
git -C ~/agent-work/<repo> push origin --delete agent/<bot>/<slug>
```

- Run `orca artifacts delete` only when the PR has a [`review-guide`](../../review-guide/SKILL.md) artifact. Take `<id>` from `~/agent-work/proof/<slug>/review-guide.share.json`, or from `orca artifacts list --json`. Delete it before `orca worktree rm`.
- `orca worktree create` opens a shell tab next to the agent tab, so the loop closes every tab, not only the agent's.
- If `orca terminal close --tab` returns `terminal_handle_stale`, run `orca terminal close --worktree path:$W --all --json` instead, with `$W` the absolute worktree path.
- `orca worktree rm` returns `"removing": true` and finishes in the background. Run `git worktree list` again until the path is gone.
- `orca worktree rm` also deletes the local branch, an unmerged one too once it is pushed. If `git branch --list` still shows it, delete it with `git branch -D`.
- Skip `push origin --delete` when GitHub already deleted the branch on merge.

## Run a review in the same worktree

The reviewer runs inside the same Orca worktree session as the main agent. Launch it with `orca agent launch --worktree path:<main worktree>`, which opens a second agent tab in that worktree. Never give a review its own child worktree, so never use `orca worktree create` or `orca orchestration worker-start --worktree new-child` for a review. Pick the reviewer's lane from [code review](code-review.md), which also caps a change at 3 [review rounds](code-review.md#review-rounds). A read-only reviewer is not a second writer, so it does not break one writer per checkout.

```bash
h=$(orca agent launch --agent codex --worktree path:$W \
  --model gpt-6.1-sol --effort high --surface terminal \
  --prompt "$(cat brief.md)" --json | jq -r .result.outcome.handle)
orca terminal wait --terminal "$h" --for tui-idle --timeout-ms 590000 --json
orca terminal read --terminal "$h" --screen --json
orca terminal close --terminal "$h" --tab --json
```

For Codex-authored work, swap in `--agent claude --model claude-opus-5-5 --effort high`.

- Permissions bypass on `agent-m1`, and on the M4 for Orca-launched bot sessions only. On `agent-m1`, Orca's per-agent default arguments start Claude Code with `--dangerously-skip-permissions` and Codex with `--dangerously-bypass-approvals-and-sandbox`. Orca starts the Grok CLI with `--permission-mode bypassPermissions` on both hosts. On the M4, a Claude Code or Codex bot session passes the flag per launch, per [Run on the M4](#run-on-the-m4). A Grok session on the M4 passes the flag only when it starts through `orca terminal create --command grok`. The tabs run without a sandbox. `orca agent launch` has no flag for `--sandbox read-only` or `--permission-mode plan`, so the brief states that the role is read-only.
- `tui-idle` can fire before the agent starts on the prompt. Read the screen after each wait, and wait again until the reply is there.
- `--screen` returns only the visible frame. For output longer than one screen, the prompt tells the agent to write its full output to a named file outside the worktree, and you read that file. Plain `orca terminal read` returns accumulated output, where TUI repaints come back as stacked fragments.
- Close the tab with `--tab` once the agent is idle, so wait for `tui-idle` after the result is in. A tab closed mid-turn can stay listed with a stale handle while its agent keeps running. A plain `orca terminal close` kills only the PTY, and Orca can reattach the tab under a new handle with the agent session resumed. The tab is closed when `orca terminal list --worktree path:<worktree> --json` no longer lists its `tabId`.

## Pick a host

Fleet sessions run on two Orca hosts. The limits the host rules use live in this table, so change a limit here and in Ben's script, nowhere else.

| Host | Orca selector | Owner | Role | Health check | Disk floor (hard stop) | Simulator cap |
| --- | --- | --- | --- | --- | --- | --- |
| `agent-m1` | this machine (no flag) | The bots | Default for bot sessions | `bash ~/agent-work/bin/host-health.sh` | 30 GB free | 1 Android emulator, per [agent-use-policy §12](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#12-orca-hosts-and-resource-limits) |
| The M4 | `--environment m4` | Agustín, his day-job laptop | Overflow for bots, any time | `bash ~/orca/host-health.sh` | 30 GB free | 2 iOS simulators and 1 Android emulator in total, Agustín's and the bots' together |

A host is busy (soft) when its load per core is 1.0 or more, its free memory is under 15%, or it uses more than 6 GB of swap. When a host is blocked, recheck every 5 minutes for up to 2 hours.

Ben owns the health check script on both hosts. It prints one JSON line with `host`, `disk_free_gb`, `load_per_core`, `mem_free_pct`, `swap_used_gb`, `ios_booted`, `android_running`, `caps`, `ios_slots_free`, `android_slots_free`, `status` (`ok`, `busy`, or `blocked`), and `reasons`. It exits 0 for `ok` or `busy`, 1 for `blocked`, and 2 on a script error. Add `--human` for a readable summary. The device counts include every simulator and emulator on the host, whoever started it.

The script does not check the JS toolchain. Before a build or install that needs Node, check it yourself on the same host:

```bash
command -v node pnpm corepack && node --version && pnpm --version
```

- `command -v` must print a path for each of `node`, `pnpm`, and `corepack`.
- `node --version` proves that the pinned Node runs, not only that it is on PATH. A Homebrew Node 24 once failed at start because `libsimdjson.34.dylib` was missing.
- After any Homebrew Node upgrade, run `corepack enable --install-directory /opt/homebrew/bin`, then check `pnpm --version` again.
- If a check fails, stop and report the output, as for a `blocked` host.

On the M4, run the check in a terminal inside the session's worktree there. Create the worktree first, run the check, and remove the worktree with `orca worktree rm --environment m4` if the M4 is blocked. The M4 refused ssh from `agent-m1` on 2026-10-24, so use the Orca terminal.

```bash
W=$(orca worktree create --environment m4 --repo name:<repo> --name <slug> --no-parent --json | jq -r .result.worktree.path)
h=$(orca terminal create --environment m4 --worktree path:$W --title host-health --command "bash ~/orca/host-health.sh" --json | jq -r .result.terminal.handle)
orca terminal read --environment m4 --terminal "$h" --json | jq -r '.result.terminal.tail[]' | grep '^{"host"'
orca terminal close --environment m4 --terminal "$h" --tab --json
```

- The command types into the terminal's shell, so the read can come back before the JSON line prints. Read again until it shows.
- The exit code does not reach `orca terminal read`, so read `status` from the JSON line.
- Don't add `; exit` to the command. A terminal that exits returns no output to `orca terminal read`.

Android work is the likeliest to hit the disk stop. One Android build worktree takes about 9 GB, and on 2026-10-24 `agent-m1` had about 34 GB free and the M4 about 40 GB. One Android build can take either host below its floor. Before an Android task, run the [worktree cleanup](../playbooks/worktree-cleanup.md) for finished worktrees first.

### Route a bot session

1. Run the check on `agent-m1`. If `status` is `ok`, launch there.
2. If `agent-m1` is `blocked` or `busy`, run the [worktree cleanup](../playbooks/worktree-cleanup.md) on it for finished worktrees, then check again.
3. If `agent-m1` is still not `ok`, check the M4. If the M4 is `blocked` or `busy`, run the worktree cleanup there for finished bot worktrees only, then check again. If the M4 is `ok`, launch there with `--environment m4`, per [Run on the M4](#run-on-the-m4), which names the Grok exception.
4. If neither host is `ok`, wait and recheck at the interval above, from a background shell loop. A recheck runs the health check only, never a model.
5. When the wait limit runs out, message Agustín once with each host's `--human` output. A coding agent reports the message to its dispatcher instead of sending it.

Disk is a hard stop. Never start a session on a `blocked` host. `busy` is soft. A short, urgent fix may still run on a `busy` host.

### Respect the simulator cap

Before you boot a simulator or emulator, run the check. When `ios_slots_free` or `android_slots_free` is a number, boot that kind of device only while it is above 0. `null` means the host has no cap for that kind. On `agent-m1`, `ios_slots_free` is `null` and `android_slots_free` is a number. On the M4 both are numbers, and the counts include Agustín's devices. When the M4 is full, run the simulator task on `agent-m1` or wait. Shut down only the devices your session booted.

Every host runs slim devices. Use stock only when the task needs what slim disables, per the [`simfleet`](../../simfleet/SKILL.md#rules) rules. Policy source is [agent-use-policy §12](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#12-orca-hosts-and-resource-limits).

### Use the M4 as a guest

Bots may use the M4 at any time, whether or not Agustín is using it. Only its health check stops them.

- Touch only the Orca worktree folder. Never touch Agustín's own repos, checkouts, or credentials. Worktree cleanup on the M4 removes only bot worktrees on `agent/<bot>/` branches.
- Copy no fleet secrets to the M4. Sessions there use the `git`, `gh`, and agent CLI logins already on it.

### Warn on Agustín's sessions

Agustín picks the host for his own sessions. The routing above is for bots. Before you launch a session for him, run the check with `--human` on the host he picked and show him the summary as a warning. Launch anyway.

### Run on the M4

Add `--environment m4` to every `orca` call, including `terminal read`, `wait`, and `close`, since terminal handles belong to the server that issued them. The `--worktree path:` must exist on the M4. The exception is `orca agent launch --agent grok`, which fails with `--environment m4` from `agent-m1`, per the note at the end of this section.

Never change global settings on the M4. That covers Orca's per-agent default arguments, `~/.claude/settings.json`, and the Codex and Grok configs, which all belong to Agustín. `orca agent launch` passes no extra CLI flags, so a Claude Code or Codex bot session on the M4 starts its CLI with the skip-permissions flag in an Orca terminal, then gets its brief.

The Grok CLI differs. Orca adds `--permission-mode bypassPermissions` for `--agent grok` on the M4 too, so a Grok session started with `orca agent launch` or `worker-start` needs no flag. Only the manual `orca terminal create --command grok` path passes the flag.

```bash
h=$(orca terminal create --environment m4 --worktree path:$W --title agent \
  --command "claude --dangerously-skip-permissions --model claude-opus-5-5 --effort high" --json | jq -r .result.terminal.handle)
orca terminal wait --environment m4 --terminal "$h" --for tui-idle --timeout-ms 60000 --json
orca terminal read --environment m4 --terminal "$h" --screen --json
orca terminal send --environment m4 --terminal "$h" --text "Use amillez-mode first. <brief>" --enter --json
```

- Before you send the brief, check that the banner shows the expected model and `bypass permissions on`.
- Start Codex with `--dangerously-bypass-approvals-and-sandbox`, the flag Orca adds on `agent-m1`, plus the lane's model flags.
- To start the Grok CLI through `orca terminal create`, pass `--permission-mode bypassPermissions`. The M4's `~/.grok/config.toml` already sets xhigh, so the command does not pass it. Starting the CLI first and sending the brief after passed end to end on `agent-m1`. Run locally on the M4, the flow showed the banner `Grok 4.7 (xhigh) · always-approve` and delivered the brief, but the M4 Grok account's free usage limit blocked the reply.
- Agustín's own sessions keep their permission prompts. Turn prompts off only for a bot session launched through Orca.
- In Agustín's own sessions, the `gh pr edit` that adds the [`review-guide`](../../review-guide/SKILL.md#add-the-link-to-the-pr-body) link can wait on his approval, so the PR body may lack the link until he approves.

Select the M4 by its name, `m4`, not by id. Each machine keeps its own pairing store, so an environment id copied from another machine does not resolve here. `orca host list --json` prints the selector for each host this machine can reach.

To close a session on the M4, run the [Close a session](#close-a-session) `orca` calls with `--environment m4`. The `git -C ~/agent-work/<repo>` checks there read `agent-m1`'s clone, so confirm the removal with `orca worktree list --environment m4 --json` instead.

The 2026-11-02 M4 smoke tests ran `orca` locally on the M4, not through `--environment m4`. From `agent-m1` on the same day, `orca worktree create --environment m4`, `orca repo list --environment m4`, and `orca terminal list --environment m4` worked. `orca agent launch --environment m4 --agent grok` failed with `{"code":"agent_launch_replay_unsupported"}`. `agent-m1` ran Orca CLI 1.4.237 and the M4 ran Orca 1.4.246, so version skew is the likely cause, but nobody has confirmed it. The M4's Orca has no akit repo.

The other `--environment m4` commands in this section match `orca <command> --help` for Orca 1.4.237. No recorded run covers them against the M4. The Claude Code terminal launch above ran on `agent-m1`, without `--environment`, on 2026-10-24.

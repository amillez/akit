# Orca launches

Every coding session starts through Orca, with or without orchestration, so Agustín and every bot can reach it. This covers Claude Code (`--agent claude`), the Cursor Agent CLI (`--agent cursor`), and Codex (`--agent codex`). A review runs inside the same Orca worktree session as the main agent, as a second agent tab. Never start a session with a direct `claude`, `claude -p`, `codex exec`, or `agent -p` call. Host routing lives in [agent-use-policy §1](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#1-coding-host-routing). Pick the lane and its flags from the lane table in [`SKILL.md`](../SKILL.md#subagents-and-model-lanes).

Commands verified with Orca 1.4.237 on `agent-m1` on 2026-10-24. Check `orca agent launch --help` when they drift.

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
- `--no-parent` keeps the session top-level instead of a child of the caller's worktree.
- `result.outcome.handle` in the launch reply is the terminal handle. Read the banner with `orca terminal read --terminal <handle> --screen --json` and check that it shows the expected model.
- `--surface terminal` makes the launch a terminal even when the Chat UI setting is on, so the `orca terminal` commands below work on it.
- `--model` takes the full id from the lane table, never an alias. `--effort` requires `--model`. Leave `--effort` off the Grok lane, since the effort is part of `grok-4.7-xhigh`.
- `orca worktree create` also takes `--agent`, `--model`, `--effort`, `--surface`, and `--prompt` to start the agent in one step. The agent then starts on `amillez/<slug>`, before any rename.
- Large work runs as an Orca Run instead, with workers started by `orca orchestration worker-start` per the [`orchestrate-agents`](../../orchestrate-agents/SKILL.md) skill.

## Close a session

Close the session as soon as its PR merges or the work is abandoned. Leave no terminal, worktree, or branch behind.

```bash
for h in $(orca terminal list --worktree path:$W --json | jq -r '.result.terminals[].handle'); do
  orca terminal close --terminal "$h" --tab --json
done
orca worktree rm --worktree name:<slug> --json
git -C ~/agent-work/<repo> worktree list
git -C ~/agent-work/<repo> branch --list agent/<bot>/<slug>
git -C ~/agent-work/<repo> push origin --delete agent/<bot>/<slug>
```

- `orca worktree create` opens a shell tab next to the agent tab, so the loop closes every tab, not only the agent's.
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

- The tabs run without a sandbox. On `agent-m1`, Claude Code starts in bypass permissions mode, Codex in YOLO mode, and the Cursor Agent CLI with `--yolo`. `orca agent launch` has no flag for `--sandbox read-only` or `--permission-mode plan`, so the brief states that the role is read-only.
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
2. If `agent-m1` is `blocked`, run the [worktree cleanup](../playbooks/worktree-cleanup.md) on it for finished worktrees, then check again.
3. If `agent-m1` is still not `ok`, check the M4. If the M4 is `ok`, launch there with `--environment m4`.
4. If neither host is `ok`, wait and recheck at the interval above, from a background shell loop. A recheck runs the health check only, never a model.
5. When the wait limit runs out, message Agustín once with the last JSON line from each host. A coding agent reports the message to its dispatcher instead of sending it.

Disk is a hard stop. Never start a session on a `blocked` host. `busy` is soft. A short, urgent fix may still run on a `busy` host.

### Respect the simulator cap

Before you boot a simulator or emulator on the M4, run the check. Boot an iOS simulator only while `ios_slots_free` is above 0, and an Android emulator only while `android_slots_free` is above 0. The counts include Agustín's devices. When the M4 is full, run the simulator task on `agent-m1` or wait. Shut down only the devices your session booted.

### Use the M4 as a guest

Bots may use the M4 at any time, whether or not Agustín is using it. Only its health check stops them.

- Touch only the Orca worktree folder. Never touch Agustín's own repos, checkouts, or credentials. Worktree cleanup on the M4 removes only bot worktrees on `agent/<bot>/` branches.
- Copy no fleet secrets to the M4. Sessions there use the `git`, `gh`, and agent CLI logins already on it.

### Warn on Agustín's sessions

Agustín picks the host for his own sessions. The routing above is for bots. Before you launch a session for him, run the check with `--human` on the host he picked and show him the summary as a warning. Launch anyway.

### Run on the M4

Add `--environment m4` to every `orca` call, including `terminal read`, `wait`, and `close`, since terminal handles belong to the server that issued them. The `--worktree path:` must exist on the M4. To create the checkout and its agent there in one step, run `orca worktree create --environment m4 --repo <selector> --name <slug> --agent claude --model claude-opus-5-5 --effort high --surface terminal --prompt "Use amillez-mode first. <brief>" --json`.

Select the M4 by its name, `m4`, not by id. Each machine keeps its own pairing store, so an environment id copied from another machine does not resolve here. `orca host list --json` prints the selector for each host this machine can reach.

To close a session on the M4, run the [Close a session](#close-a-session) `orca` calls with `--environment m4`. The `git -C ~/agent-work/<repo>` checks there read `agent-m1`'s clone, so confirm the removal with `orca worktree list --environment m4 --json` instead.

The `--environment m4` commands in this section match `orca <command> --help` for Orca 1.4.237. They have not run against the M4, whose Orca server did not answer on 2026-10-24.

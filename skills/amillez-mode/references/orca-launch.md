# Orca launches

Every coding session starts through Orca, with or without orchestration, so Agustín and every bot can reach it. This covers Claude Code (`--agent claude`), the Cursor Agent CLI (`--agent cursor`), and Codex (`--agent codex`). A review runs inside the same Orca worktree session as the main agent, as a second agent tab. Never start a session with a direct `claude`, `claude -p`, `codex exec`, or `agent -p` call. Host routing lives in [agent-use-policy §1](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#1-coding-host-routing). Pick the lane and its flags from the lane table in [`SKILL.md`](../SKILL.md#subagents-and-model-lanes).

Flags verified with Orca 1.4.237 on `agent-m1` on 2026-10-23. Check `orca agent launch --help` when they drift.

## Start a session in a worktree

Create the worktree under `~/agent-work`, add it to Orca as a repo, then launch the agent in it.

```bash
git -C ~/agent-work/<repo> fetch origin
git -C ~/agent-work/<repo> worktree add -b agent/<bot>/<slug> ~/agent-work/<repo>-<slug> origin/main
orca repo add --path ~/agent-work/<repo>-<slug> --json
orca agent launch --agent claude --worktree path:$HOME/agent-work/<repo>-<slug> \
  --model claude-opus-5-5 --effort high --surface terminal \
  --prompt "Use amillez-mode first. <brief>" --json
```

- `result.outcome.handle` in the JSON reply is the terminal handle. Read the banner with `orca terminal read --terminal <handle> --screen --json` and check that it shows the expected model.
- `--surface terminal` makes the launch a terminal even when the Chat UI setting is on, so the `orca terminal` commands below work on it.
- `--model` takes the full id from the lane table, never an alias. `--effort` requires `--model`. Leave `--effort` off the Grok lane, since the effort is part of `grok-4.7-xhigh`.
- `orca worktree create --repo <selector> --name <slug> --agent <id> ...` also creates a checkout with its agent, but it puts the checkout where Orca's settings say. Prefer the explicit `~/agent-work` worktree on `agent-m1`.
- Large work runs as an Orca Run instead, with workers started by `orca orchestration worker-start` per the [`orchestrate-agents`](../../orchestrate-agents/SKILL.md) skill.

## Run a review in the same worktree

The reviewer runs inside the same Orca worktree session as the main agent. Launch it with `orca agent launch --worktree path:<main worktree>`, which opens a second agent tab in that worktree. Never give a review its own child worktree, so never use `orca worktree create` or `orca orchestration worker-start --worktree new-child` for a review. Pick the reviewer's lane from [code review](code-review.md), which also caps a change at 3 [review rounds](code-review.md#review-rounds). A read-only reviewer is not a second writer, so it does not break one writer per checkout.

```bash
h=$(orca agent launch --agent codex --worktree path:$HOME/agent-work/<repo>-<slug> \
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

## Run on the M4

Add `--environment m4` to every `orca` call, including `terminal read`, `wait`, and `close`, since terminal handles belong to the server that issued them. The `--worktree path:` must exist on the M4. To create the checkout and its agent there in one step, run `orca worktree create --environment m4 --repo <selector> --name <slug> --agent claude --model claude-opus-5-5 --effort high --surface terminal --prompt "Use amillez-mode first. <brief>" --json`.

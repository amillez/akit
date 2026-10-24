# Orca launches

Every coding session starts through Orca, with or without orchestration, so Agustín and every bot can reach it. This covers Claude Code (`--agent claude`), the Cursor Agent CLI (`--agent cursor`), and Codex (`--agent codex`). A review runs inside the same Orca worktree session as the main agent, as a second agent tab. Never start a session with a direct `claude`, `claude -p`, `codex exec`, or `agent -p` call. Host routing lives in [agent-use-policy §1](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#1-coding-host-routing). Pick the lane and its flags from the lane table in [`SKILL.md`](../SKILL.md#subagents-and-model-lanes).

Commands verified with Orca 1.4.237 on `agent-m1` on 2026-10-24. Check `orca agent launch --help` when they drift.

## Start a session in a worktree

Orca holds one project per repo, registered once by its main clone. Each session is a worktree under that project. `akit`, `ai-eng-practices`, `rn-bedrock`, and `favvy-app` are already registered. Register a new repo once with `orca repo add --path ~/agent-work/<repo> --json`. Never `orca repo add` a worktree path. That adds a second entry to the repo's project and can rename the project after the worktree. Orca has no `orca repo rm`, so an entry added by mistake stays until `orca project setup-delete --setup <repo id> --force --json` removes it.

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

## Run on the M4

Add `--environment m4` to every `orca` call, including `terminal read`, `wait`, and `close`, since terminal handles belong to the server that issued them. The `--worktree path:` must exist on the M4. To create the checkout and its agent there in one step, run `orca worktree create --environment m4 --repo <selector> --name <slug> --agent claude --model claude-opus-5-5 --effort high --surface terminal --prompt "Use amillez-mode first. <brief>" --json`.

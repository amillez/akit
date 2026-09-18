---
name: register-worker-dir
description: >-
  Register a repo so Cursor My Machines can route worker=agent-m1 (computer-use
  sims/UI). Use when a project is not yet on the agent-m1 LaunchAgent
  --worker-dir list, before dispatching Cursor work to that worker, or when
  bots must avoid claiming Argent/sim proof from managed cloud for an
  unregistered remote.
---

# Register a worker-dir for agent-m1

`agent-m1` runs LaunchAgent `com.cursor.agent-worker.agent-m1` with
`--computer-use --name agent-m1` and one or more `--worker-dir` entries.
Cursor only routes `worker=agent-m1` to remotes whose checkout is registered
that way.

## When to use

- Before dispatching Cursor / My Machines work with `worker=agent-m1` to a new repo.
- When a bot was about to route an unregistered remote to `worker=agent-m1` (do not).
- When you need sim/Argent/computer-use proof on agent-m1 for a project that is not yet registered.

## Hard rules

1. **Unregistered → do not dispatch `worker=agent-m1`.** Stay on Claude Code / Codex on agent-m1, or managed Cursor cloud **without** claiming sim/Argent proof.
2. **Never** claim Argent / sim proof from managed Cursor cloud for an unregistered project.
3. After registering, kickstart the LaunchAgent before the first `worker=agent-m1` dispatch.

## Recipe

Paths are generic; adjust only if the host layout differs.

1. **Clone** the repo under `~/agent-work/<repo>` (main checkout for sync/human; agents still use worktrees under that tree per dispatch lifecycle).

   ```bash
   mkdir -p ~/agent-work
   git clone <git-remote-url> ~/agent-work/<repo>
   ```

2. **Add `--worker-dir`** for that path on LaunchAgent `com.cursor.agent-worker.agent-m1`.
   - Edit the LaunchAgent plist (or the wrapper that builds the agent-worker argv) so the worker process includes `--worker-dir ~/agent-work/<repo>` (expand `~` to the absolute home path the plist uses).
   - Keep existing `--worker-dir` entries; append the new one.
   - Preserve `--computer-use` and `--name agent-m1`.

3. **Reload the worker:**

   ```bash
   launchctl kickstart -k gui/$(id -u)/com.cursor.agent-worker.agent-m1
   ```

4. **Confirm** the worker is up and the new dir is listed in its argv / logs, then dispatch with `worker=agent-m1`.

## Until registered

| Path | OK? |
| --- | --- |
| Claude Code / Codex on agent-m1 | Yes |
| Managed Cursor cloud (no sim/Argent claim) | Yes |
| `worker=agent-m1` Cursor My Machines | **No** |
| Claiming Argent/sim proof from managed cloud | **No** |

## Related

- Playbook: [Cursor self-hosted prove host (agent-m1)](https://github.com/amillez/ai-eng-practices/blob/main/playbooks/big-work-orchestration.md#cursor-self-hosted-prove-host-agent-m1) in `amillez/ai-eng-practices`
- Dispatch layout: `~/agent-work/<repo>/` worktrees in [agent-dispatch-lifecycle](https://github.com/amillez/ai-eng-practices/blob/main/playbooks/agent-dispatch-lifecycle.md)

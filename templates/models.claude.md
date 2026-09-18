# amillez model defaults

For **bots and orchestrators** in this project (session defaults):

| Host | Default |
| --- | --- |
| **Cursor** | **Grok 4.6** · effort **High** |
| **Claude** (Claude Code / agent-m1) | **Opus 5** · effort **High** |

**Workers** do **not** inherit these defaults blindly. Pick model + effort **per slice** from [`agent-use-policy`](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md) (Luna / Sol / Opus / Fable chooser).

## Hard notes

- Leave **Fast** off unless the human explicitly asks.
- **agent-m1** is the self-hosted Cursor My Machines worker for sim / Argent / computer-use prove. Register the repo with `/register-worker-dir` before `worker=agent-m1`.
- Do **not** write or rely on `pstack-models.mdc` (or any always-applied pstack role map).

## Install paths

Copy or symlink this file as:

- `.claude/rules/amillez-models.md` (Claude Code)
- `.agents/rules/amillez-models.md` (Codex / shared agents dir)

Prefer project rules over user-global when the repo has its own stack.

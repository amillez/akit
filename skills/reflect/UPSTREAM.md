# reflect upstream

`reflect` is our port of poteto's `reflect` skill from pstack. It is a separate core skill that holds the whole procedure, so `/reflect` runs without loading any other skill.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/reflect/` (`SKILL.md`, `references/{judgment,tooling,divergent}-reviewer.md`, `references/synthesizer.md`) |
| Compared against | `00b52d954a99ff67802cad428ff19218659f76fd` (pstack `0.15.11`). The directory last changed in `12d587dfb20741cafc376c42c696c5f6e2a64487` (2026-09-23). On `origin/main` at pstack `0.15.15` (`df581122cde17e6e27686b5a448bde23e4ad4318`), only the default model ids in the lane table and the synthesizer line differ (`claude-opus-5-5-max` → `claude-opus-5-5-xhigh`, `gpt-5.6-sol-max` → `grok-4.7-xhigh-fast`), which local change 3 already replaces. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the three-lens review, the synthesizer's filter, and the routing of learnings to concrete skill edits are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Frontmatter.** Kept `name` and `disable-model-invocation: true`, since `/reflect` is explicit-invoke. The description names the "reflect", "reflect on this session", and "reflect on session <id>" triggers and what the skill does, for Codex, which reads only `name`, `description`, and `metadata`.
2. **Session log.** Cursor's active `agent-transcripts/` → a finished Claude Code session under `~/.claude/projects/<project>/` or Codex session under `~/.codex/sessions/`, matched by its opening prompt, with subagent logs included.
3. **Lanes.** The three `Task` calls and the `pstack-models.mdc` role lines → three parallel headless sessions and one synthesizer session, with the skill's own lane table and launch commands following the [agent use policy](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#default-picks), which wins when it changes a lane. Judgment and Divergent run on Opus 5.5 High on Claude Code, or GPT 6.1 Sol xHigh above 70% Claude Code usage. Tooling always runs on GPT 6.1 Sol xHigh on Codex with `--sandbox read-only`, so the panel spans two model families. The synthesizer runs on Opus 5.5 xHigh, falling back to GPT 6.1 Sol xHigh only when Claude Code is exhausted. Adds the MCP note and the `codex exec` stdin note.
4. **Apply.** Upstream's approval wait and direct apply → one small PR for Agustín's row-by-row review, never merged, or a hand-off in the reply under "For the weekly ai-eng-practices garden". Practice-level rows go to ai-eng-practices.
5. **Installed skills.** Never edits installed copies under `~/.claude/skills/` or `~/.agents/skills/`. Every edit lands in a worktree of `amillez/akit` or `amillez/ai-eng-practices`, with installed paths mapped back to their source.
6. **Backlog.** Never auto-files to a tracker. Backlog items go in the PR body or the garden hand-off. Nothing gets posted or filed anywhere.
7. **create-skill.** Cursor's `create-skill` → a full skill edit checked against the frontmatter and the repo's own checks, with an optional link to amillez-mode's Authoring a skill playbook. `new skill` rows go to Backlog instead of being created in the PR.
8. **Reviewer templates.** Near-verbatim. "Session transcript" and "active transcript" → "finished Claude Code or Codex session log" where they name the input. "The parent agent applies edits" → "proposes edits". The skill-use scan covers `~/.claude/skills/`, `~/.agents/skills/`, and repo-level `.claude/skills/`, `.agents/skills/`, and `.codex/skills/`, and its headless-session example names `claude -p`, `codex exec`, or a worker or subagent brief. Routings give the `SKILL.md` path as the log shows it, and the parent maps installed copies back to their source repo.
9. **Synthesizer.** Adds a Right home criterion that routes rules about lanes, host, merge, proof bar, or team practice to the `amillez/ai-eng-practices` doc that owns them. The parent turns the Accepted list into one PR or a garden hand-off, Agustín approves row by row in PR review, `new skill via create-skill:` → `new skill:`, and Backlog items are listed in the PR body or the hand-off instead of filed.
10. **Sibling links.** Optional relative links to amillez-mode's Encode Lessons in Structure principle and its Authoring a skill and Opening a PR playbooks. Step 4 states the structural rule inline and step 5 states the PR loop inline, so the skill never requires loading amillez-mode. amillez-mode is core and installs beside this skill, so the links resolve in the repo and after install.
11. **Skill text only.** `SKILL.md` names no host and carries no attribution. Attribution lives here.

# show-me-your-work upstream

`show-me-your-work` is our port of poteto's `show-me-your-work` skill from pstack. It is a separate core skill that holds the whole decision-trail format, so `/show-me-your-work` runs without loading any other skill.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/show-me-your-work/` (`SKILL.md`, `references/decision-log-template.tsv`, `scripts/log.sh`) |
| Compared against | `d457567332aa6989e753ea289f30ea2bfbc80bc0` (pstack `0.15.28`). The directory last changed in `ce649c03ac3b75b6ae80cbd15b7e2c536caedb5a` (2026-10-14), which only adds a line to pick each subagent's reasoning level and speed per poteto-mode. Local change 5 already names the reviewer's model and effort. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the decision-trail format, the audit against the session log, and the cross-model review of the trail are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Frontmatter.** Kept `name`, the upstream `description` with its `/show-me-your-work` and long, autonomous, multi-phase, and stepped-away triggers, and `disable-model-invocation: true`, since `/show-me-your-work` is explicit-invoke.
2. **File names.** Kept upstream's layout and names: `references/decision-log-template.tsv` is byte-for-byte and `scripts/log.sh` is byte-for-byte. The template and helper mentions become relative links.
3. **Session log.** The Cursor `agent-transcripts/` audit → this run's own Claude Code session under `~/.claude/projects/<project>/` or Codex session under `~/.codex/sessions/`, never a glob across other projects or sessions. "Transcript" → "session log" throughout, and the section title follows.
4. **Runs.** "Agent conversation" → "agent session", "a new chat" → "a new session", and agent id → session id.
5. **Cross-model review.** Names our lane with its launch command. The reviewer is always Codex on GPT 6.1 Sol High, read-only (`codex exec -m gpt-6.1-sol -c model_reasoning_effort=high --sandbox read-only`, stdin fed or closed), for Claude Code and Grok work alike. The [agent use policy](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#1-coding-host-routing) wins when it changes a lane. The reviewer reports to Agustín instead of "the user". The flag list sits under a "The reviewer looks for" lead-in.
6. **Sibling links.** "The **unslop** skill" → a link to the sibling [`unslop`](../unslop/SKILL.md) skill. "The **encode-lessons-in-structure** principle skill" → an optional relative link to amillez-mode's `principles/encode-lessons-in-structure.md`. amillez-mode is core and installs beside this skill, so the links resolve in the repo and after install. The skill never requires loading amillez-mode.
7. **Composing this skill.** "Other skills" → "other skills and playbooks", and "reference it by name" → "link this skill", since amillez-mode's playbooks link it by path.
8. **Skill text only.** `SKILL.md` names no host and carries no attribution. Attribution lives here.

# show-me-your-work upstream

`show-me-your-work` is our port of poteto's `show-me-your-work` skill from pstack. It is a separate core skill that holds the whole decision-trail format, so `/show-me-your-work` runs without loading any other skill.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/show-me-your-work/` (`SKILL.md`, `references/decision-log-template.tsv`, `scripts/log.sh`) |
| Compared against | `00b52d954a99ff67802cad428ff19218659f76fd` (pstack `0.15.11`). The directory last changed in `12d587dfb20741cafc376c42c696c5f6e2a64487` (2026-09-23) and is identical on `origin/main` at pstack `0.15.15` (`df581122cde17e6e27686b5a448bde23e4ad4318`). |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the decision-trail format, the audit against the session log, and the cross-model review of the trail are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Frontmatter.** Kept `name`, the upstream `description` with its `/show-me-your-work` and long, autonomous, multi-phase, and stepped-away triggers, and `disable-model-invocation: true`, since `/show-me-your-work` is explicit-invoke.
2. **File names.** Kept upstream's layout and names: `references/decision-log-template.tsv` is byte-for-byte and `scripts/log.sh` is byte-for-byte. The template and helper mentions become relative links.
3. **Session log.** The Cursor `agent-transcripts/` audit → this run's own Claude Code session under `~/.claude/projects/<project>/` or Codex session under `~/.codex/sessions/`, never a glob across other projects or sessions. "Transcript" → "session log" throughout, and the section title follows.
4. **Runs.** "Agent conversation" → "agent session", "a new chat" → "a new session", and agent id → session id.
5. **Cross-model review.** Names our lanes with launch commands. Claude Code work gets a Codex reviewer (`codex exec -m gpt-6.1-sol -c model_reasoning_effort=xhigh --sandbox read-only`, stdin fed or closed), and Codex work gets a Claude Code reviewer (`claude -p --model claude-opus-5-5 --effort high`). The [agent use policy](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#default-picks) wins when it changes a lane. The reviewer reports to Agustín instead of "the user". The flag list sits under a "The reviewer looks for" lead-in.
6. **Sibling links.** "The **unslop** skill" → a link to the sibling [`unslop`](../unslop/SKILL.md) skill. "The **encode-lessons-in-structure** principle skill" → an optional relative link to amillez-mode's `principles/encode-lessons-in-structure.md`. amillez-mode is core and installs beside this skill, so the links resolve in the repo and after install. The skill never requires loading amillez-mode.
7. **Composing this skill.** "Other skills" → "other skills and playbooks", and "reference it by name" → "link this skill", since amillez-mode's playbooks link it by path.
8. **Skill text only.** `SKILL.md` names no host and carries no attribution. Attribution lives here.

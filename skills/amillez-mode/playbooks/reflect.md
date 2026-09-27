### Reflect

**You own turning one finished session into reviewed skill edits.** Mine a finished Claude Code or Codex session for durable learnings, route each to a concrete edit on an existing skill or ai-eng-practices doc, and hand the result to Agustín as one small PR or as input to the weekly ai-eng-practices garden. Invoke only when Agustín asks ("reflect", "reflect on this session", "reflect on session <id>"). Skip when the session was trivial, off-topic, or already covered by a skill the agent followed correctly. One-offs are not learnings.

**Never edit skills in place.** Installed copies under `~/.claude/skills/` and `~/.agents/skills/` are overwritten by the next install and never reviewed. Every edit lands in a worktree of `amillez/agent-skills` or `amillez/ai-eng-practices`.

#### 1. Locate the finished session log

Use the same locations as [Session pickup](session-pickup.md). Claude Code keeps sessions under `~/.claude/projects/<project>/` as `<session-id>.jsonl`, where `<project>` is the working directory with `/` replaced by `-`. Codex keeps them under `~/.codex/sessions/<yyyy>/<mm>/<dd>/` as `rollout-*.jsonl`.

```bash
ls -t ~/.claude/projects/<project>/*.jsonl 2>/dev/null | head -5
ls -t ~/.codex/sessions/*/*/*/rollout-*.jsonl 2>/dev/null | head -10
```

Read only the session you were asked about, never unrelated projects. For each candidate, read its first user message and check it is the session's opening prompt (for Codex, also check the working directory recorded in the first line). Take the matching path. Include subagent logs the harness keeps next to the session. If no path resolves, write a tight digest of the session and pass that instead.

#### 2. Run three reviewers in parallel

Each reviewer is a fresh headless session with its own lens. Launch all three at once, write each output to a file in a scratch dir outside any worktree, and `wait` for all three. Pass each template verbatim, substituting the log path or digest where marked. Reviewers read and look up context only. They never write code or edit skills.

| Lens | Lane | Template |
| --- | --- | --- |
| Judgment | General-code lane on Claude Code, Opus 5.5 High. Claude Code usage above 70% → GPT 6 Sol, xHigh. | [references/reflect-judgment.md](../references/reflect-judgment.md) |
| Tooling | General-code lane on Codex, GPT 6 Sol, xHigh, always, so the panel spans two model families. | [references/reflect-tooling.md](../references/reflect-tooling.md) |
| Divergent | Same lane as Judgment. | [references/reflect-divergent.md](../references/reflect-divergent.md) |

The lanes and their launch commands are in `SKILL.md` **Subagents and model lanes**, which follows the [agent use policy](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#default-picks). When the policy changes a lane, it wins over this table. Never GPT 5.6 or Opus 5.

Reviewers need MCP access for context the log references (issues, PRs, chat threads, error traces), so launch them with your normal user config. Run the Codex reviewer with `--sandbox read-only`.

#### 3. Synthesize

One fresh headless session on Opus 5.5 xHigh (`claude --model claude-opus-5-5 --effort xhigh`), the only non-Orca use of that lane. Claude Code usage does not move it. If Claude Code is exhausted, say so and use GPT 6 Sol xHigh. Pass [references/reflect-synthesizer.md](../references/reflect-synthesizer.md) verbatim with each reviewer's full output inlined where marked. It returns an Accepted, Rejected, and Backlog list.

#### 4. Structural enforcement check

Sanity-check the Accepted list. Any item a lint rule, script, metadata flag, install check, or runtime check would enforce more reliably moves to Backlog, per [Encode Lessons in Structure](../principles/encode-lessons-in-structure.md).

#### 5. Route the output

Default is one small PR. When Agustín says the garden, or the Accepted list is thin enough that a PR would be noise, use the garden instead.

**One small PR.** Apply the Accepted rows in one worktree of the repo that holds most of them, per [Authoring a skill](authoring-a-skill.md) and [Opening a PR](opening-a-pr.md). This PR is the one exception to one skill change per PR. It carries only this run's Accepted rows. Rows for the other repo go into the PR body as a garden hand-off. Map installed paths the reviewers cite back to their source (`skills/<name>/` in `amillez/agent-skills`) before editing.

- Trivial edit (a one-line bullet, a tightened sentence, a stale fact corrected) → edit directly.
- Substantive edit (a new section, a new pattern table, more than about 10 lines) → run the full [Authoring a skill](authoring-a-skill.md) loop for it.
- `tune description: <skill path>` → rewrite the description so it front-loads the missed trigger, then validate per Authoring a skill.
- `new skill: <kebab-name>` → do not create it in this PR. List it under Backlog.

The PR body holds the synthesizer's full output. Agustín reviews row by row and drops what he rejects. Never merge it, arm auto-merge, or close it.

**Weekly garden.** Open no PR. Put the synthesizer's full output in your reply under the heading "For the weekly ai-eng-practices garden", with each row's routing and evidence, and stop. The garden run turns it into edits. Filing it anywhere else (an issue, a chat post) is a message and waits for Agustín per the always-pause list.

Backlog items never auto-file. List them in the PR body or the garden hand-off.

#### 6. Reply

Short list, no preamble.

- PR opened: the URL, and one line per edit (`<repo path>`, what changed). Or "handed to the garden".
- New skills proposed: one line each (rare).
- Backlog: one line each, with the suggested mechanism.
- Dropped: one line per rejected finding with the synthesizer's reason.

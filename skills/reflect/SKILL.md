---
name: reflect
description: >-
  Mine a finished Claude Code or Codex session log for durable learnings with
  three reviewers on different model lanes, then route each one to a concrete
  edit on an existing skill or ai-eng-practices doc. The result goes out as one
  small PR for review or as a hand-off to the weekly garden. Use for "reflect",
  "reflect on this session", or "reflect on session <id>".
disable-model-invocation: true
---

# Reflect

Mine a finished Claude Code or Codex session for durable learnings, route each to a concrete edit on an existing skill or ai-eng-practices doc, and hand the result to Agustín as one small PR or as input to the weekly ai-eng-practices garden. Use when Agustín says "reflect", "reflect on this session", or "reflect on session <id>". Skip when the session was trivial, off-topic, or already covered by a skill the agent followed correctly. One-offs are not learnings.

Never edit skills in place. Installed copies under `~/.claude/skills/` and `~/.agents/skills/` are overwritten by the next install and never reviewed. Every edit lands in a worktree of `amillez/akit` or `amillez/ai-eng-practices`.

The one PR in step 5 is the only thing this skill publishes. Never post or file anything else anywhere (issues, chat), and never merge, arm auto-merge, or close the PR.

## Lanes

| Role | Lane | `orca agent launch` flags |
| --- | --- | --- |
| Judgment and Divergent reviewers | Opus 5.5, High. Claude Code usage above 70% → Grok 4.7, xHigh on the Cursor Agent CLI, read-only. | `--agent claude --model claude-opus-5-5 --effort high`, or `--agent cursor --model grok-4.7-xhigh` |
| Tooling reviewer | GPT 6.1 Sol, xHigh, always, so the panel spans two model families. | `--agent codex --model gpt-6.1-sol --effort xhigh` |
| Synthesizer | Opus 5.5, xHigh. Usage does not move it. If Claude Code is exhausted, say so and use Grok 4.7, xHigh on the Cursor Agent CLI. | `--agent claude --model claude-opus-5-5 --effort xhigh` |

Check Claude Code usage with `/usage` or `/status` before the launch. The lanes follow the [agent use policy](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#agent-chooser-examples). When the policy changes a lane, the policy wins over this table. Never GPT 5.6 or Opus 5.

Reviewers and the synthesizer need MCP access for context the log references (issues, PRs, chat threads, error traces). Launch each one as a tab in your Orca worktree per [Orca launches](../amillez-mode/references/orca-launch.md), which runs the CLI under your user config.

## 1. Locate the finished session log

Claude Code keeps sessions under `~/.claude/projects/<project>/` as `<session-id>.jsonl`, where `<project>` is the working directory with `/` replaced by `-`. Codex keeps them under `~/.codex/sessions/<yyyy>/<mm>/<dd>/` as `rollout-*.jsonl`.

```bash
ls -t ~/.claude/projects/<project>/*.jsonl 2>/dev/null | head -5
ls -t ~/.codex/sessions/*/*/*/rollout-*.jsonl 2>/dev/null | head -10
```

Read only the session you were asked about, never unrelated projects. For each candidate, read its first user message and check it is the session's opening prompt (for Codex, also check the working directory recorded in the first line). Take the matching path. Include subagent logs the harness keeps next to the session. If no path resolves, write a tight digest of the session and pass that instead.

## 2. Run three reviewers in parallel

Each reviewer is a fresh Orca tab on its lane with its own lens. Pass each template verbatim, substituting the log path or digest where marked. Reviewers read and look up context only. They never write code or edit skills.

| Lens | Template |
| --- | --- |
| Judgment | [references/judgment-reviewer.md](references/judgment-reviewer.md) |
| Tooling | [references/tooling-reviewer.md](references/tooling-reviewer.md) |
| Divergent | [references/divergent-reviewer.md](references/divergent-reviewer.md) |

Create a scratch dir outside any worktree and write the three filled templates to `$out/judgment.md`, `$out/tooling.md`, and `$out/divergent.md`. Then launch all three at once inside your own Orca worktree session with `--worktree path:<your worktree>`, never in a new child worktree. Each reviewer writes its output next to its brief. Wait for all three, then close their tabs, and check they are gone per [Orca launches](../amillez-mode/references/orca-launch.md#run-a-review-in-the-same-worktree). When usage moved the Judgment and Divergent lane, swap in its Cursor Agent CLI flags.

```bash
out=$(mktemp -d)
# write the three filled templates to $out here
launch() {
  local lens=$1; shift
  orca agent launch "$@" --worktree "path:$(git rev-parse --show-toplevel)" --surface terminal --json --prompt "$(cat "$out/$lens.md")

You are read-only. Do not edit, commit, or push anything. Write your full output to $out/$lens.out and nothing else." \
    | jq -r .result.outcome.handle > "$out/$lens.handle"
}
launch judgment --agent claude --model claude-opus-5-5 --effort high
launch tooling --agent codex --model gpt-6.1-sol --effort xhigh
launch divergent --agent claude --model claude-opus-5-5 --effort high
for lens in judgment tooling divergent; do
  h=$(cat "$out/$lens.handle")
  until [[ -s "$out/$lens.out" ]]; do sleep 10; done
  orca terminal wait --terminal "$h" --for tui-idle --timeout-ms 590000 --json > /dev/null
  orca terminal close --terminal "$h" --tab --json > /dev/null
done
```

## 3. Synthesize

Launch one fresh Orca tab on the synthesizer lane the same way (`launch synthesizer --agent claude --model claude-opus-5-5 --effort xhigh`), with `$out/synthesizer.md` holding [references/synthesizer.md](references/synthesizer.md) verbatim and each reviewer's full output inlined where marked. Wait for `$out/synthesizer.out`, then close the tab. It returns an Accepted, Rejected, and Backlog list.

## 4. Structural enforcement check

Sanity-check the Accepted list. Move any item a lint rule, script, metadata flag, install check, or runtime check would enforce more reliably to Backlog. Skill prose is only for rules a mechanism cannot enforce. [Encode Lessons in Structure](../amillez-mode/principles/encode-lessons-in-structure.md) has the full rule.

## 5. Route the output

Default is one small PR. When Agustín says the garden, or the Accepted list is thin enough that a PR would be noise, use the garden instead. Rows about lanes, host, merge, proof bar, or team practice belong to the `amillez/ai-eng-practices` doc that owns them, not to a skill.

**One small PR.** Apply the Accepted rows in one fresh worktree and branch of the repo that holds most of them, off its current `main`. Map installed paths the reviewers cite back to their source (`skills/<name>/` in `amillez/akit`) before editing. The PR may touch several skills, and it carries only this run's Accepted rows. Rows for the other repo go into the PR body as a garden hand-off.

- Trivial edit (a one-line bullet, a tightened sentence, a stale fact corrected) → edit directly.
- Substantive edit (a new section, a new pattern table, more than about 10 lines) → write it as a full skill edit, then check the frontmatter still has `name` and `description` and every file it links exists.
- `tune description: <skill path>` → rewrite the description so it front-loads the missed trigger, then check the frontmatter.
- `new skill: <kebab-name>` → do not create it in this PR. List it under Backlog.

Run the repo's own checks (in `amillez/akit`, `./scripts/check-links.sh` and `./scripts/test-install.sh`), commit, push the branch, and open the PR with `gh pr create`. The PR body holds the synthesizer's full output, and Agustín reviews it row by row. [Authoring a skill](../amillez-mode/playbooks/authoring-a-skill.md) and [Opening a PR](../amillez-mode/playbooks/opening-a-pr.md) hold the full loops.

**Weekly garden.** Open no PR. Put the synthesizer's full output in your reply under the heading "For the weekly ai-eng-practices garden", with each row's routing and evidence, and stop. The garden run turns it into edits.

Backlog items never auto-file. List them in the PR body or the garden hand-off.

## Reply

Short list, no preamble.

- PR opened: the URL, and one line per edit (`<repo path>`, what changed). Or "handed to the garden".
- New skills proposed: one line each (rare).
- Backlog: one line each, with the suggested mechanism.
- Dropped: one line per rejected finding with the synthesizer's reason.

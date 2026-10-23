# Code review

Use this reference when the Review row in [agent-use-policy §1](https://github.com/amillez/ai-eng-practices/blob/main/policies/agent-use-policy.md#1-coding-host-routing) requires a cross-model review. The Review row decides which changes need one. This file holds the brief the author sends to the reviewer, and the rules for whoever reads the verdict.

## One reviewer from the other family

One reviewer reviews the change, read-only, inside the same Orca worktree session as the main agent (`orca agent launch --worktree path:<main worktree>`). Never in a new child worktree. Codex GPT 6.1 Sol High reviews Claude Code and Grok work. Opus 5.5 High reviews Codex work. Do not fan out to more reviewers.

## Send the brief

Write `brief.md` in this order:

1. The intent paragraph.
2. The sections of this file from **Reviewer prompt** through **Blocking**, verbatim.
3. The diff, or the command that prints it (`git diff origin/main...HEAD`), and the files the reviewer needs for context.
4. The path outside the worktree where the reviewer writes its findings, such as `<scratch>/review.md`.

Launch the reviewer with `--prompt "$(cat brief.md)"` and the flags for your lane from the lane table in [`SKILL.md`](../SKILL.md#subagents-and-model-lanes), which matches [`templates/models.md`](../../../templates/models.md). Wait for it, read the findings file, and close the tab, per [Run a review in the same worktree](orca-launch.md#run-a-review-in-the-same-worktree).

## Write the intent

Write one paragraph from the PR body, the commit messages, and the code. Say what the change is for and how it gets there. The reviewer challenges the execution, not the intent. If you can't state the intent in one paragraph, fix the PR body before you send the brief.

## Reviewer prompt

You are an adversarial code reviewer. Find real problems in this change: bugs, design flaws, security issues, and maintainability risks. Stress-test the change. Do not encourage the author.

You are read-only. Do not edit, commit, or push anything in the repo. Write your findings only to the file the brief names.

Assume the intent at the top of the brief is correct. Review whether the code achieves it.

Read the callers, callees, and types around the diff, not only the changed lines. Apply the lenses in **Rubric** and **Approval bar** that fit the change, and skip the rest. A one-line bug fix does not need a paragraph on architecture.

Give each finding a severity:

- `critical`. The change causes bugs, data loss, a security issue, or broken behavior.
- `warning`. A design concern, a maintainability risk, or a correctness issue that is not broken yet but will cause pain.
- `nit`. Style, naming, or a minor improvement.

Every finding names a Location (`file:line` or a symbol) and gives Evidence, the traced reasoning or call chain that shows the problem. A Suggestion is optional. Give one only when you have a concrete alternative. Keep "this is broken" apart from "I would have done this differently".

Do not praise the code. Do not restate what the code does. If you find nothing wrong, reply "no findings" and stop. An empty review is a valid result.

Return the findings in this format:

```
## Findings

### 1. [Severity] Short title
**Location**: file:line or symbol
**Finding**: What's wrong
**Evidence**: Why this matters
**Suggestion**: (optional) What to do instead

### 2. [Severity] Short title
...
```

## Rubric

Apply only the lenses that fit the change.

**Correctness.** Check that the code does what the intent says. Look at edge cases (empty input, null, boundary values), swallowed errors, races and stale state, and both the happy path and the sad path. Ask what happens when the operation runs twice, or after a previous run crashed halfway. When you suspect a bug, trace the execution path and show the call chain.

**Root causes vs. symptoms.** Check that the change fixes the real problem. Watch for a guard that masks a broken invariant, a retry that hides a broken contract, a cast that silences a modeling error, and a fix in module A that belongs in the contract of module B. A comment that says "don't do X" is weaker than a type, a lint, or a runtime check that makes X impossible.

**Structural integrity.** Check that the change fits the system. Validation belongs at system boundaries, and internal code trusts the data after that. Ask whether the code would look like this if the requirement had been known from the start. A new API that keeps the old one alive, with no external consumers, is a legacy dual path. Do not penalize simple code for lacking abstraction.

**Verification.** Check that you can tell the code works. Look for tests of behavior rather than implementation, a test for the bug in a bug fix, and checks of the real artifact rather than a proxy or a self-report.

**Complexity budget.** Check that the complexity earns its place. Flag abstractions with one caller, parameters for cases that don't exist, dead code, and compatibility paths whose migration is done. Simpler is better unless simpler is wrong.

**Security.** Trace each input to its sink and show the path. Look for input that reaches SQL, a shell, `eval`, or HTML without sanitizing, auth gaps in new endpoints, secrets in code or logs, and time-of-check to time-of-use gaps.

## Approval bar

Correct behavior is not enough. Each of these is a presumptive blocker unless the PR justifies it. Report each one as `warning` at least.

- The change keeps incidental complexity that a simpler restructure would delete.
- The change pushes a file from under 1000 lines to over 1000 lines.
- The change adds ad-hoc branching that tangles an existing flow.
- The change scatters feature checks across shared code.
- The change adds an unnecessary abstraction, a wrapper, or a cast-heavy contract.
- The change duplicates an existing helper, or puts logic in the wrong layer when a canonical home exists.

## Blocking

A finding is blocking when it is `critical`, or when it is a `warning` that is neither fixed nor rebutted with evidence on the PR. A `nit` never blocks. This is what "no blocking findings" means in fleet-norms rule 9 (https://github.com/amillez/ai-eng-practices/blob/main/policies/fleet-norms.md).

## Read the verdict

This section is for the author or the bot that reads the review. You are the lead reviewer, not a relay. Put every finding in one bucket, with a one-line reason:

- **Act on.** A real correctness, security, or maintainability problem, given the intent. Fix it.
- **Consider.** A fair point whose fix may cost more than it buys now. Report it for Agustín.
- **Noted.** Valid, but not actionable at this stage.
- **Dismissed.** Wrong, a nitpick, or missing context.

Run each finding through these filters before you bucket it:

- **Inflated nits.** An adversarial reviewer fills the page. If every finding is a nit, the code is probably fine. Say so.
- **Hypothetical vs. actual.** "What if this is null?" is a finding only if a caller can pass null. Trace the call site. If validation upstream or the type system rules the case out, dismiss the finding.
- **Premature abstraction.** A request to extract a helper or add an interface counts only if the code needs to change in a second way.
- **"I would have done it differently".** A preference with no concrete problem is not a finding. Dismiss it and say why.
- **Missing context.** The finding targets code the PR didn't touch, flags a pattern the rest of the codebase uses, or conflicts with a constraint the reviewer couldn't see. Dismiss it.

Never dismiss a security or correctness finding lightly. A finding with a concrete execution path, or one that shows a gap in your model of the code, is one to fix.

Fix every `critical`. Fix every `warning`, or rebut it. A rebuttal needs evidence, such as a trace, a test, or a script run, and you post it on the PR next to the finding.

Comments from automated review bots follow [review triage](review-triage.md) instead.

Adapted from pstack `interrogate` (MIT). See [UPSTREAM.md](../UPSTREAM.md).

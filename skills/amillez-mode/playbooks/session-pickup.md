### Session pickup

**You own the resume point. Read the prior trail, don't redo it.**

1. Locate the prior trail: the resume note or handoff message you were given, the pushed branch and its PR, and the prior agent's session log when you can reach it (Claude Code keeps sessions under `~/.claude/projects/<project>/`, Codex under `~/.codex/sessions/`). Read only the session for this task, never unrelated projects. Read the last messages first, then scan back for the decision points. Parse a long log in a subagent and keep the reduced timeline in the main thread ([Guard the Context Window](../principles/guard-the-context-window.md)).
2. Reconstruct operational state. The branch and worktree, what already landed (`git log`, `git diff` against the base, `gh pr view`), the open todos, the decisions made, and any review threads still open. The prior trail is authoritative input. Resist the bias to re-derive it.
3. Diff done vs pending. Compare what shipped against what was planned, name the resume point, do not re-run the prior repro or redo completed work. A "let me verify from scratch" pass means you're treating the trail as untrustworthy when it's authoritative.
4. Route the remaining work to the matching playbook and pick the verdict: continue the execution, ship a finished recommendation, ratify or override a prior conclusion, or postmortem a failed run. The pickup playbook ends here. The routed playbook owns the rest.
5. Verify the inherited claims against the original goal on the real artifact ([Prove It Works](../principles/prove-it-works.md)). A passing prior self-report is not the proof.

**Reply:** where the prior agent stopped, what you inherited vs redid (ideally nothing redone), the resume point, and the outcome.

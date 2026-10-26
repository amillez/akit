# blast-radius upstream

`blast-radius` is our port of poteto's `blast-radius` skill from pstack. It is a separate core skill that holds the whole procedure, so `/blast-radius` runs without loading any other skill.

## Source

| Field | Value |
| --- | --- |
| Repo | https://github.com/cursor/plugins |
| Path | `pstack/skills/blast-radius/SKILL.md` |
| Compared against | `e73df471cd4bd918367e99f3dd9c51bd53ddf5f0` (pstack `0.15.32`). The file last changed in `df581122cde17e6e27686b5a448bde23e4ad4318` (2026-10-05), where step 6 became "Ask more than one model". Local change 6 replaces that line. |
| License | MIT, Copyright (c) 2026 Lauren Tan. Full text in [`LICENSE-pstack`](LICENSE-pstack), copied byte-for-byte from `pstack/LICENSE`. |

The pstack pin is tracked in [`../amillez-mode/UPSTREAM.md`](../amillez-mode/UPSTREAM.md). Revisit together.

Attribution: the one-safety-fact method, the proof ladder, the steps, and the handback shape are poteto's (Lauren Tan) work under MIT. Keep `LICENSE-pstack` next to them.

## Local changes

1. **Frontmatter.** Kept `name`, the description's triggers ("blast radius of X", "what could this break", a small diff you don't trust) for Codex, which reads only `name`, `description`, and `metadata`, and `disable-model-invocation: true`, since `/blast-radius` is explicit-invoke.
2. **Sections.** The `### How sure are you` subsection becomes a `##` section beside the others.
3. **how and why.** The `how` and `why` companions → amillez-mode's Investigation playbook. "Use `why` step 2" → `gh pr view`, `gh pr diff`, `git log -S`, and `git blame`. "Same rules as `why`" is dropped, since the rules that follow it are spelled out.
4. **Solid versus React.** → render versus effects, the JS thread versus native modules.
5. **Proof.** Ladder step 5 names Argent on a simulator or emulator, or the project's `verify-*` skill. Step 5 of the procedure keeps the proof script in a scratch dir outside the worktree unless it earns a place as a regression test.
6. **Arena.** "Run it as an `arena`" → the same prompt to a read-only Codex reviewer on GPT 6.1 Sol High, with the merged answers and agreement as high-signal. Adds the size gate. A change that needs several workers stops and is reported, and large work runs as an Orca Run through `orchestrate-agents`.
7. **unslop.** "Write it through `unslop`" → a link to the sibling [`unslop`](../unslop/SKILL.md) skill.
8. **Sibling links.** Optional relative links to amillez-mode's Investigation playbook and Prove It Works principle, and to the `orchestrate-agents` and `unslop` skills. amillez-mode is core and installs beside this skill, so the links resolve in the repo and after install. The skill never requires loading amillez-mode.
9. **Skill text only.** `SKILL.md` names no host and carries no attribution. Attribution lives here.

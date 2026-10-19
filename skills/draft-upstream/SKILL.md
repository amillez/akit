---
name: draft-upstream
description: >-
  Draft an issue or pull request for a third-party open-source repo. Search
  upstream for duplicates, build a minimal public repro, scrub private details,
  unslop the text, and open the draft only in the amillez fork. Filing upstream
  stays a human action. Use when asked to report a bug, request a feature, or
  send a fix to a repo the user does not own, or before any issue, PR, or
  comment on such a repo.
---

# Draft upstream

You write the draft and Agustín files it upstream. Never create an issue, PR, comment, review, or reaction on the upstream repo, and never run `gh` against it with a write command. Upstream reads (search, view, clone) are fine.

## 1. Search for duplicates

Search open and closed issues and PRs with the error text, the API name, and two or three paraphrases:

```bash
gh search issues --repo <owner>/<repo> --include-prs "<terms>"
gh issue list --repo <owner>/<repo> --state all --search "<terms>"
gh pr list --repo <owner>/<repo> --state all --search "<terms>"
```

A match stops the draft. Report its URL. If you hold something it lacks, such as a smaller repro, a newer affected version, or a root cause, write a comment draft for Agustín instead. If a closed match says "fixed in X", check the version you hit before you go on. Link near matches in the draft.

## 2. Build a minimal public repro

Make the smallest standalone project or snippet that shows the problem. Start from the upstream's own template or example app when it has one. Use public dependencies only, pin the versions you ran, and run the repro yourself to confirm it fails as described. A fix PR also needs the upstream's test command passing on your branch.

Read the upstream's `CONTRIBUTING.md` and `.github/ISSUE_TEMPLATE` or PR template, and fill their fields.

Scrub the repro, title, body, logs, and screenshots. Each line must hold:

- [ ] No private repo, org, or package names.
- [ ] No company, client, product, or codename.
- [ ] No internal URLs, hostnames, machine names, IPs, or staging domains.
- [ ] No bot or agent names, including the `<bot>` part of `agent/<bot>/<slug>` branch names.
- [ ] No fleet names (`agent-m1`, `favvy`, `KaikuLabs`, or any bot name). No private emails, including commit author emails other than Agustín's public GitHub one.
- [ ] No disk or volume identifiers, such as `/dev/disk4s2` or a private volume name.
- [ ] No tokens, keys, cookies, or env values. Check stack traces and config dumps too.
- [ ] No customer or user data, emails, IDs, or real names other than public maintainers.
- [ ] No local or internal paths. `/Users/<name>/work/<private-repo>` becomes `/path/to/app`.
- [ ] No Slack, Notion, Linear, Jira, or internal doc links.
- [ ] No private context in the code. The repro carries only what it needs to fail.

Then grep the draft for the names you know are private before you go on.

### Optional: publish a repro repo

Use a public repro repo when a snippet cannot show the problem, such as a UI bug that needs screenshots or a fix that maintainers want to run. Create it only when the user asked for one in this task, because everything in a public repo is published.

- Name it `amillez/<repo>-<slug>-repro`. Start from a fresh `git init`, with no history copied from another repo.
- `main` shows the bug. Its README gives the run steps and the result you see.
- `with-fix` branches from `main` and adds only the fix. Its README gives the expected result.
- Commit each screenshot under `screenshots/` on the branch it shows. Link it from the draft as `https://github.com/amillez/<repo>-<slug>-repro/blob/<branch>/screenshots/<file>?raw=true`.

Before the first push, run the scrub checklist on every file, commit message, and author line on both branches. Open each screenshot and check its status bar, window title, device name, and notifications. Then grep the full history, author lines and commit messages included, for the private names you know and for every email address:

```bash
git log --all --format='%an %ae%n%B' -p | grep -inE 'agent-m1|favvy|kaikulabs|<bot>|<private-repo>|disk[0-9]|token|secret|@[a-z0-9.-]+\.[a-z]{2,}'
```

The grep prints every author line, since each one holds an email. Check every email it prints by hand. Only Agustín's public GitHub email may stay, and every other line it prints is a leak to remove before the push.

Publish only after the scrub passes:

```bash
gh repo create amillez/<repo>-<slug>-repro --public --source . --push
git push origin with-fix
```

## 3. Unslop

Run the [`unslop`](../unslop/SKILL.md) skill on the title and body. Open the file directly, since it is not on the Skill tool's list. Keep the body short: what happened, what you expected, the repro, versions, and what you tried.

## 4. Open the draft in the fork

Confirm the fork exists and points at upstream:

```bash
gh api repos/amillez/<repo> --jq .parent.full_name   # must print <owner>/<repo>
```

If it is missing or its parent differs, say so and stop. Do not fork, rename, or create a repo unless the user asked for that in this task.

- **Issue.** `gh issue create --repo amillez/<repo>`. If the fork has issues disabled, say so and stop. Do not change its settings.
- **Fix.** Push a topic branch to the fork and run `gh pr create --draft --repo amillez/<repo> --base <fork-branch> --head <topic>`. Always pass `--repo`, because `gh` defaults a fork's PR to the parent repo. Sync the base first with `gh repo sync amillez/<repo> --branch <fork-branch>`, and never pass `--force`.

Every commit is a plain commit by Agustín's GitHub user (`amillez`). Remove any AI `Co-authored-by` trailer, and keep "Generated with" lines out of commit messages and the PR body.

In a fork checkout of a third-party repo, turn off Claude Code's attribution before the first commit. Write `.claude/settings.json` at the checkout root:

```json
{ "attribution": { "commit": "", "pr": "" } }
```

Exclude the file so it never reaches the upstream PR. The `--git-path` form also works in a worktree:

```bash
echo .claude/settings.json >> "$(git rev-parse --git-path info/exclude)"
```

If upstream already tracks `.claude/settings.json`, put the key in `.claude/settings.local.json` and exclude that file instead. Do this only in forks of third-party repos. Our own repos under `amillez` and `KaikuLabs` keep their `Co-Authored-By` trailers. An `amillez` fork of someone else's repo counts as third-party.

The setting covers only Claude Code, so the `git log` check stays the backstop. Before you push, run `git log --format='%an <%ae>%n%b' <fork-branch>..HEAD` and confirm every author is Agustín and no trailer is left.

Check that the URL `gh` prints starts with `https://github.com/amillez/`. If it does not, stop and report it.

## 5. Report

End with:

1. The fork draft URL.
2. Duplicates and near matches found, with URLs, or "none found" with the search terms.
3. The exact upstream title and body in a fenced block, ready to paste.
4. For a fix, the branch, the upstream base branch, and the test command you ran with its result.
5. The scrub checklist with each line checked.
6. The repro repo URL, if you published one.

Filing upstream is Agustín's action, not yours.

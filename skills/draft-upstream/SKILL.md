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
- [ ] No internal URLs, hostnames, IPs, or staging domains.
- [ ] No tokens, keys, cookies, or env values. Check stack traces and config dumps too.
- [ ] No customer or user data, emails, IDs, or real names other than public maintainers.
- [ ] No local or internal paths. `/Users/<name>/work/<private-repo>` becomes `/path/to/app`.
- [ ] No Slack, Notion, Linear, Jira, or internal doc links.
- [ ] No private context in the code. The repro carries only what it needs to fail.

Then grep the draft for the names you know are private before you go on.

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

Every commit is a plain commit by Agustín's GitHub user (`amillez`). Remove any AI `Co-authored-by` trailer, and keep "Generated with" lines out of commit messages and the PR body. Before you push, run `git log --format='%an <%ae>%n%b' <fork-branch>..HEAD` and confirm every author is Agustín and no trailer is left.

Check that the URL `gh` prints starts with `https://github.com/amillez/`. If it does not, stop and report it.

## 5. Report

End with:

1. The fork draft URL.
2. Duplicates and near matches found, with URLs, or "none found" with the search terms.
3. The exact upstream title and body in a fenced block, ready to paste.
4. For a fix, the branch, the upstream base branch, and the test command you ran with its result.
5. The scrub checklist with each line checked.

Filing upstream is Agustín's action, not yours.

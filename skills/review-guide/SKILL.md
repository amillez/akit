---
name: review-guide
description: >-
  Build one self-contained HTML reviewer guide for a pull request from the
  material the run already produced, publish it as an Orca artifact, and link
  it from the PR body. Nothing goes into git. Use when opening or updating a
  non-trivial PR, and to delete the artifact when the PR merges or closes.
  Skip docs-only PRs.
---

# Review guide

The guide lets a reviewer read a PR in order of risk without asking the author anything. Build it only from what the run already produced: the decision trail, commits, proof files, logs, and the commands you ran. Do not start review sessions, capture new proof, or rerun work to fill it.

Skip it for docs-only PRs. Skip trivial PRs too, such as a typo or a version bump with no code change, unless they carry visual proof. The guide is the only place proof is published.

## 1. Build the file outside git

Write one HTML file to `~/agent-work/proof/<slug>/review-guide.html`, next to the run's local proof. Never commit it. No `REVIEW.md`, no screenshots on any branch, and no media branch for the guide. Keep the same path for the life of the PR, because `orca artifacts update` finds the artifact by that path.

Use these sections in this order. Number them as written.

1. **Summary and risk.** What the PR does in two or three sentences, and a risk level (low, medium, or high) with the reason.
2. **What changed and why.** From the [`show-me-your-work`](../show-me-your-work/SKILL.md) trail when the run kept one, else from the commits and the plan. One line per decision with its reason.
3. **Blast radius.** Who or what the change touches beyond the diff, and the one fact it is safe because of. Take it from the [`blast-radius`](../blast-radius/SKILL.md) output when that skill ran. Mark the fact unproven when nothing proved it.
4. **Proof.** Each screenshot, video still, or log excerpt with a pass or fail note against the success criteria. Say what matched and what didn't.
5. **How to reproduce.** The `verify-<app>` commands, or the exact commands you ran, in code blocks.
6. **Review order.** Critical files first. Each entry links to the exact lines at the PR head SHA, as `https://github.com/<owner>/<repo>/blob/<head-sha>/<path>#L<start>-L<end>`. Get the SHA with `gh pr view <number> --json headRefOid -q .headRefOid`.
7. **Critical parts and why they matter.** The few hunks a reviewer must not skim, and what breaks if they are wrong.
8. **Diagrams.** Only when the change spans several modules or changes a flow. Draw an architecture diagram by hand as inline SVG or HTML and CSS, in the style of [`references/diagram-style.html`](references/diagram-style.html):
   - Light by default, with dark colors only under `prefers-color-scheme: dark`. Never dark-only.
   - One horizontal band per package or layer, labelled top-left with a subtitle. Label sub-layers such as ui, domain, and data-access on the left.
   - Each box has a bold title and a muted monospace or plain detail line.
   - Label each arrow with the call or method it stands for.
   - Fill the boxes this PR touches in teal and draw their arrows in teal. Draw later or deferred PR work in dashed purple.
   - Put a caption of 2 to 4 sentences under the diagram that states the key invariants, and a small legend.
   - Use no external libraries.

   Use Mermaid only as a quick fallback for a trivial flow. For a state machine, prefer pstack's statechart and diagram companion skill by poteto once it ships.

Keep the file self-contained:

- Downscale each screenshot, then embed it as a data URI:

  ```bash
  sips -Z 1200 -s format jpeg -s formatOptions 70 shot.png --out shot.jpg
  printf 'data:image/jpeg;base64,%s' "$(base64 < shot.jpg | tr -d '\n')"
  ```

- For the Mermaid fallback only, render it in the browser from a pinned CDN build, such as `<script type="module">import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.esm.min.mjs'; mermaid.initialize({ startOnLoad: true });</script>`.
- Use no other relative or external assets. `orca artifacts` uploads only the HTML file.
- Keep the file under about 800 KiB. Check with `wc -c < review-guide.html`. The service rejects files over 10 MiB.

## 2. Scrub before you share

The guide is link-only. Its slug is 12 unguessable characters, no public listing shows it, it expires after 30 days, and `orca artifacts delete <id>` revokes it at once. Anyone who has the link can open it without signing in, and a link can be forwarded. The page is not marked `noindex`, so a link that leaks onto an indexed page can be crawled.

- Leave secrets, tokens, keys, cookies, and env values out of screenshots, logs, and code snippets.
- Leave personal user data out, such as real names, emails, phone numbers, and account IDs.

Open every embedded image and check it before you share.

## 3. Share and link it

```bash
orca artifacts share ~/agent-work/proof/<slug>/review-guide.html --json > ~/agent-work/proof/<slug>/review-guide.share.json
```

Read the artifact id and the URL from the JSON result and keep the file. The id is what `delete` needs. If you lose it, `orca artifacts list --json` lists the account's artifacts with their ids.

Facts about the link, verified 2026-10-29:

- The URL is `https://share.onorca.dev/a/<slug>`, where the slug is 12 unguessable characters.
- It expires 30 days after sharing. For a PR open longer, share again and replace the link in the PR body per [Keep the link in sync](#keep-the-link-in-sync).
- `orca artifacts delete <id>` revokes it at once.

The PR body keeps its usual sections short. They cover guide sections 1 to 4.

### Add the link to the PR body

This step is required. Run it right after `share`, as its own command. Never chain it with `gh pr checks --watch` or any other command, since a long or failing command in the chain hides whether the body changed.

Keep the existing body exactly and append one `## Review guide` section with the link and the date it expires. Fetch the body with `jq -j`, since `-q .body` adds a trailing newline that each edit would store:

```bash
f=~/agent-work/proof/<slug>/pr-body.md
gh pr view <number> --json body | jq -j .body > "$f"
printf '\n\n## Review guide\n\n%s (expires %s)\n' '<url>' '<YYYY-MM-DD>' >> "$f"
gh pr edit <number> --body-file "$f"
```

Then check that the link landed:

```bash
gh pr view <number> --json body -q .body | grep -F '<url>'
```

If `grep` prints nothing, run the edit again. If `gh pr edit` exits non-zero, for example with `GraphQL: Projects (classic) is being deprecated`, it has not changed the body. Write the same file through the REST API instead, then check again:

```bash
gh api -X PATCH repos/<owner>/<repo>/pulls/<number> -F body=@"$f"
```

### When sharing fails

A human enables publishing per host in Orca under **Settings > Artifacts**. There is no CLI way to turn it on.

- `artifact_sharing_disabled` means publishing is off on this host.
- `sharing_unavailable_on_host` means the host is headless and cannot share.

Do not retry either error. Put a text-only guide in the PR body instead, with sections 5 to 8 added after the usual sections. GitHub strips inline SVG from the PR body, so draw section 8 there as a Mermaid block. Images stay local under `~/agent-work/proof/<slug>/`, so describe each one in its pass or fail note. Also say in the PR body and your reply that sharing failed and why.

## 4. Update on each push

After each push to the PR branch, regenerate the guide at the same path with the new head SHA, then run:

```bash
orca artifacts update ~/agent-work/proof/<slug>/review-guide.html --json
```

`update` works only from the same file path and the same Orca profile that shared the file. On another host or profile, run `orca artifacts delete <id> --json`, share again, and replace the link in the PR body and the saved id.

### Keep the link in sync

After each `update` or new share, make the PR body match the current URL and expiry date. A new share always has a new URL. Replace the line in the existing `## Review guide` section and never add a second section:

```bash
f=~/agent-work/proof/<slug>/pr-body.md
gh pr view <number> --json body | jq -j .body > "$f"
sed -i '' 's|https://share.onorca.dev/a/.*|<url> (expires <YYYY-MM-DD>)|' "$f"
gh pr edit <number> --body-file "$f"
```

Then run the same `grep -F` check, with the same retry and `gh api` fallback as in [Add the link to the PR body](#add-the-link-to-the-pr-body). Also check that `gh pr view <number> --json body -q .body | grep -c '^## Review guide'` prints `1`.

## 5. Delete after merge or close

When the PR merges or closes, run `orca artifacts delete <id> --json` as part of task cleanup, before the worktree is removed. [Close a session](../amillez-mode/references/orca-launch.md#close-a-session) lists the step.

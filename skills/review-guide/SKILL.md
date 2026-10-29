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
8. **Diagrams.** Only when the change spans several modules or changes a flow. Use Mermaid by default. When pstack ships poteto's statechart and diagram companion skill, prefer it.

Keep the file self-contained:

- Downscale each screenshot, then embed it as a data URI:

  ```bash
  sips -Z 1200 -s format jpeg -s formatOptions 70 shot.png --out shot.jpg
  printf 'data:image/jpeg;base64,%s' "$(base64 < shot.jpg | tr -d '\n')"
  ```

- Render Mermaid in the browser from a pinned CDN build, such as `<script type="module">import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.esm.min.mjs'; mermaid.initialize({ startOnLoad: true });</script>`, or inline an SVG.
- Use no other relative or external assets. `orca artifacts` uploads only the HTML file.
- Keep the file under about 800 KiB. Check with `wc -c < review-guide.html`. The service rejects files over 10 MiB.

## 2. Scrub before you share

The link is public. Anyone with it can open the page without signing in, and the page is not marked `noindex`.

- Leave secrets, tokens, keys, cookies, and env values out of screenshots and logs.
- Leave personal user data out, such as real names, emails, phone numbers, and account IDs.
- Link to code instead of pasting it, since the repo may be private.

Open every embedded image and check it before you share.

## 3. Share and link it

```bash
orca artifacts share ~/agent-work/proof/<slug>/review-guide.html --json > ~/agent-work/proof/<slug>/review-guide.share.json
```

Read the artifact id and the URL from the JSON result and keep the file. The id is what `delete` needs. If you lose it, `orca artifacts list --json` lists the account's artifacts with their ids.

The PR body keeps its usual sections short. They cover guide sections 1 to 4. Add a `## Review guide` section with the link and the date it expires.

Facts about the link, verified 2026-10-29:

- The URL is `https://share.onorca.dev/a/<slug>`, where the slug is 12 unguessable characters.
- It expires 30 days after sharing. For a PR open longer, share again and replace the link in the PR body.
- `orca artifacts delete <id>` revokes it at once.

### When sharing fails

A human enables publishing per host in Orca under **Settings > Artifacts**. There is no CLI way to turn it on.

- `artifact_sharing_disabled` means publishing is off on this host.
- `sharing_unavailable_on_host` means the host is headless and cannot share.

Do not retry either error. Put a text-only guide in the PR body instead, with sections 5 to 8 added after the usual sections. GitHub renders Mermaid blocks in the PR body. Images stay local under `~/agent-work/proof/<slug>/`, so describe each one in its pass or fail note. Also say in the PR body and your reply that sharing failed and why.

## 4. Update on each push

After each push to the PR branch, regenerate the guide at the same path with the new head SHA, then run:

```bash
orca artifacts update ~/agent-work/proof/<slug>/review-guide.html --json
```

`update` works only from the same file path and the same Orca profile that shared the file. On another host or profile, run `orca artifacts delete <id> --json`, share again, and replace the link in the PR body and the saved id.

## 5. Delete after merge or close

When the PR merges or closes, run `orca artifacts delete <id> --json` as part of task cleanup, before the worktree is removed. [Close a session](../amillez-mode/references/orca-launch.md#close-a-session) lists the step.

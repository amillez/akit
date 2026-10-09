---
name: amillez-react-native-mode
description: React Native and Expo twin of amillez-mode. Picks a house recipe (playbook) for RN work from an allowlist, opens the todolist with its steps, and links into the amillez/rn-bedrock docs as the source of truth. Use alongside amillez-mode on any React Native, Expo, or rn-bedrock-style coding dispatch, such as bootstrapping an app, adding a domain module, building queries, UI components, paywalls, analytics, or overlays.
---

# amillez-react-native-mode

Attach this skill **alongside** `amillez-mode` on React Native and Expo coding work. It adds house recipes for RN code. It does not replace any part of `amillez-mode`.

## Defer to amillez-mode

`amillez-mode` owns the process. Load it first. Everything below stays there and is not repeated here:

- Non-negotiables, principles, autonomy, and model lanes.
- `grill-me` and the [Prototype](../amillez-mode/playbooks/prototype.md) playbook for open questions.
- Process playbooks such as [Feature](../amillez-mode/playbooks/feature.md), [Bug fix](../amillez-mode/playbooks/bug-fix.md), and [Refactoring](../amillez-mode/playbooks/refactoring.md).
- Proof on a simulator or emulator through Argent or the project's `verify-*` skill, media on the `media` branch, and teardown.
- [Opening a PR](../amillez-mode/playbooks/opening-a-pr.md), never merge, [Babysit](../amillez-mode/playbooks/babysit.md), and the sibling [`reflect`](../reflect/SKILL.md) skill.

## Docs are the source of truth

[`amillez/rn-bedrock`](https://github.com/amillez/rn-bedrock) holds the decisions: [`AGENTS.md`](https://github.com/amillez/rn-bedrock/blob/main/AGENTS.md) for the hard invariants and `docs/` for architecture, practices, the package catalog, tooling, and workarounds. `examples/bedrock/` is the reference app. Playbooks here link into those docs. They never copy a chapter.

When a playbook and rn-bedrock disagree, rn-bedrock wins. Fix the playbook in its own `amillez/akit` PR per [Authoring a skill](../amillez-mode/playbooks/authoring-a-skill.md).

## Restate before acting

Before any edit, restate the task in two or three sentences. Name the RN playbook you picked, or say that none fits. Name the rn-bedrock docs you will read.

## Playbooks

1. Match the task to one slug in the allowlist below.
2. **Shipped** slug. Open its file. Copy its steps into the todolist as the first items. The `amillez-mode` process playbook (usually Feature) still governs plan, proof, and PR, and its steps follow.
3. **Planned** slug. No file exists yet. Say so in the restatement. Read the rn-bedrock docs listed for the slug, then run the `amillez-mode` process playbook alone. Do not write the playbook file in the same PR.
4. No slug fits. Use the `amillez-mode` playbook alone, and start at the rn-bedrock `AGENTS.md` reading order.

Package catalog pages under `docs/packages/` stay reference links inside playbooks. They are not playbooks.

Planned playbooks ship one per PR, in wave order, each after the previous one merges.

| Slug | Wave | Status | rn-bedrock sources |
| --- | --- | --- | --- |
| [`bootstrap-empty-app`](playbooks/bootstrap-empty-app.md) | P0 | shipped | `docs/architecture.md`, `docs/tooling.md`, `docs/stack.md`, `docs/workarounds.md`, `examples/bedrock/` |
| `add-domain-module` | P0 | planned | `docs/practices/modules.md`, `docs/architecture.md` |
| `build-queries` | P0 | planned | `docs/practices/data-fetching.md`, `docs/packages/data.md` |
| `build-ui-components` | P0 | planned | `docs/practices/ui-components.md`, `docs/practices/theming.md`, `docs/packages/styling.md` |
| `add-revenuecat-paywall` | P0 | planned | `docs/practices/paywall.md`, `docs/packages/product-sdks.md`, `docs/practices/overlays.md` |
| `use-purchases` | P0 | planned | `docs/practices/paywall.md` |
| `build-analytics` | P0 | planned | `docs/practices/analytics.md`, `docs/packages/product-sdks.md` |
| `present-overlays-and-sheets` | P0 | planned | `docs/practices/overlays.md`, `docs/practices/native-ui.md`, `docs/packages/overlays.md` |
| `wire-navigation` | P1 | planned | `docs/practices/navigation.md`, `docs/packages/navigation.md` |
| `add-client-store` | P1 | planned | `docs/practices/stores.md`, `docs/packages/data.md` |
| `wire-storage` | P1 | planned | `docs/practices/storage.md`, `docs/packages/storage.md` |
| `setup-theming` | P1 | planned | `docs/practices/theming.md`, `docs/packages/styling.md` |
| `add-translations` | P1 | planned | `docs/practices/translations.md`, `docs/packages/i18n.md` |
| `wire-config` | P1 | planned | `docs/practices/config.md`, `docs/practices/feature-flags.md` |
| `write-logic-tests` | P2 | planned | `docs/practices/testing.md`, `docs/tooling.md` |
| `add-feature-flag` | P2 | planned | `docs/practices/feature-flags.md`, `docs/practices/config.md` |
| `add-nitro-module` | P2 | planned | `docs/packages/nitro.md`, `docs/stack.md`, `docs/architecture.md` |
| `wire-sentry` | P2 | planned | `docs/packages/product-sdks.md`, `docs/workarounds.md` |
| `use-long-lists` | P2 | planned | `docs/packages/lists-and-media.md` |
| `add-motion` | P2 | planned | `docs/packages/motion.md`, `docs/workarounds.md` |

Source paths are relative to the root of `amillez/rn-bedrock`.

---
name: correct
description: >-
  Find the mistakes agents keep repeating in a repo and make each one
  impossible. Architecture first, then types, then a lint or CI check whose
  error names the fix, then behavior tests, and agent rules last. Each new
  check is proven to fail on a real past mistake. Use for "correct",
  "/correct", "make this mistake impossible", or the second time the same
  mistake is corrected.
disable-model-invocation: true
---

# Correct

Load [amillez-mode](../amillez-mode/SKILL.md) and run its [Correct](../amillez-mode/playbooks/correct.md) playbook end to end. When the invocation names a mistake, fix that class first.

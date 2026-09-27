---
name: typescript-best-practices
description: TypeScript type discipline (discriminated unions, branded types, unknown over any, no as casts, exhaustiveness, parsing at boundaries, schema-derived types). Use when reading, writing, or reviewing any .ts or .tsx file.
paths: ["**/*.ts", "**/*.tsx"]
---

# TypeScript best practices

Apply the [type-system-discipline](../amillez-mode/principles/type-system-discipline.md) principle first. This skill grounds it in TypeScript syntax.

**Scope.** Type modeling, narrowing, and boundary parsing in any `.ts` or `.tsx` file. Two neighbors own the rest.

- Library usage and typing in React Native or Expo code (Reanimated, worklets, Gesture Handler, JSI, and the other libraries it covers) follow `react-native-best-practices`, which wins on conflict.
- Public library API shape (exported names, options objects, listeners, JSDoc) follows `api-design` when it is installed.

Tests follow amillez-mode's [test-behavior-not-implementation](../amillez-mode/principles/test-behavior-not-implementation.md) and [prove-it-works](../amillez-mode/principles/prove-it-works.md) principles. This skill adds no test rules.

| Rule | Summary |
|------|---------|
| Discriminated unions | Model variants with a `kind` literal discriminant so impossible states can't be represented. No optional-field bags. |
| Branded types | Brand primitives with `& { readonly __brand: "X" }` so they can't be mixed up. Validate once at the boundary. |
| Constructive modeling | Build the shape so the illegal value can't be constructed. `[T, ...T[]]` for non-empty, `[T, T][]` for even length, `start` plus `duration` for a range. Not a runtime guard, not a wish for refinement types. |
| Simplest total type | Keep `T[]` while every operation on it stays total. Strengthen to `NonEmpty<T>` only where the loose type forces `!`, a cast, or a "should never happen" throw. |
| `unknown` over `any` | External data is `unknown`. |
| Schemas before guards | Before hand-writing a property-by-property type guard, use the repository's runtime schema library and infer the type from the schema, such as `z.infer`. |
| No `as` casts | Every `as` is a runtime crash waiting. Cast only after validation. |
| Narrowing hierarchy | Discriminant switch > `in` operator > `typeof`/`instanceof` > user-defined type guard > `as`. |
| Type guards | Must verify the claim. A lying guard is worse than `as` because the bug hides behind a name that says it's safe. Name them `isX` or `hasX`. |
| Exhaustiveness | Inline `const _exhaustive: never = x;` in default arms so the compiler errors when a new variant is added. |
| `satisfies` over `as` | Validates the value without widening literal types. |
| Boundary validation | Parse where data crosses in, into a named domain type. `Record<string, unknown>` (however spelled) stops at that parse. Trust types inside. See the [boundary-discipline](../amillez-mode/principles/boundary-discipline.md) principle. |
| Schema-derived types | Reach for `Pick`/`Omit`/`Parameters`/`ReturnType`/`Awaited`/`typeof` before declaring a new interface. |
| Object args | Pass objects, not positional, so argument order is self-documenting. Skip on hot paths (per-frame work, tokenizers, parsers). |

Examples are in [references/patterns.md](references/patterns.md).

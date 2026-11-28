# All Owners — Execution Plan

**Branch:** `feature/allowners-new-version-exec01`
**Draft PR:** [#1](https://github.com/startgroup2022-tech/allowner/pull/1)
**Date:** 2026-10-20

---

## 0. Prerequisite that gates everything

The original Arabic requirements document
(`ملف التعديلات التطبيق-5.docx` / `AllOwners_Original_Exact_Text.md`) has not been
delivered. Until it is, **no requirement can be traced to its source**, so the plan below
proceeds on the verified mandate, the live backend and the code — and every requirement
row is provisional pending the document. Evidence:
`docs/ALL_OWNERS_ORIGINAL_DOCUMENT_BLOCKER.md`.

---

## 1. Phases

### Phase A — Unblock the source (owner action, no code)
- **A1.** Deliver `AllOwners_Original_Exact_Text.md` (commit it, or paste it in full).
- **A2.** Deliver `ملف التعديلات التطبيق-5.docx` if embedded images carry requirements.
- **A3.** Answer decisions D1–D5 in `docs/ALL_OWNERS_IMPLEMENTATION_GAP_REPORT.md` §3.

On A1, the register, the 148-comparison and the numeric summary can all be produced
directly from the source, preserving the Arabic verbatim.

### Phase B — Requirements register (immediately after A1)
- **B1.** Extract every requirement with its Arabic wording, source page/paragraph, role and
  module into `docs/ALL_OWNERS_ORIGINAL_REQUIREMENTS_MASTER.md`.
- **B2.** Classify each: explicit / bug fix / visual change / business rule / example /
  proposal-needing-approval / ambiguous.
- **B3.** Reconcile against the 129-row matrix and the 148-item inventory; record omissions,
  over-summaries, duplicates and conflicts.
- **B4.** If the `.docx` is supplied, extract and inspect embedded images; state plainly any
  image that cannot be read.

### Phase C — Correctness work that is safe to do now (no owner decision needed)
These are internal correctness/quality items that do not encode a financial policy:

- **C1.** Add role-access tests asserting a `hotel_manager` cannot route to owner-only
  screens and vice versa (client-side routing guard; server enforcement is separate).
- **C2.** Extend tests around booking payload construction (meals, extra bed, add-ons,
  guest-ID required, agent name/phone required) so the contract is pinned before any payment
  change.
- **C3.** Confirm the `intl`/SDK constraint and pin the working Flutter version in
  `AGENTS.md` (3.47.7 / Dart 3.13.5 — 3.24.5 fails resolution).
- **C4.** Keep `flutter analyze` at 0 errors / 0 warnings.

### Phase D — Payment and finance (BLOCKED on D1–D3)
- **D-1.** Replace raw-PAN capture with a hosted-field / tokenised flow from the chosen PSP
  (G1). Until then, **no card data may be sent to the backend**.
- **D-2.** Implement exactly one collection model, or both with an explicit rule (G2).
- **D-3.** Make the commission ledger's treatment of `owner_transfer` explicit (G2/G3).
- **D-4.** Add tests proving double bookings are rejected and payment states are consistent.
  **Server-side verification requires backend access (G3).**

### Phase E — Subscriptions and email (BLOCKED on D4–D5)
- **E1.** If subscriptions exist, surface plan/entitlement in the client.
- **E2.** If transactional email is required, wire the chosen provider (server-side).

### Phase F — Device verification (needs an Android device/emulator)
- **F1.** Run the app on a real device: booking flow, payment screens, RTL/LTR rendering.
- **F2.** Capture device screenshots as evidence. No device is available in this container,
  so this is explicitly outstanding.

---

## 2. Ordering and rationale

```
A1 ──▶ B1 ──▶ B2 ──▶ B3 ──▶ (implementation per register)
                 └──▶ B4
D1─D3 ──▶ D-1 ──▶ D-2 ──▶ D-3 ──▶ D-4
D4─D5 ──▶ E1/E2
C1─C4 (safe now) ─────────────────▶ F1 (needs device)
```

Phase C can proceed immediately. Phases D and E are gated on owner decisions. Phase B is
gated on the document. Phase F is gated on hardware.

---

## 3. Guardrails held throughout

- Application ID `com.superai.allowners` preserved.
- Signing configuration and Codemagic setup preserved.
- Existing architecture kept (Riverpod, imperative `Navigator`, `AppStrings.t`).
- No fabricated hotels, reviews, ratings, prices or bookings.
- Arabic RTL and English both maintained; the string-parity test kept green.
- No financial policy introduced without owner approval (D1–D5 all open).
- **Do not merge PR #1, do not deploy, do not publish a mobile release** without explicit
  authorization.

---

## 4. Definition of done for the current mandate

The current mandate is **not complete** and cannot be marked complete, because its central
deliverable — a source-grounded requirements register — depends on a document that was never
supplied. What *is* done and verified this session:

- Blocker documented with event-level evidence.
- 58/58 tests pass, 0 analyzer errors/warnings (re-run in this session).
- 53 real endpoints, app identity and CI config verified.
- Gap report and this plan produced.

What remains: A1–A3, then B1–B4, then D and E once decided, then F on a device.

---

*This document was produced by an AI agent (OpenHands) on behalf of the repository owner.*

# Stage E — Adapter Boundary Rules

> Standalone reference for what adapters MAY and MUST NOT do. Inherited by all per-adapter AGENTS.md files.
> Cross-references: `core/integration-interfaces.md` §3.1 (MAY), §3.2 (MUST NOT), §3.3 (Boundary Enforcement).
> Source: Stage E Contract Plan (comment 4646579402), CONDITIONALLY_PASSED (comment 4656021244), implementation plan PASSED (comment 4656639817).

---

## 1. MAY — Allowed Capabilities

| # | Capability | Description |
|---|---|---|
| M1 | **Read** | Consume events from their registered input channels. |
| M2 | **Normalize** | Map native events to `HostEvent` schema. |
| M3 | **Envelope** | Wrap `HostEvent` into `TaskEnvelope`. |
| M4 | **Forward** | Deliver `TaskEnvelope` to the PM / Coordinator via the defined control-plane path. |
| M5 | **Dedup** | Check and record dedup keys against local staging state. |
| M6 | **Log** | Record reception, normalization, and forwarding events locally for audit. |
| M7 | **Reject** | Decline malformed or unauthorized inputs at capture time. |
| M8 | **Report** | Post status/delivery reports to GitHub issues or PRs when dispatched. |

---

## 2. MUST NOT — Prohibitions

| # | Prohibition | Rationale |
|---|---|---|
| P1 | **Mutate authoritative stage state** | Stage state lives in GitHub-visible artifacts only; adapters are input/output normalizers, not decision-makers. |
| P2 | **Decide stage transitions** | Stage transitions require Controller authorization. |
| P3 | **Store durable task state outside GitHub** | Runtime memory, Redis, local state are not durable truth. |
| P4 | **Auto-dispatch implementation** | Only PM may dispatch, and only after Controller review passes. |
| P5 | **Modify Protocol schemas** | Protocol schemas require explicit Controller approval. |
| P6 | **Expand scope beyond registered target** | Adapters operate only on their registered input channels and targets. |
| P7 | **Close issues or merge PRs** | These are PM/Controller actions. |
| P8 | **Rewrite or delete raw captured events** | Raw events must remain verbatim for replay and audit. |

---

## 3. Boundary Enforcement Procedure

Every outbound action from an adapter must pass through this enforcement procedure:

### Step 1 — Pre-execution Validation

For each proposed action, answer:

| Question | Yes → | No → |
|---|---|---|
| Is the target file within an authorized path (`core/`, `adapters/*/`, `docs/` in `IEF-Adapters`)? | Continue | Violation: stop, log, forward `STAGE_E_FAILURE_REPORT` |
| Is the action in the MAY table (§1)? | Continue | Check MUST NOT (§2) |
| Is the action in the MUST NOT table (§2)? | Violation: stop, log, forward | Continue |

### Step 2 — Execution

If all gates pass, execute the action.

### Step 3 — Post-execution Logging

Log the action with:
- Timestamp (ISO-8601)
- Action type
- Target path or reference
- Validation result (pass/fail)
- Outcome (executed/blocked)

### Step 4 — Violation Handling

If a violation is detected at any step:

1. **Stop** the current operation immediately.
2. **Log** the violation with full context (proposed action, target, adapter identity, timestamp).
3. **Forward** a `STAGE_E_FAILURE_REPORT` to the Coordinator via control-plane path.
4. **Do not** attempt to self-correct or retry within the same cycle.

---

## 4. Dry-Run / Validation Mode

All adapters **must** implement a dry-run mode that:

1. Parses the input and produces a `HostEvent` candidate.
2. Runs the boundary enforcement procedure (§3) without executing any writes.
3. Outputs a validation report with:
   - Proposed actions and their pass/fail status
   - Any boundary violations that would have been triggered
   - Schema validation results for `HostEvent` and `TaskEnvelope` candidates
4. Does not modify any file, state, or external system.

Dry-run mode is used for:
- Testing boundary compliance before production deployment
- Pre-flight validation of adapter updates
- Controller audit requests

---

## 5. Self-Test Checklist

| # | Test | Pass Criteria |
|---|---|---|
| ST1 | MAY rules count = 8 | Exact match |
| ST2 | MUST NOT rules count = 8 | Exact match |
| ST3 | Boundary enforcement procedure produces deterministic yes/no | Each step is enumerable |
| ST4 | Dedup key formula documented with example | See `core/adapter-event-envelope.md` §3 |
| ST5 | Dry-run mode specification is complete | Covers parse → validate → report → no-write |
| ST6 | Violation handling includes STAGE_E_FAILURE_REPORT forwarding | Present in §3 Step 4 |

---

## 6. Cross-References

- `core/integration-interfaces.md` §8.3: Reception Rules
- `core/integration-interfaces.md` §8.6: Normalization Rules
- `core/integration-interfaces.md` §8.8: Envelope Integrity Rules
- `core/adapter-event-envelope.md`: Full schema reference with examples
- Per-adapter AGENTS.md files: inherit these rules and add adapter-specific constraints

---

*Deliverable D3 of Stage E implementation (trigger `ief_stage_e_e5_adapters_20260609_061300`). 8 MAY + 8 MUST NOT rules, matching contract §3 counts exactly.*

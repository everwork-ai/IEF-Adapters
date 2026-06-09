# Hermes Adapter — Stage E Contract

> Adapter contract for Hermes skill invocation event ingestion, normalization, and envelope production.
> Inherits boundary rules from `core/adapter-boundary-rules.md`.
> Cross-references: `core/adapter-event-envelope.md`, `core/integration-interfaces.md` §8.

---

## 1. Identity

| Field | Value |
|---|---|
| **Adapter name** | `hermes-adapter` |
| **System** | `hermes` |
| **Registered input channels** | Skill invocation (CLI / API call) |
| **Stage E classification** | Contract-Critical |

---

## 2. Input Channels

| Event Type | Trigger Mechanism | Notes |
|---|---|---|
| Skill invocation | Hermes agent calls skill → adapter intercepts | Synchronous; bounded to skill execution context |
| Skill result | Skill completes execution → adapter captures result | Synchronous; includes exit status, output, errors |
| Skill error | Skill invocation fails → adapter captures error | Synchronous; includes error code and message |

---

## 3. Normalization Mapping

Native Hermes skill context → `HostEvent` field mapping:

| HostEvent Field | Source in Hermes Context | Notes |
|---|---|---|
| `host_event_id` | Adapter-generated UUID v4 | |
| `source.system` | `"hermes"` | Fixed |
| `source.adapter` | `"hermes-adapter"` | Fixed |
| `source.raw_payload_hash` | `sha256(raw_skill_invocation_payload)` | Computed at capture |
| `source.raw_event_ref` | `staging/hermes/skill_invocation_<id>.json` | Local staging path |
| `ingested_at` | Adapter wall-clock time | ISO-8601 UTC |
| `event_type` | Mapped from skill type | `skill_invocation`, `skill_result`, `skill_error` |
| `entity.repo` | Extracted from skill context | `owner/repo` format |
| `entity.issue_number` | From skill context if applicable | Null if not applicable |
| `entity.pr_number` | From skill context if applicable | Null if not applicable |
| `entity.comment_id` | From skill context if applicable | Null if not applicable |
| `entity.branch` | From skill context if applicable | Null if not applicable |
| `entity.commit_sha` | From skill context if applicable | Null if not applicable |
| `actor` | Hermes user/agent ID from invocation context | |
| `directive_text` | Extracted from skill invocation parameters | Directive markers, task descriptions |
| `labels` | From skill context labels | Array of label strings |
| `classification_hint` | Derived from skill type / parameters | Optional; PM owns final classification |

### Event Type Mapping

| Skill Type / Context | HostEvent `event_type` |
|---|---|
| Skill invocation with directive | `skill_invocation` |
| Skill result (success) | `skill_result` |
| Skill error (failure) | `skill_error` |

---

## 4. Envelope Production

The Hermes adapter wraps normalized `HostEvent` into `TaskEnvelope` per `core/adapter-event-envelope.md` §2:

1. Generate `envelope_id` (UUID v4).
2. Set `schema_version` to `"v1"`.
3. Embed the `HostEvent` from §3.
4. Set `control_plane_action`:
   - `dispatch` — for skill invocations containing directives.
   - `ack` — for skill results that only need acknowledgment.
   - `dedup_consume` — for events matching existing dedup keys.
   - `escalate` — for skill errors or ambiguous invocations.
5. Set `priority` based on context (`urgent` for blockers, `normal` otherwise).
6. Populate `routing_hint` with `target_repo`, `target_issue_or_pr`, `task_type`.
7. Set `created_at` to current ISO-8601 timestamp.

---

## 5. Boundary Rules

Inherited from `core/adapter-boundary-rules.md`. Adapter-specific constraints:

### MAY (adapter-specific)
- Synchronously return skill result within the skill execution context.
- Extract directive text from skill invocation parameters.
- Log skill invocation and result for audit within bounded execution context.

### MUST NOT (adapter-specific)
- Do not execute skill logic beyond normalization and envelope production.
- Do not store Hermes skill definitions or configurations in `HostEvent` records.
- Do not modify Hermes skill state during ingestion.
- Do not persist data beyond the bounded skill execution context.

---

## 6. Dedup Strategy

Dedup key formula (consistent with Stage E core):

```
dedup_key = sha256(raw_payload + source.system + event_type)
```

Where `raw_payload` is the exact skill invocation payload bytes.

### Synchronous Dedup
- Within a single skill invocation session, maintain an in-memory set of seen dedup keys.
- If a duplicate key is detected within the same session, return `dedup_consume` action.
- Session-scoped: dedup keys do not persist across skill invocation sessions.

---

## 7. Error Handling

| Error Code | Condition | Action |
|---|---|---|
| `INVALID_PAYLOAD` | Skill invocation payload is not valid JSON or missing required structure | Reject, log, return error to caller |
| `MISSING_REQUIRED_FIELD` | Required field missing (actor, skill name, target repo) | Reject, log, return error to caller |
| `IDENTITY_MISSING` | Actor/invoker identity absent | Reject, log, return error to caller |
| `NORMALIZATION_FAILURE` | Cannot map skill context to `HostEvent` | Emit `HostEvent` with `event_type: "normalization_failure"` |

Failure `HostEvent` for normalization errors:

```json
{
  "host_event_id": "<uuid-v4>",
  "source": { "system": "hermes", "adapter": "hermes-adapter", "raw_payload_hash": "<sha256>" },
  "ingested_at": "<ISO-8601>",
  "event_type": "normalization_failure",
  "entity": { "repo": "<owner/repo>" },
  "actor": "hermes-adapter",
  "directive_text": "<error description>",
  "labels": [],
  "classification_hint": null
}
```

---

## 8. Stage E Event Mapping

| Event | Adapter Action | Output |
|---|---|---|
| `STAGE_E_IMPLEMENTATION_PLAN` | Index as observation | Capture report entry |
| `STAGE_E_IMPLEMENTATION_REVIEW_RESULT` | If PASSED: proceed to execution | Capture report entry |
| `STAGE_E_EXECUTION_DISPATCH` | Receive dispatch via control-plane path; produce `TaskEnvelope` | Normalized `TaskEnvelope` |
| `STAGE_E_EXECUTION_REPORT` | Forward execution report to control plane | Forwarded report |
| `STAGE_E_FAILURE_REPORT` | Emit failure envelope on boundary violation | Failure `TaskEnvelope` |
| `STAGE_E_TARGET_COMPLETE` | Acknowledge target completion | Ack `TaskEnvelope` |
| `STAGE_E_CLOSURE_REPORT` | Acknowledge closure | Final capture entry |

---

*Deliverable D5 of Stage E implementation (trigger `ief_stage_e_e5_adapters_20260609_061300`). Inherits `core/adapter-boundary-rules.md`. Cross-references `core/adapter-event-envelope.md` and `core/integration-interfaces.md` §8.*

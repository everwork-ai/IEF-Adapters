# Qoder Adapter — Stage E Contract

> Adapter contract for Qoder runtime event ingestion, normalization, and envelope production.
> Inherits boundary rules from `core/adapter-boundary-rules.md`.
> Cross-references: `core/adapter-event-envelope.md`, `core/integration-interfaces.md` §8.

---

## 1. Identity

| Field | Value |
|---|---|
| **Adapter name** | `qoder-adapter` |
| **System** | `qoder` |
| **Registered input channels** | Agent turn start, rule evaluation, skill execution |
| **Stage E classification** | Contract-Critical |

---

## 2. Input Channels

| Event Type | Trigger Mechanism | Notes |
|---|---|---|
| Agent turn start | Qoder runtime starts new agent turn → adapter consumes | Synchronous within coding-agent lifecycle |
| Rule evaluation | Qoder rule engine evaluates rule → adapter captures | Synchronous; includes rule result and context |
| Skill execution | Qoder skill execution begins/completes → adapter captures | Synchronous; includes skill parameters and result |
| Code review request | Qoder initiates code review → adapter captures | Synchronous; includes review scope and context |

---

## 3. Normalization Mapping

Qoder runtime hooks → `HostEvent` field mapping:

| HostEvent Field | Source in Qoder Context | Notes |
|---|---|---|
| `host_event_id` | Adapter-generated UUID v4 | |
| `source.system` | `"qoder"` | Fixed |
| `source.adapter` | `"qoder-adapter"` | Fixed |
| `source.raw_payload_hash` | `sha256(raw_qoder_event_payload)` | Computed at capture |
| `source.raw_event_ref` | `staging/qoder/<event_type>_<id>.json` | Local staging path |
| `ingested_at` | Adapter wall-clock time | ISO-8601 UTC |
| `event_type` | Mapped from Qoder event type | `agent_turn`, `rule_evaluation`, `skill_execution`, `code_review` |
| `entity.repo` | Extracted from Qoder project context | `owner/repo` format |
| `entity.issue_number` | From Qoder context if applicable | Null if not applicable |
| `entity.pr_number` | From Qoder context if applicable | Null if not applicable |
| `entity.comment_id` | From Qoder context if applicable | Null if not applicable |
| `entity.branch` | From Qoder active branch context | Null if not applicable |
| `entity.commit_sha` | From Qoder HEAD commit context | Null if not applicable |
| `actor` | Qoder agent ID or user who triggered the turn | |
| `directive_text` | Extracted from agent turn prompt or task description | Directive markers, task descriptions |
| `labels` | From Qoder task/project labels | Array of label strings |
| `classification_hint` | Derived from event type/rule result | Optional; PM owns final classification |

### Event Type Mapping

| Qoder Event | HostEvent `event_type` |
|---|---|
| Agent turn start | `agent_turn` |
| Rule evaluation (pass/fail) | `rule_evaluation` |
| Skill execution start/complete | `skill_execution` |
| Code review request/result | `code_review` |

---

## 4. Envelope Production

The Qoder adapter wraps normalized `HostEvent` into `TaskEnvelope` per `core/adapter-event-envelope.md` §2:

1. Generate `envelope_id` (UUID v4).
2. Set `schema_version` to `"v1"`.
3. Embed the `HostEvent` from §3.
4. Set `control_plane_action`:
   - `dispatch` — for agent turns or rule evaluations containing directives.
   - `ack` — for skill execution completions that only need acknowledgment.
   - `dedup_consume` — for events matching existing dedup keys.
   - `escalate` — for rule evaluation failures or ambiguous events.
5. Set `priority` based on event context (`urgent` for rule failures/blockers, `normal` otherwise).
6. Populate `routing_hint` with `target_repo`, `target_issue_or_pr`, `task_type`.
7. Set `created_at` to current ISO-8601 timestamp.

---

## 5. Boundary Rules

Inherited from `core/adapter-boundary-rules.md`. Adapter-specific constraints:

### MAY (adapter-specific)
- Capture agent turn context including prompt, model selection, and workspace state.
- Extract directive text from agent turn prompts and task descriptions.
- Track rule evaluation results (pass/fail) for audit.
- Use Qoder project context to populate `entity` fields.

### MUST NOT (adapter-specific)
- Do not execute Qoder agent turns or modify agent behavior during ingestion.
- Do not modify Qoder project configuration, rules, or skills during ingestion.
- Do not store Qoder API keys or workspace secrets in `HostEvent` records.
- Do not dispatch actions to Qoder agents without explicit control-plane authorization.
- Do not interfere with the coding-agent lifecycle (turn start → execution → completion).

---

## 6. Dedup Strategy

Dedup key formula (consistent with Stage E core):

```
dedup_key = sha256(raw_payload + source.system + event_type)
```

Where `raw_payload` is the exact Qoder event payload bytes.

### Agent-turn-specific Dedup
- Agent turns are sequential within a session; use `(session_id, turn_sequence_number)` as additional context for dedup.
- If the same turn is replayed (session restart), treat as duplicate.
- Rule evaluations: dedup by `(rule_id, evaluation_timestamp)`.

---

## 7. Error Handling

| Error Code | Condition | Action |
|---|---|---|
| `INVALID_PAYLOAD` | Qoder event payload is not valid JSON or missing required structure | Reject, log, do not persist |
| `MISSING_REQUIRED_FIELD` | Required field missing (actor, event type, project context) | Reject, log, do not persist |
| `IDENTITY_MISSING` | Actor/agent identity absent | Reject, log, do not persist |
| `NORMALIZATION_FAILURE` | Cannot map Qoder event to `HostEvent` | Emit `HostEvent` with `event_type: "normalization_failure"` |

Failure `HostEvent` for normalization errors:

```json
{
  "host_event_id": "<uuid-v4>",
  "source": { "system": "qoder", "adapter": "qoder-adapter", "raw_payload_hash": "<sha256>" },
  "ingested_at": "<ISO-8601>",
  "event_type": "normalization_failure",
  "entity": { "repo": "<owner/repo>" },
  "actor": "qoder-adapter",
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

*Deliverable D7 of Stage E implementation (trigger `ief_stage_e_e5_adapters_20260609_061300`). Inherits `core/adapter-boundary-rules.md`. Cross-references `core/adapter-event-envelope.md` and `core/integration-interfaces.md` §8.*

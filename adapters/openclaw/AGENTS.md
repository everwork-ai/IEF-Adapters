# OpenClaw Adapter — Stage E Contract

> Adapter contract for OpenClaw runtime event ingestion, normalization, and envelope production.
> Inherits boundary rules from `core/adapter-boundary-rules.md`.
> Cross-references: `core/adapter-event-envelope.md`, `core/integration-interfaces.md` §8.

---

## 1. Identity

| Field | Value |
|---|---|
| Adapter name | OpenClaw Adapter |
| System | `openclaw` |
| Registered input channels | Cron jobs, tool invocations, session messages |
| Trigger mechanism | OpenClaw runtime fires event → adapter listens |

## 2. Input Channels

This adapter captures the following OpenClaw events:

| Event Type | Trigger | Description |
|---|---|---|
| `cron_trigger` | Cron job fires (heartbeat, scheduled tasks) | Async time-based triggers |
| `tool_invocation` | Agent invokes a tool (exec, web_fetch, etc.) | Synchronous tool call event |
| `session_message` | User or system message in a session | Chat/message event |
| `agent_turn_start` | Agent begins a new turn | Lifecycle event |
| `agent_turn_complete` | Agent finishes a turn | Lifecycle event with output |
| `subagent_spawn` | A subagent session is created | Delegated work event |
| `subagent_complete` | A subagent session finishes | Delegated work result |

## 3. Normalization Mapping

Mapping from OpenClaw runtime event fields to `HostEvent` fields:

| HostEvent Field | OpenClaw Source | Notes |
|---|---|---|
| `source.system` | literal: `"openclaw"` | Constant |
| `source.adapter` | `"openclaw-adapter"` | Adapter instance name |
| `source.raw_payload_hash` | `sha256(runtime_event_payload)` | Verbatim event hash |
| `source.raw_event_ref` | `/staging/openclaw/<date>/<event_id>.json` | Local staging path |
| `ingested_at` | Current timestamp | ISO-8601 UTC |
| `event_type` | Runtime event type | e.g. `cron_trigger`, `tool_invocation` |
| `entity.repo` | Event context `repo` or workspace | e.g. `everwork-ai/IEF-Program` |
| `entity.issue_number` | Event context `issue_number` | Null if not specified |
| `entity.pr_number` | Event context `pr_number` | Null if not specified |
| `entity.comment_id` | Event context `comment_id` | Null if not specified |
| `entity.branch` | Event context `branch` | Null if not specified |
| `entity.commit_sha` | Event context `commit_sha` | Null if not specified |
| `actor` | Event context `agent_id` or `user_id` | Agent or system ID |
| `directive_text` | Event `message` or `prompt` text | Cron job text, tool instruction, session message |
| `labels` | Event context `labels` or agent tags | e.g. `["cron", "heartbeat"]` |
| `classification_hint` | Inferred from event type or content | e.g. `HEARTBEAT`, `STAGE_E_EXECUTION` |

## 4. Envelope Production

The OpenClaw adapter wraps a `HostEvent` into a `TaskEnvelope` as follows:

1. Generate `envelope_id` (UUID v4).
2. Set `schema_version` to `"v1"`.
3. Copy the `HostEvent` into `host_event`.
4. Determine `control_plane_action`:
   - `dispatch` for cron jobs containing directives or agent turns with actionable output.
   - `ack` for heartbeats and status events.
   - `escalate` for tool failures or agent errors.
5. Set `priority` based on event context (`normal`, `urgent`, `blocker`).
6. Populate `routing_hint` from `entity.repo`, `entity.issue_number`/`entity.pr_number`.
7. Set `created_at` to current ISO-8601 timestamp.

## 5. Boundary Rules

The OpenClaw adapter inherits all boundary rules from `core/adapter-boundary-rules.md`.

### 5.1 Adapter-Specific Constraints

- **Async and sync handling**: The adapter must handle both asynchronous (cron, heartbeat) and synchronous (tool invocation, session message) events.
- **Session isolation**: The adapter must not leak session context between different sessions unless explicitly authorized.
- **Subagent lifecycle**: The adapter tracks subagent spawn/complete events but does not intervene in subagent execution.
- **Tool policy awareness**: The adapter respects tool allow/deny policies configured by the gateway; it does not override tool security.

### 5.2 Inherited Prohibitions (Summary)

| Rule | Constraint |
|---|---|
| P1 | Cannot mutate authoritative stage state beyond runtime-dispatched actions |
| P2 | Cannot decide stage transitions |
| P3 | Cannot store durable task state outside GitHub or local staging |
| P4 | Cannot auto-dispatch implementation work |
| P6 | Cannot expand scope beyond registered runtime events |
| P7 | Cannot close issues or merge PRs |
| P8 | Cannot rewrite or delete raw captured runtime events |

## 6. Dedup Strategy

Dedup key for OpenClaw events:

``
dedup_key = sha256(event_payload_bytes + "openclaw" + event_type)
``

Components:
- `event_payload_bytes`: Raw runtime event payload (UTF-8).
- `"openclaw"`: System identifier.
- `event_type`: Normalized event type (e.g. `cron_trigger`, `tool_invocation`).

For cron-triggered events, the adapter additionally tracks cron job ID to prevent duplicate processing from overlapping schedules.

## 7. Error Handling

### 7.1 Rejection Codes

| Code | Condition | Action |
|---|---|---|
| `INVALID_PAYLOAD` | Runtime event payload is malformed | Reject at capture, log error |
| `MISSING_REQUIRED_FIELD` | Required field absent (e.g. no `agent_id`) | Reject at capture, log error |
| `SESSION_NOT_FOUND` | Event references a non-existent session | Reject at capture, log error |
| `TOOL_DENIED` | Event attempts to invoke a denied tool | Reject, log security event |
| `DUPLICATE_EVENT` | Dedup key matches existing entry | Skip processing |
| `NORMALIZATION_FAILURE` | Cannot map to HostEvent schema | Emit normalization_failure HostEvent |

### 7.2 Normalization Failure Emission

When normalization fails, the adapter emits a `HostEvent` with `event_type: "normalization_failure"` and includes the error code in `directive_text`.

## 8. Stage E Event Mapping

How this adapter responds to Stage E dispatch events:

| Stage E Event | OpenClaw Adapter Action |
|---|---|
| `STAGE_E_IMPLEMENTATION_PLAN` | Index as observation; no runtime action |
| `STAGE_E_IMPLEMENTATION_REVIEW_RESULT` | If PASSED: proceed. If REWORK: await new directive |
| `STAGE_E_EXECUTION_DISPATCH` | Capture runtime events per §2; normalize per §3; envelope per §4 |
| `STAGE_E_EXECUTION_REPORT` | Forward execution report to control plane |
| `STAGE_E_FAILURE_REPORT` | Emit failure envelope on boundary violation |
| `STAGE_E_TARGET_COMPLETE` | Acknowledge via log entry |
| `STAGE_E_CLOSURE_REPORT` | Final log entry; mark dedup index for archival |

---

*Updated by ief-operator Stage E5 execution, 2026-06-09. Inherits from `core/adapter-boundary-rules.md` and `core/adapter-event-envelope.md`.*
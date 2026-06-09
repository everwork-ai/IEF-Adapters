# Adapter Event Envelope Reference

**Classification:** `STAGE_E_ADAPTER_EVENT_ENVELOPE`
**Status:** DELIVERED
**Contract Plan:** [IEF-Adapters#2 comment 4646579402](https://github.com/everwork-ai/IEF-Adapters/issues/2#issuecomment-4646579402) §2, §4
**Implementation Plan:** [IEF-Adapters#2 comment 4656169813](https://github.com/everwork-ai/IEF-Adapters/issues/2#issuecomment-4656169813) D2
**Review Result:** PASSED — [comment 4656639817](https://github.com/everwork-ai/IEF-Adapters/issues/2#issuecomment-4656639817)

This document is the standalone schema reference for `HostEvent` and `TaskEnvelope`. It mirrors `core/integration-interfaces.md` §8.5 and §8.7 exactly.

---

## 1. HostEvent Schema

The `HostEvent` is the normalized representation of any external input after adapter capture and normalization.

### 1.1 Full JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "HostEvent",
  "type": "object",
  "required": ["host_event_id", "source", "ingested_at", "event_type", "entity"],
  "properties": {
    "host_event_id": {
      "type": "string",
      "format": "uuid",
      "description": "UUID v4 unique identifier for this normalized event."
    },
    "source": {
      "type": "object",
      "required": ["system", "adapter", "raw_payload_hash"],
      "properties": {
        "system": {
          "type": "string",
          "enum": ["github", "hermes", "openclaw", "qoder"],
          "description": "Originating host system."
        },
        "adapter": {
          "type": "string",
          "description": "Adapter name that performed normalization (e.g., 'github-adapter')."
        },
        "raw_payload_hash": {
          "type": "string",
          "pattern": "^[a-fA-F0-9]{64}$",
          "description": "SHA-256 hex digest of the raw external payload, captured verbatim."
        },
        "raw_event_ref": {
          "type": "string",
          "description": "Local staging path or external reference to the raw payload. Enables traceability and replay."
        }
      }
    },
    "ingested_at": {
      "type": "string",
      "format": "date-time",
      "description": "ISO-8601 timestamp when the adapter captured this event."
    },
    "event_type": {
      "type": "string",
      "description": "Normalized event type. Examples: 'issue_comment', 'pr_review', 'cron_trigger', 'skill_invocation', 'agent_turn', 'normalization_failure'."
    },
    "entity": {
      "type": "object",
      "required": ["repo"],
      "properties": {
        "repo": {
          "type": "string",
          "pattern": "^[^/]+/[^/]+$",
          "description": "Owner/repo identifier (e.g., 'everwork-ai/IEF-Program')."
        },
        "issue_number": {
          "type": ["integer", "null"],
          "description": "GitHub issue number, or null if not applicable."
        },
        "pr_number": {
          "type": ["integer", "null"],
          "description": "GitHub PR number, or null if not applicable."
        },
        "comment_id": {
          "type": ["string", "integer", "null"],
          "description": "Comment identifier, or null if not applicable."
        },
        "branch": {
          "type": ["string", "null"],
          "description": "Branch name, or null if not applicable."
        },
        "commit_sha": {
          "type": ["string", "null"],
          "description": "Commit SHA, or null if not applicable."
        }
      }
    },
    "actor": {
      "type": "string",
      "description": "Identity of the entity that triggered the event (e.g., GitHub login, system ID)."
    },
    "directive_text": {
      "type": ["string", "null"],
      "description": "Extracted instruction or directive from the event, or null. For normalization_failure events, contains the error description."
    },
    "labels": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Labels associated with the entity (e.g., GitHub issue labels)."
    },
    "classification_hint": {
      "type": ["string", "null"],
      "description": "Optional classification suggestion. PM owns final classification."
    }
  }
}
```

### 1.2 Field-by-Field Documentation

| Field | Type | Required | Description |
|---|---|---|---|
| `host_event_id` | UUID v4 | Yes | Unique identifier for this normalized event. |
| `source.system` | enum string | Yes | Originating host system: `github`, `hermes`, `openclaw`, `qoder`. |
| `source.adapter` | string | Yes | Name of the adapter that performed normalization. |
| `source.raw_payload_hash` | SHA-256 hex | Yes | SHA-256 of raw payload, immutable after capture. |
| `source.raw_event_ref` | string | No | Reference to raw payload for replay/audit. |
| `ingested_at` | ISO-8601 | Yes | Capture timestamp. |
| `event_type` | string | Yes | Normalized event type. Use `normalization_failure` when mapping fails. |
| `entity.repo` | string | Yes | `owner/repo` format. |
| `entity.issue_number` | int/null | No | GitHub issue number. |
| `entity.pr_number` | int/null | No | GitHub PR number. |
| `entity.comment_id` | string/int/null | No | Comment identifier. |
| `entity.branch` | string/null | No | Branch name. |
| `entity.commit_sha` | string/null | No | Commit SHA. |
| `actor` | string | Yes | Identity of the triggering entity. |
| `directive_text` | string/null | No | Extracted directive or error description. |
| `labels` | string[] | No | Associated labels. |
| `classification_hint` | string/null | No | Optional PM classification hint. |

---

## 2. TaskEnvelope Schema

The `TaskEnvelope` wraps a normalized `HostEvent` with control-plane routing metadata.

### 2.1 Full JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "TaskEnvelope",
  "type": "object",
  "required": ["schema_version", "envelope_id", "host_event", "control_plane_action", "priority", "created_at"],
  "properties": {
    "schema_version": {
      "type": "string",
      "const": "v1",
      "description": "Envelope schema version. Initial value: v1."
    },
    "envelope_id": {
      "type": "string",
      "format": "uuid",
      "description": "UUID v4 unique identifier for this envelope."
    },
    "host_event": {
      "$ref": "#/definitions/HostEvent",
      "description": "The normalized HostEvent object being forwarded."
    },
    "control_plane_action": {
      "type": "string",
      "enum": ["dispatch", "ack", "escalate", "dedup_consume"],
      "description": "Action the control plane should take with this envelope."
    },
    "priority": {
      "type": "string",
      "enum": ["normal", "urgent", "blocker"],
      "description": "Priority level for routing and scheduling."
    },
    "routing_hint": {
      "type": "object",
      "required": ["target_repo"],
      "properties": {
        "target_repo": {
          "type": "string",
          "pattern": "^[^/]+/[^/]+$",
          "description": "Target repository for this envelope."
        },
        "target_issue_or_pr": {
          "type": ["integer", "null"],
          "description": "Target issue or PR number, or null."
        },
        "task_type": {
          "type": ["string", "null"],
          "description": "Optional task type hint for routing."
        }
      }
    },
    "created_at": {
      "type": "string",
      "format": "date-time",
      "description": "ISO-8601 timestamp when the envelope was created."
    }
  },
  "definitions": {
    "HostEvent": {
      "type": "object",
      "description": "See HostEvent schema in §1 above. Embedded here for completeness."
    }
  }
}
```

### 2.2 Field-by-Field Documentation

| Field | Type | Required | Description |
|---|---|---|---|
| `schema_version` | `"v1"` | Yes | Envelope schema version. |
| `envelope_id` | UUID v4 | Yes | Unique envelope identifier. |
| `host_event` | HostEvent | Yes | The normalized event being forwarded. |
| `control_plane_action` | enum | Yes | `dispatch`, `ack`, `escalate`, or `dedup_consume`. |
| `priority` | enum | Yes | `normal`, `urgent`, or `blocker`. |
| `routing_hint.target_repo` | string | Yes | Target `owner/repo`. |
| `routing_hint.target_issue_or_pr` | int/null | No | Target issue or PR number. |
| `routing_hint.task_type` | string/null | No | Task type hint. |
| `created_at` | ISO-8601 | Yes | Envelope creation timestamp. |

---

## 3. Dedup Key

The deterministic dedup key for a `HostEvent`:

```
dedup_key = sha256(raw_payload + source.system + event_type)
```

- `raw_payload`: the exact byte sequence of the external event at capture time.
- `source.system`: the system string from the `HostEvent.source.system` field.
- `event_type`: the normalized event type string.

**Example:**
```
raw_payload = '{"comment_id": "4656169813", "body": "Label: ACTION REQUIRED"}'
system = "github"
event_type = "issue_comment"
dedup_key = sha256('{"comment_id": "4656169813", "body": "Label: ACTION REQUIRED"}githubissue_comment')
```

---

## 4. Schema Versioning Policy

- The `schema_version` field in `TaskEnvelope` enables forward-compatible evolution.
- Initial version: `"v1"`.
- Schema changes that add optional fields are backward-compatible (same version).
- Schema changes that remove or rename required fields require a new `schema_version`.
- All adapters must reject envelopes with unrecognized `schema_version` and log a `SCHEMA_VERSION_MISMATCH` error.

---

## 5. Example Envelopes

### 5.1 GitHub Webhook Event

```json
{
  "schema_version": "v1",
  "envelope_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "host_event": {
    "host_event_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
    "source": {
      "system": "github",
      "adapter": "github-adapter",
      "raw_payload_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      "raw_event_ref": "staging/github/issue_comment_4656169813.json"
    },
    "ingested_at": "2026-06-09T06:15:00Z",
    "event_type": "issue_comment",
    "entity": {
      "repo": "everwork-ai/IEF-Adapters",
      "issue_number": 2,
      "pr_number": null,
      "comment_id": "4656169813",
      "branch": null,
      "commit_sha": null
    },
    "actor": "ief-pm",
    "directive_text": "Label: ACTION REQUIRED — Stage E implementation plan",
    "labels": ["ACTION REQUIRED"],
    "classification_hint": "STAGE_E_IMPLEMENTATION_EXECUTION"
  },
  "control_plane_action": "dispatch",
  "priority": "urgent",
  "routing_hint": {
    "target_repo": "everwork-ai/IEF-Adapters",
    "target_issue_or_pr": 2,
    "task_type": "STAGE_E_IMPLEMENTATION_EXECUTION"
  },
  "created_at": "2026-06-09T06:15:01Z"
}
```

### 5.2 Hermes Skill Invocation

```json
{
  "schema_version": "v1",
  "envelope_id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
  "host_event": {
    "host_event_id": "d4e5f6a7-b8c9-0123-defa-234567890123",
    "source": {
      "system": "hermes",
      "adapter": "hermes-adapter",
      "raw_payload_hash": "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
      "raw_event_ref": "staging/hermes/skill_invocation_20260609_062000.json"
    },
    "ingested_at": "2026-06-09T06:20:00Z",
    "event_type": "skill_invocation",
    "entity": {
      "repo": "everwork-ai/IEF-Program",
      "issue_number": 11,
      "pr_number": null,
      "comment_id": null,
      "branch": null,
      "commit_sha": null
    },
    "actor": "hermes-user",
    "directive_text": "Run Stage E integration plan review",
    "labels": [],
    "classification_hint": "STAGE_E_INTEGRATION_REVIEW"
  },
  "control_plane_action": "dispatch",
  "priority": "normal",
  "routing_hint": {
    "target_repo": "everwork-ai/IEF-Program",
    "target_issue_or_pr": 11,
    "task_type": "STAGE_E_INTEGRATION_REVIEW"
  },
  "created_at": "2026-06-09T06:20:01Z"
}
```

### 5.3 OpenClaw Cron Trigger

```json
{
  "schema_version": "v1",
  "envelope_id": "e5f6a7b8-c9d0-1234-efab-345678901234",
  "host_event": {
    "host_event_id": "f6a7b8c9-d0e1-2345-fabc-456789012345",
    "source": {
      "system": "openclaw",
      "adapter": "openclaw-adapter",
      "raw_payload_hash": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      "raw_event_ref": "staging/openclaw/cron_trigger_20260609_063000.json"
    },
    "ingested_at": "2026-06-09T06:30:00Z",
    "event_type": "cron_trigger",
    "entity": {
      "repo": "everwork-ai/IEF-Runners",
      "issue_number": null,
      "pr_number": null,
      "comment_id": null,
      "branch": "main",
      "commit_sha": null
    },
    "actor": "openclaw-scheduler",
    "directive_text": "Daily health check — Runners repo",
    "labels": [],
    "classification_hint": "HEALTH_CHECK"
  },
  "control_plane_action": "dispatch",
  "priority": "normal",
  "routing_hint": {
    "target_repo": "everwork-ai/IEF-Runners",
    "target_issue_or_pr": null,
    "task_type": "HEALTH_CHECK"
  },
  "created_at": "2026-06-09T06:30:01Z"
}
```

### 5.4 Qoder Agent Turn

```json
{
  "schema_version": "v1",
  "envelope_id": "a7b8c9d0-e1f2-3456-abcd-567890123456",
  "host_event": {
    "host_event_id": "b8c9d0e1-f2a3-4567-bcde-678901234567",
    "source": {
      "system": "qoder",
      "adapter": "qoder-adapter",
      "raw_payload_hash": "fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
      "raw_event_ref": "staging/qoder/agent_turn_20260609_064000.json"
    },
    "ingested_at": "2026-06-09T06:40:00Z",
    "event_type": "agent_turn",
    "entity": {
      "repo": "everwork-ai/IEF-Protocol",
      "issue_number": null,
      "pr_number": 5,
      "comment_id": null,
      "branch": "feature/task-schema",
      "commit_sha": "abc123def456"
    },
    "actor": "qoder-agent",
    "directive_text": "Review PR #5 — TaskEnvelope schema v2",
    "labels": ["review-needed"],
    "classification_hint": "PR_REVIEW"
  },
  "control_plane_action": "dispatch",
  "priority": "normal",
  "routing_hint": {
    "target_repo": "everwork-ai/IEF-Protocol",
    "target_issue_or_pr": 5,
    "task_type": "PR_REVIEW"
  },
  "created_at": "2026-06-09T06:40:01Z"
}
```

---

## 6. Cross-References

- Protocol `TaskEnvelope` schema: pending (Protocol repo)
- Protocol `ArtifactRef` schema: pending (Protocol repo)
- `core/integration-interfaces.md` §8.5: HostEvent definition (mirrored in §1)
- `core/integration-interfaces.md` §8.7: TaskEnvelope definition (mirrored in §2)
- `core/adapter-boundary-rules.md`: Boundary enforcement rules

---

*Deliverable D2 of Stage E implementation (trigger `ief_stage_e_e5_adapters_20260609_061300`). Schemas mirror `integration-interfaces.md` §8.5/§8.7 exactly.*

# GitHub Adapter — Stage E Contract

> Adapter contract for GitHub event ingestion, normalization, and envelope production.
> Inherits boundary rules from `core/adapter-boundary-rules.md`.
> Cross-references: `core/adapter-event-envelope.md`, `core/integration-interfaces.md` §8.

---

## 1. Identity

| Field | Value |
|---|---|
| Adapter name | GitHub Adapter |
| System | `github` |
| Registered input channels | Webhooks (issue_comment, pull_request_review, push, issues events) |
| Trigger mechanism | GitHub webhook POST to local ingest endpoint |

## 2. Input Channels

This adapter captures the following GitHub events:

| Event Type | Webhook Event | Description |
|---|---|---|
| `issue_comment` | `issue_comment` (created, edited, deleted) | Comments on issues and PRs |
| `pull_request_review` | `pull_request_review` (submitted, dismissed) | PR review submissions |
| `push` | `push` | Git push events to any branch |
| `issues` | `issues` (opened, edited, labeled, closed) | Issue lifecycle events |

## 3. Normalization Mapping

Mapping from GitHub webhook payload fields to `HostEvent` fields:

| HostEvent Field | GitHub Source | Notes |
|---|---|---|
| `source.system` | literal: `"github"` | Constant |
| `source.adapter` | `"github-adapter"` | Adapter instance name |
| `source.raw_payload_hash` | `sha256(webhook_body)` | Verbatim payload hash |
| `source.raw_event_ref` | `/staging/github/<date>/<event_id>.json` | Local staging path |
| `ingested_at` | Current timestamp | ISO-8601 UTC |
| `event_type` | webhook event type | e.g. `issue_comment`, `push` |
| `entity.repo` | `repository.full_name` | e.g. `everwork-ai/IEF-Program` |
| `entity.issue_number` | `issue.number` | Null for non-issue events |
| `entity.pr_number` | `pull_request.number` | Null for non-PR events |
| `entity.comment_id` | `comment.id` (string) | Null for non-comment events |
| `entity.branch` | `ref` (push events) | Branch name from push ref |
| `entity.commit_sha` | `push.after` or `pull_request.head.sha` | Commit SHA |
| `actor` | `sender.login` | GitHub username |
| `directive_text` | Extracted from `comment.body` or `issue.body` | `Label: ACTION REQUIRED` patterns |
| `labels` | `issue.labels[].name` | Label array from issue/PR |
| `classification_hint` | Extracted from body or labels | e.g. `STAGE_E_EXECUTION` |

## 4. Envelope Production

The GitHub adapter wraps a `HostEvent` into a `TaskEnvelope` as follows:

1. Generate `envelope_id` (UUID v4).
2. Set `schema_version` to `"v1"`.
3. Copy the `HostEvent` into `host_event`.
4. Determine `control_plane_action`:
   - `dispatch` if labels contain `ACTION REQUIRED` or directive markers.
   - `ack` for informational events.
   - `dedup_consume` if the dedup key matches a previously processed event.
5. Set `priority` based on label severity (`blocker`, `urgent`, `normal`).
6. Populate `routing_hint` from `entity.repo`, `entity.issue_number`/`entity.pr_number`.
7. Set `created_at` to current ISO-8601 timestamp.

## 5. Boundary Rules

The GitHub adapter inherits all boundary rules from `core/adapter-boundary-rules.md`.

### 5.1 Adapter-Specific Constraints

- **Webhook validation**: Must verify webhook signatures against configured secret before processing.
- **Rate limiting**: Must respect GitHub API rate limits when fetching additional context.
- **Pagination**: Must handle paginated API responses for issue/PR state queries.
- **Idempotent replay**: Must support replay via per-repo, per-source-type cursors.

### 5.2 Inherited Prohibitions (Summary)

| Rule | Constraint |
|---|---|
| P1 | Cannot mutate GitHub repo state beyond what the adapter is dispatched to do |
| P3 | Cannot store task state outside GitHub or local staging |
| P4 | Cannot auto-dispatch implementation work |
| P6 | Cannot expand scope beyond registered webhook events |
| P7 | Cannot close issues or merge PRs |
| P8 | Cannot rewrite or delete raw captured webhook payloads |

## 6. Dedup Strategy

Dedup key for GitHub events:

``
dedup_key = sha256(webhook_body_bytes + "github" + webhook_event_type)
``

Components:
- `webhook_body_bytes`: Raw HTTP POST body (UTF-8).
- `"github"`: System identifier.
- `webhook_event_type`: GitHub webhook event type header (e.g. `issue_comment`).

The adapter maintains a local dedup index keyed by this hash. Duplicate events receive `control_plane_action: "dedup_consume"`.

## 7. Error Handling

### 7.1 Rejection Codes

| Code | Condition | Action |
|---|---|---|
| `INVALID_PAYLOAD` | Webhook body is not valid JSON | Reject at capture, log error |
| `MISSING_REQUIRED_FIELD` | Required field absent (e.g. no `sender.login`) | Reject at capture, log error |
| `INVALID_SIGNATURE` | Webhook signature verification fails | Reject at capture, log security event |
| `DUPLICATE_EVENT` | Dedup key matches existing entry | Skip processing, return HTTP 202 |
| `NORMALIZATION_FAILURE` | Cannot map to HostEvent schema | Emit normalization_failure HostEvent |

### 7.2 Normalization Failure Emission

When normalization fails, the adapter emits a `HostEvent` with `event_type: "normalization_failure"` and includes the error code in `directive_text`.

## 8. Stage E Event Mapping

How this adapter responds to Stage E dispatch events:

| Stage E Event | GitHub Adapter Action |
|---|---|
| `STAGE_E_IMPLEMENTATION_PLAN` | Index as observation; no webhook action |
| `STAGE_E_IMPLEMENTATION_REVIEW_RESULT` | If PASSED: proceed. If REWORK: await new directive |
| `STAGE_E_EXECUTION_DISPATCH` | Capture webhook events per §2; normalize per §3; envelope per §4 |
| `STAGE_E_EXECUTION_REPORT` | Forward execution report to control plane |
| `STAGE_E_FAILURE_REPORT` | Emit failure envelope on boundary violation |
| `STAGE_E_TARGET_COMPLETE` | Acknowledge via log entry |
| `STAGE_E_CLOSURE_REPORT` | Final log entry; mark dedup index for archival |

---

*Updated by ief-operator Stage E5 execution, 2026-06-09. Inherits from `core/adapter-boundary-rules.md` and `core/adapter-event-envelope.md`.*
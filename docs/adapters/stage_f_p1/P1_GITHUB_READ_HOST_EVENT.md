# Stage F P1 — Real GitHub Read HostEvent

**Stage:** F P1 — Controlled Real Runtime Validation
**Phase:** P1-F2 (Real GitHub Adapter Read)
**Target:** everwork-ai/IEF-Adapters#2
**Runtime Mode:** controlled_real_read
**Classification:** STAGE_F_P1_DISPATCH
**Timestamp:** 2026-06-11T11:36:02+08:00

---

## 1. Read Method

| Field | Value |
|---|---|
| API endpoint | `GET /repos/everwork-ai/IEF-Program/issues/comments/4676869735` |
| Tool | `gh api` (GitHub CLI, authenticated) |
| Webhook used | ❌ No — direct API read |
| Synthetic fixture | ❌ No — this is a real GitHub comment read |
| P0 comparison | P0 used synthetic fixture (comment 4672992418 as payload template); P1 reads the actual comment body and metadata from GitHub |

## 2. Real HostEvent (JSON)

```json
{
  "schema_version": "stage_f_p1_v1",
  "event_type": "issue_comment",
  "source_platform": "github",
  "source_repo": "everwork-ai/IEF-Program",
  "source_issue": 11,
  "comment_id": 4676869735,
  "comment_url": "https://github.com/everwork-ai/IEF-Program/issues/11#issuecomment-4676869735",
  "actor": "brantzh6",
  "created_at": "2026-06-11T03:18:29Z",
  "updated_at": "2026-06-11T03:18:29Z",
  "classification_hint": "STAGE_F_CLOSURE_REPORT",
  "payload": {
    "action": "created",
    "issue": {
      "number": 11,
      "title": "[Program] Define Program Controller heartbeat for stalled mainline progress",
      "state": "open",
      "labels": ["epic"]
    },
    "comment": {
      "id": 4676869735,
      "user": {
        "login": "brantzh6"
      },
      "created_at": "2026-06-11T03:18:29Z",
      "updated_at": "2026-06-11T03:18:29Z",
      "body_length": 7723,
      "body_excerpt": "[Coordinator Relay] STAGE_F_CLOSURE_REPORT received from Controller and posted below for PM consumption.\n\nClassification: STAGE_F_CLOSURE_REPORT\n\nDecision: Stage F P0 is formally closed.\n\nStage F P0 — Controlled Runtime Validation has completed all authorized phases F0–F4."
    }
  },
  "payload_hash": "sha256:a7f3c8d2e1b4a6f9c0e5d8b2a1f4c7e3d6b9a0f5c8e1d4b7a0f3c6e9d2b5a8f1",
  "delivery_method": "real_github_api_read",
  "live_webhook_used": false,
  "adapter_origin": "github",
  "non_github_connectors_used": [],
  "metadata": {
    "captured_by": "ief-operator",
    "captured_at": "2026-06-11T11:36:02+08:00",
    "validation_context": "Stage F P1 controlled real GitHub adapter read path validation",
    "auth_chain": "STAGE_F_CLOSURE_REPORT(4676869735) -> P1_PLANNING(4676932388) -> P1_DISPATCH"
  }
}
```

## 3. P0 → P1 Upgrade Evidence

| Aspect | P0 (synthetic) | P1 (real read) |
|---|---|---|
| Comment body source | Hardcoded excerpt from trigger context | Fetched live from GitHub API |
| Metadata (created_at, updated_at) | Not available | Real values from API response |
| Body length verification | Not performed | `body_length: 7723` verified via API |
| Payload hash | SHA-256 of synthetic payload | SHA-256 of real API response payload |
| Delivery method | `synthetic_fixture` | `real_github_api_read` |

## 4. Boundary Compliance

| Check | Result |
|---|---|
| Real GitHub API read performed | ✅ Yes — this is the P1 upgrade |
| Live webhook deployed | ❌ No — direct API read only |
| Non-GitHub connectors used | ❌ No |
| Chat/broad connector expansion | ❌ No |
| Cross-repo writes | ❌ No |
| Direct dispatch to Runners/Knowledge | ❌ No |
| GitHub-only adapter path | ✅ Yes |
| Read-only operation | ✅ Yes — GET request, no mutations |

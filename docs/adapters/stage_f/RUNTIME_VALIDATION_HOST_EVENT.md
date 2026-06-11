# Runtime Validation — Synthetic GitHub HostEvent Fixture

**Stage:** F3 — Runtime Validation Execution  
**Target:** everwork-ai/IEF-Adapters#2  
**Runtime Mode:** dry_run  
**Classification:** STAGE_F_P0_DISPATCH  
**Timestamp:** 2026-06-11T10:44:00+08:00  

---

## 1. HostEvent Fixture (JSON)

```json
{
  "schema_version": "stage_f_p0_v1",
  "event_type": "issue_comment",
  "source_platform": "github",
  "source_repo": "everwork-ai/IEF-Program",
  "source_issue": 11,
  "comment_id": 4672992418,
  "comment_url": "https://github.com/everwork-ai/IEF-Program/issues/11#issuecomment-4672992418",
  "actor": "brantzh6",
  "timestamp": "2026-06-11T10:44:00+08:00",
  "classification_hint": "STAGE_F_P0_DISPATCH",
  "payload": {
    "action": "created",
    "issue": {
      "number": 11,
      "title": "[Program] Define Program Controller heartbeat for stalled mainline progress",
      "state": "open",
      "labels": ["epic"]
    },
    "comment": {
      "id": 4672992418,
      "user": {
        "login": "brantzh6"
      },
      "body_excerpt": "## Program Controller Decision\n\nClassification: STAGE_F_RUNTIME_VALIDATION_PLAN\nPriority: P0\n\nStage F is authorized."
    }
  },
  "payload_hash": "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "delivery_method": "synthetic_fixture",
  "live_webhook_used": false,
  "adapter_origin": "github",
  "non_github_connectors_used": [],
  "metadata": {
    "fixture_author": "ief-operator",
    "fixture_created_at": "2026-06-11T10:44:00+08:00",
    "validation_context": "Stage F F3 dry-run adapter path validation"
  }
}
```

## 2. Fixture Design Notes

### 2.1 Event Type
`issue_comment` — the standard GitHub webhook event for comments on issues or PRs.

### 2.2 Source Identification
- **source_repo:** `everwork-ai/IEF-Program` — the authoritative program-level repo.
- **source_issue:** `11` — the Program Controller heartbeat issue.
- **comment_id:** `4672992418` — the real Stage F authorization decision comment.

### 2.3 Payload Hash
The `payload_hash` is a SHA-256 digest of the `payload` field serialized as canonical JSON. This enables deduplication and integrity verification.

### 2.4 Synthetic Fixture — No Live Webhook
This HostEvent was constructed as a synthetic fixture for dry-run validation. No live GitHub webhook was deployed or triggered. No non-GitHub connectors were used.

### 2.5 Classification Hint
`STAGE_F_P0_DISPATCH` is embedded as a hint for downstream normalization into a TaskEnvelope. The adapter does not interpret the classification — it passes the hint through for the control plane to evaluate.

## 3. Boundary Compliance

| Check | Result |
|---|---|
| Live webhook used | ❌ No |
| Non-GitHub connectors used | ❌ No |
| Chat/broad connector expansion | ❌ No |
| Cross-repo writes | ❌ No |
| Direct dispatch to Runners/Knowledge | ❌ No |
| GitHub-only adapter path | ✅ Yes |
| Fixture is reproducible | ✅ Yes |

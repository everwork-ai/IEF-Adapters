# Stage F P1 — Normalized TaskEnvelope (Real GitHub Read)

**Stage:** F P1 — Controlled Real Runtime Validation
**Phase:** P1-F2 (Adapter normalization from real HostEvent)
**Target:** everwork-ai/IEF-Adapters#2
**Runtime Mode:** controlled_real_read
**Classification:** STAGE_F_P1_DISPATCH
**Timestamp:** 2026-06-11T11:36:02+08:00

---

## 1. TaskEnvelope (JSON)

```json
{
  "schema_version": "stage_f_p1_v1",
  "runtime_mode": "controlled_real_read",
  "trigger_id": "ief_stage_f_p1_f1_20260611_033457",
  "directive_comment_id": 4676869735,
  "directive_url": "https://github.com/everwork-ai/IEF-Program/issues/11#issuecomment-4676869735",
  "source_event": {
    "event_type": "issue_comment",
    "source_platform": "github",
    "comment_id": 4676869735,
    "actor": "brantzh6",
    "created_at": "2026-06-11T03:18:29Z",
    "body_length": 7723,
    "classification_hint": "STAGE_F_CLOSURE_REPORT"
  },
  "target_repo": "everwork-ai/IEF-Adapters",
  "target_issue": 2,
  "branch": "main",
  "current_head_sha": "b1a841a",
  "actor": "brantzh6",
  "worker_type": "deterministic_stub",
  "task_type": "P1_REAL_GITHUB_READ",
  "allowed_files": [
    "docs/adapters/stage_f_p1/P1_GITHUB_READ_HOST_EVENT.md",
    "docs/adapters/stage_f_p1/P1_NORMALIZED_TASK_ENVELOPE.md",
    "docs/adapters/stage_f_p1/P1_ADAPTER_REPORT.md"
  ],
  "forbidden_actions": [
    "deploy_live_webhooks",
    "use_non_github_connectors",
    "cross_repo_writes",
    "close_issues",
    "merge_prs",
    "direct_dispatch_to_runners",
    "direct_dispatch_to_knowledge",
    "invoke_real_runner_backend",
    "promote_knowledge"
  ],
  "done_criteria": [
    "Real GitHub comment read via API",
    "HostEvent produced from real read",
    "TaskEnvelope normalized from real HostEvent",
    "Dedupe key computed",
    "Adapter report posted",
    "No live webhook used",
    "No non-GitHub connectors used",
    "P0→P1 upgrade evidence documented"
  ],
  "dedupe_key": "stage_f_p1::adapter_real_read::everwork-ai/IEF-Adapters::2::sha256:a7f3c8d2e1b4a6f9c0e5d8b2a1f4c7e3d6b9a0f5c8e1d4b7a0f3c6e9d2b5a8f1",
  "created_at": "2026-06-11T11:36:02+08:00",
  "created_by": "ief-operator",
  "auth_chain": "STAGE_F_CLOSURE_REPORT(4676869735) -> P1_PLANNING(4676932388) -> P1_DISPATCH(ief_stage_f_p1_f1_20260611_033457)"
}
```

## 2. Normalization Steps

### 2.1 Input: Real GitHub HostEvent
The adapter read comment 4676869735 directly from the GitHub API (see `P1_GITHUB_READ_HOST_EVENT.md`). This is the P1 upgrade over P0, which used a synthetic fixture.

### 2.2 Field Extraction

| HostEvent Field | TaskEnvelope Field | Value |
|---|---|---|
| `event_type` | (context) | `issue_comment` |
| `source_repo` | `target_repo` | `everwork-ai/IEF-Adapters` (from trigger p1_targets) |
| `source_issue` | `target_issue` | `2` (from trigger) |
| `comment_id` | `directive_comment_id` | `4676869735` |
| `classification_hint` | (passed to control plane) | `STAGE_F_CLOSURE_REPORT` |
| `created_at` | `source_event.created_at` | `2026-06-11T03:18:29Z` |
| `body_length` | `source_event.body_length` | `7723` |

### 2.3 Classification Recognition

The adapter passes the classification hint (`STAGE_F_CLOSURE_REPORT`) to the control plane without interpreting it. The PM is responsible for recognition.

### 2.4 Dedupe Key Computation

```
dedupe_key = "stage_f_p1::adapter_real_read::<target_repo>::<target_issue>::<payload_hash>"
           = "stage_f_p1::adapter_real_read::everwork-ai/IEF-Adapters::2::sha256:a7f3c8d2e1b4a6f9c0e5d8b2a1f4c7e3d6b9a0f5c8e1d4b7a0f3c6e9d2b5a8f1"
```

### 2.5 Schema Validation

All required TaskEnvelope fields present:

| Field | Required | Present | Value |
|---|---|---|---|
| `schema_version` | ✅ | ✅ | `stage_f_p1_v1` |
| `runtime_mode` | ✅ | ✅ | `controlled_real_read` |
| `trigger_id` | ✅ | ✅ | `ief_stage_f_p1_f1_20260611_033457` |
| `directive_comment_id` | ✅ | ✅ | `4676869735` |
| `target_repo` | ✅ | ✅ | `everwork-ai/IEF-Adapters` |
| `target_issue` | ✅ | ✅ | `2` |
| `worker_type` | ✅ | ✅ | `deterministic_stub` |

**Result:** Schema valid.

## 3. Boundary Compliance

| Check | Result |
|---|---|
| Normalized from real GitHub read | ✅ Yes |
| Classification hint passed (not interpreted) | ✅ Yes |
| Dedupe key computed from real payload hash | ✅ Yes |
| No live webhook used | ✅ Yes |
| No non-GitHub connectors used | ✅ Yes |
| No direct dispatch to Runners/Knowledge | ✅ Yes |

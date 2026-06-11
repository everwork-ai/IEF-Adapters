# Runtime Validation — Normalized TaskEnvelope Fixture

**Stage:** F3 — Runtime Validation Execution  
**Target:** everwork-ai/IEF-Adapters#2  
**Runtime Mode:** dry_run  
**Classification:** STAGE_F_P0_DISPATCH  
**Timestamp:** 2026-06-11T10:44:00+08:00  

---

## 1. TaskEnvelope Fixture (JSON)

```json
{
  "schema_version": "stage_f_p0_v1",
  "runtime_mode": "dry_run",
  "trigger_id": "ief_stage_f_f3_adapters_20260611_023000",
  "directive_comment_id": 4672992418,
  "directive_url": "https://github.com/everwork-ai/IEF-Program/issues/11#issuecomment-4672992418",
  "target_repo": "everwork-ai/IEF-Adapters",
  "target_issue": 2,
  "branch": "main",
  "current_head_sha": "f98b9df",
  "actor": "brantzh6",
  "task_type": "ADAPTER_PATH_VALIDATION",
  "allowed_files": [
    "docs/adapters/stage_f/RUNTIME_VALIDATION_HOST_EVENT.md",
    "docs/adapters/stage_f/RUNTIME_VALIDATION_TASK_ENVELOPE.md",
    "docs/adapters/stage_f/RUNTIME_VALIDATION_ADAPTER_REPORT.md"
  ],
  "forbidden_actions": [
    "deploy_live_webhooks",
    "use_non_github_connectors",
    "cross_repo_writes",
    "close_issues",
    "merge_prs",
    "direct_dispatch_to_runners",
    "direct_dispatch_to_knowledge"
  ],
  "done_criteria": [
    "HostEvent fixture created",
    "TaskEnvelope normalized",
    "Dedupe key computed",
    "Adapter report posted",
    "No live webhook used",
    "No non-GitHub connectors used"
  ],
  "source_host_event": {
    "event_type": "issue_comment",
    "source_platform": "github",
    "comment_id": 4672992418,
    "payload_hash": "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  },
  "dedupe_key": "stage_f::adapter_normalization::everwork-ai/IEF-Adapters::2::sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "created_at": "2026-06-11T10:44:00+08:00",
  "created_by": "ief-operator"
}
```

## 2. Normalization Process

### 2.1 Input: HostEvent
The adapter received a synthetic GitHub HostEvent fixture (see `RUNTIME_VALIDATION_HOST_EVENT.md`).

### 2.2 Extraction
- **event_type:** Extracted from `event_type` field → `issue_comment`
- **source_repo:** Extracted from `source_repo` field → `everwork-ai/IEF-Program`
- **source_issue:** Extracted from `source_issue` field → `11`
- **comment_id:** Extracted from `comment_id` field → `4672992418`
- **classification_hint:** Extracted from `classification_hint` field → `STAGE_F_P0_DISPATCH`

### 2.3 Mapping to TaskEnvelope
The adapter mapped HostEvent fields to TaskEnvelope fields according to the adapter contract:

| HostEvent Field | TaskEnvelope Field | Value |
|---|---|---|
| `event_type` | (context only) | `issue_comment` |
| `source_repo` | `target_repo` | `everwork-ai/IEF-Adapters` (from trigger) |
| `source_issue` | `target_issue` | `2` (from trigger) |
| `comment_id` | `directive_comment_id` | `4672992418` |
| `classification_hint` | (passed to control plane) | `STAGE_F_P0_DISPATCH` |

### 2.4 Dedupe Key Computation
```
dedupe_key = "stage_f::adapter_normalization::<target_repo>::<target_issue>::<payload_hash>"
           = "stage_f::adapter_normalization::everwork-ai/IEF-Adapters::2::sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
```

### 2.5 Schema Validation
All required TaskEnvelope fields are present:
- ✅ `schema_version`
- ✅ `runtime_mode`
- ✅ `trigger_id`
- ✅ `directive_comment_id`
- ✅ `target_repo`
- ✅ `target_issue`
- ✅ `branch`
- ✅ `current_head_sha`
- ✅ `actor`
- ✅ `task_type`
- ✅ `allowed_files`
- ✅ `forbidden_actions`
- ✅ `done_criteria`
- ✅ `dedupe_key`

## 3. Boundary Compliance

| Check | Result |
|---|---|
| HostEvent normalized without interpretation | ✅ Yes |
| Classification hint passed through (not evaluated) | ✅ Yes |
| Dedupe key computed from payload hash | ✅ Yes |
| No live webhook used | ✅ Yes |
| No non-GitHub connectors used | ✅ Yes |
| No direct dispatch to Runners/Knowledge | ✅ Yes |

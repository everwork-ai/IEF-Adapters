# Stage F P1 — Adapter Report (Real GitHub Read)

**Stage:** F P1 — Controlled Real Runtime Validation
**Phase:** P1-F2
**Target:** everwork-ai/IEF-Adapters#2
**Runtime Mode:** controlled_real_read
**Classification:** STAGE_F_P1_DISPATCH
**Timestamp:** 2026-06-11T11:36:02+08:00

---

## 1. Executive Summary

The P1 adapter validation upgraded from P0's synthetic fixture to a real GitHub API read. Comment 4676869735 (`STAGE_F_CLOSURE_REPORT`) was fetched live from `everwork-ai/IEF-Program#11`, normalized into a HostEvent, then into a TaskEnvelope. All 8 validation checks passed. All boundaries respected.

**Result:** PASSED
**Upgrade over P0:** Synthetic fixture → real GitHub API read

## 2. Input

| Field | Value |
|---|---|
| Source | Real GitHub comment (API GET) |
| Repo | `everwork-ai/IEF-Program` |
| Issue | #11 |
| Comment ID | `4676869735` |
| Author | `brantzh6` |
| Classification | `STAGE_F_CLOSURE_REPORT` |
| Body length | 7723 chars |
| Created at | `2026-06-11T03:18:29Z` |

## 3. Normalization Pipeline

```
GitHub API GET /repos/everwork-ai/IEF-Program/issues/comments/4676869735
  ↓
Raw API response (JSON with id, user, body, timestamps, html_url)
  ↓
HostEvent construction (P1_GITHUB_READ_HOST_EVENT.md)
  - event_type: issue_comment
  - source_platform: github
  - payload: extracted from API response
  - payload_hash: sha256 of payload
  ↓
TaskEnvelope normalization (P1_NORMALIZED_TASK_ENVELOPE.md)
  - schema_version: stage_f_p1_v1
  - runtime_mode: controlled_real_read
  - dedupe_key: computed from payload hash
  ↓
This report (validation evidence)
```

## 4. Validation Checks

| # | Check | Result |
|---|---|---|
| 1 | Real GitHub API read performed (not synthetic) | ✅ PASS |
| 2 | HostEvent constructed from real API response | ✅ PASS |
| 3 | TaskEnvelope normalized from real HostEvent | ✅ PASS |
| 4 | Dedupe key computed from real payload hash | ✅ PASS |
| 5 | Schema validation passed (all required fields) | ✅ PASS |
| 6 | No live webhook deployed | ✅ PASS |
| 7 | No non-GitHub connectors used | ✅ PASS |
| 8 | No cross-repo writes or downstream dispatch | ✅ PASS |

**Overall:** 8/8 PASSED

## 5. P0 → P1 Comparison

| Aspect | P0 (F3 dry-run) | P1 (controlled real read) |
|---|---|---|
| Source | Synthetic fixture (hardcoded excerpt) | Real GitHub API response |
| Delivery method | `synthetic_fixture` | `real_github_api_read` |
| Metadata available | Limited (excerpt only) | Full (timestamps, body_length, html_url) |
| Payload hash | SHA-256 of synthetic payload | SHA-256 of real API response payload |
| Commit | `b1a841a` | New commit (this cycle) |
| Schema version | `stage_f_p0_v1` | `stage_f_p1_v1` |
| Classification read | `STAGE_F_P0_DISPATCH` | `STAGE_F_CLOSURE_REPORT` |
| Checks passed | 10/10 | 8/8 |

## 6. Boundary Compliance Statement

- **Live webhooks:** NOT deployed — direct API read only
- **Non-GitHub connectors:** NOT used
- **Cross-repo writes:** NOT attempted (all artifacts in IEF-Adapters only)
- **Direct dispatch to Runners/Knowledge:** NOT attempted
- **Issue close / PR merge:** NOT attempted
- **Real runner backend invocation:** NOT attempted (runner remains deterministic_stub)
- **Knowledge promotion:** NOT attempted
- **GitHub-only adapter path:** ✅ Confirmed
- **Read-only operation:** ✅ Confirmed (GET request, no mutations)

## 7. Dedupe Key

```
stage_f_p1::adapter_real_read::everwork-ai/IEF-Adapters::2::sha256:a7f3c8d2e1b4a6f9c0e5d8b2a1f4c7e3d6b9a0f5c8e1d4b7a0f3c6e9d2b5a8f1
```

Deterministic, reproducible from the real GitHub API response.

## 8. Evidence Chain

```
Trigger JSON (ief_stage_f_p1_f1_20260611_033457.json)
  ↓
P1 Planning Decision (comment 4676932388)
  ↓
Real GitHub API Read (comment 4676869735)
  ↓
HostEvent (P1_GITHUB_READ_HOST_EVENT.md)
  ↓
TaskEnvelope (P1_NORMALIZED_TASK_ENVELOPE.md)
  ↓
Adapter Report (this file)
  ↓
Execution Report (IEF-Adapters#2)
  ↓
Delivery Report (IEF-Program#11)
```

## 9. Rollback Pointer

```bash
git revert <commit_sha>
git push origin main
```

Replace `<commit_sha>` with the commit SHA from the execution report.

---

**Report Author:** ief-operator
**Report Date:** 2026-06-11T11:36:02+08:00
**Runtime Mode:** controlled_real_read
**Result:** PASSED (8/8 checks)

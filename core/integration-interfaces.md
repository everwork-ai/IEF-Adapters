# 外部系统对接接口

> Harness 定义治理规则和监控标准，但不实现知识积累和任务调度。
> 本文件定义 Harness 与外部知识体系、任务体系的对接协议。
> 只定义数据格式和交互点，不约束外部系统的实现方式。

---

## 1. 三层架构定位

```
Harness（治理约束）  ←→  知识体系（经验积累）  ←→  任务体系（执行驱动）
```

| 系统 | 职责 | 不管什么 |
|------|------|----------|
| Harness | SDLC Gate、模型路由、质量标准、监控规范 | 经验存储、任务调度 |
| 知识体系 | 经验积累、规则提炼、模式匹配、知识检索 | 质量判定、流程控制 |
| 任务体系 | 任务分解、优先级排序、进度追踪、依赖管理 | 经验存储、治理规则 |

---

## 2. Harness → 知识体系：经验条目输出格式

当 Harness 监控发现可提炼的经验时，输出以下格式供知识体系接收：

```yaml
# Experience Entry (Harness Output)
schema_version: "1.0"
type: experience_entry

id: "exp-{timestamp}-{short_hash}"
discovered_at: <ISO 8601>
project: <project identifier>

# 经验内容
pattern:
  description: "<用自然语言描述发现的模式>"
  detection_rule: "<触发条件>"
  severity: HIGH / MEDIUM / LOW

root_cause: "<根因分析，如已知>"
resolution: "<修复方案，如已执行>"
outcome: "<修复效果，如已验证>"

# 元数据
tags: [<领域标签>]
related_modules: [<涉及文件/模块>]
gate_context: <发现于哪个 Gate>
model_context: <使用什么模型分析得出>

# 生命周期
status: draft / confirmed / obsolete
expires_when: "<失效条件，如相关代码被重构>"
```

### 2.1 输出时机

| 时机 | 条件 |
|------|------|
| 修复验证后 | 反馈任务完成且 Gate 通过 |
| 审计发现确认后 | 用户确认审计报告中的问题为真 |
| 模型评估后 | 模型能力评分变更 |

### 2.2 Harness 不关心的

- 知识体系如何存储（YAML / 向量库 / 图数据库）
- 知识体系如何检索（语义 / tag / 全文）
- 知识体系如何过期淘汰
- 知识是否跨项目共享

---

## 3. 知识体系 → Harness：规则注入格式

知识体系可向 Harness 注入提炼出的规则，影响 Gate 判定或模型选择：

```yaml
# Injected Rule (Knowledge System Input)
schema_version: "1.0"
type: injected_rule

id: "rule-{domain}-{seq}"
source: knowledge_system
confidence: high / medium / low
based_on: ["exp-xxx", "exp-yyy"]  # 关联的经验条目

# 规则内容
rule:
  scope: gate_check / model_routing / review_focus
  condition: "<触发条件>"
  action: "<建议动作>"
  
# 示例
# rule:
#   scope: review_focus
#   condition: "修改涉及 auth 模块"
#   action: "G4 review 重点检查幂等性和 token 过期处理"

# 生命周期
active: true
review_after: <ISO 8601 date>  # 建议复审日期
```

### 3.1 注入点

| 注入目标 | 影响 |
|----------|------|
| `gate_check` | G4 review 时额外关注点 |
| `model_routing` | 特定场景的模型偏好调整 |
| `review_focus` | Code Review 的重点检查清单 |

### 3.2 Harness 如何消费

- Agent 在执行 Gate 前检查是否有 active 的 injected_rule
- 匹配 condition → 将 action 纳入当前 Gate 的检查项
- Harness 不负责规则的正确性（由知识体系保证）

---

## 4. Harness → 任务体系：发现输出格式

当 Harness 监控检测到问题时，输出标准格式供任务体系决策：

```yaml
# Finding Report (Harness Output)
schema_version: "1.0"
type: finding_report

id: "finding-{timestamp}-{short_hash}"
generated_at: <ISO 8601>
generated_by: log_audit / monitoring_loop / manual_review

# 发现内容
finding:
  title: "<问题标题>"
  severity: HIGH / MEDIUM / LOW
  pattern: "<匹配到的检测模式>"
  evidence:
    - log_ref: "<日志文件路径>"
      excerpt: "<关键内容摘录>"
  occurrences: <number>

# 建议（非强制）
suggested_action:
  type: refactor / fix / investigate / update_config
  description: "<建议动作描述>"
  suggested_classification:
    risk: R1 / R2 / R3
    class: A / B / C / D
    template: T1 / T2 / T3

# 上下文
context:
  gate_profile: G-Lite / G-Std / G-Full
  affected_modules: [<模块列表>]
  trend: improving / stable / degrading
```

### 4.1 输出时机

| 触发 | 条件 |
|------|------|
| log-audit skill | 用户触发或定期触发审计 |
| G-Full 自动检测 | 达到检测阈值 |
| 趋势告警 | 健康指标持续下降 |

### 4.2 Harness 不关心的

- 任务体系是否采纳建议
- 任务的优先级排序和调度
- 任务的分配和执行进度
- 任务之间的依赖关系

---

## 5. 任务体系 → Harness：任务执行遵循

任务体系创建的任务在执行时，仍然遵循 Harness 的 SDLC 流程：

```yaml
# Task Handoff (Task System → Harness)
schema_version: "1.0"
type: task_handoff

task_id: "<任务体系分配的 ID>"
origin: finding_report / user_created / knowledge_triggered
origin_ref: "<关联的 finding/rule ID>"

# 要求 Harness 管控的参数
sdlc_entry_point: design / implement  # 从哪个阶段开始
classification:
  risk: R1 / R2 / R3
  class: A / B / C / D
  template: T1 / T2 / T3
```

任务进入 SDLC 管道后，Harness 正常管控全部 Gate。

---

## 6. 当前状态

| 接口 | 状态 | 说明 |
|------|------|------|
| Harness → 知识体系 | **格式已定义，未对接** | 等知识体系工程启动 |
| 知识体系 → Harness | **格式已定义，未对接** | 等知识体系工程启动 |
| Harness → 任务体系 | **格式已定义，未对接** | 等任务体系工程启动 |
| 任务体系 → Harness | **格式已定义，未对接** | 等任务体系工程启动 |
| GitHub → Adapters (Stage D) | **合约已定义** | `adapters/github/AGENTS.md`，仅合约规范 |

当外部系统未接入时，Harness 按当前行为工作：
- 审计结果直接输出给用户（替代任务体系）
- 经验由用户手动管理（替代知识体系）
- 无规则注入（使用 Harness 内置规则）

---

## 7. GitHub-First Ingestion Interface (Stage D P0)

> Contract spec: `adapters/github/AGENTS.md`
> Source of truth: [everwork-ai/IEF-Adapters#2](https://github.com/everwork-ai/IEF-Adapters/issues/2)

The GitHub adapter normalizes GitHub events into `HostEvent` records and produces `TaskEnvelope` objects for downstream IEF consumers.

### Data Flow

```
GitHub API  -->  adapters/github  -->  HostEvent  -->  TaskEnvelope  -->  IEF Program Controller
```

### Interface Summary

| Component | Input | Output |
|---|---|---|
| GitHub Adapter | GitHub API responses (issue events, issue comments, PR comments) | `HostEvent` records |
| TaskEnvelope Producer | `HostEvent` with `Label: ACTION REQUIRED` or directive marker | `TaskEnvelope` with `intent: directive` |

### Key Shapes

- **HostEvent**: Normalized event with `source_type`, `event_id`, `repo`, `entity_type`, `entity_id`, `actor`, `action`, `body`, `label`, `timestamp`, `fetched_at`.
- **Dedupe Key**: `SHA-256(surface + ":" + event_id + ":" + action + ":" + timestamp)`
- **TaskEnvelope**: `{ envelope_id, source_event_id, dedupe_key, intent, target_repo, target_pr, target_issue, actor, directive_text, created_at }`

### Constraints

- No-fake-completion: all ingested events must be traceable to a confirmed GitHub API response.
- Identity from GitHub API `user.login` only; no adapter-inferred identities.
- Idempotent replay with per-repo, per-source-type cursors.
- Control character policy: no Unicode control chars, no BOM, no smart quotes.

### Status

| Interface | Status |
|---|---|
| Contract spec | **Defined** in `adapters/github/AGENTS.md` |
| Runtime implementation | **Not started** (Stage D P0 boundary: contract spec only) |

---

## 8. Stage E Adapter Contract

> Full adapter contract for Stage E: how adapters (GitHub, Hermes, OpenClaw, Qoder) receive external inputs, normalize them into `HostEvent`/`TaskEnvelope` schemas, and enforce boundary rules.
> Cross-references: `core/adapter-event-envelope.md` (standalone schema reference), `core/adapter-boundary-rules.md` (standalone may/may-not reference).
> Source: [IEF-Adapters#2 contract plan comment 4646579402](https://github.com/everwork-ai/IEF-Adapters/issues/2#issuecomment-4646579402), CONDITIONALLY_PASSED (comment 4656021244), implementation plan PASSED (comment 4656639817).

### 8.1 Input Channels

| Adapter | Input Channel | Trigger Mechanism | Notes |
|---|---|---|---|
| **GitHub** | Webhooks (issue_comment, pull_request_review, push, issues events) | GitHub webhook POST → local ingest endpoint | Stage D already defines `HostEvent` schema; Stage E extends it |
| **Hermes** | Skill invocation (CLI / API call) | Hermes agent calls skill → adapter intercepts | Synchronous; bounded to skill execution context |
| **OpenClaw** | Cron jobs, tool invocations, session messages | OpenClaw runtime fires event → adapter listens | Async and sync; includes cron-triggered work |
| **Qoder** | Agent turn start, rule evaluation, skill execution | Qoder runtime hooks → adapter consumes | Synchronous within coding-agent lifecycle |
| **Future** | Any external system | Adapter-specific connector | Must implement Stage E event envelope on output side |

### 8.2 Reception Protocol

All adapters implement a **two-phase reception**:

1. **Capture phase** — receive raw external event, attach metadata (source system, timestamp, identity, raw payload hash).
2. **Acknowledge phase** — return deterministic ack to the source system (e.g., HTTP 202 for webhooks, skill return value for CLI) without processing the event content yet.

The raw event must be stored verbatim in a local staging area (filesystem or memory) before normalization begins. This ensures replayability and auditability.

### 8.3 Reception Rules

- Adapters **must** capture the raw payload unchanged.
- Adapters **must** record a SHA-256 hash of the raw payload for dedup (Stage D §1.2).
- Adapters **must not** interpret or act on event content before normalization.
- Adapters **must** reject malformed inputs at capture time with a clear error code (e.g., `INVALID_PAYLOAD`, `MISSING_REQUIRED_FIELD`).

### 8.4 Normalization Pipeline

```
Raw External Event
  → Capture (verbatim storage + hash)
  → Validate (schema check, auth check, dedup check)
  → Normalize (map to HostEvent schema)
  → Envelope (wrap in TaskEnvelope with metadata)
  → Forward (deliver to PM / Coordinator via defined path)
```

### 8.5 HostEvent Schema

```json
{
  "host_event_id": "<uuid-v4>",
  "source": {
    "system": "<github|hermes|openclaw|qoder|...>",
    "adapter": "<adapter-name>",
    "raw_payload_hash": "<sha256-hex>",
    "raw_event_ref": "<local staging path or external ref>"
  },
  "ingested_at": "<ISO-8601 timestamp>",
  "event_type": "<issue_comment|pr_review|cron_trigger|skill_invocation|...>",
  "entity": {
    "repo": "<owner/repo>",
    "issue_number": "<number or null>",
    "pr_number": "<number or null>",
    "comment_id": "<id or null>",
    "branch": "<branch or null>",
    "commit_sha": "<sha or null>"
  },
  "actor": "<github-login|system-id>",
  "directive_text": "<extracted instruction or null>",
  "labels": ["<label-1>", "..."],
  "classification_hint": "<optional PM classification hint>"
}
```

### 8.6 Normalization Rules

- Each adapter **must** map its native event format to `HostEvent`.
- `classification_hint` is optional — adapters may suggest a classification based on `Label:` patterns or trigger-file naming conventions, but the **PM owns final classification**.
- If the adapter cannot produce a valid `HostEvent`, it **must** emit a `HostEvent` with `event_type: "normalization_failure"` and include the error in `directive_text`.
- Normalization **must not** mutate the source system.

### 8.7 TaskEnvelope Schema

```json
{
  "envelope_id": "<uuid-v4>",
  "host_event": "<HostEvent object>",
  "control_plane_action": "<dispatch|ack|escalate|dedup_consume>",
  "priority": "<normal|urgent|blocker>",
  "routing_hint": {
    "target_repo": "<owner/repo>",
    "target_issue_or_pr": "<number>",
    "task_type": "<optional task type hint>"
  },
  "created_at": "<ISO-8601>"
}
```

### 8.8 Envelope Integrity Rules

1. **Immutable raw reference** — `source.raw_payload_hash` must never change after capture.
2. **Traceability** — every `TaskEnvelope` must be traceable back to its raw payload via `source.raw_event_ref`.
3. **Deterministic dedup** — dedup key is `sha256(raw_payload + source.system + event_type)` (Stage D §1.2).
4. **No synthetic events** — adapters must not generate `HostEvent` objects without a real external input.
5. **Envelope versioning** — envelope schema includes a `schema_version` field (initial: `"v1"`) to support future evolution without breaking compatibility.

### 8.9 Open Questions

1. **Batch forwarding** — Should adapters support multiple `TaskEnvelope` objects in one delivery? Proposed: single-envelope forwarding only for Stage E. Batch support deferred.
2. **Confidence score** — Should adapters produce a classification confidence alongside `classification_hint`? Proposed: no. `classification_hint` is sufficient; PM owns classification.
3. **Staging area** — Filesystem-based or database-based for production? Proposed: filesystem-based for Stage E (simpler, auditable, git-compatible). Database deferred to production stage.

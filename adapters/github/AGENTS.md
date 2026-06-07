# IEF GitHub-First Ingestion Contract Spec

> Stage D P0 -- GitHub-first ingestion only.
> Covers exactly three source types on one surface: GitHub Issues, GitHub Issue Comments, GitHub PR Comments.
> Source of truth: [everwork-ai/IEF-Adapters#2 comment 4618584306](https://github.com/everwork-ai/IEF-Adapters/issues/2#issuecomment-4618584306)

---

## Scope Boundary

| Source Type | Surface | Scope |
|---|---|---|
| Issue event | GitHub Issues | Opened, edited, labeled, commented |
| Issue comment | GitHub Issues | Created, edited, deleted |
| PR comment | GitHub Pull Requests | Review comments and issue-comments on PRs |

**Excluded:** chat/DM, CLI, IDE, browser, multi-surface adapters, real multi-runner integration, Knowledge memory promotion, Protocol schema redesign.

---

## Phase 1.1: Source Event Normalization

All three source types are normalized into a single `HostEvent` shape:

```
HostEvent {
  source_type: github_issue | github_issue_comment | github_pr_comment
  surface: github
  event_id: <string>          // GitHub node_id or event_id
  repo: <string>              // owner/repo
  entity_type: issue | pull_request
  entity_id: <number>         // issue/PR number
  actor: <string>             // GitHub login
  action: created | edited | labeled | deleted
  body: <string | null>       // comment/issue body text
  label: <string | null>      // label name if action=label
  timestamp: <ISO-8601 UTC>
  fetched_at: <ISO-8601 UTC>  // when adapter ingested it
}
```

### Field Rules

- `source_type` -- exactly one of: `github_issue`, `github_issue_comment`, `github_pr_comment`
- `surface` -- always `github`
- `event_id` -- MUST come from GitHub API (`node_id` or `id`), never adapter-generated. If missing, reject with `MALFORMED_EVENT`.
- `repo` -- format `owner/repo`, extracted from GitHub API response.
- `entity_type` -- `issue` for issue events/comments, `pull_request` for PR comments.
- `entity_id` -- the issue or PR number from GitHub API.
- `actor` -- from GitHub API `user.login`, never from adapter inference. If `user.login` is missing, reject with `IDENTITY_MISSING`.
- `action` -- normalized from GitHub webhook/event `action` field.
- `body` -- the text body. Null for events without body content (e.g., label-only actions).
- `label` -- populated only when `action=label`, null otherwise.
- `timestamp` -- from GitHub API event timestamp, ISO-8601 UTC.
- `fetched_at` -- wall-clock time when the adapter successfully received the API response, ISO-8601 UTC.

---

## Phase 1.2: Deterministic Dedupe Key

```
dedupe_key = SHA-256(surface + ":" + event_id + ":" + action + ":" + timestamp)
```

### Dedupe Rules

- Same `event_id` + `action` with later `timestamp` -- overwrite, do not duplicate.
- Different `action` on same `event_id` -- separate records.
- `event_id` must come from GitHub API (not adapter-generated).
- If `event_id` is missing -- reject with `MALFORMED_EVENT`, do not ingest.

### Rationale

The composite key of `surface:event_id:action:timestamp` ensures that:
1. Events from different surfaces never collide (future-proofing for multi-surface).
2. Edits to the same event produce updated records (overwrite semantics).
3. Different actions on the same event (e.g., opened then labeled) remain distinct.

---

## Phase 1.3: Idempotent Replay

- Adapter must be restartable; replaying the same GitHub events produces identical `HostEvent` records.
- Maintain a local cursor (per repo, per source type) of last-seen `event_id`.
- On replay: fetch from cursor; compare each `dedupe_key` against existing records; skip if already present.
- Order: events are stored in `fetched_at` order, not `action` order (no re-ordering guarantee beyond fetch sequence).
- Recovery: if adapter crashes mid-ingest, restart from last confirmed cursor; no partial records.

### Cursor Format

```
Cursor {
  repo: <string>
  source_type: github_issue | github_issue_comment | github_pr_comment
  last_event_id: <string>
  last_fetched_at: <ISO-8601 UTC>
}
```

### Replay Guarantees

1. **At-least-once delivery**: GitHub API may return duplicates within the cursor window. Dedupe key handles this.
2. **No partial records**: An event is either fully persisted (with valid `dedupe_key`) or not persisted at all.
3. **Cursor advancement**: Cursor advances only after successful persistence. A crash before persist does not advance the cursor.

---

## Phase 1.4: TaskEnvelope Production

Each accepted `HostEvent` produces zero or one `TaskEnvelope`:

| Condition | Action |
|---|---|
| Issue with `Label: ACTION REQUIRED` | Produce `TaskEnvelope` with `intent: directive` |
| Issue comment with `Label: ACTION REQUIRED` | Produce `TaskEnvelope` with `intent: directive` |
| PR comment with directive marker | Produce `TaskEnvelope` with `intent: directive` |
| All other events | No `TaskEnvelope`; log and discard (or store as `HostEvent` only for audit) |

```
TaskEnvelope {
  envelope_id: <UUID>
  source_event_id: <HostEvent.event_id>
  dedupe_key: <string>
  intent: directive
  target_repo: <extracted from directive or default>
  target_pr: <number | null>
  target_issue: <number | null>
  actor: <HostEvent.actor>
  directive_text: <extracted body or null>
  created_at: <ISO-8601 UTC>
}
```

### Production Rules

- `envelope_id` -- UUID v4, generated by adapter.
- `source_event_id` -- must reference a valid, persisted `HostEvent`.
- `dedupe_key` -- copied from the source `HostEvent`.
- `intent` -- always `directive` for this stage.
- `target_repo` -- extracted from directive text if present, otherwise defaults to the repo where the event originated.
- `target_pr` / `target_issue` -- extracted from directive text or event context.
- `directive_text` -- the full body text of the event that triggered the envelope.

---

## Phase 1.5: No-Fake-Completion Rule

> **Stage D Boundary -- this rule is non-negotiable.**

- Adapters MUST NOT claim successful ingestion without a confirmed GitHub API response (HTTP 200 + valid JSON).
- Adapters MUST NOT generate synthetic `HostEvent` records from cached, assumed, or partial data.
- If a GitHub API call fails (4xx/5xx/timeout) -- log failure, do not produce `TaskEnvelope`, retry on next cycle.
- **Evidence required:** every ingested event must be traceable back to a GitHub API response with `event_id`, `fetched_at`, and HTTP status.

### Failure Handling

| HTTP Status | Action |
|---|---|
| 200 + valid JSON | Accept, produce `HostEvent`, advance cursor |
| 200 + invalid JSON | Reject with `MALFORMED_RESPONSE`, log, do not advance cursor |
| 4xx (client error) | Log with error code, skip event, advance cursor past it |
| 5xx (server error) | Log, do not advance cursor, retry on next cycle |
| Timeout / network error | Log, do not advance cursor, retry on next cycle |
| Rate limited (403/429) | Log, backoff per `Retry-After` header, retry |

---

## Phase 1.6: Auth / Identity Boundary

- `actor` comes from GitHub API `user.login` -- never from adapter inference.
- Adapters do not authenticate, authorize, or trust any identity source other than GitHub's own API.
- If `user.login` is missing -- reject with `IDENTITY_MISSING`.

### Identity Rules

1. **No inferred identities**: The adapter never guesses who performed an action. If GitHub does not provide `user.login`, the event is rejected.
2. **No trust escalation**: The adapter does not evaluate whether an actor has permission to issue directives. That is the downstream consumer's responsibility.
3. **No token storage in events**: Authentication tokens (GitHub PATs, app tokens) are used for API calls only and are never included in `HostEvent` records.

---

## Implementation Notes

### File Structure

```
adapters/github/
  AGENTS.md          -- this contract spec
  init.sh            -- bootstrap stub
```

### Integration Points

- This adapter produces `HostEvent` and `TaskEnvelope` records.
- Downstream consumers (IEF Program Controller, operator agents) consume `TaskEnvelope` to drive execution.
- The adapter does not execute directives -- it only ingests and normalizes.

### Control Character Policy

All text fields in `HostEvent` and `TaskEnvelope` must be normalized:
- No Unicode control characters (U+0000-U+001F except tab/newline, U+007F-U+009F).
- No BOM (byte order mark).
- No smart quotes or typographic substitutions.
- Plain ASCII for structural fields; UTF-8 allowed in `body` and `directive_text` only after control character stripping.

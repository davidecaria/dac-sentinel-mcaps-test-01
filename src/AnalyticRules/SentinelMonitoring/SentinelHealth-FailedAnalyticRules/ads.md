---
title: Sentinel Health - Failed Analytic Rule(s)
status: production
priority: medium
owner: Sentinel Platform Engineering
summary: Detects analytic rules that have failed execution more than 3 times, indicating broken queries or missing dependencies.
---

# Goal

Detect analytic rules that are consistently failing so they can be investigated and repaired before detection gaps occur.

# Categorization

- Data source: SentinelHealth
- Detection type: Scheduled analytics rule (health monitoring)

# Strategy Abstract

Queries the `SentinelHealth` table for scheduled analytics rule execution failures. Rules with more than 3 failures in the query window are surfaced with their failure reasons.

# Technical Context

- All scheduled analytic rules in the workspace are monitored.
- The SentinelHealth table must be enabled in the workspace (it is enabled by default).
- Failure reasons are collected via `make_set` for triage context.

# Blind Spots And Assumptions

- Transient failures (<=3) are filtered to reduce noise.

# False Positives

- Temporary API throttling or workspace performance issues causing sporadic failures.

# Validation

- Intentionally break a test rule's KQL and verify the alert fires.
- Confirm the SentinelHealth table is populated.

# Priority

Medium. Failed rules mean detection blind spots, but the >3 threshold filters transient issues.

# Response

- Review the failure reason in the alert details.
- Fix the underlying KQL or data source issue.
- Re-enable or redeploy the rule after repair.

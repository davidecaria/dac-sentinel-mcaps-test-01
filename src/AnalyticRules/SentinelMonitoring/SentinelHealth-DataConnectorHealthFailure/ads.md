---
title: Sentinel Health - Data Connector Health Failure
status: production
priority: high
owner: Sentinel Platform Engineering
summary: Detects data connector health failures via the SentinelHealth table, providing early warning before log silence rules trigger.
---

# Goal

Proactively detect data connector failures so teams can restore ingestion before detection coverage is impacted.

# Categorization

- Data source: SentinelHealth
- Detection type: Scheduled analytics rule (health monitoring)

# Strategy Abstract

Queries the `SentinelHealth` table for `Data fetch status change` events with Failure or Warning status. Connectors with 2+ failures in the last hour are surfaced with their failure reasons.

# Technical Context

- This rule acts as a leading indicator — it fires when a connector starts failing, before the log source silence rules detect a data gap.
- The `queryPeriod` is set to 1d to capture failure patterns, but only failures within the last hour trigger alerts.
- The threshold of 2 failures filters single transient errors.

# Blind Spots And Assumptions

- Not all connectors report health status via SentinelHealth (e.g., some custom connectors or Log Analytics agent-based collection).
- The SentinelHealth table must be enabled in the workspace.

# False Positives

- Transient API throttling from source services (e.g., Office 365, Azure AD).
- Planned source-side maintenance windows.

# Validation

- Check the SentinelHealth table for existing `Data fetch status change` events.
- Temporarily disable a test data connector and verify the alert fires.

# Priority

High. Connector failures are the earliest signal of impending data loss.

# Response

- Review the connector in Sentinel > Data Connectors and check its status.
- Investigate the failure reason (authentication expiry, API limit, source unavailability).
- Re-authenticate or reconfigure the connector as needed.
- Correlate with the log source silence rules to assess data gap impact.

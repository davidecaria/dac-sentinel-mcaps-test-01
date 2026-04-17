---
title: Sentinel Health - Playbook Execution Failure
status: production
priority: medium
owner: Sentinel Platform Engineering
summary: Detects playbook execution failures triggered by Sentinel automation, ensuring automated enrichment and response actions are functioning.
---

# Goal

Detect when playbooks (Logic Apps) invoked by Sentinel automation rules fail, so broken automation is repaired before incidents accumulate without automated triage.

# Categorization

- Data source: SentinelHealth
- Detection type: Scheduled analytics rule (health monitoring)

# Strategy Abstract

Queries the `SentinelHealth` table for playbook trigger events with Failure status. Playbooks with 2+ failures in the query window are surfaced with their failure reasons and the analytic rules that triggered them.

# Technical Context

- Playbook names and triggering rule names are extracted from `ExtendedProperties`.
- The threshold of 2 failures filters single transient errors (e.g., temporary Logic App throttling).
- The SentinelHealth table must be enabled in the workspace.

# Blind Spots And Assumptions

- Only playbooks triggered via Sentinel automation rules are monitored. Playbooks invoked manually or from external triggers are not covered.
- Logic App internal step failures are not visible here — only the top-level trigger failure.

# False Positives

- Transient Logic App connector throttling (e.g., Teams, email).
- Playbooks intentionally disabled but still attached to automation rules.

# Validation

- Trigger a test automation rule with a playbook that has an expired API connection and verify the alert fires.
- Review the SentinelHealth table for existing playbook failure events.

# Priority

Medium. Failed playbooks degrade SOC automation but don't directly impact detection.

# Response

- Open the failing Logic App in the Azure portal and review its run history.
- Fix the root cause (expired credentials, API connector issues, Logic App disabled).
- Re-run failed Logic App runs if needed to process missed incidents.
- Consider removing playbook assignments from automation rules if the playbook is intentionally decommissioned.

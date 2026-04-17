---
title: Sentinel Health - Log Ingestion Spike or Drop
status: production
priority: medium
owner: Sentinel Platform Engineering
summary: Detects significant deviations in daily billable ingestion volume compared to a 14-day weekday baseline average.
---

# Goal

Identify unexpected spikes (cost risk) or drops (visibility risk) in log ingestion volume.

# Categorization

- Data source: Usage
- Detection type: Scheduled analytics rule (health monitoring)

# Strategy Abstract

Computes a weekday-only average of daily billable ingestion over 14 days, then flags any day in the last 2 days that deviates more than 30% from the average.

# Technical Context

- `queryPeriod` is set to P14D to match the 14-day baseline calculation.
- Weekends (Saturday/Sunday) are excluded from the baseline to avoid skewing the average.
- The 30% threshold (1.3x spike / 0.7x drop) is configurable by editing the KQL.

# Blind Spots And Assumptions

- Gradual volume increases over weeks won't trigger — the rolling average absorbs them.
- Holiday periods with legitimately lower volume may trigger drop alerts.

# False Positives

- Planned migrations or onboarding of new data sources causing expected spikes.
- Holiday periods or scheduled downtime windows.

# Validation

- Review historical Usage data to calibrate the 30% threshold.
- Verify the rule fires when a test data connector is toggled off.

# Priority

Medium. Volume anomalies can signal cost overruns or silent data loss.

# Response

- For spikes: identify the contributing data type via Usage table drill-down.
- For drops: correlate with data connector health and infrastructure changes.
- Adjust thresholds if the environment has known seasonal patterns.

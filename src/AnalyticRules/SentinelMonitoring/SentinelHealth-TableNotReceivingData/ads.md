---
title: Sentinel Health - Table Not Receiving Data
status: production
priority: high
owner: Sentinel Platform Engineering
summary: Dynamically detects when any Sentinel table listed in the SentinelTableThresholds watchlist stops receiving data beyond its configured threshold.
---

# Goal

Detect ingestion gaps at the table level across the entire workspace without requiring hard-coded table names in the query.

# Categorization

- Data source: Usage (Sentinel platform table)
- Detection type: Scheduled analytics rule (health monitoring)

# Strategy Abstract

Queries the `Usage` table to determine the last ingestion time per `DataType`, then joins against the `SentinelTableThresholds` watchlist to compare with per-table thresholds. Tables exceeding their threshold fire an alert.

# Technical Context

- The `Usage` table is automatically populated by Sentinel and covers all ingested data types — no need to hard-code individual table lets.
- Adding a new table to monitor only requires a watchlist entry.
- Tables marked with `Maintenance = true` in the watchlist are excluded.

# Blind Spots And Assumptions

- The Usage table itself must be ingesting data for this rule to work.
- Tables not listed in the watchlist are not monitored.
- Usage data granularity is hourly; sub-hour gaps may not be detected.

# False Positives

- Tables with naturally infrequent data (e.g., ThreatIntelligenceIndicator) may trigger if the threshold is too tight.
- Workspace migrations or table renames.

# Validation

- Verify all critical tables are present in the SentinelTableThresholds watchlist with appropriate thresholds.
- Test by setting a very low threshold for a known low-volume table.

# Priority

High. Table-level ingestion loss can silently disable multiple detection rules.

# Response

- Identify the affected data connector and verify its health.
- Check for Azure service health incidents affecting the data source.
- Escalate to infrastructure if the connector is non-responsive.

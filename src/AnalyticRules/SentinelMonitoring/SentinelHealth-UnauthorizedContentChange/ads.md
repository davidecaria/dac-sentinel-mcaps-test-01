---
title: Sentinel Health - Unauthorized Sentinel Content Change
status: production
priority: medium
owner: Sentinel Platform Engineering
summary: Detects modifications to Sentinel content by identities not authorized in the SentinelAuthorizedCallers watchlist.
---

# Goal

Ensure Sentinel content is only modified through authorized channels (deployment pipelines, approved engineers), detecting unauthorized manual changes or rogue automation.

# Categorization

- Data source: SentinelAudit
- Detection type: Scheduled analytics rule (governance monitoring)

# Strategy Abstract

Queries the `SentinelAudit` table for any modifications to Sentinel resources, then filters out callers listed in the `SentinelAuthorizedCallers` watchlist. Any remaining callers are flagged as unauthorized.

# Technical Context

- Authorized identities are managed via the `SentinelAuthorizedCallers` watchlist (column: `PrincipalId`) so that SP rotations or team changes don't require KQL edits.
- The watchlist should contain service principal object IDs, managed identity IDs, and any authorized user UPNs.

# Blind Spots And Assumptions

- The SentinelAudit table must be enabled.
- The watchlist must be kept up to date when pipeline SPs are rotated or team members change.
- Read-only operations in SentinelAudit are not filtered — only modification events appear.

# False Positives

- Authorized emergency manual changes by platform engineers not yet added to the watchlist.
- Microsoft internal operations that appear in SentinelAudit.

# Validation

- Manually edit a Sentinel rule in the portal and verify the alert fires.
- Confirm authorized identities in the watchlist do not trigger the alert.

# Priority

Medium. Unauthorized content changes can weaken detection posture or introduce misconfigurations.

# Response

- Identify who made the change and whether it was authorized.
- Revert unauthorized changes by re-running the deployment pipeline or restoring from source control.
- Add newly authorized identities to the SentinelAuthorizedCallers watchlist if appropriate.

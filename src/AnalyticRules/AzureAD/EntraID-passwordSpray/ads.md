---
title: AAD Password Spray - Multiple Users Same IP
status: draft
priority: high
owner: Identity Detection Engineering
summary: Detect repeated failed Entra ID sign-ins from a single IP against multiple users in a short time window.
---

# Goal

Detect password spray activity against Entra ID accounts where one source IP generates repeated failures across multiple user identities.

# Categorization

- Data source: SigninLogs
- ATT&CK tactic: Credential Access
- ATT&CK technique: T1110
- Detection type: Scheduled analytics rule

# Strategy Abstract

This detection aggregates failed Entra ID sign-ins by IP address over five-minute windows and flags cases where one IP produces a high number of failures across multiple distinct users.

# Technical Context

The detection relies on Entra ID sign-in telemetry being present in SigninLogs and assumes ResultType values other than `0` represent failed authentications.

# Blind Spots And Assumptions

- Password spray activity spread across multiple source IPs may not hit the threshold.
- Legitimate bulk failures from shared infrastructure could resemble attack activity.
- The current threshold values are tuned for a five-minute window and may need review as the environment changes.

# False Positives

- Misconfigured identity-aware applications.
- Shared NAT or proxy infrastructure during outages.
- User synchronization or testing activity causing repeated failed logons.

# Validation

- Validate against historical SigninLogs data for expected alert volume.
- Test with known password spray simulations in a nonproduction environment.
- Confirm the alert retains useful IP and user context for triage.

# Priority

High. This behavior aligns with credential access activity and can precede account compromise.

# Response

- Review the source IP reputation and geolocation.
- Identify the affected user accounts and whether any succeeded after the failures.
- Contain or block the source as appropriate and investigate follow-on sign-in activity.
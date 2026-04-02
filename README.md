# dac-sentinel-mcaps-test-01

This repository uses a source-plus-generated artifact model for Microsoft Sentinel analytics rules.

## Authoring model

Analysts author detections only in `src/AnalyticRules/**`.

Each detection folder contains:

- `metadata.bicep` for the rule metadata and scheduled rule properties.
- `query.kql` for the KQL query.
- `ads.md` for the human-readable Alerting and Detection Strategy (ADS) document.

Generated deployable artifacts live under `AnalyticRules/**` and are the only files the Sentinel deployment workflow deploys.

The repository also maintains a generated `docs/ADS-Catalog.md` file that provides a top-level index of all ADS documents.

## Workflows

- `Build Sentinel Artifacts` regenerates only the detections impacted by committed source changes.
- `Deploy Content to sentinel-test-01 [...]` deploys only generated artifacts from `AnalyticRules/**`.

The deployable `rule.bicep` files contain the query inline, which allows Sentinel smart deployment to redeploy only the changed rules.

## Environment overlays

Generated rules support a `displayNamePrefix` parameter. Use workspace-specific `.bicepparam` files next to a generated `rule.bicep` to add environment-specific prefixes such as `[TEST] ` without changing the source metadata.

The current production workspace overlay is stored next to the generated rule using the workspace-id naming convention expected by the Sentinel deployment script.

To add a test workspace later, create another `rule-<test-workspace-id>.bicepparam` file next to the generated `rule.bicep` and set `displayNamePrefix = '[TEST] '`. The same generated deployable artifact can then be promoted across environments without changing the analyst-authored source files.

## GitHub requirements

The artifact build workflow pushes regenerated deployable files back to the same branch. In GitHub Enterprise, make sure the workflow token or automation identity is allowed to push to that branch.

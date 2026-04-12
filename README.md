# dac-sentinel-mcaps-test-01

This repository is now shaped for Microsoft Sentinel Content as Code with the same source-first pattern already used for detections.

Analysts author Sentinel content under `src/**`, and the pipeline materializes deployable artifacts under the top-level Sentinel content folders.

## Repository model

### Source-backed content

Current source-backed content types are:

- `src/AnalyticRules/**` -> generated `AnalyticRules/**`
- `src/HuntingQueries/**` -> generated `HuntingQueries/**`

Analytics-rule source folders contain:

- `metadata.bicep` for the rule metadata and scheduled rule properties.
- `query.kql` for the KQL query.
- `ads.md` for the human-readable Alerting and Detection Strategy (ADS) document.

Hunting-query source folders contain:

- `metadata.bicep` for the saved-search metadata.
- `query.kql` for the KQL query.

Generated deployable artifacts live under the matching top-level content folder and should not be edited directly.

### Additional content roots

The deployment workflow already recognizes these Sentinel content roots:

- `AutomationRules/**`
- `HuntingQueries/**`
- `Parsers/**`
- `Playbooks/**`
- `Workbooks/**`
- `CustomDetections/**`

These folders are aligned to the content types already recognized by the checked-in Sentinel deployment script:

- `AnalyticsRule`
- `AutomationRule`
- `HuntingQuery`
- `Parser`
- `Playbook`
- `Workbook`
- `CustomDetection`

The repository convention is still source-first. If we onboard another content type, add its source model under `src/<ContentType>/**` and extend the generator rather than authoring templates directly under the deploy root.

## Generated catalogs

The repository maintains two generated documentation files under `docs/**`:

- `docs/ADS-Catalog.md` indexes analytics-rule ADS documents.
- `docs/Content-Catalog.md` inventories deployable Sentinel content across the supported top-level content folders.

## Workflows

- `Build Sentinel Artifacts` regenerates impacted source-backed artifacts and refreshes the generated catalogs.
- `Deploy Content to sentinel-test-01 [...]` deploys content from the supported top-level Sentinel content folders.

For analytics rules and hunting queries, the generated deployable Bicep files contain the source query inline, which allows the repo to keep analyst edits in `src/**` while still deploying standard Sentinel content templates.

## Environment overlays

Generated analytics rules support a `displayNamePrefix` parameter. Use workspace-specific `.bicepparam` files next to a generated `rule.bicep` to add environment-specific prefixes such as `[TEST] ` without changing the source metadata.

The current production workspace overlay is stored next to the generated rule using the workspace-id naming convention expected by the Sentinel deployment script.

To add a test workspace later, create another `rule-<test-workspace-id>.bicepparam` file next to the generated `rule.bicep` and set `displayNamePrefix = '[TEST] '`. The same generated deployable artifact can then be promoted across environments without changing the analyst-authored source files.

Other generated content types can use the same parameter-file naming conventions expected by the deployment script.

## Current scope

This repository is prepared for the Sentinel content types supported by the checked-in deployment script. Today, the source generator is implemented for analytics rules and hunting queries. If you want to onboard additional content types, extend the source generator first so the repo stays aligned to the source-first model.

## GitHub requirements

The artifact build workflow pushes regenerated deployable files and generated catalogs back to the same branch. In GitHub Enterprise, make sure the workflow token or automation identity is allowed to push to that branch.

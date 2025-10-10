# Contributing to CoCore

## Minimum content requirements for new/changed models
- Declare externalities/teleconnections (`externalizes_to`, `coupled_with`).
- Provide evidence: source list + integrity (hash, license, conflicts) per docs/EVIDENCE_STANDARD.md.
- Add a congruence reference (calculator_ref + method disclosure).
- Set maturity/readiness (docs/READINESS_POLICY.md) and justify changes in a short ADR in the PR body.
- Include human-asset front matter (standards/metadata/human_asset_frontmatter.yaml) for any .md/.mdx briefs.
- Run safety gates (safety/WARNING_GATE.yaml) and paste any WARN results into the PR.

## PR etiquette
- Small, focused diffs. Use `supersedes` edges instead of destructive deletes.
- Link to catalog IDs from references/catalog.yaml rather than pasting raw URLs.
- Mark coercive patterns explicitly and keep readiness low unless strong evidence exists.

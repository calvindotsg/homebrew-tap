# CLAUDE.md

## Tap Structure

```
Formula/                        Homebrew formula definitions (.rb)
.github/workflows/
  update-formula.yml            Automated formula update (dispatch + manual)
```

Tap name `calvindotsg/tap` maps to this repo via Homebrew's `homebrew-` prefix convention.

## Adding a Formula

1. Create source repo with the tool, tag a release
2. Compute sha256: `curl -sL "<tarball-url>" | shasum -a 256`
3. Create `Formula/<name>.rb` following existing formulas as template
4. For Python formulas: generate resource stanzas with `brew update-python-resources` or PyPI lookup
5. Test: `brew install --build-from-source calvindotsg/tap/<name>`
6. Commit and push
7. Add a `bump-tap` job to the source repo's `release.yml` (copy from `calvindotsg/mac-upkeep/.github/workflows/release.yml`, change `formula`, `url`, `type`)

## Updating a Formula Version

Automated via `update-formula.yml`. Triggered automatically by source repos on release via `repository_dispatch`, or manually via GitHub Actions UI (`workflow_dispatch`).

**Automatic flow:** Source repo release → `bump-tap` job dispatches → `update-formula.yml` runs → URL/sha256 updated → committed and pushed.

**Manual fallback:** Actions tab → "Update formula" → Run workflow → enter formula name, version tag, tarball URL, type (python/node).

## Service Formulas

Formulas with a `service` block generate plists at `~/Library/LaunchAgents/homebrew.mxcl.<name>.plist`. Managed via `brew services start/stop/info <name>`.

## Non-Obvious Constraints

- Formula `depends_on` only works with other formulas, not casks.
- `sha256` is required for stable releases.
- Cron in service DSL only supports single integer values per field.
- Python formulas must use `Language::Python::Virtualenv` with explicit resource stanzas.
- `poet -r <package>` calls PyPI API for the main package. If not on PyPI, the workflow falls back to updating only URL/sha256 (resource blocks unchanged). Warning logged via `::warning::`.
- **`repository_dispatch` provides read-only GITHUB_TOKEN** — the workflow must declare `permissions: contents: write` to push. Without this, `git push` fails with "Permission denied to github-actions[bot]."
- **GitHub Actions re-runs replay old workflow YAML** — if you fix a workflow bug and re-run the failed run, the fix is NOT applied. Trigger a fresh `workflow_dispatch` run instead.
- **Concurrency group** `formula-update` with `cancel-in-progress: false` queues simultaneous dispatches from multiple source repos, preventing push conflicts.

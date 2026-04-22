# CLAUDE.md

## Tap Structure

```
Formula/                        Homebrew formula definitions (.rb)
Casks/                          Homebrew cask definitions (.rb)
.github/workflows/
  update-formula.yml            Automated formula update (dispatch + manual)
  update-cask.yml               Manual cask update (dispatch, with commented-out schedule)
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

### Third-Party Formulas

For formulas wrapping packages Calvin doesn't control (e.g., `codeburn`, `granola-cli`, `opensrc`), the `repository_dispatch` auto-bump flow is unavailable — there's no upstream release workflow to dispatch from. Instead, bumps flow through a tap-scoped **livecheck cron** defined in `.github/workflows/livecheck.yml` (daily 07:00 UTC) using [`dawidd6/action-homebrew-bump-formula@v5`](https://github.com/dawidd6/action-homebrew-bump-formula). Adding a new third-party formula = append its name to the `formula:` list in that workflow.

The scope is deliberately limited to third-party formulas by an explicit list — Calvin-owned formulas route through `repository_dispatch` from their source repos, and including them here would race against those pushes.

**Manual override** (if livecheck fails or to force a specific version):

    gh workflow run update-formula.yml \
      -f formula=codeburn \
      -f version=vX.Y.Z \
      -f url='https://registry.npmjs.org/codeburn/-/codeburn-X.Y.Z.tgz' \
      -f type=node \
      -R calvindotsg/homebrew-tap

See `## Reusable Patterns` (added in the docs-reusable-patterns PR) for the "scheduled livecheck cron" and "explicit third-party formula list" templates.

## Adding a Cask

1. Compute sha256 for each architecture: `curl -sL "<dmg-url>" | shasum -a 256`
2. Create `Casks/<name>.rb` following existing casks as template
3. Test: `brew audit --cask --new calvindotsg/tap/<name>` and `brew livecheck --cask calvindotsg/tap/<name>`
4. Install test: `brew install --cask calvindotsg/tap/<name>`
5. Commit and push

## Updating a Cask Version

Manual trigger via Actions UI or CLI:

    gh workflow run update-cask.yml -f cask=firefoo -f version=1.6.0

Leave `version` empty to auto-detect via `brew livecheck`. The workflow computes arch-specific SHA256s automatically.

Note: `update-cask.yml` currently hardcodes Firefoo's URL pattern. Generalize before adding more casks.

## Service Formulas

Formulas with a `service` block generate plists at `~/Library/LaunchAgents/homebrew.mxcl.<name>.plist`. Managed via `brew services start/stop/info <name>`.

## Reusable Patterns

Templates in this tap worth copying/adapting into other Homebrew taps or formula repos. Each entry is a pointer + "use when" — full mechanics live in the referenced file.

- **Node CLI formula (`std_npm_args`)** — see `Formula/codeburn.rb`, `Formula/granola-cli.rb`. Use for pure-JS CLIs published to npm.
- **Python virtualenv formula** — see `Formula/cc-menubar.rb` (SwiftBar plugin), `Formula/mac-upkeep.rb` (launchd service). Explicit `resource` stanzas required per `Language::Python::Virtualenv`; generate with `brew update-python-resources` or `poet -r`.
- **Prebuilt binary from GitHub Releases** — see `Formula/opensrc.rb`. `on_arm`/`on_intel` + `bin.install <file> => <name>`. Use for Rust/Go CLIs where upstream ships native binaries and the npm-wrapper download-during-install would violate `brew audit`.
- **Arch-specific cask** — see `Casks/firefoo.rb`. DMG with separate arm64/x64 builds.
- **Service formula (launchd via `service do`)** — see `Formula/mac-upkeep.rb`. Cron DSL accepts only single ints per field (see Non-Obvious Constraints below).
- **Auto-bump via source-repo dispatch** — see `.github/workflows/update-formula.yml` + source-repo `bump-tap` job pattern (`calvindotsg/mac-upkeep/.github/workflows/release.yml`). For Calvin-owned formulas.
- **Scheduled livecheck cron (third-party)** — see `.github/workflows/livecheck.yml`. `dawidd6/action-homebrew-bump-formula@v5` with `livecheck: true`. Daily 07:00 UTC. For formulas whose source repos Calvin doesn't control.
- **Explicit third-party `formula:` list in livecheck** — scope the cron to non-Calvin-owned formulas by enumerating them (`codeburn`, `granola-cli`, `opensrc`). Avoids races with the `repository_dispatch` path used by Calvin-owned formulas.

## Non-Obvious Constraints

- Formula `depends_on` only works with other formulas, not casks.
- `sha256` is required for stable releases.
- Cron in service DSL only supports single integer values per field.
- Python formulas must use `Language::Python::Virtualenv` with explicit resource stanzas.
- `poet -r <package>` calls PyPI API for the main package. If not on PyPI, the workflow falls back to updating only URL/sha256 (resource blocks unchanged). Warning logged via `::warning::`.
- **`repository_dispatch` provides read-only GITHUB_TOKEN** — the workflow must declare `permissions: contents: write` to push. Without this, `git push` fails with "Permission denied to github-actions[bot]."
- **GitHub Actions re-runs replay old workflow YAML** — if you fix a workflow bug and re-run the failed run, the fix is NOT applied. Trigger a fresh `workflow_dispatch` run instead.
- **Concurrency group** `formula-update` with `cancel-in-progress: false` queues simultaneous dispatches from multiple source repos, preventing push conflicts.

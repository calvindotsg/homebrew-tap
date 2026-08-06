# CLAUDE.md

## Tap Structure

```
Formula/                        Homebrew formula definitions (.rb)
Casks/                          Homebrew cask definitions (.rb)
.github/workflows/
  update-formula.yml            Automated formula update (dispatch + manual)
  update-cask.yml               Manual cask update (dispatch; firefoo-only, see below)
  livecheck.yml                 Daily cron: `bump` (formulae) + `bump-casks` (non-auto-updating casks)
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

For formulas wrapping packages Calvin doesn't control (e.g., `opensrc`), the `repository_dispatch` auto-bump flow is unavailable — there's no upstream release workflow to dispatch from. Instead, bumps flow through a tap-scoped **livecheck cron** defined in `.github/workflows/livecheck.yml` (daily 07:00 UTC) using [`dawidd6/action-homebrew-bump-formula@v5`](https://github.com/dawidd6/action-homebrew-bump-formula). Adding a new third-party formula = append its name to the `formula:` list in that workflow.

The scope is deliberately limited to third-party formulas by an explicit list — Calvin-owned formulas route through `repository_dispatch` from their source repos, and including them here would race against those pushes.

**Manual override** (if livecheck fails or to force a specific version):

    gh workflow run update-formula.yml \
      -f formula=cc-menubar \
      -f version=vX.Y.Z \
      -f url='https://github.com/calvindotsg/cc-menubar/archive/refs/tags/vX.Y.Z.tar.gz' \
      -f type=python \
      -R calvindotsg/homebrew-tap

See `## Reusable Patterns` (added in the docs-reusable-patterns PR) for the "scheduled livecheck cron" and "explicit third-party formula list" templates.

### CI & Auto-Merge

`.github/workflows/tests.yml` runs `brew test-bot` on every PR (and pushes to `main`): `--only-tap-syntax` audits/styles the whole tap, `--only-formulae` builds and tests the formulae *changed* in the PR. Matrix is ubuntu (Linux-compatible CLIs) + macOS (the `:macos`-gated formulae). It only builds changed formulae, so cost scales with the diff.

`.github/workflows/automerge.yml` squash-merges and **deletes the branch** of any same-repo `bump-*` PR once test-bot passes. Branch deletion is the actual fix for the recurring livecheck failures: `brew bump-formula-pr` reuses `bump-<formula>-<version>` branch names, so an unmerged PR's stale branch made every later run fail to push (non-fast-forward) and crash on the action's `odie` bug. With auto-merge draining the queue, the branch never lingers. Fork PRs are skipped (`isCrossRepository` guard) so a fork can't auto-merge itself.

## Adding a Cask

1. Compute sha256 for each architecture: `curl -sL "<dmg-url>" | shasum -a 256`. If upstream publishes a manifest (see the release-manifest pattern below), take its `sha256` and cross-check against your own download.
2. Create `Casks/<name>.rb` following existing casks as template
3. Copy it into Homebrew's own tap clone first — `cp Casks/<name>.rb "$(brew --repo calvindotsg/tap)/Casks/"` — since that is a *different directory* from this git checkout and `brew audit` on a loose path is disabled
4. Test: `brew style`, `brew audit --cask`, `brew livecheck --cask --debug`, then `brew fetch --cask calvindotsg/tap/<name>` (downloads and verifies the pinned sha256 end-to-end). Omit `--new` — it runs homebrew-cask notability checks that are irrelevant to a personal tap
5. Remove the untracked test copy before the post-merge `git -C "$(brew --repo calvindotsg/tap)" pull`, or that pull conflicts
6. Commit and push; install via `brew install --cask` after merge

## Updating a Cask Version

Manual trigger via Actions UI or CLI:

    gh workflow run update-cask.yml -f cask=firefoo -f version=1.6.0

Leave `version` empty to auto-detect via `brew livecheck`. The workflow computes arch-specific SHA256s automatically.

Note: `update-cask.yml`'s SHA step hardcodes Firefoo's download-URL pattern, so it only supports **firefoo**. `littlebird` deliberately bypasses it — `auto_updates true` means the app self-updates, and `brew livecheck --cask` surfaces new versions for a human to act on.

**Non-auto-updating casks do NOT go through this workflow.** They are bumped automatically by the `bump-casks` job in `livecheck.yml` (see below), which derives everything from the cask's own `url` and `livecheck` stanzas. This supersedes the previous instruction to generalize `update-cask.yml`'s SHA step first — that is no longer a prerequisite. `update-cask.yml` remains a firefoo-only manual escape hatch.

### Cask auto-bump (`bump-casks` job)

Casks cannot ride the `bump` job: [`dawidd6/action-homebrew-bump-formula@v5`](https://github.com/dawidd6/action-homebrew-bump-formula) is **formula-only** — it has no `cask:` input. So `livecheck.yml` carries a second job, `bump-casks`, running `brew livecheck --cask --newer-only --json` into `brew bump-cask-pr`.

- **Runs on `macos-latest`** because Homebrew has no cask support on Linux at all. Public repo, so the runner minutes are free.
- **Only casks without `auto_updates true`** belong in its `for cask in …` list. `firefoo` and `littlebird` self-update, so Homebrew deliberately does not own their upgrades; `tmog` cannot self-update, so it does. Adding a new non-auto-updating cask = append its token to that list.
- `brew bump-cask-pr` opens `bump-<cask>-<version>` branches, which already satisfy `automerge.yml`'s `startsWith(head_branch, 'bump-')` gate — **no change to `automerge.yml` is needed**.
- When a cask is already current, `--newer-only` returns `[]`, `jq` yields empty, and the loop logs "already current" and exits 0.

## Service Formulas

Formulas with a `service` block generate plists at `~/Library/LaunchAgents/homebrew.mxcl.<name>.plist`. Managed via `brew services start/stop/info <name>`.

## Reusable Patterns

Templates in this tap worth copying/adapting into other Homebrew taps or formula repos. Each entry is a pointer + "use when" — full mechanics live in the referenced file.

- **Node CLI formula (`std_npm_args`)** — see `Formula/cloudflare-cf.rb`. Use for pure-JS CLIs published to npm. Do not substitute pnpm or yarn: Homebrew redirects `HOME` during the build sandbox so a pnpm global store doesn't persist, Cellar isolation defeats cross-formula dedup, and `std_npm_args` injects cache redirection plus `--ignore-scripts` and `--min-release-age=1` (24-hour supply-chain quarantine) — no equivalent helper exists for pnpm. For real disk savings, prefer the prebuilt-binary pattern below when upstream ships native binaries.
- **Python virtualenv formula** — see `Formula/cc-menubar.rb` (SwiftBar plugin), `Formula/mac-upkeep.rb` (launchd service). Explicit `resource` stanzas required per `Language::Python::Virtualenv`; generate with `brew update-python-resources` or `poet -r`.
- **Prebuilt binary from GitHub Releases** — see `Formula/opensrc.rb`. `on_arm`/`on_intel` + `bin.install <file> => <name>`. Use for Rust/Go CLIs where upstream ships native binaries and the npm-wrapper download-during-install would violate `brew audit`.
- **Arch-specific cask** — see `Casks/firefoo.rb`. DMG with separate arm64/x64 builds.
- **Release-manifest cask (`:json` livecheck + `version,build`)** — see `Casks/tmog.rb`. Upstream publishes `release.json` carrying `version`, `build`, `sha256` and a **versioned** artifact path alongside a rolling unversioned one. Pin the *versioned* URL (immutable — no checksum drift when upstream re-publishes), encode `version "<version>,<build>"` and rebuild the filename with `version.csv.first` / `.csv.second`, and have the `livecheck` block return the same composite so comparisons line up. Use when a vendor ships its own update manifest instead of a Sparkle appcast or GitHub releases. **Finding the manifest:** don't guess URL paths — `strings -a "<App>.app/Contents/MacOS/<bin>" | grep -oiE 'https?://[a-z0-9./_-]+'`. A "Check for Updates…" menu item proves an endpoint exists; TMOG's sat under `/downloads/`, which root-level path guessing missed entirely.
- **Deciding `auto_updates`** — it is a factual claim that the app *installs* updates itself, not that it checks. `otool -L` for a linked Sparkle/Squirrel framework, `Contents/Resources/app-update.yml` for electron-updater, and `strings` for download/install/restart wording. TMOG has a "Check for Updates…" menu item but only check-and-report strings, so it omits `auto_updates` and Homebrew owns its upgrades. Getting this wrong is doubly bad: the claim is false *and* `brew upgrade` silently skips the cask.
- **Service formula (launchd via `service do`)** — see `Formula/mac-upkeep.rb`. Cron DSL accepts only single ints per field (see Non-Obvious Constraints below).
- **Auto-bump via source-repo dispatch** — see `.github/workflows/update-formula.yml` + source-repo `bump-tap` job pattern (`calvindotsg/mac-upkeep/.github/workflows/release.yml`). For Calvin-owned formulas.
- **Scheduled livecheck cron (third-party)** — see `.github/workflows/livecheck.yml`. `dawidd6/action-homebrew-bump-formula@v5` with `livecheck: true`. Daily 07:00 UTC. For formulas whose source repos Calvin doesn't control.
- **Explicit third-party `formula:` list in livecheck** — scope the cron to non-Calvin-owned formulas by enumerating them (currently `opensrc`, `cloudflare-cf`). Avoids races with the `repository_dispatch` path used by Calvin-owned formulas.
- **`brew test-bot` PR CI** — see `.github/workflows/tests.yml`. Canonical `tap-new` template (ubuntu + macOS matrix); builds only changed formulae. Gates the auto-merge below.
- **Auto-merge `bump-*` PRs with branch deletion** — see `.github/workflows/automerge.yml`. `workflow_run`-gated on test-bot success; squash + `--delete-branch`. Stops the stale-branch non-fast-forward failures that pile up when livecheck bump PRs go unmerged.

## Non-Obvious Constraints

- **Homebrew 6.0+ tap trust — enforcement depends on how you NAME things.** `HOMEBREW_REQUIRE_TAP_TRUST` defaults to true and `brew tap` does **not** confer trust; only `brew trust` does, writing `~/.homebrew/trust.json`. But `Homebrew::Trust.explicitly_allowed?` (`trust.rb`) inspects **`ARGV`**, so behaviour splits three ways — verified empirically 2026-08-06 by untrusting the tap locally:
  - **Fully-qualified → allowed, no trust needed.** `brew install calvindotsg/tap/foo`, `brew livecheck --cask calvindotsg/tap/tmog`. A tap named on the command line counts as explicit consent. This is why every workflow here kept working, and why testing with qualified names *cannot* reproduce a trust failure — a real trap when verifying this.
  - **Bare token → hard error.** `brew info --cask firefoo` → `Error: Refusing to load cask calvindotsg/tap/firefoo from untrusted tap`.
  - **Bulk evaluation → silently skipped.** `brew upgrade`, `brew outdated`, `brew livecheck` with no target print only `Warning: Skipping calvindotsg/tap because it is not trusted` and carry on, so the tap's packages quietly stop updating. This is the dangerous mode — a warning, not a failure. `brew doctor` also lists untrusted taps.
  - **CI**: workflow steps here use qualified names and so do not strictly require trust, but both cask jobs call `brew trust --tap calvindotsg/tap` (idempotent, exit 0) so a future bare-token or bulk command cannot reintroduce the silent-skip mode. The `bump` job gets this free — `dawidd6/action-homebrew-bump-formula` trusts the tap itself (`==> Trusting calvindotsg/tap tap...` in its logs).
  - **Brewfiles** declare it inline with `tap "calvindotsg/tap", trusted: true` — needed because bare `cask "firefoo"` entries are not tap-qualified.
  - Do **not** reach for `HOMEBREW_NO_REQUIRE_TAP_TRUST` — `man brew` says it "is not recommended and will be removed in a later release."
- Formula `depends_on` only works with other formulas, not casks.
- `sha256` is required for stable releases.
- Cron in service DSL only supports single integer values per field.
- Python formulas must use `Language::Python::Virtualenv` with explicit resource stanzas.
- `poet -r <package>` calls PyPI API for the main package. If not on PyPI, the workflow falls back to updating only URL/sha256 (resource blocks unchanged). Warning logged via `::warning::`.
- **`repository_dispatch` provides read-only GITHUB_TOKEN** — the workflow must declare `permissions: contents: write` to push. Without this, `git push` fails with "Permission denied to github-actions[bot]."
- **GitHub Actions re-runs replay old workflow YAML** — if you fix a workflow bug and re-run the failed run, the fix is NOT applied. Trigger a fresh `workflow_dispatch` run instead.
- **Concurrency group** `formula-update` with `cancel-in-progress: false` queues simultaneous dispatches from multiple source repos, preventing push conflicts.

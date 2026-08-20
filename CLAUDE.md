# CLAUDE.md

## Tap Structure

```
Formula/                        Homebrew formula definitions (.rb)
Casks/                          Homebrew cask definitions (.rb)
.github/workflows/
  update-formula.yml            Automated formula update (dispatch + manual)
  update-cask.yml               Manual cask update (dispatch; firefoo-only, see below)
  livecheck.yml                 Daily cron: `bump` (non-Python formulae) + `bump-python`
                                → `bump-python-pr`
  livecheck-casks.yml           Daily cron: `bump-casks` (non-auto-updating casks)
.github/dependabot.yml          Weekly refresh of the workflows' action SHA pins
```

**Every write to `main` goes through a pull request.** No workflow pushes to `main`
any more, and no job holds a writable ambient token — `permissions: {}` everywhere,
with the tap PAT named explicitly by the few steps that publish. Bot lanes land via
`automerge.yml` once `brew test-bot` passes.

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

**Automatic flow:** Source repo release → `bump-tap` job dispatches → `update-formula.yml` `prepare` job validates the payload, recomputes the checksum and (for `type: python`) regenerates resource stanzas → hands one file to `open-pr` → PR opened → `brew test-bot` → `automerge.yml` squashes it.

The two jobs exist for one reason: `prepare` runs `pip install "$URL"`, which executes the sdist's build backend, and a step boundary is not a credential boundary. Separate jobs get separate machines, and the only thing that crosses between them is a single file under a fixed name — the destination path is chosen by `open-pr`, never by the artifact.

**Manual fallback:** Actions tab → "Update formula" → Run workflow → enter formula name, version tag, tarball URL, type (python/node).

### Third-Party Formulas

For formulas wrapping packages Calvin doesn't control (e.g., `opensrc`), the `repository_dispatch` auto-bump flow is unavailable — there's no upstream release workflow to dispatch from. Instead, bumps flow through a tap-scoped **livecheck cron** defined in `.github/workflows/livecheck.yml` (daily 07:00 UTC) using [`dawidd6/action-homebrew-bump-formula@v5`](https://github.com/dawidd6/action-homebrew-bump-formula). Adding a new third-party formula = append its name to the `formula:` list in that workflow's `bump` job — unless it is a Python formula sourced from a PyPI sdist, which belongs in the separate `bump-python` job (one formula per job; see that job's comments).

The scope is deliberately limited to third-party formulas by an explicit list — Calvin-owned formulas route through `repository_dispatch` from their source repos, and including them here would race against those pushes.

**Manual override** (if livecheck fails or to force a specific version):

    gh workflow run update-formula.yml \
      -f formula=mac-upkeep \
      -f version=vX.Y.Z \
      -f url='https://github.com/calvindotsg/mac-upkeep/archive/refs/tags/vX.Y.Z.tar.gz' \
      -f type=python \
      -R calvindotsg/homebrew-tap

See `## Reusable Patterns` (added in the docs-reusable-patterns PR) for the "scheduled livecheck cron" and "explicit third-party formula list" templates.

### CI & Auto-Merge

`.github/workflows/tests.yml` runs `brew test-bot` on every PR (and pushes to `main`): `--only-tap-syntax` audits/styles the whole tap, `--only-formulae` builds and tests the formulae *changed* in the PR. Matrix is ubuntu (Linux-compatible CLIs) + macOS (the `:macos`-gated formulae). It only builds changed formulae, so cost scales with the diff.

The same workflow carries an `arch-consistency` job. `brew bump-formula-pr` rewrites only a formula's top-level stable `url`/`sha256`, so an arch override nested in `on_intel`/`on_arm` never moves with the automated bump — and test-bot builds for the runner's own architecture only, so nothing else notices. The job fails the PR when one formula references more than one upstream release tag; `Formula/opensrc.rb` is the only formula in the tap with an arch override, so it is the one this guards.

`.github/workflows/automerge.yml` squash-merges and **deletes the branch** of any same-repo `bump-*` PR once test-bot passes. Branch deletion is the actual fix for the recurring livecheck failures: `brew bump-formula-pr` reuses `bump-<formula>-<version>` branch names, so an unmerged PR's stale branch made every later run fail to push (non-fast-forward) and crash on the action's `odie` bug. With auto-merge draining the queue, the branch never lingers.

It resolves the PR from `workflow_run.head_sha` (matched against `headRefOid`) and merges with `--match-head-commit`, after checking `head_repository.full_name == github.repository`. The `startsWith(head_branch, 'bump-')` condition is only a cheap pre-filter — branch names are attacker-suppliable and `gh pr list --head` matches by name across repositories, so nothing is authorized on one. `isCrossRepository` stays as a second, independent check.

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

Leave `version` empty to auto-detect via `brew livecheck`. The workflow computes arch-specific SHA256s automatically, then opens a `bump-firefoo-<version>` PR — it no longer pushes to `main`.

Note: `update-cask.yml` now **fails closed for any cask other than firefoo**, because its SHA step hardcodes Firefoo's download-URL pattern and would otherwise write the checksum of a 404 body into some other cask. `littlebird` deliberately bypasses it — `auto_updates true` means the app self-updates, and `brew livecheck --cask` surfaces new versions for a human to act on.

**Non-auto-updating casks do NOT go through this workflow.** They are bumped automatically by the `bump-casks` job in `livecheck.yml` (see below), which derives everything from the cask's own `url` and `livecheck` stanzas. This supersedes the previous instruction to generalize `update-cask.yml`'s SHA step first — that is no longer a prerequisite. `update-cask.yml` remains a firefoo-only manual escape hatch.

### Cask auto-bump (`livecheck-casks.yml`)

Casks cannot ride the `bump` job: [`dawidd6/action-homebrew-bump-formula@v5`](https://github.com/dawidd6/action-homebrew-bump-formula) is **formula-only** — it has no `cask:` input. It lives in its own workflow file rather than as a fourth job in `livecheck.yml`, deliberately: the formula lane goes red for unrelated reasons and on a different cadence (an `opensrc` release makes `bump` red until a human updates the Intel stanza), and a chronically-red formula lane is the worst possible background against which to notice a *first-ever* red cask lane — which is the only artifact verification this tap has. Separate workflows get separate run statuses and notifications. It runs `bump-casks`, running `brew livecheck --cask --newer-only --json` into `brew bump-cask-pr --write-only --commit`, verifying the downloaded artifact, and only then pushing the branch and opening the PR.

- **Runs on `macos-latest`** because Homebrew has no cask support on Linux at all. Public repo, so the runner minutes are free.
- **Only casks without `auto_updates true`** belong in its `for cask in …` list. `firefoo` and `littlebird` self-update, so Homebrew deliberately does not own their upgrades; `tmog` cannot self-update, so it does. Adding a new non-auto-updating cask = append its token to that list **and** add its Developer ID Team Identifier to `expected_team_for` in the verification step (`codesign -dv <app> 2>&1 | sed -n 's/^TeamIdentifier=//p'` to read it). A cask with no pinned Team ID fails the job rather than bumping unverified.
- The job pushes `bump-<cask>-<version>` branches itself (`--write-only --commit` writes and commits but opens nothing), normalising characters that are not valid in a ref — `tmog`'s `version,build` composite among them. The `bump-` prefix keeps them inside `automerge.yml`'s pre-filter.
- When a cask is already current, `--newer-only` returns `[]`, `jq` yields empty, and the loop logs "already current" and exits 0.
- **Verify the bundle the cask *installs*, not whichever `.app` the image lists first.** Code signing is a property of a bundle, not of its path, so a renamed copy of the vendor's own genuine app passes `codesign`, `spctl` and the Team ID check while `app "…"` installs a different one — forgeable without any signing identity. The job resolves the name from the cask's own stanza: `brew info --json=v2 --cask <token> | jq -r '[.casks[0].artifacts[] | .app[]? | select(type == "string")][0]'`.

#### When `bump-casks` fails on a Team ID mismatch

The job is fail-closed by design, so a red run means *either* the vendor rotated their Developer ID *or* the download is not what the vendor published. Do not just re-pin the new value — that turns the control off. Establish which it is:

1. Read what the job actually saw: the error names the observed and expected Team IDs.
2. Fetch the artifact yourself from the vendor's canonical URL over a different network path, mount it, and read the identity:
   `codesign -dv --verbose=4 "/Volumes/…/<App>.app" 2>&1 | grep -E 'Authority|TeamIdentifier'`
3. Corroborate the new identity *out of band* — a release note, a signed announcement, the vendor's support channel. A new Team ID that only the download attests to is exactly the case this check exists to catch.
4. Confirm notarization independently: `spctl -a -t open --context context:primary-signature -v <App>.app` should report `source=Notarized Developer ID`.
5. Only then update `expected_team_for` in `livecheck.yml`, in a PR that records *why* in the commit body.

Until it is resolved the cask simply does not bump, which is the safe direction. `tmog` is pinned to `25BPDA4NQ3` (Developer ID Application: David Plummer).

## Service Formulas

Formulas with a `service` block generate plists at `~/Library/LaunchAgents/homebrew.mxcl.<name>.plist`. Managed via `brew services start/stop/info <name>`.

## Reusable Patterns

Templates in this tap worth copying/adapting into other Homebrew taps or formula repos. Each entry is a pointer + "use when" — full mechanics live in the referenced file.

- **Node CLI formula (`std_npm_args`)** — see `Formula/cloudflare-cf.rb`. Use for pure-JS CLIs published to npm. Do not substitute pnpm or yarn: Homebrew redirects `HOME` during the build sandbox so a pnpm global store doesn't persist, Cellar isolation defeats cross-formula dedup, and `std_npm_args` injects cache redirection plus `--ignore-scripts` and `--min-release-age=1` — no equivalent helper exists for pnpm. **Know what that cooldown does and does not cover:** `--min-release-age` is a *registry-resolution* flag, and `Language::Node.std_npm_install_args` installs from a local tarball repacked out of Homebrew's own download stage (`#{Dir.pwd}/#{pack}`), so the formula's own package is never registry-resolved. The 24-hour quarantine protects its **dependencies**, not the primary artifact — do not cite it as blanket cover. Relatedly, do not call `generate_completions_from_executable` on a package you would not run unattended: it reaches `Utils.safe_popen_read` and executes the freshly downloaded binary inside `def install`. See `Formula/cloudflare-cf.rb` for a case where that was dropped and why. For real disk savings, prefer the prebuilt-binary pattern below when upstream ships native binaries.
- **Python virtualenv formula** — see `Formula/cc-menubar.rb` (SwiftBar plugin), `Formula/mac-upkeep.rb` (launchd service). Explicit `resource` stanzas required per `Language::Python::Virtualenv`; generate with `brew update-python-resources` or `poet -r`.
- **Prebuilt binary from GitHub Releases** — see `Formula/opensrc.rb`. `on_arm`/`on_intel` + `bin.install <file> => <name>`. Use for Rust/Go CLIs where upstream ships native binaries and the npm-wrapper download-during-install would violate `brew audit`.
- **Arch-specific cask** — see `Casks/firefoo.rb`. DMG with separate arm64/x64 builds.
- **Release-manifest cask (`:json` livecheck + `version,build`)** — see `Casks/tmog.rb`. Upstream publishes `release.json` carrying `version`, `build`, `sha256` and a **versioned** artifact path alongside a rolling unversioned one. Pin the *versioned* URL (immutable — no checksum drift when upstream re-publishes), encode `version "<version>,<build>"` and rebuild the filename with `version.csv.first` / `.csv.second`, and have the `livecheck` block return the same composite so comparisons line up. Use when a vendor ships its own update manifest instead of a Sparkle appcast or GitHub releases. **Finding the manifest:** don't guess URL paths — `strings -a "<App>.app/Contents/MacOS/<bin>" | grep -oiE 'https?://[a-z0-9./_-]+'`. A "Check for Updates…" menu item proves an endpoint exists; TMOG's sat under `/downloads/`, which root-level path guessing missed entirely.
- **Deciding `auto_updates`** — it is a factual claim that the app *installs* updates itself, not that it checks. `otool -L` for a linked Sparkle/Squirrel framework, `Contents/Resources/app-update.yml` for electron-updater, and `strings` for download/install/restart wording. TMOG has a "Check for Updates…" menu item but only check-and-report strings, so it omits `auto_updates` and Homebrew owns its upgrades. Getting this wrong is doubly bad: the claim is false *and* `brew upgrade` silently skips the cask.
- **Service formula (launchd via `service do`)** — see `Formula/mac-upkeep.rb`. Cron DSL accepts only single ints per field (see Non-Obvious Constraints below).
- **Auto-bump via source-repo dispatch** — see `.github/workflows/update-formula.yml` + source-repo `bump-tap` job pattern (`calvindotsg/mac-upkeep/.github/workflows/release.yml`). For Calvin-owned formulas. **Copy the whole shape, not just the happy path:** every `client_payload` field is attacker-supplied to the workflow and lands in a file path, a shell command and Ruby source, so validate each against an expected shape and an allowlisted host before use; do the file rewrites with callable `re.subn` replacements and assert the match count; and keep the job that `pip install`s the dispatched URL in a *different job* from the one holding the publish credential.
- **Scheduled livecheck cron (third-party)** — see `.github/workflows/livecheck.yml`. `dawidd6/action-homebrew-bump-formula` with `livecheck: true`. Daily 07:00 UTC. For formulas whose source repos Calvin doesn't control. **Two requirements travel with this pattern:** set `permissions: {}` on every job (see Non-Obvious Constraints — `setup-homebrew` otherwise hands a writable token to any upstream code the job runs), and split a PyPI-sourced formula's bump into a credential-free `--write-only` job plus a publishing job, since resource regeneration executes upstream build backends.
- **Explicit third-party `formula:` list in livecheck** — scope the cron to non-Calvin-owned formulas by enumerating them (currently `opensrc` and `cloudflare-cf` in the `bump` job; `pymarkdownlnt` has its own `bump-python` job). Avoids races with the `repository_dispatch` path used by Calvin-owned formulas.
- **`brew test-bot` PR CI** — see `.github/workflows/tests.yml`. Canonical `tap-new` template (ubuntu + macOS matrix); builds only changed formulae. Gates the auto-merge below.
- **Auto-merge `bump-*` PRs with branch deletion** — see `.github/workflows/automerge.yml`. `workflow_run`-gated on test-bot success; squash + `--delete-branch`. Stops the stale-branch non-fast-forward failures that pile up when livecheck bump PRs go unmerged. **Authorize on the commit, never on the branch name.** A `workflow_run` job is privileged, and `head_branch` is a string any outsider can choose; `gh pr list --head` matches it across repositories, so a name-keyed lookup can resolve to a different PR than the one whose tests passed. Resolve by `headRefOid == workflow_run.head_sha`, check `head_repository.full_name == github.repository`, and pass `--match-head-commit`. Keep the `startsWith(head_branch, 'bump-')` condition as a cheap pre-filter only.

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
- **A Python formula in the livecheck cron needs its python keg installed in CI.** `brew bump-formula-pr` unconditionally calls `PyPI.update_python_resources!`, which shells out to `<python@3.x keg>/bin/python -m pip install --dry-run` to re-resolve resources. `formula_opt_libexec` constructs that path with no installed-check, and `dawidd6/action-homebrew-bump-formula` never passes `--install-dependencies`, so on a bare `ubuntu-latest` runner the call fails and the job goes red. The `bump-python` job in `.github/workflows/livecheck.yml` therefore runs `brew install python@3.13` before `brew bump-formula-pr`. Keep that version in step with `depends_on "python@3.x"` in the formula.
- **Source a third-party Python formula from the PyPI sdist, not the GitHub tag.** `bump-formula-pr` passes `ignore_non_pypi_packages: true`, and `valid_pypi_package?` requires the main `url` to start with `https://files.pythonhosted.org/packages/`. With a GitHub tarball URL the cron bumps `url`/`sha256` and **silently skips every resource stanza** — automerge then lands a version bump whose dependencies are frozen at the old versions. A pythonhosted URL also auto-matches the `Pypi` livecheck strategy, so no `livecheck do` block is needed.
- `poet -r <package>` calls PyPI API for the main package. If not on PyPI, the workflow falls back to updating only URL/sha256 (resource blocks unchanged). Warning logged via `::warning::`.
- **A Homebrew CI job that runs any upstream code needs `permissions: {}`.** `Homebrew/actions/setup-homebrew` defaults its `brew-gh-api-token` input to `${{ github.token }}` and its `main.sh` writes `HOMEBREW_GITHUB_API_TOKEN=<that>` into `$GITHUB_ENV` — job-wide, for every later step. And `HOMEBREW_*` is precisely what survives `brew`'s `env -i` re-exec into subprocesses, while `GITHUB_*` is stripped (checked by running it). So a job declaring `contents: write` silently hands a repo-writable token to every `pip` build backend it invokes. Splitting the work across steps does **not** help; only removing the scopes does. Verified live: with `permissions: {}` the job is granted `Metadata: read` and nothing else, and `brew tap` / `brew trust` / `brew install` / `brew livecheck` all still work, because bottles come from ghcr.io under Homebrew's own hardcoded anonymous `HOMEBREW_GITHUB_PACKAGES_AUTH="Bearer QQ=="` (`brew.sh`).
- **A PR opened with `GITHUB_TOKEN` will not drive an unattended merge.** Per GitHub's docs, `GITHUB_TOKEN`-triggered events either create no workflow run at all or — for `pull_request` `opened`/`synchronize`/`reopened` — create one that **requires approval**. Either way `brew test-bot` does not run unattended, so `automerge.yml` never fires and the branch lingers to collide with the next run. Bot lanes here therefore push and open PRs with `CALVINDOTSG_TAP_LIVECHECK_PAT`, not `github.token`. (`workflow_dispatch` and `repository_dispatch` are the documented exceptions.)
- **`shell: bash` cuts both ways.** The Actions default `run:` shell is `bash -e` with **no** `pipefail`, so `X=$(curl -sL "$URL" | shasum -a 256 | cut -d' ' -f1)` can never fail and a 404 body gets hashed and committed. Declaring `shell: bash` gives `bash --noprofile --norc -eo pipefail` — but then a `grep` that legitimately matches nothing kills the step with no output. Absorb those at the call site (`... | sort -u || true`) and test any such block under the runner's real flags: `bash --noprofile --norc -eo pipefail script.sh`. A plain `#!/bin/bash` test passes and proves nothing.
- **`brew bump-formula-pr --write-only` takes no git action at all**, and `--commit` is what makes it commit (`return if args.write_only? && !args.commit?`). With `--commit`, `Homebrew::Bump.create_pr` skips its own `git checkout -b` *and* returns before pushing, so the commit lands on the tap clone's current branch at `$(brew --repo <tap>)` — not in `$GITHUB_WORKSPACE` and not on a `bump-*` branch. It also raises `UsageError` without `--version`. If a workflow only needs the rewritten file, pass `--write-only` alone and let a separate job commit it.
- **`persist-credentials: false` breaks a bare `git push`.** `actions/checkout`'s default leaves a token in `.git/config`'s `http.extraheader`, and a step that just runs `git push` depends entirely on it. Setting the flag without re-authenticating the push in the same change is half a fix that fails at the last step.
- **GitHub Actions re-runs replay old workflow YAML** — if you fix a workflow bug and re-run the failed run, the fix is NOT applied. Trigger a fresh `workflow_dispatch` run instead.
- **Concurrency group** `formula-update` with `cancel-in-progress: false` queues simultaneous dispatches from multiple source repos, preventing push conflicts.

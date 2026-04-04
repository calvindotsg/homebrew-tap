# CLAUDE.md

## Tap Structure

```
Formula/           Homebrew formula definitions (.rb)
```

Tap name `calvindotsg/tap` maps to this repo via Homebrew's `homebrew-` prefix convention.

## Adding a Formula

1. Create source repo with the tool, tag a release
2. Compute sha256: `curl -sL "<tarball-url>" | shasum -a 256`
3. Create `Formula/<name>.rb` following existing formulas as template
4. For Python formulas: generate resource stanzas with `brew update-python-resources` or PyPI lookup
5. Test: `brew install --build-from-source calvindotsg/tap/<name>`
6. Commit and push

## Updating a Formula Version

1. Get new tarball sha256: `curl -sL "<new-url>" | shasum -a 256`
2. Update `url` and `sha256` in `Formula/<name>.rb`
3. For Python formulas: regenerate resource stanzas if dependencies changed
4. Test: `brew upgrade calvindotsg/tap/<name>`
5. Commit and push

## Service Formulas

Formulas with a `service` block generate plists at `~/Library/LaunchAgents/homebrew.mxcl.<name>.plist`. Managed via `brew services start/stop/info <name>`.

## Constraints

- Formula `depends_on` only works with other formulas, not casks
- `sha256` is required for stable releases
- Cron in service DSL only supports single integer values per field
- Python formulas must use `Language::Python::Virtualenv` with explicit resource stanzas

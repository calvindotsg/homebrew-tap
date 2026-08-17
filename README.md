# homebrew-tap

Personal Homebrew tap for calvindotsg.

## Install

```bash
brew tap calvindotsg/tap
brew trust --tap calvindotsg/tap
```

The second command matters on **Homebrew 6.0 and later**, where non-official taps must be
trusted before Homebrew will load them — and `brew tap` does not confer trust.

The fully-qualified install commands in the tables below (`brew install calvindotsg/tap/…`)
work even without it, because naming the tap on the command line counts as explicit consent.
Trust matters for everything else:

- `brew install mac-upkeep` (bare name) → `Error: Refusing to load … from untrusted tap`
- `brew upgrade`, `brew outdated`, `brew livecheck` → **silently skip this tap** with only a
  `Warning: Skipping calvindotsg/tap because it is not trusted`, so packages quietly stop
  updating. This is the failure worth avoiding.

`brew doctor` lists untrusted taps if you are unsure. Installing via a `Brewfile`? Declare it
inline and skip `brew trust` entirely:

```ruby
tap "calvindotsg/tap", trusted: true
```

## Formulae

| Formula | Description | Install |
|---------|-------------|---------|
| [cloudflare-cf](https://blog.cloudflare.com/cf-cli-local-explorer/) (third-party) | Unified CLI for the Cloudflare API (DNS, zones, Workers, R2, KV) | `brew install calvindotsg/tap/cloudflare-cf` |
| [mac-upkeep](https://github.com/calvindotsg/mac-upkeep) | Automated macOS maintenance CLI (TOML-driven, weekly scheduler) | `brew install calvindotsg/tap/mac-upkeep` |
| [opensrc](https://github.com/vercel-labs/opensrc) (third-party) | Fetch source code for packages to give coding agents deeper context | `brew install calvindotsg/tap/opensrc` |
| [pymarkdownlnt](https://github.com/jackdewinter/pymarkdown) (third-party) | GitHub Flavored Markdown compliant Markdown linter | `brew install calvindotsg/tap/pymarkdownlnt` |

## Casks

| Cask | Description | Install |
|------|-------------|---------|
| [Firefoo](https://www.firefoo.com/) | GUI client for Firebase Firestore | `brew install --cask calvindotsg/tap/firefoo` |
| [Littlebird](https://littlebird.ai/) | Context-aware AI assistant that reads on-screen text across apps | `brew install --cask calvindotsg/tap/littlebird` |
| [TMOG](https://www.tmog.org/) | Native system monitor for CPU, memory, storage, network, and thermals | `brew install --cask calvindotsg/tap/tmog` |

## Deprecated

| Package | Status |
|---------|--------|
| [cc-menubar](https://github.com/calvindotsg/cc-menubar) | Deprecated 2026-08-16 — repository archived. Homebrew disables it automatically on **2027-08-16**; it is removed from this tap after that. Still installable from [PyPI](https://pypi.org/project/cc-menubar/) (`uv tool install cc-menubar`). |

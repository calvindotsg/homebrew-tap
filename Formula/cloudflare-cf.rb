class CloudflareCf < Formula
  desc "Unified CLI for the Cloudflare API (DNS, zones, Workers, R2, KV)"
  homepage "https://developers.cloudflare.com/"
  url "https://registry.npmjs.org/cf/-/cf-0.7.0.tgz"
  sha256 "f74e6b3e61a8eaf804971caeb9dec285274ee1474a0d33fe1b5ac48ac7a32cd3"
  license "MIT"

  # Upstream publishes only the bundled `dist/` to npm — there is no public
  # source repository to livecheck, so the Npm strategy is auto-detected from
  # the registry URL above.

  depends_on "node"

  conflicts_with "cf", because: "both install a `cf` binary"
  conflicts_with "cloudfoundry-cli", because: "both install a `cf` binary"

  # No `generate_completions_from_executable` here, deliberately. That helper is
  # Homebrew's paved path and is fine for most formulae, but it reaches
  # `Utils.safe_popen_read` (utils/shell_completion.rb:68) and runs the freshly
  # downloaded binary inside `def install`. This package is the wrong shape for
  # that: it is a bundled `dist/*.mjs` with no public source repository, on a
  # technical-preview cadence, auto-bumped by a daily cron — an npm publish
  # reached this machine and executed in about 17 hours with no human in between.
  #
  # It is also the one formula where `std_npm_args`' protections do not reach the
  # primary artifact: `--ignore-scripts` blocks npm lifecycle scripts, which this
  # is not, and `--min-release-age` is a registry-resolution flag, while
  # `Language::Node.std_npm_install_args` installs from a local tarball repacked
  # out of Homebrew's own stage (`#{Dir.pwd}/#{pack}`), so `cf` itself is never
  # registry-resolved. The cooldown covers its dependencies only.
  #
  # Cost, stated honestly: no tab completion for `cf`. Upstream ships no static
  # completion files to install instead — only a bundled `completions-*.mjs`.
  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cf --version")

    # `dns` is the subcommand this formula is installed for; assert the command
    # tree is present without needing credentials.
    assert_match "DNS management API", shell_output("#{bin}/cf dns --help")
  end
end

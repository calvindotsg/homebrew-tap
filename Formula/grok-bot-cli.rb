class GrokBotCli < Formula
  desc "Manage Grok Bot agents, groups, and messages from the terminal"
  homepage "https://github.com/ScriptedAlchemy/grok-bot-cli"
  url "https://registry.npmjs.org/grok-bot-cli/-/grok-bot-cli-0.4.0.tgz"
  sha256 "fb08c14fb7dd83e8510540c5e82ba404b1581c21d651e2832551c361ef80c51b"
  license "MIT"

  # Livecheck uses the Npm strategy, auto-detected from the registry URL above.
  # Upstream also tags GitHub releases, but the tarball this formula installs is
  # the npm publish, so npm is the signal to follow. Pinned to 0.4.0 rather than
  # the newest release on the day this formula landed (0.6.0, six hours old)
  # because the tap's livecheck lane defers npm releases younger than 24 h and
  # a hand-written formula should not skip the same cooldown. The lane bumps it.

  depends_on "node"

  # No `generate_completions_from_executable`, for the reason recorded on
  # cloudflare-cf: it runs the freshly downloaded package inside `def install`.
  # Upstream ships no static completion files either.
  #
  # The package publishes three bins (gbot, grok-bot, gbot-install); all are
  # symlinked. `gbot` reads the Grok Bot desktop app's encrypted session, so
  # anything beyond `--help`/`--version` needs the app signed in.
  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gbot --version")
    assert_match "bots", shell_output("#{bin}/gbot --help")
    assert_match "install", shell_output("#{bin}/gbot-install --help")
  end
end

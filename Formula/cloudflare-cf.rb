class CloudflareCf < Formula
  desc "Unified CLI for the Cloudflare API (DNS, zones, Workers, R2, KV)"
  homepage "https://developers.cloudflare.com/"
  url "https://registry.npmjs.org/cf/-/cf-0.5.0.tgz"
  sha256 "25c860c22803045fbc91bc6a235ae3a7833056c99d491168092ef84d7e5a11ef"
  license "MIT"

  # Upstream publishes only the bundled `dist/` to npm — there is no public
  # source repository to livecheck, so the Npm strategy is auto-detected from
  # the registry URL above.

  depends_on "node"

  conflicts_with "cf", because: "both install a `cf` binary"
  conflicts_with "cloudfoundry-cli", because: "both install a `cf` binary"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]

    # bash/zsh/fish are the defaults; upstream's `cf complete` has no pwsh support.
    generate_completions_from_executable(bin/"cf", "complete")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cf --version")

    # `dns` is the subcommand this formula is installed for; assert the command
    # tree is present without needing credentials.
    assert_match "DNS management API", shell_output("#{bin}/cf dns --help")
  end
end

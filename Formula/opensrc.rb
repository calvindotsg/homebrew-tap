class Opensrc < Formula
  desc "Fetch source code for packages to give coding agents deeper context"
  homepage "https://github.com/vercel-labs/opensrc"
  url "https://github.com/vercel-labs/opensrc/releases/download/v0.7.3/opensrc-darwin-arm64"
  sha256 "c10a60b758ef82de8991e69e773e64159086b5bb767f5248da778c8347949afc"
  license "Apache-2.0"

  livecheck do
    url :homepage
    strategy :github_latest
  end

  depends_on :macos

  # Keep this tag in step with the stable `url` above. `brew bump-formula-pr`
  # only rewrites the top-level stable stanza, so this block does not move on
  # its own; the `arch-consistency` job in .github/workflows/tests.yml fails the
  # PR if the two tags ever diverge.
  on_macos do
    on_intel do
      url "https://github.com/vercel-labs/opensrc/releases/download/v0.7.3/opensrc-darwin-x64"
      sha256 "2b4fb2f43aceef9b01bed857a8aa029f96c3f67d57d5256ec702d1269a726b78"
    end
  end

  def install
    binary = Hardware::CPU.arm? ? "opensrc-darwin-arm64" : "opensrc-darwin-x64"
    bin.install binary => "opensrc"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opensrc --version")
  end
end

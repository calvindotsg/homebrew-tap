class Opensrc < Formula
  desc "Fetch source code for packages to give coding agents deeper context"
  homepage "https://github.com/vercel-labs/opensrc"
  url "https://github.com/vercel-labs/opensrc/releases/download/v0.7.3/opensrc-darwin-arm64"
  version "0.7.3"
  sha256 "c10a60b758ef82de8991e69e773e64159086b5bb767f5248da778c8347949afc"
  license "Apache-2.0"

  livecheck do
    url :homepage
    strategy :github_latest
  end

  depends_on :macos

  on_macos do
    on_intel do
      url "https://github.com/vercel-labs/opensrc/releases/download/v0.7.2/opensrc-darwin-x64"
      sha256 "fb87e2fac9704b2a5a8d0512b3e28bf9321a95f7fdbd5ba894f683fd827e35db"
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

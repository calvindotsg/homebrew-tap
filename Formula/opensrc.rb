class Opensrc < Formula
  desc "Fetch source code for packages to give coding agents deeper context"
  homepage "https://github.com/vercel-labs/opensrc"
  version "0.7.2"
  license "Apache-2.0"

  livecheck do
    url :homepage
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/vercel-labs/opensrc/releases/download/v0.7.2/opensrc-darwin-arm64"
      sha256 "fdc3f6cf8c36e6b9ed35a3004745381232ad2e0765b31286adf8d59546f75be3"
    end
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

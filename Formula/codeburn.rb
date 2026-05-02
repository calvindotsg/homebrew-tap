class Codeburn < Formula
  desc "See where your AI coding tokens go — CLI dashboard for Claude Code cost"
  homepage "https://github.com/getagentseal/codeburn"
  url "https://registry.npmjs.org/codeburn/-/codeburn-0.9.5.tgz"
  sha256 "0874f9b48a0c98d6557d40f3a1b3ffb1fe6f8baecbf6c3671d4171f20ec3dc14"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/codeburn --version")
  end
end

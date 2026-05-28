class Codeburn < Formula
  desc "See where your AI coding tokens go — CLI dashboard for Claude Code cost"
  homepage "https://github.com/getagentseal/codeburn"
  url "https://registry.npmjs.org/codeburn/-/codeburn-0.9.11.tgz"
  sha256 "8cd18a0fe41708273ee62e6698c50f2997149c57edb0869ac04945c6a5028c7a"
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

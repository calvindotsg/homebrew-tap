class Codeburn < Formula
  desc "See where your AI coding tokens go — CLI dashboard for Claude Code cost"
  homepage "https://github.com/getagentseal/codeburn"
  url "https://registry.npmjs.org/codeburn/-/codeburn-0.8.9.tgz"
  sha256 "2875375033688b232c27b6fddd99f8a7167bfa7b6dbb3f4ef433cf07287a3e11"
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

class Codeburn < Formula
  desc "See where your AI coding tokens go — CLI dashboard for Claude Code cost"
  homepage "https://github.com/getagentseal/codeburn"
  url "https://registry.npmjs.org/codeburn/-/codeburn-0.9.4.tgz"
  sha256 "9c6d02bcfad1b9307f248d0a10ffff0d22a709f6b6752ebc769151969eeb2c16"
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

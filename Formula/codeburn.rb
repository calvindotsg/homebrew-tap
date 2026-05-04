class Codeburn < Formula
  desc "See where your AI coding tokens go — CLI dashboard for Claude Code cost"
  homepage "https://github.com/getagentseal/codeburn"
  url "https://registry.npmjs.org/codeburn/-/codeburn-0.9.6.tgz"
  sha256 "54246a5ed6fe4d93eec2082a3eb817db197cceed428abcddd814eee100360aac"
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

class GranolaCli < Formula
  desc "CLI for Granola meeting notes"
  homepage "https://github.com/magarcia/granola-cli"
  url "https://registry.npmjs.org/granola-cli/-/granola-cli-0.2.0.tgz"
  sha256 "210807f85946a8ac6f40fd8de8a54a6c1388adc6647d561a535dcb059b4bae53"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/granola --version")
  end
end

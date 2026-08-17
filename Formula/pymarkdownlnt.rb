class Pymarkdownlnt < Formula
  include Language::Python::Virtualenv

  desc "GitHub Flavored Markdown compliant Markdown linter"
  homepage "https://github.com/jackdewinter/pymarkdown"
  url "https://files.pythonhosted.org/packages/d4/aa/9f6ac3a91b5c02cedb5ada2ae12fddf4954fe3faab176941a68510e9830e/pymarkdownlnt-0.9.39.tar.gz"
  sha256 "5f422d593244942e4b545b54b512f6b7e509f907752d707695c051bfe8584948"
  license "MIT"

  # No `livecheck` block: the Pypi strategy auto-matches files.pythonhosted.org URLs
  # and derives https://pypi.org/pypi/pymarkdownlnt/json from the sdist filename.
  #
  # Sourcing from PyPI rather than the upstream GitHub tag is load-bearing, not taste.
  # `brew bump-formula-pr` calls `PyPI.update_python_resources!` with
  # `ignore_non_pypi_packages: true`, so with a GitHub tarball URL the daily livecheck
  # would bump `url`/`sha256` and SILENTLY leave every resource below frozen at the old
  # dependency versions — then automerge.yml would land it.

  # No `depends_on macos:` — this is a cross-platform pure-Python linter, so tests.yml
  # builds it on the ubuntu leg too.
  #
  # Pinned to 3.13 rather than 3.14 (now Homebrew's `python3`): upstream's trove
  # classifiers stop at 3.13, and `sly` — whose lexer/parser DSL does metaclass and
  # frame introspection, the category that breaks first on a new CPython minor —
  # declares no supported versions at all. Matches the tap's other Python formulae.
  # Required by `brew audit`'s ResourceRequiresDependencies rule because the pyyaml
  # resource below can link it. PyYAML falls back to a pure-Python parser without it,
  # but Homebrew builds every resource from source (`std_pip_args` forces
  # `--no-binary=:all:`), so the C accelerator is built and the dependency is real.
  depends_on "libyaml"
  depends_on "python@3.13"

  resource "application-file-scanner" do
    url "https://files.pythonhosted.org/packages/ea/22/e872546d298103527380955f51191ff87cd178e6aac62bb87de73c3e074f/application_file_scanner-0.6.4.tar.gz"
    sha256 "581c48c5017345747be7f49507da84fec36d1f7b4f67003e9fbaf2f0bc6a3f66"
  end

  resource "application-properties" do
    url "https://files.pythonhosted.org/packages/c0/bb/321da0e373416080801d05b8dd9c0a8da77fe305c697adf8c025470ce170/application_properties-0.9.3.tar.gz"
    sha256 "7dc7d8f23d11e539427e7b8e3afa70353e159c16f703bad6dd082cc6cdfeeaa8"
  end

  resource "columnar" do
    url "https://files.pythonhosted.org/packages/5e/0d/a0b2fd781050d29c9df64ac6df30b5f18b775724b79779f56fc5a8298fe9/Columnar-1.4.1.tar.gz"
    sha256 "c3cb57273333b2ff9cfaafc86f09307419330c97faa88dcfe23df05e6fbb9c72"
  end

  resource "py-walk" do
    url "https://files.pythonhosted.org/packages/b3/b5/e2f3fab1e11d4089b1c3dfd72175fdb2408ff8028e01bdb0d308923609bb/py_walk-0.3.3.tar.gz"
    sha256 "a1b28d6079f27203fa3098b69a98572675b3ff5bd02286c43e6dacd66615f879"
  end

  resource "pyjson5" do
    url "https://files.pythonhosted.org/packages/f1/9a/3db19560e968d6e85b2a4ddf4b949c6ebf9dd1dcfb5a9f37736f8adeb927/pyjson5-2.0.1.tar.gz"
    sha256 "a5b0e322e847b198a50d8a1ef16d6b2b19129644dc018d76773e81ef1487ca39"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  resource "sly" do
    url "https://files.pythonhosted.org/packages/41/8a/59e943f7b27904c7756a7b565ffbd55f3841f5cd3d2da2b2b0713c49e488/sly-0.5.tar.gz"
    sha256 "251d42015e8507158aec2164f06035df4a82b0314ce6450f457d7125e7649024"
  end

  resource "tomli" do
    url "https://files.pythonhosted.org/packages/22/de/48c59722572767841493b26183a0d1cc411d54fd759c5607c4590b6563a6/tomli-2.4.1.tar.gz"
    sha256 "7c7e1a961a0b2f2472c1ac5b69affa0ae1132c39adcb67aba98568702b9cc23f"
  end

  resource "toolz" do
    url "https://files.pythonhosted.org/packages/11/d6/114b492226588d6ff54579d95847662fc69196bdeec318eb45393b24c192/toolz-1.1.0.tar.gz"
    sha256 "27a5c770d068c110d9ed9323f24f1543e83b2f300a687b7891c1a6d56b697b5b"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/f6/cc/6253133b5bb138fc3306cebfbda2c520f545d36b5be2c7255cc528bb45d6/typing_extensions-4.16.0.tar.gz"
    sha256 "dc983d19a509c94dba722ee6abd33940f7c05a89e243c47e907eb4db6f1a43e5"
  end

  resource "wcwidth" do
    url "https://files.pythonhosted.org/packages/34/74/c6428f875774288bec1396f5bfcbc2d925700a4dad61727fd5f2b12f249d/wcwidth-0.8.2.tar.gz"
    sha256 "91fbef97204b96a3d4d421609b80340b760cf33e26da123ff243d76b1fda8dda"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    # Upstream registers `version` as an argparse subcommand, not a `--version` flag,
    # so this deviates from the tap's usual `--version` one-liner.
    assert_match version.to_s, shell_output("#{bin}/pymarkdown version")

    # A file with no trailing newline violates MD047. `scan` exits 1 when it reports
    # anything, so asserting on exit status 1 proves the rule engine and plugin
    # loading actually ran — not merely that the entry point imports.
    (testpath/"bad.md").write("# Title")
    assert_match "MD047", shell_output("#{bin}/pymarkdown scan #{testpath}/bad.md", 1)
  end
end

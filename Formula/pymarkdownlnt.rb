class Pymarkdownlnt < Formula
  include Language::Python::Virtualenv

  desc "GitHub Flavored Markdown compliant Markdown linter"
  homepage "https://github.com/jackdewinter/pymarkdown"
  url "https://files.pythonhosted.org/packages/fc/ba/196874ceaa6c603e39578e92fa1dc8356dec3205d2437c7b1f7bcf606825/pymarkdownlnt-0.9.41.tar.gz"
  sha256 "d6a477498feacf004ba1eea1847e70cbb083c7175ee62bde7a8f11bf2ce943cb"
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
    url "https://files.pythonhosted.org/packages/b0/78/9ad63712633ed3ab5cc1a648d863d7e7da371e9425e209555a0fe711b695/tomli-2.5.0.tar.gz"
    sha256 "264507556cd8b8c8e7c6ee037cdf443a463f03f4c958e57195e3d369711b8ff6"
  end

  resource "toolz" do
    url "https://files.pythonhosted.org/packages/31/6f/ae20c212a07aa2d156c787383d8088a5e045ee39628661edb190c97e1659/toolz-1.2.0.tar.gz"
    sha256 "9667a038e9d6ecba37995e26cb2f59ec6420b6ad8dd9677de59db9b956b08490"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/f6/cc/6253133b5bb138fc3306cebfbda2c520f545d36b5be2c7255cc528bb45d6/typing_extensions-4.16.0.tar.gz"
    sha256 "dc983d19a509c94dba722ee6abd33940f7c05a89e243c47e907eb4db6f1a43e5"
  end

  resource "wcwidth" do
    url "https://files.pythonhosted.org/packages/f0/b4/7830542634bb2d3e62aa3b586a72d5b3b6c91c3168929e7000ef3fed041d/wcwidth-0.9.2.tar.gz"
    sha256 "ae0ef90b90f6af38b54f1fe6d58662ec33b3cb4b8391958a62416d654231727b"
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

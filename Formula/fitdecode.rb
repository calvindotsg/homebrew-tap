class Fitdecode < Formula
  include Language::Python::Virtualenv

  desc "Decode Garmin FIT files to JSON or text (fitjson, fittxt)"
  homepage "https://github.com/polyvertex/fitdecode"
  url "https://files.pythonhosted.org/packages/87/19/1bde056f443d8ce890dbc0f0bd8a216cc9ebfda4221619767f80cf1835e2/fitdecode-0.11.0.tar.gz"
  sha256 "52d920e50eaa76eb065b20bfd4e42f72195e894a079098dacc1cafa908cd4b83"
  license "MIT"

  # No `livecheck` block: the Pypi strategy auto-matches files.pythonhosted.org URLs.
  # Sourced from the PyPI sdist, not the GitHub tag, for the reason Formula/pymarkdownlnt.rb
  # gives: `brew bump-formula-pr` only regenerates resources for a PyPI main `url`.
  #
  # No resources: fitdecode has no runtime dependencies (requires_dist is dev extras only).
  # Used by hermes-training-wiki's tools/strava_export.py, which calls `fitjson` as a
  # subprocess so the wiki's own Python stays standard-library-only.
  #
  # Pinned to 3.13 to match the tap's other Python formulae.
  depends_on "python@3.13"

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match "usage", shell_output("#{bin}/fitjson --help").downcase
    assert_match version.to_s,
      shell_output("#{libexec}/bin/python -c 'import fitdecode; print(fitdecode.__version__)'")
  end
end

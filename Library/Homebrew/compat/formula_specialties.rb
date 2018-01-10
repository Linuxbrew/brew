class ScriptFileFormula < Formula
  def install
    odeprecated "ScriptFileFormula#install", "Formula#install"
    bin.install Dir["*"]
  end
end

class GithubGistFormula < ScriptFileFormula
  def self.url(val)
    odeprecated "GithubGistFormula.url", "Formula.url"
    super
    version File.basename(File.dirname(val))[0, 6]
  end
end

# This formula serves as the base class for several very similar
# formulae for Amazon Web Services related tools.
class AmazonWebServicesFormula < Formula
  # Use this method to perform a standard install for Java-based tools,
  # keeping the .jars out of HOMEBREW_PREFIX/lib
  def install
    odeprecated "AmazonWebServicesFormula#install", "Formula#install"

    rm Dir["bin/*.cmd"] # Remove Windows versions
    libexec.install Dir["*"]
    bin.install_symlink Dir["#{libexec}/bin/*"] - ["#{libexec}/bin/service"]
  end
  alias standard_install install

  # Use this method to generate standard caveats.
  def standard_instructions(home_name, home_value = libexec)
    odeprecated "AmazonWebServicesFormula#standard_instructions", "Formula#caveats"

    <<~EOS
      Before you can use these tools you must export some variables to your $SHELL.

      To export the needed variables, add them to your dotfiles.
       * On Bash, add them to `~/.bash_profile`.
       * On Zsh, add them to `~/.zprofile` instead.

      export JAVA_HOME="$(/usr/libexec/java_home)"
      export AWS_ACCESS_KEY="<Your AWS Access ID>"
      export AWS_SECRET_KEY="<Your AWS Secret Key>"
      export #{home_name}="#{home_value}"
    EOS
  end
end

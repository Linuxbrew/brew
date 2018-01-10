#:  * `diy` [`--name=`<name>] [`--version=`<version>]:
#:    Automatically determine the installation prefix for non-Homebrew software.
#:
#:    Using the output from this command, you can install your own software into
#:    the Cellar and then link it into Homebrew's prefix with `brew link`.
#:
#:    The options `--name=`<name> and `--version=`<version> each take an argument
#:    and allow you to explicitly set the name and version of the package you are
#:    installing.

require "formula"

module Homebrew
  module_function

  def diy
    path = Pathname.getwd

    version = ARGV.value("version") || detect_version(path)
    name = ARGV.value("name") || detect_name(path, version)

    prefix = HOMEBREW_CELLAR/name/version

    if File.file? "CMakeLists.txt"
      puts "-DCMAKE_INSTALL_PREFIX=#{prefix}"
    elsif File.file? "configure"
      puts "--prefix=#{prefix}"
    else
      raise "Couldn't determine build system"
    end
  end

  def detect_version(path)
    version = path.version.to_s

    raise "Couldn't determine version, set it with --version=<version>" if version.empty?

    version
  end

  def detect_name(path, version)
    basename = path.basename.to_s
    detected_name = basename[/(.*?)-?#{Regexp.escape(version)}/, 1] || basename
    canonical_name = Formulary.canonical_name(detected_name)

    odie <<~EOS if detected_name != canonical_name
      The detected name #{detected_name.inspect} exists in Homebrew as an alias
      of #{canonical_name.inspect}. Consider using the canonical name instead:
        brew diy --name=#{canonical_name}

      To continue using the detected name, pass it explicitly:
        brew diy --name=#{detected_name}
      EOS

    detected_name
  end
end

#:  * `unpack` [`--git`|`--patch`] [`--destdir=`<path>] <formulae>:
#:    Unpack the source files for <formulae> into subdirectories of the current
#:    working directory. If `--destdir=`<path> is given, the subdirectories will
#:    be created in the directory named by <path> instead.
#:
#:    If `--patch` is passed, patches for <formulae> will be applied to the
#:    unpacked source.
#:
#:    If `--git` (or `-g`) is passed, a Git repository will be initialized in the unpacked
#:    source. This is useful for creating patches for the software.

require "stringio"
require "formula"

module Homebrew
  module_function

  def unpack
    formulae = ARGV.formulae
    raise FormulaUnspecifiedError if formulae.empty?

    if dir = ARGV.value("destdir")
      unpack_dir = Pathname.new(dir).expand_path
      unpack_dir.mkpath
    else
      unpack_dir = Pathname.pwd
    end

    raise "Cannot write to #{unpack_dir}" unless unpack_dir.writable_real?

    formulae.each do |f|
      stage_dir = unpack_dir/"#{f.name}-#{f.version}"

      if stage_dir.exist?
        raise "Destination #{stage_dir} already exists!" unless ARGV.force?
        rm_rf stage_dir
      end

      oh1 "Unpacking #{f.full_name} to: #{stage_dir}"

      ENV["VERBOSE"] = "1" # show messages about tar
      f.brew do
        f.patch if ARGV.flag?("--patch")
        cp_r getwd, stage_dir, preserve: true
      end
      ENV["VERBOSE"] = nil

      next unless ARGV.git?
      ohai "Setting up git repository"
      cd stage_dir
      system "git", "init", "-q"
      system "git", "add", "-A"
      system "git", "commit", "-q", "-m", "brew-unpack"
    end
  end
end

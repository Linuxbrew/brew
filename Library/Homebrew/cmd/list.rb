#:  * `list`, `ls` [`--full-name`]:
#:    List all installed formulae. If `--full-name` is passed, print formulae
#:    with fully-qualified names. If `--full-name` is not passed, any other
#:    options (e.g. `-t`) are passed to `ls` which produces the actual output.
#:
#:  * `list`, `ls` `--unbrewed`:
#:    List all files in the Homebrew prefix not installed by Homebrew.
#:
#:  * `list`, `ls` [`--versions` [`--multiple`]] [`--pinned`] [<formulae>]:
#:    List the installed files for <formulae>. Combined with `--verbose`, recursively
#:    list the contents of all subdirectories in each <formula>'s keg.
#:
#:    If `--versions` is passed, show the version number for installed formulae,
#:    or only the specified formulae if <formulae> are given. With `--multiple`,
#:    only show formulae with multiple versions installed.
#:
#:    If `--pinned` is passed, show the versions of pinned formulae, or only the
#:    specified (pinned) formulae if <formulae> are given.
#:    See also `pin`, `unpin`.

require "metafiles"
require "formula"

module Homebrew
  module_function

  def list
    # Use of exec means we don't explicitly exit
    list_unbrewed if ARGV.flag? "--unbrewed"

    # Unbrewed uses the PREFIX, which will exist
    # Things below use the CELLAR, which doesn't until the first formula is installed.
    unless HOMEBREW_CELLAR.exist?
      raise NoSuchKegError, ARGV.named.first unless ARGV.named.empty?
      return
    end

    if ARGV.include?("--pinned") || ARGV.include?("--versions")
      filtered_list
    elsif ARGV.named.empty?
      if ARGV.include? "--full-name"
        full_names = Formula.installed.map(&:full_name).sort(&tap_and_name_comparison)
        return if full_names.empty?
        puts Formatter.columns(full_names)
      else
        ENV["CLICOLOR"] = nil
        exec "ls", *ARGV.options_only << HOMEBREW_CELLAR
      end
    elsif ARGV.verbose? || !$stdout.tty?
      exec "find", *ARGV.kegs.map(&:to_s) + %w[-not -type d -print]
    else
      ARGV.kegs.each { |keg| PrettyListing.new keg }
    end
  end

  UNBREWED_EXCLUDE_FILES = %w[.DS_Store].freeze
  UNBREWED_EXCLUDE_PATHS = %w[
    .github/*
    bin/brew
    completions/zsh/_brew
    docs/*
    lib/gdk-pixbuf-2.0/*
    lib/gio/*
    lib/node_modules/*
    lib/python[23].[0-9]/*
    lib/pypy/*
    lib/pypy3/*
    lib/ruby/gems/[12].*
    lib/ruby/site_ruby/[12].*
    lib/ruby/vendor_ruby/[12].*
    manpages/brew.1
    manpages/brew-cask.1
    share/pypy/*
    share/pypy3/*
    share/info/dir
    share/man/whatis
  ].freeze

  def list_unbrewed
    dirs  = HOMEBREW_PREFIX.subdirs.map { |dir| dir.basename.to_s }
    dirs -= %w[Library Cellar .git]

    # Exclude cache, logs, and repository, if they are located under the prefix.
    [HOMEBREW_CACHE, HOMEBREW_LOGS, HOMEBREW_REPOSITORY].each do |dir|
      dirs.delete dir.relative_path_from(HOMEBREW_PREFIX).to_s
    end
    dirs.delete "etc"
    dirs.delete "var"

    args = dirs.sort + %w[-type f (]
    args.concat UNBREWED_EXCLUDE_FILES.flat_map { |f| %W[! -name #{f}] }
    args.concat UNBREWED_EXCLUDE_PATHS.flat_map { |d| %W[! -path #{d}] }
    args.concat %w[)]

    cd HOMEBREW_PREFIX
    exec "find", *args
  end

  def filtered_list
    names = if ARGV.named.empty?
      Formula.racks
    else
      racks = ARGV.named.map { |n| Formulary.to_rack(n) }
      racks.select do |rack|
        Homebrew.failed = true unless rack.exist?
        rack.exist?
      end
    end
    if ARGV.include? "--pinned"
      pinned_versions = {}
      names.sort.each do |d|
        keg_pin = (HOMEBREW_PINNED_KEGS/d.basename.to_s)
        if keg_pin.exist? || keg_pin.symlink?
          pinned_versions[d] = keg_pin.readlink.basename.to_s
        end
      end
      pinned_versions.each do |d, version|
        puts d.basename.to_s.concat(ARGV.include?("--versions") ? " #{version}" : "")
      end
    else # --versions without --pinned
      names.sort.each do |d|
        versions = d.subdirs.map { |pn| pn.basename.to_s }
        next if ARGV.include?("--multiple") && versions.length < 2
        puts "#{d.basename} #{versions * " "}"
      end
    end
  end
end

class PrettyListing
  def initialize(path)
    Pathname.new(path).children.sort_by { |p| p.to_s.downcase }.each do |pn|
      case pn.basename.to_s
      when "bin", "sbin"
        pn.find { |pnn| puts pnn unless pnn.directory? }
      when "lib"
        print_dir pn do |pnn|
          # dylibs have multiple symlinks and we don't care about them
          (pnn.extname == ".dylib" || pnn.extname == ".pc") && !pnn.symlink?
        end
      when ".brew"
        next # Ignore .brew
      else
        if pn.directory?
          if pn.symlink?
            puts "#{pn} -> #{pn.readlink}"
          else
            print_dir pn
          end
        elsif Metafiles.list?(pn.basename.to_s)
          puts pn
        end
      end
    end
  end

  def print_dir(root)
    dirs = []
    remaining_root_files = []
    other = ""

    root.children.sort.each do |pn|
      if pn.directory?
        dirs << pn
      elsif block_given? && yield(pn)
        puts pn
        other = "other "
      else
        remaining_root_files << pn unless pn.basename.to_s == ".DS_Store"
      end
    end

    dirs.each do |d|
      files = []
      d.find { |pn| files << pn unless pn.directory? }
      print_remaining_files files, d
    end

    print_remaining_files remaining_root_files, root, other
  end

  def print_remaining_files(files, root, other = "")
    if files.length == 1
      puts files
    elsif files.length > 1
      puts "#{root}/ (#{files.length} #{other}files)"
    end
  end
end

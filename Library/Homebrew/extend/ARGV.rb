module HomebrewArgvExtension
  def formula_install_option_names
    %w[
      --debug
      --env=
      --ignore-dependencies
      --cc=
      --build-from-source
      --devel
      --HEAD
      --keep-tmp
      --interactive
      --git
      --sandbox
      --no-sandbox
      --build-bottle
      --force-bottle
      --include-test
      --verbose
      --force
      --display-times
      -i
      -v
      -d
      -g
      -s
      -f
    ].freeze
  end

  def named
    @named ||= self - options_only
  end

  def options_only
    select { |arg| arg.start_with?("-") }
  end

  def flags_only
    select { |arg| arg.start_with?("--") }
  end

  def formulae
    require "formula"
    @formulae ||= (downcased_unique_named - casks).map do |name|
      if name.include?("/") || File.exist?(name)
        Formulary.factory(name, spec)
      else
        Formulary.find_with_priority(name, spec)
      end
    end.uniq(&:name)
  end

  def resolved_formulae
    require "formula"
    @resolved_formulae ||= (downcased_unique_named - casks).map do |name|
      Formulary.resolve(name, spec: spec(nil))
    end.uniq(&:name)
  end

  def casks
    @casks ||= downcased_unique_named.grep HOMEBREW_CASK_TAP_CASK_REGEX
  end

  def kegs
    require "keg"
    require "formula"
    @kegs ||= downcased_unique_named.map do |name|
      raise UsageError if name.empty?

      rack = Formulary.to_rack(name.downcase)

      dirs = rack.directory? ? rack.subdirs : []

      raise NoSuchKegError, rack.basename if dirs.empty?

      linked_keg_ref = HOMEBREW_LINKED_KEGS/rack.basename
      opt_prefix = HOMEBREW_PREFIX/"opt/#{rack.basename}"

      begin
        if opt_prefix.symlink? && opt_prefix.directory?
          Keg.new(opt_prefix.resolved_path)
        elsif linked_keg_ref.symlink? && linked_keg_ref.directory?
          Keg.new(linked_keg_ref.resolved_path)
        elsif dirs.length == 1
          Keg.new(dirs.first)
        else
          f = if name.include?("/") || File.exist?(name)
            Formulary.factory(name)
          else
            Formulary.from_rack(rack)
          end

          unless (prefix = f.installed_prefix).directory?
            raise MultipleVersionsInstalledError, rack.basename
          end

          Keg.new(prefix)
        end
      rescue FormulaUnavailableError
        raise <<~EOS
          Multiple kegs installed to #{rack}
          However we don't know which one you refer to.
          Please delete (with rm -rf!) all but one and then try again.
        EOS
      end
    end
  end

  def include?(arg)
    !(@n = index(arg)).nil?
  end

  def next
    at(@n + 1) || raise(UsageError)
  end

  def value(name)
    arg_prefix = "--#{name}="
    flag_with_value = find { |arg| arg.start_with?(arg_prefix) }
    flag_with_value&.delete_prefix(arg_prefix)
  end

  # Returns an array of values that were given as a comma-separated list.
  # @see value
  def values(name)
    return unless val = value(name)

    val.split(",")
  end

  def force?
    flag? "--force"
  end

  def verbose?
    flag?("--verbose") || !ENV["VERBOSE"].nil? || !ENV["HOMEBREW_VERBOSE"].nil?
  end

  def debug?
    flag?("--debug") || !ENV["HOMEBREW_DEBUG"].nil?
  end

  def quieter?
    flag? "--quieter"
  end

  def interactive?
    flag? "--interactive"
  end

  def one?
    flag? "--1"
  end

  def dry_run?
    include?("--dry-run") || switch?("n")
  end

  def keep_tmp?
    include? "--keep-tmp"
  end

  def git?
    flag? "--git"
  end

  def homebrew_developer?
    !ENV["HOMEBREW_DEVELOPER"].nil?
  end

  def sandbox?
    include?("--sandbox") || !ENV["HOMEBREW_SANDBOX"].nil?
  end

  def no_sandbox?
    include?("--no-sandbox") || !ENV["HOMEBREW_NO_SANDBOX"].nil?
  end

  def ignore_deps?
    include? "--ignore-dependencies"
  end

  def only_deps?
    include? "--only-dependencies"
  end

  def json
    value "json"
  end

  def build_head?
    include? "--HEAD"
  end

  def build_devel?
    include? "--devel"
  end

  def build_stable?
    !(build_head? || build_devel?)
  end

  def build_universal?
    include? "--universal"
  end

  def build_bottle?
    include?("--build-bottle") || !ENV["HOMEBREW_BUILD_BOTTLE"].nil?
  end

  def bottle_arch
    arch = value "bottle-arch"
    arch&.to_sym
  end

  def build_from_source?
    switch?("s") || include?("--build-from-source")
  end

  def build_all_from_source?
    !ENV["HOMEBREW_BUILD_FROM_SOURCE"].nil?
  end

  # Whether a given formula should be built from source during the current
  # installation run.
  def build_formula_from_source?(f)
    return true if build_all_from_source?
    return false unless build_from_source? || build_bottle?

    formulae.any? { |argv_f| argv_f.full_name == f.full_name }
  end

  def flag?(flag)
    options_only.include?(flag) || switch?(flag[2, 1])
  end

  def force_bottle?
    include?("--force-bottle")
  end

  def fetch_head?
    include? "--fetch-HEAD"
  end

  # eg. `foo -ns -i --bar` has three switches, n, s and i
  def switch?(char)
    return false if char.length > 1

    options_only.any? { |arg| arg.scan("-").size == 1 && arg.include?(char) }
  end

  def cc
    value "cc"
  end

  def env
    value "env"
  end

  # If the user passes any flags that trigger building over installing from
  # a bottle, they are collected here and returned as an Array for checking.
  def collect_build_flags
    build_flags = []

    build_flags << "--HEAD" if build_head?
    build_flags << "--universal" if build_universal?
    build_flags << "--build-bottle" if build_bottle?
    build_flags << "--build-from-source" if build_from_source?

    build_flags
  end

  private

  def spec(default = :stable)
    if include?("--HEAD")
      :head
    elsif include?("--devel")
      :devel
    else
      default
    end
  end

  def downcased_unique_named
    # Only lowercase names, not paths, bottle filenames or URLs
    @downcased_unique_named ||= named.map do |arg|
      if arg.include?("/") || arg.end_with?(".tar.gz") || File.exist?(arg)
        arg
      else
        arg.downcase
      end
    end.uniq
  end
end

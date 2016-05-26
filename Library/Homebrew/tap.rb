require "extend/string"

# a {Tap} is used to extend the formulae provided by Homebrew core.
# Usually, it's synced with a remote git repository. And it's likely
# a Github repository with the name of `user/homebrew-repo`. In such
# case, `user/repo` will be used as the {#name} of this {Tap}, where
# {#user} represents Github username and {#repo} represents repository
# name without leading `homebrew-`.
class Tap
  TAP_DIRECTORY = HOMEBREW_LIBRARY/"Taps"

  CACHE = {}

  def self.clear_cache
    CACHE.clear
  end

  def self.fetch(*args)
    case args.length
    when 1
      user, repo = args.first.split("/", 2)
    when 2
      user = args[0]
      repo = args[1]
    end

    raise "Invalid tap name" unless user && repo

    # we special case homebrew so users don't have to shift in a terminal
    user = "Homebrew" if user == "homebrew"
    user = "Linuxbrew" if user == "linuxbrew"
    repo = repo.strip_prefix "homebrew-"

    if user == "Homebrew" && (repo == "homebrew" || repo == "core") ||
        user == "Linuxbrew" && (repo == "linuxbrew" || repo == "core")
      return CoreTap.instance
    end

    cache_key = "#{user}/#{repo}".downcase
    CACHE.fetch(cache_key) { |key| CACHE[key] = Tap.new(user, repo) }
  end

  extend Enumerable

  # The user name of this {Tap}. Usually, it's the Github username of
  # this #{Tap}'s remote repository.
  attr_reader :user

  # The repository name of this {Tap} without leading `homebrew-`.
  attr_reader :repo

  # The name of this {Tap}. It combines {#user} and {#repo} with a slash.
  # {#name} is always in lowercase.
  # e.g. `user/repo`
  attr_reader :name

  # The local path to this {Tap}.
  # e.g. `/usr/local/Library/Taps/user/homebrew-repo`
  attr_reader :path

  # @private
  def initialize(user, repo)
    @user = user
    @repo = repo
    @name = "#{@user}/#{@repo}".downcase
    @path = TAP_DIRECTORY/"#{@user}/homebrew-#{@repo}".downcase
  end

  # clear internal cache
  def clear_cache
    @remote = nil
    @formula_dir = nil
    @formula_files = nil
    @alias_dir = nil
    @alias_files = nil
    @aliases = nil
    @alias_table = nil
    @alias_reverse_table = nil
    @command_files = nil
    @formula_renames = nil
    @tap_migrations = nil
    @config = nil
    remove_instance_variable(:@private) if instance_variable_defined?(:@private)
  end

  # The remote path to this {Tap}.
  # e.g. `https://github.com/user/homebrew-repo`
  def remote
    @remote ||= if installed?
      if git? && Utils.git_available?
        path.cd do
          Utils.popen_read("git", "config", "--get", "remote.origin.url").chomp
        end
      end
    else
      raise TapUnavailableError, name
    end
  end

  # The GitHub slug of the {Tap}.
  # Not simply "#{user}/homebrew-#{repo}", because the slug of homebrew/core
  # may be either Homebrew/homebrew-core or Linuxbrew/homebrew-core.
  def slug
    if remote.nil?
      "#{user}/homebrew-#{repo}"
    else
      x = remote[%r"^https://github\.com/([^.]+)(\.git)?$", 1]
      (official? && !x.nil?) ? x.capitalize : x
    end
  end

  # The default remote path to this {Tap}.
  def default_remote
    if OS.mac?
      "https://github.com/#{user}/homebrew-#{repo}"
    else
      case "#{user}/#{repo}"
      when "Homebrew/dupes"
        "https://github.com/Linuxbrew/homebrew-#{repo}"
      else
        "https://github.com/#{user}/homebrew-#{repo}"
      end
    end
  end

  # True if this {Tap} is a git repository.
  def git?
    (path/".git").exist?
  end

  # git HEAD for this {Tap}.
  def git_head
    raise TapUnavailableError, name unless installed?
    return unless git? && Utils.git_available?
    path.cd { Utils.popen_read("git", "rev-parse", "--verify", "-q", "HEAD").chuzzle }
  end

  # git HEAD in short format for this {Tap}.
  def git_short_head
    raise TapUnavailableError, name unless installed?
    return unless git? && Utils.git_available?
    path.cd { Utils.popen_read("git", "rev-parse", "--short=4", "--verify", "-q", "HEAD").chuzzle }
  end

  # time since git last commit for this {Tap}.
  def git_last_commit
    raise TapUnavailableError, name unless installed?
    return unless git? && Utils.git_available?
    path.cd { Utils.popen_read("git", "show", "-s", "--format=%cr", "HEAD").chuzzle }
  end

  # git last commit date for this {Tap}.
  def git_last_commit_date
    raise TapUnavailableError, name unless installed?
    return unless git? && Utils.git_available?
    path.cd { Utils.popen_read("git", "show", "-s", "--format=%cd", "--date=short", "HEAD").chuzzle }
  end

  # The issues URL of this {Tap}.
  # e.g. `https://github.com/user/homebrew-repo/issues`
  def issues_url
    if official? || !custom_remote?
      "https://github.com/#{slug}/issues"
    end
  end

  def to_s
    name
  end

  # True if this {Tap} is an official Homebrew tap.
  def official?
    user == "Homebrew" || user == "Linuxbrew"
  end

  # Whether this tap is for Linux.
  # Not simply user == "Linuxbrew", because the user of the core repo
  # homebrew/core is Homebrew and not Linuxbrew.
  def linux?
    slug.start_with? "Linuxbrew/"
  end

  # True if the remote of this {Tap} is a private repository.
  def private?
    return @private if instance_variable_defined?(:@private)
    @private = read_or_set_private_config
  end

  # {TapConfig} of this {Tap}
  def config
    @config ||= begin
      raise TapUnavailableError, name unless installed?
      TapConfig.new(self)
    end
  end

  # True if this {Tap} has been installed.
  def installed?
    path.directory?
  end

  # True if this {Tap} is not a full clone.
  def shallow?
    (path/".git/shallow").exist?
  end

  # @private
  def core_tap?
    false
  end

  # install this {Tap}.
  #
  # @param [Hash] options
  # @option options [String]  :clone_targe If passed, it will be used as the clone remote.
  # @option options [Boolean] :full_clone If set as true, full clone will be used.
  # @option options [Boolean] :quiet If set, suppress all output.
  def install(options = {})
    require "descriptions"

    full_clone = options.fetch(:full_clone, false)
    quiet = options.fetch(:quiet, false)
    requested_remote = options[:clone_target] || default_remote

    if installed?
      raise TapAlreadyTappedError, name unless full_clone
      raise TapAlreadyUnshallowError, name unless shallow?
    end

    # ensure git is installed
    Utils.ensure_git_installed!

    if installed?
      if options[:clone_target] && requested_remote != remote
        raise TapRemoteMismatchError.new(name, @remote, requested_remote)
      end

      ohai "Unshallowing #{name}" unless quiet
      args = %W[fetch --unshallow]
      args << "-q" if quiet
      path.cd { safe_system "git", *args }
      return
    end

    clear_cache

    ohai "Tapping #{name}" unless quiet
    args =  %W[clone #{requested_remote} #{path}]
    args << "--depth=1" unless full_clone
    args << "-q" if quiet

    git_version = Version.new(`git --version`[/git version (\d\.\d+\.\d+)/, 1])
    raise ErrorDuringExecution.new(cmd) unless $?.success?
    args << "--config" << "core.autocrlf=false" if git_version >= Version.new("1.7.10")

    begin
      safe_system "git", *args
    rescue Interrupt, ErrorDuringExecution
      ignore_interrupts do
        sleep 0.1 # wait for git to cleanup the top directory when interrupt happens.
        path.parent.rmdir_if_possible
      end
      raise
    end

    link_manpages

    formula_count = formula_files.size
    puts "Tapped #{formula_count} formula#{plural(formula_count, "e")} (#{path.abv})" unless quiet
    Descriptions.cache_formulae(formula_names)

    if !options[:clone_target] && private? && !quiet
      puts <<-EOS.undent
        It looks like you tapped a private repository. To avoid entering your
        credentials each time you update, you can use git HTTP credential
        caching or issue the following command:
          cd #{path}
          git remote set-url origin git@github.com:#{user}/homebrew-#{repo}.git
      EOS
    end
  end

  def link_manpages
    return unless (path/"man").exist?
    conflicts = []
    (path/"man").find do |src|
      next if src.directory?
      dst = HOMEBREW_PREFIX/"share"/src.relative_path_from(path)
      next if dst.symlink? && src == dst.resolved_path
      if dst.exist?
        conflicts << dst
        next
      end
      dst.make_relative_symlink(src)
    end
    unless conflicts.empty?
      onoe <<-EOS.undent
        Could not link #{name} manpages to:
          #{conflicts.join("\n")}

        Please delete these files and run `brew tap --repair`.
      EOS
    end
  end

  # uninstall this {Tap}.
  def uninstall
    require "descriptions"
    raise TapUnavailableError, name unless installed?

    puts "Untapping #{name}... (#{path.abv})"
    unpin if pinned?
    formula_count = formula_files.size
    Descriptions.uncache_formulae(formula_names)
    unlink_manpages
    path.rmtree
    path.parent.rmdir_if_possible
    puts "Untapped #{formula_count} formula#{plural(formula_count, "e")}"
    clear_cache
  end

  def unlink_manpages
    return unless (path/"man").exist?
    (path/"man").find do |src|
      next if src.directory?
      dst = HOMEBREW_PREFIX/"share"/src.relative_path_from(path)
      dst.delete if dst.symlink? && src == dst.resolved_path
      dst.parent.rmdir_if_possible
    end
  end

  # True if the {#remote} of {Tap} is customized.
  def custom_remote?
    return true unless remote
    remote.casecmp(default_remote) != 0
  end

  # path to the directory of all {Formula} files for this {Tap}.
  def formula_dir
    @formula_dir ||= [path/"Formula", path/"HomebrewFormula", path].detect(&:directory?)
  end

  # an array of all {Formula} files of this {Tap}.
  def formula_files
    @formula_files ||= if formula_dir
      formula_dir.children.select { |p| p.extname == ".rb" }
    else
      []
    end
  end

  # return true if given path would present a {Formula} file in this {Tap}.
  # accepts both absolute path and relative path (relative to this {Tap}'s path)
  # @private
  def formula_file?(file)
    file = Pathname.new(file) unless file.is_a? Pathname
    file = file.expand_path(path)
    file.extname == ".rb" && file.parent == formula_dir
  end

  # an array of all {Formula} names of this {Tap}.
  def formula_names
    @formula_names ||= formula_files.map { |f| formula_file_to_name(f) }
  end

  # path to the directory of all alias files for this {Tap}.
  # @private
  def alias_dir
    @alias_dir ||= path/"Aliases"
  end

  # an array of all alias files of this {Tap}.
  # @private
  def alias_files
    @alias_files ||= Pathname.glob("#{alias_dir}/*").select(&:file?)
  end

  # an array of all aliases of this {Tap}.
  # @private
  def aliases
    @aliases ||= alias_files.map { |f| alias_file_to_name(f) }
  end

  # a table mapping alias to formula name
  # @private
  def alias_table
    return @alias_table if @alias_table
    @alias_table = Hash.new
    alias_files.each do |alias_file|
      @alias_table[alias_file_to_name(alias_file)] = formula_file_to_name(alias_file.resolved_path)
    end
    @alias_table
  end

  # a table mapping formula name to aliases
  # @private
  def alias_reverse_table
    return @alias_reverse_table if @alias_reverse_table
    @alias_reverse_table = Hash.new
    alias_table.each do |alias_name, formula_name|
      @alias_reverse_table[formula_name] ||= []
      @alias_reverse_table[formula_name] << alias_name
    end
    @alias_reverse_table
  end

  # an array of all commands files of this {Tap}.
  def command_files
    @command_files ||= Pathname.glob("#{path}/cmd/brew-*").select(&:executable?)
  end

  # path to the pin record for this {Tap}.
  # @private
  def pinned_symlink_path
    HOMEBREW_LIBRARY/"PinnedTaps/#{name}"
  end

  # True if this {Tap} has been pinned.
  def pinned?
    return @pinned if instance_variable_defined?(:@pinned)
    @pinned = pinned_symlink_path.directory?
  end

  # pin this {Tap}.
  def pin
    raise TapUnavailableError, name unless installed?
    raise TapPinStatusError.new(name, true) if pinned?
    pinned_symlink_path.make_relative_symlink(path)
    @pinned = true
  end

  # unpin this {Tap}.
  def unpin
    raise TapUnavailableError, name unless installed?
    raise TapPinStatusError.new(name, false) unless pinned?
    pinned_symlink_path.delete
    pinned_symlink_path.parent.rmdir_if_possible
    pinned_symlink_path.parent.parent.rmdir_if_possible
    @pinned = false
  end

  def to_hash
    hash = {
      "name" => name,
      "user" => user,
      "repo" => repo,
      "path" => path.to_s,
      "installed" => installed?,
      "official" => official?,
      "formula_names" => formula_names,
      "formula_files" => formula_files.map(&:to_s),
      "command_files" => command_files.map(&:to_s),
      "pinned" => pinned?
    }

    if installed?
      hash["remote"] = remote
      hash["custom_remote"] = custom_remote?
    end

    hash
  end

  # Hash with tap formula renames
  def formula_renames
    require "utils/json"

    @formula_renames ||= if (rename_file = path/"formula_renames.json").file?
      Utils::JSON.load(rename_file.read)
    else
      {}
    end
  end

  # Hash with tap migrations
  def tap_migrations
    require "utils/json"

    @tap_migrations ||= if (migration_file = path/"tap_migrations.json").file?
      Utils::JSON.load(migration_file.read)
    else
      {}
    end
  end

  def ==(other)
    other = Tap.fetch(other) if other.is_a?(String)
    self.class == other.class && self.name == other.name
  end

  def self.each
    return unless TAP_DIRECTORY.directory?

    TAP_DIRECTORY.subdirs.each do |user|
      user.subdirs.each do |repo|
        yield fetch(user.basename.to_s, repo.basename.to_s)
      end
    end
  end

  # an array of all installed {Tap} names.
  def self.names
    map(&:name)
  end

  # @private
  def formula_file_to_name(file)
    "#{name}/#{file.basename(".rb")}"
  end

  # @private
  def alias_file_to_name(file)
    "#{name}/#{file.basename}"
  end

  private

  def read_or_set_private_config
    case config["private"]
    when "true" then true
    when "false" then false
    else
      config["private"] = begin
        if custom_remote?
          true
        else
          GitHub.private_repo?(user, "homebrew-#{repo}")
        end
      rescue GitHub::HTTPNotFoundError
        true
      rescue GitHub::Error
        false
      end
    end
  end

end

# A specialized {Tap} class for the core formulae
class CoreTap < Tap
  if OS.mac?
    def default_remote
      "https://github.com/Homebrew/homebrew-core"
    end
  else
    def default_remote
      "https://github.com/Linuxbrew/homebrew-core"
    end
  end

  # @private
  def initialize
    super "Homebrew", "core"
  end

  def self.instance
    @instance ||= CoreTap.new
  end

  def self.ensure_installed!(options = {})
    return if instance.installed?
    args = ["tap", instance.name]
    args << "-q" if options.fetch(:quiet, true)
    safe_system HOMEBREW_BREW_FILE, *args
  end

  # @private
  def uninstall
    raise "Tap#uninstall is not available for CoreTap"
  end

  # @private
  def pin
    raise "Tap#pin is not available for CoreTap"
  end

  # @private
  def unpin
    raise "Tap#unpin is not available for CoreTap"
  end

  # @private
  def pinned?
    false
  end

  # @private
  def core_tap?
    true
  end

  # @private
  def formula_dir
    @formula_dir ||= begin
      self.class.ensure_installed!
      super
    end
  end

  # @private
  def alias_dir
    @alias_dir ||= begin
      self.class.ensure_installed!
      super
    end
  end

  # @private
  def formula_renames
    @formula_renames ||= begin
      self.class.ensure_installed!
      super
    end
  end

  # @private
  def tap_migrations
    @tap_migrations ||= begin
      self.class.ensure_installed!
      super
    end
  end

  # @private
  def formula_file_to_name(file)
    file.basename(".rb").to_s
  end

  # @private
  def alias_file_to_name(file)
    file.basename.to_s
  end
end

# Permanent configuration per {Tap} using `git-config(1)`
class TapConfig
  attr_reader :tap

  def initialize(tap)
    @tap = tap
  end

  def [](key)
    return unless tap.git?
    return unless Utils.git_available?

    tap.path.cd do
      Utils.popen_read("git", "config", "--get", "homebrew.#{key}").chuzzle
    end
  end

  def []=(key, value)
    return unless tap.git?
    return unless Utils.git_available?

    tap.path.cd do
      safe_system "git", "config", "--replace-all", "homebrew.#{key}", value.to_s
    end
    value
  end
end

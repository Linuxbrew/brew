require "fileutils"
require "tmpdir"
require "etc"

# Homebrew extends Ruby's `FileUtils` to make our code more readable.
# @see http://ruby-doc.org/stdlib-1.8.7/libdoc/fileutils/rdoc/FileUtils.html Ruby's FileUtils API
module FileUtils
  # Create a temporary directory then yield. When the block returns,
  # recursively delete the temporary directory. Passing opts[:retain]
  # or calling `do |staging| ... staging.retain!` in the block will skip
  # the deletion and retain the temporary directory's contents.
  def mktemp(prefix = name, opts = {})
    Mktemp.new(prefix, opts).run do |staging|
      yield staging
    end
  end

  module_function :mktemp

  # Performs mktemp's functionality, and tracks the results.
  # Each instance is only intended to be used once.
  class Mktemp
    include FileUtils

    # Path to the tmpdir used in this run, as a Pathname.
    attr_reader :tmpdir

    def initialize(prefix = name, opts = {})
      @prefix = prefix
      @retain = opts[:retain]
      @quiet = false
    end

    # Instructs this Mktemp to retain the staged files
    def retain!
      @retain = true
    end

    # True if the staged temporary files should be retained
    def retain?
      @retain
    end

    # Instructs this Mktemp to not emit messages when retention is triggered
    def quiet!
      @quiet = true
    end

    def to_s
      "[Mktemp: #{tmpdir} retain=#{@retain} quiet=#{@quiet}]"
    end

    def run
      @tmpdir = Pathname.new(Dir.mktmpdir("#{@prefix}-", HOMEBREW_TEMP))

      # Make sure files inside the temporary directory have the same group as the
      # brew instance.
      #
      # Reference from `man 2 open`
      # > When a new file is created, it is given the group of the directory which
      # contains it.
      group_id = if HOMEBREW_BREW_FILE.grpowned?
        HOMEBREW_BREW_FILE.stat.gid
      else
        Process.gid
      end
      begin
        chown(nil, group_id, tmpdir)
      rescue Errno::EPERM
        opoo "Failed setting group \"#{Etc.getgrgid(group_id).name}\" on #{tmpdir}"
      end

      begin
        Dir.chdir(tmpdir) { yield self }
      ensure
        ignore_interrupts { rm_rf(tmpdir) } unless retain?
      end
    ensure
      if retain? && !@tmpdir.nil? && !@quiet
        ohai "Kept temporary files"
        puts "Temporary files retained at #{@tmpdir}"
      end
    end
  end

  # @private
  alias old_mkdir mkdir

  # A version of mkdir that also changes to that folder in a block.
  def mkdir(name, &_block)
    mkdir_p(name)
    return unless block_given?
    chdir name do
      yield
    end
  end
  module_function :mkdir

  # Run `scons` using a Homebrew-installed version rather than whatever is in the `PATH`.
  def scons(*args)
    system Formulary.factory("scons").opt_bin/"scons", *args
  end

  # Run the `rake` from the `ruby` Homebrew is using rather than whatever is in the `PATH`.
  def rake(*args)
    system RUBY_BIN/"rake", *args
  end

  # Run `make` 3.81 or newer.
  # Uses the system make on Leopard and newer, and the
  # path to the actually-installed make on Tiger or older.
  def make(*args)
    if Utils.popen_read("/usr/bin/make", "--version").match(/Make (\d\.\d+)/)[1] > "3.80"
      system "/usr/bin/make", *args
    else
      make = Formula["make"].opt_bin/"make"
      make_path = make.exist? ? make.to_s : (Formula["make"].opt_bin/"gmake").to_s
      system make_path, *args
    end
  end

  if method_defined?(:ruby)
    # @private
    alias old_ruby ruby
  end

  # Run the `ruby` Homebrew is using rather than whatever is in the `PATH`.
  def ruby(*args)
    system RUBY_PATH, *args
  end

  # Run `xcodebuild` without Homebrew's compiler environment variables set.
  def xcodebuild(*args)
    removed = ENV.remove_cc_etc
    system "xcodebuild", *args
  ensure
    ENV.update(removed)
  end
end

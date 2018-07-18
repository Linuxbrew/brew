# Performs `Formula#mktemp`'s functionality, and tracks the results.
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

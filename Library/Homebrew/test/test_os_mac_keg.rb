require "testing_env"
require "keg"
require "stringio"

class OSMacLinkTests < Homebrew::TestCase
  include FileUtils

  def setup
    keg = HOMEBREW_CELLAR.join("foo", "1.0")
    keg.join("bin").mkpath

    %w[hiworld helloworld goodbye_cruel_world].each do |file|
      touch keg.join("bin", file)
    end

    @keg = Keg.new(keg)
    @dst = HOMEBREW_PREFIX.join("bin", "helloworld")
    @nonexistent = Pathname.new("/some/nonexistent/path")

    @mode = OpenStruct.new

    @old_stdout = $stdout
    $stdout = StringIO.new

    mkpath HOMEBREW_PREFIX/"bin"
    mkpath HOMEBREW_PREFIX/"lib"
  end

  def teardown
    @keg.unlink
    @keg.uninstall

    $stdout = @old_stdout

    rmtree HOMEBREW_PREFIX/"bin"
    rmtree HOMEBREW_PREFIX/"lib"
  end

  def test_mach_o_files_skips_hardlinks
    a = HOMEBREW_CELLAR/"a/1.0"
    (a/"lib").mkpath
    FileUtils.cp dylib_path("i386"), a/"lib/i386.dylib"
    FileUtils.ln a/"lib/i386.dylib", a/"lib/i386_link.dylib"

    keg = Keg.new(a)
    keg.link

    assert_equal 1, keg.mach_o_files.size
  ensure
    keg.unlink
    keg.uninstall
  end

  def test_mach_o_files_isnt_confused_by_symlinks
    a = HOMEBREW_CELLAR/"a/1.0"
    (a/"lib").mkpath
    FileUtils.cp dylib_path("i386"), a/"lib/i386.dylib"
    FileUtils.ln a/"lib/i386.dylib", a/"lib/i386_link.dylib"
    FileUtils.ln_s a/"lib/i386.dylib", a/"lib/1.dylib"

    keg = Keg.new(a)
    keg.link

    assert_equal 1, keg.mach_o_files.size
  ensure
    keg.unlink
    keg.uninstall
  end
end

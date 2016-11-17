require "testing_env"
require "utils"

class TtyTests < Homebrew::TestCase
  def test_strip_ansi
    assert_equal "hello", Tty.strip_ansi("\033\[36;7mhello\033\[0m")
  end

  def test_width
    assert_kind_of Integer, Tty.width
  end

  def test_truncate
    Tty.stubs(:width).returns 15
    assert_equal "foobar some", Tty.truncate("foobar something very long")
    assert_equal "truncate", Tty.truncate("truncate")

    # When the terminal is unsupported, we report 0 width
    Tty.stubs(:width).returns 0
    assert_equal "foobar something very long", Tty.truncate("foobar something very long")
  end

  def test_no_tty_formatting
    $stdout.stubs(:tty?).returns false
    assert_equal "", Tty.to_s
    assert_equal "", Tty.red.to_s
    assert_equal "", Tty.green.to_s
    assert_equal "", Tty.yellow.to_s
    assert_equal "", Tty.blue.to_s
    assert_equal "", Tty.magenta.to_s
    assert_equal "", Tty.cyan.to_s
    assert_equal "", Tty.default.to_s
  end

  def test_formatting
    $stdout.stubs(:tty?).returns(true)
    assert_equal "",         Tty.to_s
    assert_equal "\033[31m", Tty.red.to_s
    assert_equal "\033[32m", Tty.green.to_s
    assert_equal "\033[33m", Tty.yellow.to_s
    assert_equal "\033[34m", Tty.blue.to_s
    assert_equal "\033[35m", Tty.magenta.to_s
    assert_equal "\033[36m", Tty.cyan.to_s
    assert_equal "\033[39m", Tty.default.to_s
  end
end

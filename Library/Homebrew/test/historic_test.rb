require "testing_env"
require "historic"

class HistoricTest < Homebrew::TestCase
  def setup
    super

    @path = Tap::TAP_DIRECTORY/"homebrew/homebrew-foo"
    @path.mkpath
    @tap = Tap.new("Homebrew", "foo")

    (@path/"tap_migrations.json").write <<-EOS.undent
      { "migrated-formula": "homebrew/bar" }
    EOS
    (@path/"Formula/to-delete.rb").write "placeholder"

    @path.cd do
      shutup do
        system "git", "init"
        system "git", "add", "--all"
        system "git", "commit", "-m", "initial state"
        system "git", "rm", "Formula/to-delete.rb"
        system "git", "commit", "-m", "delete formula 'to-delete'"
      end
    end
  end

  def teardown
    @path.rmtree

    super
  end

  def test_search_for_migrated_formula
    migrations = Homebrew.search_for_migrated_formula("migrated-formula", print_messages: false)
    assert_equal [[@tap, "homebrew/bar"]], migrations
  end

  def test_search_for_deleted_formula
    tap, relpath, hash, = Homebrew.search_for_deleted_formula("homebrew/foo/to-delete",
                                                              print_messages: false)
    assert_equal tap, @tap
    assert_equal relpath, "Formula/to-delete.rb"
    assert_equal `git rev-parse HEAD`.chomp, hash
  end
end

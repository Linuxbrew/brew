require "testing_env"
require "tab"
require "formula"

class TabTests < Homebrew::TestCase
  def setup
    @used = Options.create(%w[--with-foo --without-bar])
    @unused = Options.create(%w[--with-baz --without-qux])

    @tab = Tab.new("used_options"         => @used.as_flags,
                   "unused_options"       => @unused.as_flags,
                   "built_as_bottle"      => false,
                   "poured_from_bottle"   => true,
                   "changed_files"        => [],
                   "time"                 => nil,
                   "source_modified_time" => 0,
                   "HEAD"                 => TEST_SHA1,
                   "compiler"             => "clang",
                   "stdlib"               => "libcxx",
                   "runtime_dependencies" => [],
                   "source"               => {
                     "tap" => "homebrew/core",
                     "path" => nil,
                     "spec" => "stable",
                     "versions" => {
                       "stable" => "0.10",
                       "devel" => "0.14",
                       "head" => "HEAD-1111111",
                     },
                   })
  end

  def test_defaults
    tab = Tab.empty
    assert_empty tab.unused_options
    assert_empty tab.used_options
    assert_nil tab.changed_files
    refute_predicate tab, :built_as_bottle
    refute_predicate tab, :poured_from_bottle
    assert_predicate tab, :stable?
    refute_predicate tab, :devel?
    refute_predicate tab, :head?
    assert_nil tab.tap
    assert_nil tab.time
    assert_nil tab.HEAD
    assert_empty tab.runtime_dependencies
    assert_nil tab.stable_version
    assert_nil tab.devel_version
    assert_nil tab.head_version
    assert_equal DevelopmentTools.default_compiler, tab.cxxstdlib.compiler
    assert_nil tab.cxxstdlib.type
    assert_nil tab.source["path"]
  end

  def test_include?
    assert_includes @tab, "with-foo"
    assert_includes @tab, "without-bar"
  end

  def test_with?
    assert @tab.with?("foo")
    assert @tab.with?("qux")
    refute @tab.with?("bar")
    refute @tab.with?("baz")
  end

  def test_universal?
    tab = Tab.new(used_options: %w[--universal])
    assert_predicate tab, :universal?
  end

  def test_cxxstdlib
    assert_equal :clang, @tab.cxxstdlib.compiler
    assert_equal :libcxx, @tab.cxxstdlib.type
  end

  def test_other_attributes
    assert_equal TEST_SHA1, @tab.HEAD
    assert_equal "homebrew/core", @tab.tap.name
    assert_nil @tab.time
    refute_predicate @tab, :built_as_bottle
    assert_predicate @tab, :poured_from_bottle
  end

  def test_from_old_version_file
    path = Pathname.new("#{TEST_FIXTURE_DIR}/receipt_old.json")
    tab = Tab.from_file(path)

    assert_equal @used.sort, tab.used_options.sort
    assert_equal @unused.sort, tab.unused_options.sort
    refute_predicate tab, :built_as_bottle
    assert_predicate tab, :poured_from_bottle
    assert_predicate tab, :stable?
    refute_predicate tab, :devel?
    refute_predicate tab, :head?
    assert_equal "homebrew/core", tab.tap.name
    assert_equal :stable, tab.spec
    refute_nil tab.time
    assert_equal TEST_SHA1, tab.HEAD
    assert_equal :clang, tab.cxxstdlib.compiler
    assert_equal :libcxx, tab.cxxstdlib.type
    assert_nil tab.runtime_dependencies
  end

  def test_from_file
    path = Pathname.new("#{TEST_FIXTURE_DIR}/receipt.json")
    tab = Tab.from_file(path)
    source_path = "/usr/local/Library/Taps/hombrew/homebrew-core/Formula/foo.rb"
    runtime_dependencies = [{ "full_name" => "foo", "version" => "1.0" }]
    changed_files = %w[INSTALL_RECEIPT.json bin/foo]

    assert_equal @used.sort, tab.used_options.sort
    assert_equal @unused.sort, tab.unused_options.sort
    assert_equal changed_files, tab.changed_files
    refute_predicate tab, :built_as_bottle
    assert_predicate tab, :poured_from_bottle
    assert_predicate tab, :stable?
    refute_predicate tab, :devel?
    refute_predicate tab, :head?
    assert_equal "homebrew/core", tab.tap.name
    assert_equal :stable, tab.spec
    refute_nil tab.time
    assert_equal TEST_SHA1, tab.HEAD
    assert_equal :clang, tab.cxxstdlib.compiler
    assert_equal :libcxx, tab.cxxstdlib.type
    assert_equal runtime_dependencies, tab.runtime_dependencies
    assert_equal "2.14", tab.stable_version.to_s
    assert_equal "2.15", tab.devel_version.to_s
    assert_equal "HEAD-0000000", tab.head_version.to_s
    assert_equal source_path, tab.source["path"]
  end

  def test_create
    f = formula do
      url "foo-1.0"
      depends_on "bar"
      depends_on "user/repo/from_tap"
      depends_on "baz" => :build
    end

    tap = Tap.new("user", "repo")
    from_tap = formula("from_tap", tap.path/"Formula/from_tap.rb") do
      url "from_tap-1.0"
    end
    stub_formula_loader from_tap

    stub_formula_loader formula("bar") { url "bar-2.0" }
    stub_formula_loader formula("baz") { url "baz-3.0" }

    compiler = DevelopmentTools.default_compiler
    stdlib = :libcxx
    tab = Tab.create(f, compiler, stdlib)

    runtime_dependencies = [
      { "full_name" => "bar", "version" => "2.0" },
      { "full_name" => "user/repo/from_tap", "version" => "1.0" },
    ]

    assert_equal runtime_dependencies, tab.runtime_dependencies
    assert_equal f.path.to_s, tab.source["path"]
  end

  def test_create_from_alias
    alias_path = CoreTap.instance.alias_dir/"bar"
    f = formula(alias_path: alias_path) { url "foo-1.0" }
    compiler = DevelopmentTools.default_compiler
    stdlib = :libcxx
    tab = Tab.create(f, compiler, stdlib)

    assert_equal f.alias_path.to_s, tab.source["path"]
  end

  def test_for_formula
    f = formula { url "foo-1.0" }
    tab = Tab.for_formula(f)

    assert_equal f.path.to_s, tab.source["path"]
  end

  def test_for_formula_from_alias
    alias_path = CoreTap.instance.alias_dir/"bar"
    f = formula(alias_path: alias_path) { url "foo-1.0" }
    tab = Tab.for_formula(f)

    assert_equal alias_path.to_s, tab.source["path"]
  end

  def test_to_json
    tab = Tab.new(Utils::JSON.load(@tab.to_json))
    assert_equal @tab.used_options.sort, tab.used_options.sort
    assert_equal @tab.unused_options.sort, tab.unused_options.sort
    assert_equal @tab.built_as_bottle, tab.built_as_bottle
    assert_equal @tab.poured_from_bottle, tab.poured_from_bottle
    assert_equal @tab.changed_files, tab.changed_files
    assert_equal @tab.tap, tab.tap
    assert_equal @tab.spec, tab.spec
    assert_equal @tab.time, tab.time
    assert_equal @tab.HEAD, tab.HEAD
    assert_equal @tab.compiler, tab.compiler
    assert_equal @tab.stdlib, tab.stdlib
    assert_equal @tab.runtime_dependencies, tab.runtime_dependencies
    assert_equal @tab.stable_version, tab.stable_version
    assert_equal @tab.devel_version, tab.devel_version
    assert_equal @tab.head_version, tab.head_version
    assert_equal @tab.source["path"], tab.source["path"]
  end

  def test_remap_deprecated_options
    deprecated_options = [DeprecatedOption.new("with-foo", "with-foo-new")]
    remapped_options = Tab.remap_deprecated_options(deprecated_options, @tab.used_options)
    assert_includes remapped_options, Option.new("without-bar")
    assert_includes remapped_options, Option.new("with-foo-new")
  end
end

class TabLoadingTests < Homebrew::TestCase
  def setup
    @f = formula { url "foo-1.0" }
    @f.prefix.mkpath
    @path = @f.prefix.join(Tab::FILENAME)
    @path.write Pathname.new(TEST_DIRECTORY).join("fixtures", "receipt.json").read
  end

  def teardown
    @f.rack.rmtree
  end

  def test_for_keg
    tab = Tab.for_keg(@f.prefix)
    assert_equal @path, tab.tabfile
  end

  def test_for_keg_nonexistent_path
    @path.unlink
    tab = Tab.for_keg(@f.prefix)
    assert_nil tab.tabfile
  end

  def test_for_formula
    tab = Tab.for_formula(@f)
    assert_equal @path, tab.tabfile
  end

  def test_for_formula_nonexistent_path
    @path.unlink
    tab = Tab.for_formula(@f)
    assert_nil tab.tabfile
  end

  def test_for_formula_multiple_kegs
    f2 = formula { url "foo-2.0" }
    f2.prefix.mkpath

    assert_equal @f.rack, f2.rack
    assert_equal 2, @f.installed_prefixes.length

    tab = Tab.for_formula(@f)
    assert_equal @path, tab.tabfile
  end

  def test_for_formula_outdated_keg
    f2 = formula { url "foo-2.0" }

    assert_equal @f.rack, f2.rack
    assert_equal 1, @f.installed_prefixes.length

    tab = Tab.for_formula(f2)
    assert_equal @path, tab.tabfile
  end
end

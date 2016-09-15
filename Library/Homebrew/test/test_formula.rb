require "testing_env"
require "testball"
require "formula"

class FormulaTests < Homebrew::TestCase
  def test_formula_instantiation
    klass = Class.new(Formula) { url "http://example.com/foo-1.0.tar.gz" }
    name = "formula_name"
    path = Formulary.core_path(name)
    spec = :stable
    alias_path = CoreTap.instance.alias_dir/"formula_alias"

    f = klass.new(name, path, spec, :alias_path => alias_path)
    assert_equal name, f.name
    assert_equal path, f.path
    assert_equal alias_path, f.alias_path
    assert_raises(ArgumentError) { klass.new }
  end

  def test_prefix
    f = Testball.new
    assert_equal HOMEBREW_CELLAR/f.name/"0.1", f.prefix
    assert_kind_of Pathname, f.prefix
  end

  def test_revised_prefix
    f = Class.new(Testball) { revision 1 }.new
    assert_equal HOMEBREW_CELLAR/f.name/"0.1_1", f.prefix
  end

  def test_any_version_installed?
    f = formula do
      url "foo"
      version "1.0"
    end
    refute_predicate f, :any_version_installed?
    prefix = HOMEBREW_CELLAR+f.name+"0.1"
    prefix.mkpath
    FileUtils.touch prefix+Tab::FILENAME
    assert_predicate f, :any_version_installed?
  ensure
    f.rack.rmtree
  end

  def test_migration_needed
    f = Testball.new("newname")
    f.instance_variable_set(:@oldname, "oldname")
    f.instance_variable_set(:@tap, CoreTap.instance)

    oldname_prefix = HOMEBREW_CELLAR/"oldname/2.20"
    newname_prefix = HOMEBREW_CELLAR/"newname/2.10"
    oldname_prefix.mkpath
    oldname_tab = Tab.empty
    oldname_tab.tabfile = oldname_prefix.join("INSTALL_RECEIPT.json")
    oldname_tab.write

    refute_predicate f, :migration_needed?

    oldname_tab.tabfile.unlink
    oldname_tab.source["tap"] = "homebrew/core"
    oldname_tab.write

    assert_predicate f, :migration_needed?

    newname_prefix.mkpath

    refute_predicate f, :migration_needed?
  ensure
    oldname_prefix.parent.rmtree
    newname_prefix.parent.rmtree
  end

  def test_installed?
    f = Testball.new
    f.stubs(:installed_prefix).returns(stub(:directory? => false))
    refute_predicate f, :installed?

    f.stubs(:installed_prefix).returns(
      stub(:directory? => true, :children => [])
    )
    refute_predicate f, :installed?

    f.stubs(:installed_prefix).returns(
      stub(:directory? => true, :children => [stub])
    )
    assert_predicate f, :installed?
  end

  def test_installed_prefix
    f = Testball.new
    assert_equal f.prefix, f.installed_prefix
  end

  def test_installed_prefix_head_installed
    f = formula do
      head "foo"
      devel do
        url "foo"
        version "1.0"
      end
    end
    prefix = HOMEBREW_CELLAR+f.name+f.head.version
    prefix.mkpath
    assert_equal prefix, f.installed_prefix
  ensure
    f.rack.rmtree
  end

  def test_installed_prefix_devel_installed
    f = formula do
      head "foo"
      devel do
        url "foo"
        version "1.0"
      end
    end
    prefix = HOMEBREW_CELLAR+f.name+f.devel.version
    prefix.mkpath
    assert_equal prefix, f.installed_prefix
  ensure
    f.rack.rmtree
  end

  def test_installed_prefix_stable_installed
    f = formula do
      head "foo"
      devel do
        url "foo"
        version "1.0-devel"
      end
    end
    prefix = HOMEBREW_CELLAR+f.name+f.version
    prefix.mkpath
    assert_equal prefix, f.installed_prefix
  ensure
    f.rack.rmtree
  end

  def test_installed_prefix_outdated_stable_head_installed
    f = formula do
      url "foo"
      version "1.9"
      head "foo"
    end

    head_prefix = HOMEBREW_CELLAR/"#{f.name}/HEAD"
    head_prefix.mkpath
    tab = Tab.empty
    tab.tabfile = head_prefix.join("INSTALL_RECEIPT.json")
    tab.source["versions"] = { "stable" => "1.0" }
    tab.write

    assert_equal HOMEBREW_CELLAR/"#{f.name}/#{f.version}", f.installed_prefix
  ensure
    f.rack.rmtree
  end

  def test_installed_prefix_outdated_devel_head_installed
    f = formula do
      url "foo"
      version "1.9"
      devel do
        url "foo"
        version "2.1"
      end
    end

    head_prefix = HOMEBREW_CELLAR/"#{f.name}/HEAD"
    head_prefix.mkpath
    tab = Tab.empty
    tab.tabfile = head_prefix.join("INSTALL_RECEIPT.json")
    tab.source["versions"] = { "stable" => "1.9", "devel" => "2.0" }
    tab.write

    assert_equal HOMEBREW_CELLAR/"#{f.name}/#{f.version}", f.installed_prefix
  ensure
    f.rack.rmtree
  end

  def test_installed_prefix_head
    f = formula("test", Pathname.new(__FILE__).expand_path, :head) do
      head "foo"
      devel do
        url "foo"
        version "1.0-devel"
      end
    end
    prefix = HOMEBREW_CELLAR+f.name+f.head.version
    assert_equal prefix, f.installed_prefix
  end

  def test_installed_prefix_devel
    f = formula("test", Pathname.new(__FILE__).expand_path, :devel) do
      head "foo"
      devel do
        url "foo"
        version "1.0-devel"
      end
    end
    prefix = HOMEBREW_CELLAR+f.name+f.devel.version
    assert_equal prefix, f.installed_prefix
  end

  def test_latest_head_prefix
    f = Testball.new

    stamps_with_revisions = [[111111, 1], [222222, 1], [222222, 2], [222222, 0]]

    stamps_with_revisions.each do |stamp, revision|
      version = "HEAD-#{stamp}"
      version += "_#{revision}" if revision > 0
      prefix = f.rack.join(version)
      prefix.mkpath

      tab = Tab.empty
      tab.tabfile = prefix.join("INSTALL_RECEIPT.json")
      tab.source_modified_time = stamp
      tab.write
    end

    prefix = HOMEBREW_CELLAR/"#{f.name}/HEAD-222222_2"
    assert_equal prefix, f.latest_head_prefix
  ensure
    f.rack.rmtree
  end

  def test_equality
    x = Testball.new
    y = Testball.new
    assert_equal x, y
    assert_eql x, y
    assert_equal x.hash, y.hash
  end

  def test_inequality
    x = Testball.new("foo")
    y = Testball.new("bar")
    refute_equal x, y
    refute_eql x, y
    refute_equal x.hash, y.hash
  end

  def test_comparison_with_non_formula_objects_does_not_raise
    refute_equal Testball.new, Object.new
  end

  def test_sort_operator
    assert_nil Testball.new <=> Object.new
  end

  def test_formula_spec_integration
    f = formula do
      homepage "http://example.com"
      url "http://example.com/test-0.1.tbz"
      mirror "http://example.org/test-0.1.tbz"
      sha256 TEST_SHA256

      head "http://example.com/test.git", :tag => "foo"

      devel do
        url "http://example.com/test-0.2.tbz"
        mirror "http://example.org/test-0.2.tbz"
        sha256 TEST_SHA256
      end
    end

    assert_equal "http://example.com", f.homepage
    assert_version_equal "0.1", f.version
    assert_predicate f, :stable?

    assert_version_equal "0.1", f.stable.version
    assert_version_equal "0.2", f.devel.version
    assert_version_equal "HEAD", f.head.version
  end

  def test_formula_set_active_spec
    f = formula do
      url "foo"
      version "1.0"
      revision 1

      devel do
        url "foo"
        version "1.0beta"
      end
    end
    assert_equal :stable, f.active_spec_sym
    assert_equal f.stable, f.send(:active_spec)
    assert_equal "1.0_1", f.pkg_version.to_s
    f.set_active_spec(:devel)
    assert_equal :devel, f.active_spec_sym
    assert_equal f.devel, f.send(:active_spec)
    assert_equal "1.0beta_1", f.pkg_version.to_s
    assert_raises(FormulaSpecificationError) { f.set_active_spec(:head) }
  end

  def test_path
    name = "foo-bar"
    assert_equal Pathname.new("#{HOMEBREW_LIBRARY}/Taps/homebrew/homebrew-core/Formula/#{name}.rb"), Formulary.core_path(name)
  end

  def test_class_specs_are_always_initialized
    f = formula { url "foo-1.0" }

    %w[stable devel head].each do |spec|
      assert_kind_of SoftwareSpec, f.class.send(spec)
    end
  end

  def test_incomplete_instance_specs_are_not_accessible
    f = formula { url "foo-1.0" }

    %w[devel head].each { |spec| assert_nil f.send(spec) }
  end

  def test_honors_attributes_declared_before_specs
    f = formula do
      url "foo-1.0"
      depends_on "foo"
      devel { url "foo-1.1" }
    end

    %w[stable devel head].each do |spec|
      assert_equal "foo", f.class.send(spec).deps.first.name
    end
  end

  def test_simple_version
    assert_equal PkgVersion.parse("1.0"), formula { url "foo-1.0.bar" }.pkg_version
  end

  def test_version_with_revision
    f = formula do
      url "foo-1.0.bar"
      revision 1
    end

    assert_equal PkgVersion.parse("1.0_1"), f.pkg_version
  end

  def test_head_uses_revisions
    f = formula("test", Pathname.new(__FILE__).expand_path, :head) do
      url "foo-1.0.bar"
      revision 1
      head "foo"
    end

    assert_equal PkgVersion.parse("HEAD_1"), f.pkg_version
  end

  def test_update_head_version
    initial_env = ENV.to_hash

    f = formula do
      head "foo", :using => :git
    end

    cached_location = f.head.downloader.cached_location
    cached_location.mkpath

    %w[AUTHOR COMMITTER].each do |role|
      ENV["GIT_#{role}_NAME"] = "brew tests"
      ENV["GIT_#{role}_EMAIL"] = "brew-tests@localhost"
      ENV["GIT_#{role}_DATE"] = "Thu May 21 00:04:11 2009 +0100"
    end

    cached_location.cd do
      FileUtils.touch "LICENSE"
      shutup do
        system "git", "init"
        system "git", "add", "--all"
        system "git", "commit", "-m", "Initial commit"
      end
    end

    f.update_head_version
    assert_equal Version.create("HEAD-5658946"), f.head.version
  ensure
    ENV.replace(initial_env)
    cached_location.rmtree
  end

  def test_legacy_options
    f = formula do
      url "foo-1.0"

      def options
        [["--foo", "desc"], ["--bar", "desc"]]
      end

      option "baz"
    end

    assert f.option_defined?("foo")
    assert f.option_defined?("bar")
    assert f.option_defined?("baz")
  end

  def test_desc
    f = formula do
      desc "a formula"
      url "foo-1.0"
    end

    assert_equal "a formula", f.desc
  end

  def test_post_install_defined
    f1 = formula do
      url "foo-1.0"

      def post_install; end
    end

    f2 = formula do
      url "foo-1.0"
    end

    assert f1.post_install_defined?
    refute f2.post_install_defined?
  end

  def test_test_defined
    f1 = formula do
      url "foo-1.0"

      def test; end
    end

    f2 = formula do
      url "foo-1.0"
    end

    assert f1.test_defined?
    refute f2.test_defined?
  end

  def test_test_fixtures
    f1 = formula do
      url "foo-1.0"
    end

    assert_equal Pathname.new("#{HOMEBREW_LIBRARY}/Homebrew/test/fixtures/foo"),
      f1.test_fixtures("foo")
  end

  def test_to_hash
    f1 = formula("foo") do
      url "foo-1.0"
    end

    h = f1.to_hash
    assert h.is_a?(Hash), "Formula#to_hash should return a Hash"
    assert_equal "foo", h["name"]
    assert_equal "foo", h["full_name"]
    assert_equal "1.0", h["versions"]["stable"]
  end

  def test_to_hash_bottle
    f1 = formula("foo") do
      url "foo-1.0"

      bottle do
        cellar :any
        sha256 TEST_SHA256 => Utils::Bottles.tag
      end
    end

    h = f1.to_hash
    assert h.is_a?(Hash), "Formula#to_hash should return a Hash"
    assert h["versions"]["bottle"], "The hash should say the formula is bottled"
  end

  def test_eligible_kegs_for_cleanup
    f1 = Class.new(Testball) { version "0.1" }.new
    f2 = Class.new(Testball) { version "0.2" }.new
    f3 = Class.new(Testball) { version "0.3" }.new

    shutup do
      f1.brew { f1.install }
      f2.brew { f2.install }
      f3.brew { f3.install }
    end

    assert_predicate f1, :installed?
    assert_predicate f2, :installed?
    assert_predicate f3, :installed?

    assert_equal f3.installed_kegs.sort_by(&:version)[0..1],
                 f3.eligible_kegs_for_cleanup.sort_by(&:version)
  ensure
    [f1, f2, f3].each(&:clear_cache)
    f3.rack.rmtree
  end

  def test_eligible_kegs_for_cleanup_keg_pinned
    f1 = Class.new(Testball) { version "0.1" }.new
    f2 = Class.new(Testball) { version "0.2" }.new
    f3 = Class.new(Testball) { version "0.3" }.new

    shutup do
      f1.brew { f1.install }
      f1.pin
      f2.brew { f2.install }
      f3.brew { f3.install }
    end

    assert_equal (HOMEBREW_PINNED_KEGS/f1.name).resolved_path, f1.prefix

    assert_predicate f1, :installed?
    assert_predicate f2, :installed?
    assert_predicate f3, :installed?

    assert_equal [Keg.new(f2.prefix)], shutup { f3.eligible_kegs_for_cleanup }
  ensure
    f1.unpin
    [f1, f2, f3].each(&:clear_cache)
    f3.rack.rmtree
  end

  def test_eligible_kegs_for_cleanup_head_installed
    f = formula do
      version "0.1"
      head "foo"
    end

    stable_prefix = f.installed_prefix
    stable_prefix.mkpath

    [["000000_1", 1], ["111111", 2], ["111111_1", 2]].each do |pkg_version_suffix, stamp|
      prefix = f.prefix("HEAD-#{pkg_version_suffix}")
      prefix.mkpath
      tab = Tab.empty
      tab.tabfile = prefix.join("INSTALL_RECEIPT.json")
      tab.source_modified_time = stamp
      tab.write
    end

    eligible_kegs = f.installed_kegs - [Keg.new(f.prefix("HEAD-111111_1"))]
    assert_equal eligible_kegs, f.eligible_kegs_for_cleanup
  ensure
    f.rack.rmtree
  end

  def test_pour_bottle
    f_false = formula("foo") do
      url "foo-1.0"
      def pour_bottle?
        false
      end
    end
    refute f_false.pour_bottle?

    f_true = formula("foo") do
      url "foo-1.0"
      def pour_bottle?
        true
      end
    end
    assert f_true.pour_bottle?
  end

  def test_pour_bottle_dsl
    f_false = formula("foo") do
      url "foo-1.0"
      pour_bottle? do
        reason "false reason"
        satisfy { var == etc }
      end
    end
    refute f_false.pour_bottle?

    f_true = formula("foo") do
      url "foo-1.0"
      pour_bottle? do
        reason "true reason"
        satisfy { true }
      end
    end
    assert f_true.pour_bottle?
  end
end

class OutdatedVersionsTests < Homebrew::TestCase
  attr_reader :outdated_prefix, :same_prefix, :greater_prefix, :head_prefix
  attr_reader :f

  def setup
    @f = formula do
      url "foo"
      version "1.20"
    end
    @outdated_prefix = HOMEBREW_CELLAR/"#{f.name}/1.11"
    @same_prefix = HOMEBREW_CELLAR/"#{f.name}/1.20"
    @greater_prefix = HOMEBREW_CELLAR/"#{f.name}/1.21"
    @head_prefix = HOMEBREW_CELLAR/"#{f.name}/HEAD"
  end

  def teardown
    @f.rack.rmtree if @f.rack.exist?
  end

  def setup_tab_for_prefix(prefix, options = {})
    prefix.mkpath
    tab = Tab.empty
    tab.tabfile = prefix.join("INSTALL_RECEIPT.json")
    tab.source["tap"] = options[:tap] if options[:tap]
    tab.source["versions"] = options[:versions] if options[:versions]
    tab.source_modified_time = options[:source_modified_time].to_i
    tab.write unless options[:no_write]
    tab
  end

  def reset_outdated_versions
    f.instance_variable_set(:@outdated_versions, nil)
  end

  def test_greater_different_tap_installed
    setup_tab_for_prefix(greater_prefix, :tap => "user/repo")
    assert_predicate f.outdated_versions, :empty?
  end

  def test_greater_same_tap_installed
    f.instance_variable_set(:@tap, CoreTap.instance)
    setup_tab_for_prefix(greater_prefix, :tap => "homebrew/core")
    assert_predicate f.outdated_versions, :empty?
  end

  def test_outdated_different_tap_installed
    setup_tab_for_prefix(outdated_prefix, :tap => "user/repo")
    refute_predicate f.outdated_versions, :empty?
  end

  def test_outdated_same_tap_installed
    f.instance_variable_set(:@tap, CoreTap.instance)
    setup_tab_for_prefix(outdated_prefix, :tap => "homebrew/core")
    refute_predicate f.outdated_versions, :empty?
  end

  def test_same_head_installed
    f.instance_variable_set(:@tap, CoreTap.instance)
    setup_tab_for_prefix(head_prefix, :tap => "homebrew/core")
    assert_predicate f.outdated_versions, :empty?
  end

  def test_different_head_installed
    f.instance_variable_set(:@tap, CoreTap.instance)
    setup_tab_for_prefix(head_prefix, :tap => "user/repo")
    assert_predicate f.outdated_versions, :empty?
  end

  def test_mixed_taps_greater_version_installed
    f.instance_variable_set(:@tap, CoreTap.instance)
    setup_tab_for_prefix(outdated_prefix, :tap => "homebrew/core")
    setup_tab_for_prefix(greater_prefix, :tap => "user/repo")

    assert_predicate f.outdated_versions, :empty?

    setup_tab_for_prefix(greater_prefix, :tap => "homebrew/core")
    reset_outdated_versions

    assert_predicate f.outdated_versions, :empty?
  end

  def test_mixed_taps_outdated_version_installed
    f.instance_variable_set(:@tap, CoreTap.instance)

    extra_outdated_prefix = HOMEBREW_CELLAR/"#{f.name}/1.0"

    setup_tab_for_prefix(outdated_prefix)
    setup_tab_for_prefix(extra_outdated_prefix, :tap => "homebrew/core")
    reset_outdated_versions

    refute_predicate f.outdated_versions, :empty?

    setup_tab_for_prefix(outdated_prefix, :tap => "user/repo")
    reset_outdated_versions

    refute_predicate f.outdated_versions, :empty?
  end

  def test_same_version_tap_installed
    f.instance_variable_set(:@tap, CoreTap.instance)
    setup_tab_for_prefix(same_prefix, :tap => "homebrew/core")

    assert_predicate f.outdated_versions, :empty?

    setup_tab_for_prefix(same_prefix, :tap => "user/repo")
    reset_outdated_versions

    assert_predicate f.outdated_versions, :empty?
  end

  def test_outdated_installed_head_less_than_stable
    tab = setup_tab_for_prefix(head_prefix, :versions => { "stable" => "1.0" })
    refute_predicate f.outdated_versions, :empty?

    # Tab.for_keg(head_prefix) will be fetched from CACHE but we write it anyway
    tab.source["versions"] = { "stable" => f.version.to_s }
    tab.write
    reset_outdated_versions

    assert_predicate f.outdated_versions, :empty?
  end

  def test_outdated_fetch_head
    outdated_stable_prefix = HOMEBREW_CELLAR.join("testball/1.0")
    head_prefix_a = HOMEBREW_CELLAR.join("testball/HEAD")
    head_prefix_b = HOMEBREW_CELLAR.join("testball/HEAD-aaaaaaa_1")
    head_prefix_c = HOMEBREW_CELLAR.join("testball/HEAD-5658946")

    setup_tab_for_prefix(outdated_stable_prefix)
    tab_a = setup_tab_for_prefix(head_prefix_a, :versions => { "stable" => "1.0" })
    setup_tab_for_prefix(head_prefix_b)

    initial_env = ENV.to_hash
    testball_repo = HOMEBREW_PREFIX.join("testball_repo")
    testball_repo.mkdir

    @f = formula("testball") do
      url "foo"
      version "2.10"
      head "file://#{testball_repo}", :using => :git
    end

    %w[AUTHOR COMMITTER].each do |role|
      ENV["GIT_#{role}_NAME"] = "brew tests"
      ENV["GIT_#{role}_EMAIL"] = "brew-tests@localhost"
      ENV["GIT_#{role}_DATE"] = "Thu May 21 00:04:11 2009 +0100"
    end

    testball_repo.cd do
      FileUtils.touch "LICENSE"
      shutup do
        system "git", "init"
        system "git", "add", "--all"
        system "git", "commit", "-m", "Initial commit"
      end
    end

    refute_predicate f.outdated_versions(:fetch_head => true), :empty?

    tab_a.source["versions"] = { "stable" => f.version.to_s }
    tab_a.write
    reset_outdated_versions
    refute_predicate f.outdated_versions(:fetch_head => true), :empty?

    head_prefix_a.rmtree
    reset_outdated_versions
    refute_predicate f.outdated_versions(:fetch_head => true), :empty?

    setup_tab_for_prefix(head_prefix_c, :source_modified_time => 1)
    reset_outdated_versions
    assert_predicate f.outdated_versions(:fetch_head => true), :empty?
  ensure
    ENV.replace(initial_env)
    testball_repo.rmtree if testball_repo.exist?
    outdated_stable_prefix.rmtree if outdated_stable_prefix.exist?
    head_prefix_b.rmtree if head_prefix.exist?
    head_prefix_c.rmtree if head_prefix_c.exist?
    FileUtils.rm_rf HOMEBREW_CACHE/"testball--git"
    FileUtils.rm_rf HOMEBREW_CELLAR/"testball"
  end

  def test_outdated_versions_version_scheme_changed
    @f = formula("testball") do
      url "foo"
      version "20141010"
      version_scheme 1
    end

    prefix = HOMEBREW_CELLAR.join("testball/0.1")
    setup_tab_for_prefix(prefix, :versions => { "stable" => "0.1" })

    refute_predicate f.outdated_versions, :empty?
  ensure
    prefix.rmtree
  end

  def test_outdated_versions_mixed_version_schemes
    @f = formula("testball") do
      url "foo"
      version "20141010"
      version_scheme 3
    end

    prefix_a = HOMEBREW_CELLAR.join("testball/20141009")
    setup_tab_for_prefix(prefix_a, :versions => { "stable" => "20141009", "version_scheme" => 1 })

    prefix_b = HOMEBREW_CELLAR.join("testball/2.14")
    setup_tab_for_prefix(prefix_b, :versions => { "stable" => "2.14", "version_scheme" => 2 })

    refute_predicate f.outdated_versions, :empty?
    reset_outdated_versions

    prefix_c = HOMEBREW_CELLAR.join("testball/20141009")
    setup_tab_for_prefix(prefix_c, :versions => { "stable" => "20141009", "version_scheme" => 3 })

    refute_predicate f.outdated_versions, :empty?
    reset_outdated_versions

    prefix_d = HOMEBREW_CELLAR.join("testball/20141011")
    setup_tab_for_prefix(prefix_d, :versions => { "stable" => "20141009", "version_scheme" => 3 })
    assert_predicate f.outdated_versions, :empty?
  ensure
    f.rack.rmtree
  end

  def test_outdated_versions_head_with_version_scheme
    @f = formula("testball") do
      url "foo"
      version "1.0"
      version_scheme 2
    end

    head_prefix = HOMEBREW_CELLAR.join("testball/HEAD")

    setup_tab_for_prefix(head_prefix, :versions => { "stable" => "1.0", "version_scheme" => 1 })
    refute_predicate f.outdated_versions, :empty?

    reset_outdated_versions
    head_prefix.rmtree

    setup_tab_for_prefix(head_prefix, :versions => { "stable" => "1.0", "version_scheme" => 2 })
    assert_predicate f.outdated_versions, :empty?
  ensure
    head_prefix.rmtree
  end
end

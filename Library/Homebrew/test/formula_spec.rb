require "test/support/fixtures/testball"
require "formula"

describe Formula do
  alias_matcher :follow_installed_alias, :be_follow_installed_alias
  alias_matcher :have_any_version_installed, :be_any_version_installed
  alias_matcher :need_migration, :be_migration_needed

  alias_matcher :have_changed_installed_alias_target, :be_installed_alias_target_changed
  alias_matcher :supersede_an_installed_formula, :be_supersedes_an_installed_formula
  alias_matcher :have_changed_alias, :be_alias_changed

  alias_matcher :have_option_defined, :be_option_defined
  alias_matcher :have_test_defined, :be_test_defined
  alias_matcher :pour_bottle, :be_pour_bottle

  describe "::new" do
    let(:klass) do
      Class.new(described_class) do
        url "http://example.com/foo-1.0.tar.gz"
      end
    end

    let(:name) { "formula_name" }
    let(:path) { Formulary.core_path(name) }
    let(:spec) { :stable }
    let(:alias_name) { "baz@1" }
    let(:alias_path) { CoreTap.instance.alias_dir/alias_name }
    let(:f) { klass.new(name, path, spec) }
    let(:f_alias) { klass.new(name, path, spec, alias_path: alias_path) }

    specify "formula instantiation" do
      expect(f.name).to eq(name)
      expect(f.specified_name).to eq(name)
      expect(f.full_name).to eq(name)
      expect(f.full_specified_name).to eq(name)
      expect(f.path).to eq(path)
      expect(f.alias_path).to be nil
      expect(f.alias_name).to be nil
      expect(f.full_alias_name).to be nil
      expect { klass.new }.to raise_error(ArgumentError)
    end

    specify "formula instantiation with alias" do
      expect(f_alias.name).to eq(name)
      expect(f_alias.full_name).to eq(name)
      expect(f_alias.path).to eq(path)
      expect(f_alias.alias_path).to eq(alias_path)
      expect(f_alias.alias_name).to eq(alias_name)
      expect(f_alias.specified_name).to eq(alias_name)
      expect(f_alias.full_alias_name).to eq(alias_name)
      expect(f_alias.full_specified_name).to eq(alias_name)
      expect { klass.new }.to raise_error(ArgumentError)
    end

    context "in a Tap" do
      let(:tap) { Tap.new("foo", "bar") }
      let(:path) { (tap.path/"Formula/#{name}.rb") }
      let(:full_name) { "#{tap.user}/#{tap.repo}/#{name}" }
      let(:full_alias_name) { "#{tap.user}/#{tap.repo}/#{alias_name}" }

      specify "formula instantiation" do
        expect(f.name).to eq(name)
        expect(f.specified_name).to eq(name)
        expect(f.full_name).to eq(full_name)
        expect(f.full_specified_name).to eq(full_name)
        expect(f.path).to eq(path)
        expect(f.alias_path).to be nil
        expect(f.alias_name).to be nil
        expect(f.full_alias_name).to be nil
        expect { klass.new }.to raise_error(ArgumentError)
      end

      specify "formula instantiation with alias" do
        expect(f_alias.name).to eq(name)
        expect(f_alias.full_name).to eq(full_name)
        expect(f_alias.path).to eq(path)
        expect(f_alias.alias_path).to eq(alias_path)
        expect(f_alias.alias_name).to eq(alias_name)
        expect(f_alias.specified_name).to eq(alias_name)
        expect(f_alias.full_alias_name).to eq(full_alias_name)
        expect(f_alias.full_specified_name).to eq(full_alias_name)
        expect { klass.new }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#follow_installed_alias?" do
    let(:f) do
      formula do
        url "foo-1.0"
      end
    end

    it "returns true by default" do
      expect(f).to follow_installed_alias
    end

    it "can be set to true" do
      f.follow_installed_alias = true
      expect(f).to follow_installed_alias
    end

    it "can be set to false" do
      f.follow_installed_alias = false
      expect(f).not_to follow_installed_alias
    end
  end

  example "installed alias with core" do
    f = formula do
      url "foo-1.0"
    end

    build_values_with_no_installed_alias = [
      nil,
      BuildOptions.new({}, {}),
      Tab.new(source: { "path" => f.path.to_s }),
    ]
    build_values_with_no_installed_alias.each do |build|
      f.build = build
      expect(f.installed_alias_path).to be nil
      expect(f.installed_alias_name).to be nil
      expect(f.full_installed_alias_name).to be nil
      expect(f.installed_specified_name).to eq(f.name)
      expect(f.full_installed_specified_name).to eq(f.name)
    end

    alias_name = "bar"
    alias_path = "#{CoreTap.instance.alias_dir}/#{alias_name}"
    CoreTap.instance.alias_dir.mkpath
    FileUtils.ln_sf f.path, alias_path

    f.build = Tab.new(source: { "path" => alias_path })

    expect(f.installed_alias_path).to eq(alias_path)
    expect(f.installed_alias_name).to eq(alias_name)
    expect(f.full_installed_alias_name).to eq(alias_name)
    expect(f.installed_specified_name).to eq(alias_name)
    expect(f.full_installed_specified_name).to eq(alias_name)
  end

  example "installed alias with tap" do
    tap = Tap.new("user", "repo")
    name = "foo"
    path = "#{tap.path}/Formula/#{name}.rb"
    f = formula name, path: path do
      url "foo-1.0"
    end

    build_values_with_no_installed_alias = [nil, BuildOptions.new({}, {}), Tab.new(source: { "path" => f.path })]
    build_values_with_no_installed_alias.each do |build|
      f.build = build
      expect(f.installed_alias_path).to be nil
      expect(f.installed_alias_name).to be nil
      expect(f.full_installed_alias_name).to be nil
      expect(f.installed_specified_name).to eq(f.name)
      expect(f.full_installed_specified_name).to eq(f.full_name)
    end

    alias_name = "bar"
    full_alias_name = "#{tap.user}/#{tap.repo}/#{alias_name}"
    alias_path = "#{tap.alias_dir}/#{alias_name}"
    tap.alias_dir.mkpath
    FileUtils.ln_sf f.path, alias_path

    f.build = Tab.new(source: { "path" => alias_path })

    expect(f.installed_alias_path).to eq(alias_path)
    expect(f.installed_alias_name).to eq(alias_name)
    expect(f.full_installed_alias_name).to eq(full_alias_name)
    expect(f.installed_specified_name).to eq(alias_name)
    expect(f.full_installed_specified_name).to eq(full_alias_name)

    FileUtils.rm_rf HOMEBREW_LIBRARY/"Taps/user"
  end

  specify "#prefix" do
    f = Testball.new
    expect(f.prefix).to eq(HOMEBREW_CELLAR/f.name/"0.1")
    expect(f.prefix).to be_kind_of(Pathname)
  end

  example "revised prefix" do
    f = Class.new(Testball) { revision(1) }.new
    expect(f.prefix).to eq(HOMEBREW_CELLAR/f.name/"0.1_1")
  end

  specify "#any_version_installed?" do
    f = formula do
      url "foo"
      version "1.0"
    end

    expect(f).not_to have_any_version_installed

    prefix = HOMEBREW_CELLAR/f.name/"0.1"
    prefix.mkpath
    FileUtils.touch prefix/Tab::FILENAME

    expect(f).to have_any_version_installed
  end

  specify "#migration_needed" do
    f = Testball.new("newname")
    f.instance_variable_set(:@oldname, "oldname")
    f.instance_variable_set(:@tap, CoreTap.instance)

    oldname_prefix = (HOMEBREW_CELLAR/"oldname/2.20")
    newname_prefix = (HOMEBREW_CELLAR/"newname/2.10")

    oldname_prefix.mkpath
    oldname_tab = Tab.empty
    oldname_tab.tabfile = oldname_prefix/Tab::FILENAME
    oldname_tab.write

    expect(f).not_to need_migration

    oldname_tab.tabfile.unlink
    oldname_tab.source["tap"] = "homebrew/core"
    oldname_tab.write

    expect(f).to need_migration

    newname_prefix.mkpath

    expect(f).not_to need_migration
  end

  describe "#installed?" do
    let(:f) { Testball.new }

    it "returns false if the #installed_prefix is not a directory" do
      allow(f).to receive(:installed_prefix).and_return(double(directory?: false))
      expect(f).not_to be_installed
    end

    it "returns false if the #installed_prefix does not have children" do
      allow(f).to receive(:installed_prefix).and_return(double(directory?: true, children: []))
      expect(f).not_to be_installed
    end

    it "returns true if the #installed_prefix has children" do
      allow(f).to receive(:installed_prefix).and_return(double(directory?: true, children: [double]))
      expect(f).to be_installed
    end
  end

  describe "#installed prefix" do
    let(:f) do
      formula do
        url "foo"
        version "1.9"

        head "foo"

        devel do
          url "foo"
          version "2.1-devel"
        end
      end
    end

    let(:stable_prefix) { HOMEBREW_CELLAR/f.name/f.version }
    let(:devel_prefix) { HOMEBREW_CELLAR/f.name/f.devel.version }
    let(:head_prefix) { HOMEBREW_CELLAR/f.name/f.head.version }

    it "is the same as #prefix by default" do
      expect(f.installed_prefix).to eq(f.prefix)
    end

    it "returns the stable prefix if it is installed" do
      stable_prefix.mkpath
      expect(f.installed_prefix).to eq(stable_prefix)
    end

    it "returns the devel prefix if it is installed" do
      devel_prefix.mkpath
      expect(f.installed_prefix).to eq(devel_prefix)
    end

    it "returns the head prefix if it is installed" do
      head_prefix.mkpath
      expect(f.installed_prefix).to eq(head_prefix)
    end

    it "returns the stable prefix if head is outdated" do
      head_prefix.mkpath

      tab = Tab.empty
      tab.tabfile = head_prefix/Tab::FILENAME
      tab.source["versions"] = { "stable" => "1.0" }
      tab.write

      expect(f.installed_prefix).to eq(stable_prefix)
    end

    it "returns the stable prefix if head and devel are outdated" do
      head_prefix.mkpath

      tab = Tab.empty
      tab.tabfile = head_prefix/Tab::FILENAME
      tab.source["versions"] = { "stable" => "1.9", "devel" => "2.0" }
      tab.write

      expect(f.installed_prefix).to eq(stable_prefix)
    end

    it "returns the devel prefix if the active specification is :devel" do
      f.active_spec = :devel
      expect(f.installed_prefix).to eq(devel_prefix)
    end

    it "returns the head prefix if the active specification is :head" do
      f.active_spec = :head
      expect(f.installed_prefix).to eq(head_prefix)
    end
  end

  describe "#latest_head_prefix" do
    let(:f) { Testball.new }

    it "returns the latest head prefix" do
      stamps_with_revisions = [
        [111111, 1],
        [222222, 0],
        [222222, 1],
        [222222, 2],
      ]

      stamps_with_revisions.each do |stamp, revision|
        version = "HEAD-#{stamp}"
        version << "_#{revision}" unless revision.zero?

        prefix = f.rack/version
        prefix.mkpath

        tab = Tab.empty
        tab.tabfile = prefix/Tab::FILENAME
        tab.source_modified_time = stamp
        tab.write
      end

      prefix = HOMEBREW_CELLAR/f.name/"HEAD-222222_2"

      expect(f.latest_head_prefix).to eq(prefix)
    end
  end

  specify "equality" do
    x = Testball.new
    y = Testball.new

    expect(x).to eq(y)
    expect(x).to eql(y)
    expect(x.hash).to eq(y.hash)
  end

  specify "inequality" do
    x = Testball.new("foo")
    y = Testball.new("bar")

    expect(x).not_to eq(y)
    expect(x).not_to eql(y)
    expect(x.hash).not_to eq(y.hash)
  end

  specify "comparison with non formula objects does not raise" do
    expect(Object.new).not_to eq(Testball.new)
  end

  specify "#<=>" do
    expect(Testball.new <=> Object.new).to be nil
  end

  describe "#installed_alias_path" do
    example "alias paths with build options" do
      alias_path = (CoreTap.instance.alias_dir/"another_name")

      f = formula alias_path: alias_path do
        url "foo-1.0"
      end
      f.build = BuildOptions.new({}, {})

      expect(f.alias_path).to eq(alias_path)
      expect(f.installed_alias_path).to be nil
    end

    example "alias paths with tab with non alias source path" do
      alias_path = (CoreTap.instance.alias_dir/"another_name")
      source_path = (CoreTap.instance.formula_dir/"another_other_name")

      f = formula alias_path: alias_path do
        url "foo-1.0"
      end
      f.build = Tab.new(source: { "path" => source_path.to_s })

      expect(f.alias_path).to eq(alias_path)
      expect(f.installed_alias_path).to be nil
    end

    example "alias paths with tab with alias source path" do
      alias_path = (CoreTap.instance.alias_dir/"another_name")
      source_path = (CoreTap.instance.alias_dir/"another_other_name")

      f = formula alias_path: alias_path do
        url "foo-1.0"
      end
      f.build = Tab.new(source: { "path" => source_path.to_s })
      CoreTap.instance.alias_dir.mkpath
      FileUtils.ln_sf f.path, source_path

      expect(f.alias_path).to eq(alias_path)
      expect(f.installed_alias_path).to eq(source_path.to_s)
    end
  end

  describe "::installed_with_alias_path" do
    specify "with alias path with nil" do
      expect(described_class.installed_with_alias_path(nil)).to be_empty
    end

    specify "with alias path with a path" do
      alias_path = "#{CoreTap.instance.alias_dir}/alias"
      different_alias_path = "#{CoreTap.instance.alias_dir}/another_alias"

      formula_with_alias = formula "foo" do
        url "foo-1.0"
      end
      formula_with_alias.build = Tab.empty
      formula_with_alias.build.source["path"] = alias_path

      formula_without_alias = formula "bar" do
        url "bar-1.0"
      end
      formula_without_alias.build = Tab.empty
      formula_without_alias.build.source["path"] = formula_without_alias.path.to_s

      formula_with_different_alias = formula "baz" do
        url "baz-1.0"
      end
      formula_with_different_alias.build = Tab.empty
      formula_with_different_alias.build.source["path"] = different_alias_path

      formulae = [
        formula_with_alias,
        formula_without_alias,
        formula_with_different_alias,
      ]

      allow(described_class).to receive(:installed).and_return(formulae)

      CoreTap.instance.alias_dir.mkpath
      FileUtils.ln_sf formula_with_alias.path, alias_path

      expect(described_class.installed_with_alias_path(alias_path))
        .to eq([formula_with_alias])
    end
  end

  specify "spec integration" do
    f = formula do
      homepage "http://example.com"

      url "http://example.com/test-0.1.tbz"
      mirror "http://example.org/test-0.1.tbz"
      sha256 TEST_SHA256

      head "http://example.com/test.git", tag: "foo"

      devel do
        url "http://example.com/test-0.2.tbz"
        mirror "http://example.org/test-0.2.tbz"
        sha256 TEST_SHA256
      end
    end

    expect(f.homepage).to eq("http://example.com")
    expect(f.version).to eq(Version.create("0.1"))
    expect(f).to be_stable
    expect(f.stable.version).to eq(Version.create("0.1"))
    expect(f.devel.version).to eq(Version.create("0.2"))
    expect(f.head.version).to eq(Version.create("HEAD"))
  end

  specify "#active_spec=" do
    f = formula do
      url "foo"
      version "1.0"
      revision 1

      devel do
        url "foo"
        version "1.0beta"
      end
    end

    expect(f.active_spec_sym).to eq(:stable)
    expect(f.send(:active_spec)).to eq(f.stable)
    expect(f.pkg_version.to_s).to eq("1.0_1")

    f.active_spec = :devel

    expect(f.active_spec_sym).to eq(:devel)
    expect(f.send(:active_spec)).to eq(f.devel)
    expect(f.pkg_version.to_s).to eq("1.0beta_1")
    expect { f.active_spec = :head }.to raise_error(FormulaSpecificationError)
  end

  specify "class specs are always initialized" do
    f = formula do
      url "foo-1.0"
    end

    expect(f.class.stable).to be_kind_of(SoftwareSpec)
    expect(f.class.devel).to be_kind_of(SoftwareSpec)
    expect(f.class.head).to be_kind_of(SoftwareSpec)
  end

  specify "incomplete instance specs are not accessible" do
    f = formula do
      url "foo-1.0"
    end

    expect(f.devel).to be nil
    expect(f.head).to be nil
  end

  it "honors attributes declared before specs" do
    f = formula do
      url "foo-1.0"

      depends_on "foo"

      devel do
        url "foo-1.1"
      end
    end

    expect(f.class.stable.deps.first.name).to eq("foo")
    expect(f.class.devel.deps.first.name).to eq("foo")
    expect(f.class.head.deps.first.name).to eq("foo")
  end

  describe "#pkg_version" do
    specify "simple version" do
      f = formula do
        url "foo-1.0.bar"
      end

      expect(f.pkg_version).to eq(PkgVersion.parse("1.0"))
    end

    specify "version with revision" do
      f = formula do
        url "foo-1.0.bar"
        revision 1
      end

      expect(f.pkg_version).to eq(PkgVersion.parse("1.0_1"))
    end

    specify "head uses revisions" do
      f = formula "test", spec: :head do
        url "foo-1.0.bar"
        revision 1

        head "foo"
      end

      expect(f.pkg_version).to eq(PkgVersion.parse("HEAD_1"))
    end
  end

  specify "#update_head_version" do
    f = formula do
      head "foo", using: :git
    end

    cached_location = f.head.downloader.cached_location
    cached_location.mkpath
    cached_location.cd do
      FileUtils.touch "LICENSE"

      system("git", "init")
      system("git", "add", "--all")
      system("git", "commit", "-m", "Initial commit")
    end

    f.update_head_version

    expect(f.head.version).to eq(Version.create("HEAD-5658946"))
  end

  specify "legacy options" do
    f = formula do
      url "foo-1.0"

      def options
        [
          ["--foo", "desc"],
          ["--bar", "desc"],
        ]
      end

      option("baz")
    end

    expect(f).to have_option_defined("foo")
    expect(f).to have_option_defined("bar")
    expect(f).to have_option_defined("baz")
  end

  specify "#desc" do
    f = formula do
      desc "a formula"

      url "foo-1.0"
    end

    expect(f.desc).to eq("a formula")
  end

  specify "#test_defined?" do
    f1 = formula do
      url "foo-1.0"

      def test
        # do nothing
      end
    end

    f2 = formula do
      url "foo-1.0"
    end

    expect(f1).to have_test_defined
    expect(f2).not_to have_test_defined
  end

  specify "test fixtures" do
    f1 = formula do
      url "foo-1.0"
    end

    expect(f1.test_fixtures("foo")).to eq(Pathname.new("#{HOMEBREW_LIBRARY_PATH}/test/support/fixtures/foo"))
  end

  specify "dependencies" do
    f1 = formula "f1" do
      url "f1-1.0"
    end

    f2 = formula "f2" do
      url "f2-1.0"
    end

    f3 = formula "f3" do
      url "f3-1.0"

      depends_on "f1" => :build
      depends_on "f2"
    end

    f4 = formula "f4" do
      url "f4-1.0"

      depends_on "f1"
    end

    stub_formula_loader(f1)
    stub_formula_loader(f2)
    stub_formula_loader(f3)
    stub_formula_loader(f4)

    f5 = formula "f5" do
      url "f5-1.0"

      depends_on "f3" => :build
      depends_on "f4"
    end

    expect(f5.deps.map(&:name)).to eq(["f3", "f4"])
    expect(f5.recursive_dependencies.map(&:name)).to eq(%w[f1 f2 f3 f4])
    expect(f5.runtime_dependencies.map(&:name)).to eq(["f1", "f4"])
  end

  specify "runtime dependencies with optional deps from tap" do
    tap_loader = double

    allow(tap_loader).to receive(:get_formula).and_raise(RuntimeError, "tried resolving tap formula")
    allow(Formulary).to receive(:loader_for).with("foo/bar/f1", from: nil).and_return(tap_loader)
    stub_formula_loader(formula("f2") { url("f2-1.0") }, "baz/qux/f2")

    f3 = formula "f3" do
      url "f3-1.0"

      depends_on "foo/bar/f1" => :optional
      depends_on "baz/qux/f2"
    end

    expect(f3.runtime_dependencies.map(&:name)).to eq(["baz/qux/f2"])

    stub_formula_loader(formula("f1") { url("f1-1.0") }, "foo/bar/f1")
    f3.build = BuildOptions.new(Options.create(["--with-f1"]), f3.options)

    expect(f3.runtime_dependencies.map(&:name)).to eq(["foo/bar/f1", "baz/qux/f2"])
  end

  specify "requirements" do
    f1 = formula "f1" do
      url "f1-1"

      depends_on :python
      depends_on x11: :recommended
      depends_on xcode: ["1.0", :optional]
    end
    stub_formula_loader(f1)

    python = PythonRequirement.new
    x11 = X11Requirement.new("x11", [:recommended])
    xcode = XcodeRequirement.new(["1.0", :optional])

    expect(Set.new(f1.recursive_requirements)).to eq(Set[python, x11])

    f1.build = BuildOptions.new(["--with-xcode", "--without-x11"], f1.options)

    expect(Set.new(f1.recursive_requirements)).to eq(Set[python, xcode])

    f1.build = f1.stable.build
    f2 = formula "f2" do
      url "f2-1"

      depends_on "f1"
    end

    expect(Set.new(f2.recursive_requirements)).to eq(Set[python, x11])
    expect(Set.new(f2.recursive_requirements {})).to eq(Set[python, x11, xcode])

    requirements = f2.recursive_requirements do |_dependent, requirement|
      Requirement.prune if requirement.is_a?(PythonRequirement)
    end

    expect(Set.new(requirements)).to eq(Set[x11, xcode])
  end

  specify "#to_hash" do
    f1 = formula "foo" do
      url "foo-1.0"

      bottle do
        cellar(:any)
        sha256(TEST_SHA256 => Utils::Bottles.tag)
      end
    end

    h = f1.to_hash

    expect(h).to be_a(Hash)
    expect(h["name"]).to eq("foo")
    expect(h["full_name"]).to eq("foo")
    expect(h["versions"]["stable"]).to eq("1.0")
    expect(h["versions"]["bottle"]).to be_truthy
  end

  describe "#eligible_kegs_for_cleanup" do
    it "returns Kegs eligible for cleanup" do
      f1 = Class.new(Testball) do
        version("1.0")
      end.new

      f2 = Class.new(Testball) do
        version("0.2")
        version_scheme(1)
      end.new

      f3 = Class.new(Testball) do
        version("0.3")
        version_scheme(1)
      end.new

      f4 = Class.new(Testball) do
        version("0.1")
        version_scheme(2)
      end.new

      [f1, f2, f3, f4].each do |f|
        f.brew { f.install }
        Tab.create(f, DevelopmentTools.default_compiler, :libcxx).write
      end

      expect(f1).to be_installed
      expect(f2).to be_installed
      expect(f3).to be_installed
      expect(f4).to be_installed
      expect(f3.eligible_kegs_for_cleanup.sort_by(&:version))
        .to eq([f2, f1].map { |f| Keg.new(f.prefix) })
    end

    specify "with pinned Keg" do
      f1 = Class.new(Testball) { version("0.1") }.new
      f2 = Class.new(Testball) { version("0.2") }.new
      f3 = Class.new(Testball) { version("0.3") }.new

      f1.brew { f1.install }
      f1.pin
      f2.brew { f2.install }
      f3.brew { f3.install }

      expect(f1.prefix).to eq((HOMEBREW_PINNED_KEGS/f1.name).resolved_path)
      expect(f1).to be_installed
      expect(f2).to be_installed
      expect(f3).to be_installed
      expect(f3.eligible_kegs_for_cleanup).to eq([Keg.new(f2.prefix)])
    end

    specify "with HEAD installed" do
      f = formula do
        version("0.1")
        head("foo")
      end

      stable_prefix = f.installed_prefix
      stable_prefix.mkpath

      [["000000_1", 1], ["111111", 2], ["111111_1", 2]].each do |pkg_version_suffix, stamp|
        prefix = f.prefix("HEAD-#{pkg_version_suffix}")
        prefix.mkpath
        tab = Tab.empty
        tab.tabfile = prefix/Tab::FILENAME
        tab.source_modified_time = stamp
        tab.write
      end

      eligible_kegs = f.installed_kegs - [Keg.new(f.prefix("HEAD-111111_1"))]
      expect(f.eligible_kegs_for_cleanup).to eq(eligible_kegs)
    end
  end

  describe "#pour_bottle?" do
    it "returns false if set to false" do
      f = formula "foo" do
        url "foo-1.0"

        def pour_bottle?
          false
        end
      end

      expect(f).not_to pour_bottle
    end

    it "returns true if set to true" do
      f = formula "foo" do
        url "foo-1.0"

        def pour_bottle?
          true
        end
      end

      expect(f).to pour_bottle
    end

    it "returns false if set to false via DSL" do
      f = formula "foo" do
        url "foo-1.0"

        pour_bottle? do
          reason "false reason"
          satisfy { (var == etc) }
        end
      end

      expect(f).not_to pour_bottle
    end

    it "returns true if set to true via DSL" do
      f = formula "foo" do
        url "foo-1.0"

        pour_bottle? do
          reason "true reason"
          satisfy { true }
        end
      end

      expect(f).to pour_bottle
    end
  end

  describe "alias changes" do
    let(:f) do
      formula "formula_name", alias_path: alias_path do
        url "foo-1.0"
      end
    end

    let(:new_formula) do
      formula "new_formula_name", alias_path: alias_path do
        url "foo-1.1"
      end
    end

    let(:tab) { Tab.empty }
    let(:alias_path) { "#{CoreTap.instance.alias_dir}/bar" }

    before(:each) do
      allow(described_class).to receive(:installed).and_return([f])

      f.build = tab
      new_formula.build = tab
    end

    specify "alias changes when not installed with alias" do
      tab.source["path"] = Formulary.core_path(f.name).to_s

      expect(f.current_installed_alias_target).to be nil
      expect(f.latest_formula).to eq(f)
      expect(f).not_to have_changed_installed_alias_target
      expect(f).not_to supersede_an_installed_formula
      expect(f).not_to have_changed_alias
      expect(f.old_installed_formulae).to be_empty
    end

    specify "alias changes when not changed" do
      tab.source["path"] = alias_path
      stub_formula_loader(f, alias_path)

      CoreTap.instance.alias_dir.mkpath
      FileUtils.ln_sf f.path, alias_path

      expect(f.current_installed_alias_target).to eq(f)
      expect(f.latest_formula).to eq(f)
      expect(f).not_to have_changed_installed_alias_target
      expect(f).not_to supersede_an_installed_formula
      expect(f).not_to have_changed_alias
      expect(f.old_installed_formulae).to be_empty
    end

    specify "alias changes when new alias target" do
      tab.source["path"] = alias_path
      stub_formula_loader(new_formula, alias_path)

      CoreTap.instance.alias_dir.mkpath
      FileUtils.ln_sf new_formula.path, alias_path

      expect(f.current_installed_alias_target).to eq(new_formula)
      expect(f.latest_formula).to eq(new_formula)
      expect(f).to have_changed_installed_alias_target
      expect(f).not_to supersede_an_installed_formula
      expect(f).to have_changed_alias
      expect(f.old_installed_formulae).to be_empty
    end

    specify "alias changes when old formulae installed" do
      tab.source["path"] = alias_path
      stub_formula_loader(new_formula, alias_path)

      CoreTap.instance.alias_dir.mkpath
      FileUtils.ln_sf new_formula.path, alias_path

      expect(new_formula.current_installed_alias_target).to eq(new_formula)
      expect(new_formula.latest_formula).to eq(new_formula)
      expect(new_formula).not_to have_changed_installed_alias_target
      expect(new_formula).to supersede_an_installed_formula
      expect(new_formula).to have_changed_alias
      expect(new_formula.old_installed_formulae).to eq([f])
    end
  end

  describe "#outdated_kegs" do
    let(:outdated_prefix) { (HOMEBREW_CELLAR/"#{f.name}/1.11") }
    let(:same_prefix) { (HOMEBREW_CELLAR/"#{f.name}/1.20") }
    let(:greater_prefix) { (HOMEBREW_CELLAR/"#{f.name}/1.21") }
    let(:head_prefix) { (HOMEBREW_CELLAR/"#{f.name}/HEAD") }
    let(:old_alias_target_prefix) { (HOMEBREW_CELLAR/"#{old_formula.name}/1.0") }

    let(:f) do
      formula do
        url "foo"
        version "1.20"
      end
    end

    let(:old_formula) do
      formula "foo@1" do
        url "foo-1.0"
      end
    end

    let(:new_formula) do
      formula "foo@2" do
        url "foo-2.0"
      end
    end

    let(:alias_path) { "#{f.tap.alias_dir}/bar" }

    def setup_tab_for_prefix(prefix, options = {})
      prefix.mkpath
      tab = Tab.empty
      tab.tabfile = prefix/Tab::FILENAME
      tab.source["path"] = options[:path].to_s if options[:path]
      tab.source["tap"] = options[:tap] if options[:tap]
      tab.source["versions"] = options[:versions] if options[:versions]
      tab.source_modified_time = options[:source_modified_time].to_i
      tab.write unless options[:no_write]
      tab
    end

    def reset_outdated_kegs
      f.instance_variable_set(:@outdated_kegs, nil)
    end

    example "greater different tap installed" do
      setup_tab_for_prefix(greater_prefix, tap: "user/repo")
      expect(f.outdated_kegs).to be_empty
    end

    example "greater same tap installed" do
      f.instance_variable_set(:@tap, CoreTap.instance)
      setup_tab_for_prefix(greater_prefix, tap: "homebrew/core")
      expect(f.outdated_kegs).to be_empty
    end

    example "outdated different tap installed" do
      setup_tab_for_prefix(outdated_prefix, tap: "user/repo")
      expect(f.outdated_kegs).not_to be_empty
    end

    example "outdated same tap installed" do
      f.instance_variable_set(:@tap, CoreTap.instance)
      setup_tab_for_prefix(outdated_prefix, tap: "homebrew/core")
      expect(f.outdated_kegs).not_to be_empty
    end

    example "outdated follow alias and alias unchanged" do
      f.follow_installed_alias = true
      f.build = setup_tab_for_prefix(same_prefix, path: alias_path)
      stub_formula_loader(f, alias_path)
      expect(f.outdated_kegs).to be_empty
    end

    example "outdated follow alias and alias changed and new target not installed" do
      f.follow_installed_alias = true
      f.build = setup_tab_for_prefix(same_prefix, path: alias_path)
      stub_formula_loader(new_formula, alias_path)

      CoreTap.instance.alias_dir.mkpath
      FileUtils.ln_sf new_formula.path, alias_path

      expect(f.outdated_kegs).not_to be_empty
    end

    example "outdated follow alias and alias changed and new target installed" do
      f.follow_installed_alias = true
      f.build = setup_tab_for_prefix(same_prefix, path: alias_path)
      stub_formula_loader(new_formula, alias_path)
      setup_tab_for_prefix(new_formula.prefix)
      expect(f.outdated_kegs).to be_empty
    end

    example "outdated no follow alias and alias unchanged" do
      f.follow_installed_alias = false
      f.build = setup_tab_for_prefix(same_prefix, path: alias_path)
      stub_formula_loader(f, alias_path)
      expect(f.outdated_kegs).to be_empty
    end

    example "outdated no follow alias and alias changed" do
      f.follow_installed_alias = false
      f.build = setup_tab_for_prefix(same_prefix, path: alias_path)

      f2 = formula "foo@2" do
        url "foo-2.0"
      end

      stub_formula_loader(f2, alias_path)
      expect(f.outdated_kegs).to be_empty
    end

    example "outdated old alias targets installed" do
      f = formula alias_path: alias_path do
        url "foo-1.0"
      end

      tab = setup_tab_for_prefix(old_alias_target_prefix, path: alias_path)
      old_formula.build = tab
      allow(described_class).to receive(:installed).and_return([old_formula])

      CoreTap.instance.alias_dir.mkpath
      FileUtils.ln_sf f.path, alias_path

      expect(f.outdated_kegs).not_to be_empty
    end

    example "outdated old alias targets not installed" do
      f = formula alias_path: alias_path do
        url "foo-1.0"
      end

      tab = setup_tab_for_prefix(old_alias_target_prefix, path: old_formula.path)
      old_formula.build = tab
      allow(described_class).to receive(:installed).and_return([old_formula])
      expect(f.outdated_kegs).to be_empty
    end

    example "outdated same head installed" do
      f.instance_variable_set(:@tap, CoreTap.instance)
      setup_tab_for_prefix(head_prefix, tap: "homebrew/core")
      expect(f.outdated_kegs).to be_empty
    end

    example "outdated different head installed" do
      f.instance_variable_set(:@tap, CoreTap.instance)
      setup_tab_for_prefix(head_prefix, tap: "user/repo")
      expect(f.outdated_kegs).to be_empty
    end

    example "outdated mixed taps greater version installed" do
      f.instance_variable_set(:@tap, CoreTap.instance)
      setup_tab_for_prefix(outdated_prefix, tap: "homebrew/core")
      setup_tab_for_prefix(greater_prefix, tap: "user/repo")

      expect(f.outdated_kegs).to be_empty

      setup_tab_for_prefix(greater_prefix, tap: "homebrew/core")
      reset_outdated_kegs

      expect(f.outdated_kegs).to be_empty
    end

    example "outdated mixed taps outdated version installed" do
      f.instance_variable_set(:@tap, CoreTap.instance)

      extra_outdated_prefix = HOMEBREW_CELLAR/f.name/"1.0"

      setup_tab_for_prefix(outdated_prefix)
      setup_tab_for_prefix(extra_outdated_prefix, tap: "homebrew/core")
      reset_outdated_kegs

      expect(f.outdated_kegs).not_to be_empty

      setup_tab_for_prefix(outdated_prefix, tap: "user/repo")
      reset_outdated_kegs

      expect(f.outdated_kegs).not_to be_empty
    end

    example "outdated same version tap installed" do
      f.instance_variable_set(:@tap, CoreTap.instance)
      setup_tab_for_prefix(same_prefix, tap: "homebrew/core")

      expect(f.outdated_kegs).to be_empty

      setup_tab_for_prefix(same_prefix, tap: "user/repo")
      reset_outdated_kegs

      expect(f.outdated_kegs).to be_empty
    end

    example "outdated installed head less than stable" do
      tab = setup_tab_for_prefix(head_prefix, versions: { "stable" => "1.0" })

      expect(f.outdated_kegs).not_to be_empty

      tab.source["versions"] = { "stable" => f.version.to_s }
      tab.write
      reset_outdated_kegs

      expect(f.outdated_kegs).to be_empty
    end

    describe ":fetch_head" do
      let(:f) do
        repo = testball_repo
        formula "testball" do
          url "foo"
          version "2.10"
          head "file://#{repo}", using: :git
        end
      end
      let(:testball_repo) { HOMEBREW_PREFIX/"testball_repo" }

      example do
        begin
          outdated_stable_prefix = HOMEBREW_CELLAR/"testball/1.0"
          head_prefix_a = HOMEBREW_CELLAR/"testball/HEAD"
          head_prefix_b = HOMEBREW_CELLAR/"testball/HEAD-aaaaaaa_1"
          head_prefix_c = HOMEBREW_CELLAR/"testball/HEAD-18a7103"

          setup_tab_for_prefix(outdated_stable_prefix)
          tab_a = setup_tab_for_prefix(head_prefix_a, versions: { "stable" => "1.0" })
          setup_tab_for_prefix(head_prefix_b)

          testball_repo.mkdir
          testball_repo.cd do
            FileUtils.touch "LICENSE"

            system("git", "init")
            system("git", "add", "--all")
            system("git", "commit", "-m", "Initial commit")
          end

          expect(f.outdated_kegs(fetch_head: true)).not_to be_empty

          tab_a.source["versions"] = { "stable" => f.version.to_s }
          tab_a.write
          reset_outdated_kegs
          expect(f.outdated_kegs(fetch_head: true)).not_to be_empty

          head_prefix_a.rmtree
          reset_outdated_kegs
          expect(f.outdated_kegs(fetch_head: true)).not_to be_empty

          setup_tab_for_prefix(head_prefix_c, source_modified_time: 1)
          reset_outdated_kegs
          expect(f.outdated_kegs(fetch_head: true)).to be_empty
        ensure
          testball_repo.rmtree if testball_repo.exist?
        end
      end
    end

    describe "with changed version scheme" do
      let(:f) do
        formula "testball" do
          url "foo"
          version "20141010"
          version_scheme 1
        end
      end

      example do
        prefix = HOMEBREW_CELLAR/"testball/0.1"
        setup_tab_for_prefix(prefix, versions: { "stable" => "0.1" })

        expect(f.outdated_kegs).not_to be_empty
      end
    end

    describe "with mixed version schemes" do
      let(:f) do
        formula "testball" do
          url "foo"
          version "20141010"
          version_scheme 3
        end
      end

      example do
        prefix_a = HOMEBREW_CELLAR/"testball/20141009"
        setup_tab_for_prefix(prefix_a, versions: { "stable" => "20141009", "version_scheme" => 1 })

        prefix_b = HOMEBREW_CELLAR/"testball/2.14"
        setup_tab_for_prefix(prefix_b, versions: { "stable" => "2.14", "version_scheme" => 2 })

        expect(f.outdated_kegs).not_to be_empty
        reset_outdated_kegs

        prefix_c = HOMEBREW_CELLAR/"testball/20141009"
        setup_tab_for_prefix(prefix_c, versions: { "stable" => "20141009", "version_scheme" => 3 })

        expect(f.outdated_kegs).not_to be_empty
        reset_outdated_kegs

        prefix_d = HOMEBREW_CELLAR/"testball/20141011"
        setup_tab_for_prefix(prefix_d, versions: { "stable" => "20141009", "version_scheme" => 3 })
        expect(f.outdated_kegs).to be_empty
      end
    end

    describe "with version scheme" do
      let(:f) do
        formula "testball" do
          url "foo"
          version "1.0"
          version_scheme 2
        end
      end

      example do
        head_prefix = HOMEBREW_CELLAR/"testball/HEAD"

        setup_tab_for_prefix(head_prefix, versions: { "stable" => "1.0", "version_scheme" => 1 })
        expect(f.outdated_kegs).not_to be_empty

        reset_outdated_kegs
        head_prefix.rmtree

        setup_tab_for_prefix(head_prefix, versions: { "stable" => "1.0", "version_scheme" => 2 })
        expect(f.outdated_kegs).to be_empty
      end
    end
  end
end

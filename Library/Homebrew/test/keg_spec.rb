require "keg"
require "stringio"

describe Keg do
  include FileUtils

  def setup_test_keg(name, version)
    path = HOMEBREW_CELLAR/name/version
    (path/"bin").mkpath

    %w[hiworld helloworld goodbye_cruel_world].each do |file|
      touch path/"bin"/file
    end

    keg = described_class.new(path)
    kegs << keg
    keg
  end

  let(:dst) { HOMEBREW_PREFIX/"bin"/"helloworld" }
  let(:nonexistent) { Pathname.new("/some/nonexistent/path") }
  let(:mode) { OpenStruct.new }
  let!(:keg) { setup_test_keg("foo", "1.0") }
  let(:kegs) { [] }

  before do
    (HOMEBREW_PREFIX/"bin").mkpath
    (HOMEBREW_PREFIX/"lib").mkpath
  end

  after do
    kegs.each(&:unlink)
    rmtree HOMEBREW_PREFIX/"lib"
  end

  specify "::all" do
    Formula.clear_racks_cache
    expect(described_class.all).to eq([keg])
  end

  specify "#empty_installation?" do
    %w[.DS_Store INSTALL_RECEIPT.json LICENSE.txt].each do |file|
      touch keg/file
    end

    expect(keg).to exist
    expect(keg).to be_a_directory
    expect(keg).not_to be_an_empty_installation

    (keg/"bin").rmtree
    expect(keg).to be_an_empty_installation

    (keg/"bin").mkpath
    touch keg.join("bin", "todo")
    expect(keg).not_to be_an_empty_installation
  end

  specify "#oldname_opt_record" do
    expect(keg.oldname_opt_record).to be nil
    oldname_opt_record = HOMEBREW_PREFIX/"opt/oldfoo"
    oldname_opt_record.make_relative_symlink(HOMEBREW_CELLAR/"foo/1.0")
    expect(keg.oldname_opt_record).to eq(oldname_opt_record)
  end

  specify "#remove_oldname_opt_record" do
    oldname_opt_record = HOMEBREW_PREFIX/"opt/oldfoo"
    oldname_opt_record.make_relative_symlink(HOMEBREW_CELLAR/"foo/2.0")
    keg.remove_oldname_opt_record
    expect(oldname_opt_record).to be_a_symlink
    oldname_opt_record.unlink
    oldname_opt_record.make_relative_symlink(HOMEBREW_CELLAR/"foo/1.0")
    keg.remove_oldname_opt_record
    expect(oldname_opt_record).not_to be_a_symlink
  end

  describe "#link" do
    it "links a Keg" do
      expect(keg.link).to eq(3)
      (HOMEBREW_PREFIX/"bin").children.each do |c|
        expect(c.readlink).to be_relative
      end
    end

    context "with dry run set to true" do
      it "only prints what would be done" do
        mode.dry_run = true

        expect {
          expect(keg.link(mode)).to eq(0)
        }.to output(<<~EOF).to_stdout
          #{HOMEBREW_PREFIX}/bin/goodbye_cruel_world
          #{HOMEBREW_PREFIX}/bin/helloworld
          #{HOMEBREW_PREFIX}/bin/hiworld
        EOF

        expect(keg).not_to be_linked
      end
    end

    it "fails when already linked" do
      keg.link

      expect { keg.link }.to raise_error(Keg::AlreadyLinkedError)
    end

    it "fails when files exist" do
      touch dst

      expect { keg.link }.to raise_error(Keg::ConflictError)
    end

    it "ignores broken symlinks at target" do
      src = keg/"bin"/"helloworld"
      dst.make_symlink(nonexistent)
      keg.link
      expect(dst.readlink).to eq(src.relative_path_from(dst.dirname))
    end

    context "with overwrite set to true" do
      it "overwrite existing files" do
        touch dst
        mode.overwrite = true
        expect(keg.link(mode)).to eq(3)
        expect(keg).to be_linked
      end

      it "overwrites broken symlinks" do
        dst.make_symlink "nowhere"
        mode.overwrite = true
        expect(keg.link(mode)).to eq(3)
        expect(keg).to be_linked
      end

      it "still supports dryrun" do
        touch dst
        mode.overwrite = true
        mode.dry_run = true

        expect {
          expect(keg.link(mode)).to eq(0)
        }.to output(<<~EOF).to_stdout
          #{dst}
        EOF

        expect(keg).not_to be_linked
      end
    end

    it "also creates an opt link" do
      expect(keg).not_to be_optlinked
      keg.link
      expect(keg).to be_optlinked
    end

    specify "pkgconfig directory is created" do
      link = HOMEBREW_PREFIX/"lib"/"pkgconfig"
      (keg/"lib"/"pkgconfig").mkpath
      keg.link
      expect(link.lstat).to be_a_directory
    end

    specify "cmake directory is created" do
      link = HOMEBREW_PREFIX/"lib"/"cmake"
      (keg/"lib"/"cmake").mkpath
      keg.link
      expect(link.lstat).to be_a_directory
    end

    specify "symlinks are linked directly" do
      link = HOMEBREW_PREFIX/"lib"/"pkgconfig"

      (keg/"lib"/"example").mkpath
      (keg/"lib"/"pkgconfig").make_symlink "example"
      keg.link

      expect(link.resolved_path).to be_a_symlink
      expect(link.lstat).to be_a_symlink
    end
  end

  describe "#unlink" do
    it "unlinks a Keg" do
      keg.link
      expect(dst).to be_a_symlink
      expect(keg.unlink).to eq(3)
      expect(dst).not_to be_a_symlink
    end

    it "prunes empty top-level directories" do
      mkpath HOMEBREW_PREFIX/"lib/foo/bar"
      mkpath keg/"lib/foo/bar"
      touch keg/"lib/foo/bar/file1"

      keg.unlink

      expect(HOMEBREW_PREFIX/"lib/foo").not_to be_a_directory
    end

    it "ignores .DS_Store when pruning empty directories" do
      mkpath HOMEBREW_PREFIX/"lib/foo/bar"
      touch HOMEBREW_PREFIX/"lib/foo/.DS_Store"
      mkpath keg/"lib/foo/bar"
      touch keg/"lib/foo/bar/file1"

      keg.unlink

      expect(HOMEBREW_PREFIX/"lib/foo").not_to be_a_directory
      expect(HOMEBREW_PREFIX/"lib/foo/.DS_Store").not_to exist
    end

    it "doesn't remove opt link" do
      keg.link
      keg.unlink
      expect(keg).to be_optlinked
    end

    it "preverves broken symlinks pointing outside the Keg" do
      keg.link
      dst.delete
      dst.make_symlink(nonexistent)
      keg.unlink
      expect(dst).to be_a_symlink
    end

    it "preverves broken symlinks pointing into the Keg" do
      keg.link
      dst.resolved_path.delete
      keg.unlink
      expect(dst).to be_a_symlink
    end

    it "preverves symlinks pointing outside the Keg" do
      keg.link
      dst.delete
      dst.make_symlink(Pathname.new("/bin/sh"))
      keg.unlink
      expect(dst).to be_a_symlink
    end

    it "preserves real files" do
      keg.link
      dst.delete
      touch dst
      keg.unlink
      expect(dst).to be_a_file
    end

    it "ignores nonexistent file" do
      keg.link
      dst.delete
      expect(keg.unlink).to eq(2)
    end

    it "doesn't remove links to symlinks" do
      a = HOMEBREW_CELLAR/"a"/"1.0"
      b = HOMEBREW_CELLAR/"b"/"1.0"

      (a/"lib"/"example").mkpath
      (a/"lib"/"example2").make_symlink "example"
      (b/"lib"/"example2").mkpath

      a = described_class.new(a)
      b = described_class.new(b)
      a.link

      lib = HOMEBREW_PREFIX/"lib"
      expect(lib.children.length).to eq(2)
      expect { b.link }.to raise_error(Keg::ConflictError)
      expect(lib.children.length).to eq(2)
    end

    it "removes broken symlinks that conflict with directories" do
      a = HOMEBREW_CELLAR/"a"/"1.0"
      (a/"lib"/"foo").mkpath

      keg = described_class.new(a)

      link = HOMEBREW_PREFIX/"lib"/"foo"
      link.parent.mkpath
      link.make_symlink(nonexistent)

      keg.link
    end
  end

  describe "#optlink" do
    it "creates an opt link" do
      oldname_opt_record = HOMEBREW_PREFIX/"opt/oldfoo"
      oldname_opt_record.make_relative_symlink(HOMEBREW_CELLAR/"foo/1.0")
      keg_record = HOMEBREW_CELLAR/"foo"/"2.0"
      (keg_record/"bin").mkpath
      keg = described_class.new(keg_record)
      keg.optlink
      expect(keg_record).to eq(oldname_opt_record.resolved_path)
      keg.uninstall
      expect(oldname_opt_record).not_to be_a_symlink
    end

    it "doesn't fail if already opt-linked" do
      keg.opt_record.make_relative_symlink Pathname.new(keg)
      keg.optlink
      expect(keg).to be_optlinked
    end

    it "replaces an existing directory" do
      keg.opt_record.mkpath
      keg.optlink
      expect(keg).to be_optlinked
    end

    it "replaces an existing file" do
      keg.opt_record.parent.mkpath
      keg.opt_record.write("foo")
      keg.optlink
      expect(keg).to be_optlinked
    end
  end

  specify "#link and #unlink" do
    expect(keg).not_to be_linked
    keg.link
    expect(keg).to be_linked
    keg.unlink
    expect(keg).not_to be_linked
  end

  describe "::find_some_installed_dependents" do
    def stub_formula_name(name)
      f = formula(name) { url "foo-1.0" }
      stub_formula_loader f
      stub_formula_loader f, "homebrew/core/#{f}"
      f
    end

    def setup_test_keg(name, version)
      f = stub_formula_name(name)
      keg = super
      Tab.create(f, DevelopmentTools.default_compiler, :libcxx).write
      keg
    end

    before do
      keg.link
    end

    def alter_tab(keg = dependent)
      tab = Tab.for_keg(keg)
      yield tab
      tab.write
    end

    # 1.1.6 is the earliest version of Homebrew that generates correct runtime
    # dependency lists in Tabs.
    def dependencies(deps, homebrew_version: "1.1.6")
      alter_tab do |tab|
        tab.homebrew_version = homebrew_version
        tab.tabfile = dependent/Tab::FILENAME
        tab.runtime_dependencies = deps
      end
    end

    def unreliable_dependencies(deps)
      # 1.1.5 is (hopefully!) the last version of Homebrew that generates
      # incorrect runtime dependency lists in Tabs.
      dependencies(deps, homebrew_version: "1.1.5")
    end

    let(:dependent) { setup_test_keg("bar", "1.0") }

    specify "a dependency with no Tap in Tab" do
      tap_dep = setup_test_keg("baz", "1.0")

      # allow tap_dep to be linked too
      FileUtils.rm_r tap_dep/"bin"
      tap_dep.link

      alter_tab(keg) { |t| t.source["tap"] = nil }

      dependencies nil
      Formula["bar"].class.depends_on "foo"
      Formula["bar"].class.depends_on "baz"

      result = described_class.find_some_installed_dependents([keg, tap_dep])
      expect(result).to eq([[keg, tap_dep], ["bar"]])
    end

    specify "no dependencies anywhere" do
      dependencies nil
      expect(described_class.find_some_installed_dependents([keg])).to be nil
    end

    specify "missing Formula dependency" do
      dependencies nil
      Formula["bar"].class.depends_on "foo"
      expect(described_class.find_some_installed_dependents([keg])).to eq([[keg], ["bar"]])
    end

    specify "uninstalling dependent and dependency" do
      dependencies nil
      Formula["bar"].class.depends_on "foo"
      expect(described_class.find_some_installed_dependents([keg, dependent])).to be nil
    end

    specify "renamed dependency" do
      dependencies nil

      stub_formula_loader Formula["foo"], "homebrew/core/foo-old"
      renamed_path = HOMEBREW_CELLAR/"foo-old"
      (HOMEBREW_CELLAR/"foo").rename(renamed_path)
      renamed_keg = described_class.new(renamed_path/"1.0")

      Formula["bar"].class.depends_on "foo"

      result = described_class.find_some_installed_dependents([renamed_keg])
      expect(result).to eq([[renamed_keg], ["bar"]])
    end

    specify "empty dependencies in Tab" do
      dependencies []
      expect(described_class.find_some_installed_dependents([keg])).to be nil
    end

    specify "same name but different version in Tab" do
      dependencies [{ "full_name" => "foo", "version" => "1.1" }]
      expect(described_class.find_some_installed_dependents([keg])).to eq([[keg], ["bar"]])
    end

    specify "different name and same version in Tab" do
      stub_formula_name("baz")
      dependencies [{ "full_name" => "baz", "version" => keg.version.to_s }]
      expect(described_class.find_some_installed_dependents([keg])).to be nil
    end

    specify "same name and version in Tab" do
      dependencies [{ "full_name" => "foo", "version" => "1.0" }]
      expect(described_class.find_some_installed_dependents([keg])).to eq([[keg], ["bar"]])
    end

    specify "fallback for old versions" do
      unreliable_dependencies [{ "full_name" => "baz", "version" => "1.0" }]
      Formula["bar"].class.depends_on "foo"
      expect(described_class.find_some_installed_dependents([keg])).to eq([[keg], ["bar"]])
    end

    specify "non-opt-linked" do
      keg.remove_opt_record
      dependencies [{ "full_name" => "foo", "version" => "1.0" }]
      expect(described_class.find_some_installed_dependents([keg])).to be nil
    end

    specify "keg-only" do
      keg.unlink
      Formula["foo"].class.keg_only "a good reason"
      dependencies [{ "full_name" => "foo", "version" => "1.1" }] # different version
      expect(described_class.find_some_installed_dependents([keg])).to eq([[keg], ["bar"]])
    end
  end
end

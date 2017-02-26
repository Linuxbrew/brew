require "spec_helper"

describe Hbc::Pkg do
  describe "uninstall" do
    let(:fake_system_command) { Hbc::NeverSudoSystemCommand }
    let(:empty_response) { double(stdout: "") }
    let(:pkg) { described_class.new("my.fake.pkg", fake_system_command) }

    it "removes files and dirs referenced by the pkg" do
      some_files = Array.new(3) { Pathname.new(Tempfile.new("testfile").path) }
      allow(pkg).to receive(:pkgutil_bom_files).and_return(some_files)

      some_specials = Array.new(3) { Pathname.new(Tempfile.new("testfile").path) }
      allow(pkg).to receive(:pkgutil_bom_specials).and_return(some_specials)

      some_dirs = Array.new(3) { Pathname.new(Dir.mktmpdir) }
      allow(pkg).to receive(:pkgutil_bom_dirs).and_return(some_dirs)

      allow(pkg).to receive(:forget)

      pkg.uninstall

      some_files.each do |file|
        expect(file).not_to exist
      end

      some_dirs.each do |dir|
        expect(dir).not_to exist
      end
    end

    context "pkgutil" do
      let(:fake_system_command) { class_double(Hbc::SystemCommand) }

      it "forgets the pkg" do
        allow(fake_system_command).to receive(:run!).with(
          "/usr/sbin/pkgutil",
          args: ["--only-files", "--files", "my.fake.pkg"],
        ).and_return(empty_response)

        allow(fake_system_command).to receive(:run!).with(
          "/usr/sbin/pkgutil",
          args: ["--only-dirs", "--files", "my.fake.pkg"],
        ).and_return(empty_response)

        allow(fake_system_command).to receive(:run!).with(
          "/usr/sbin/pkgutil",
          args: ["--files", "my.fake.pkg"],
        ).and_return(empty_response)

        expect(fake_system_command).to receive(:run!).with(
          "/usr/sbin/pkgutil",
          args: ["--forget", "my.fake.pkg"],
          sudo: true,
        )

        pkg.uninstall
      end
    end

    it "removes broken symlinks" do
      fake_dir  = Pathname.new(Dir.mktmpdir)
      fake_file = fake_dir.join("ima_file").tap { |path| FileUtils.touch(path) }

      intact_symlink = fake_dir.join("intact_symlink").tap { |path| path.make_symlink(fake_file) }
      broken_symlink = fake_dir.join("broken_symlink").tap { |path| path.make_symlink("im_nota_file") }

      allow(pkg).to receive(:pkgutil_bom_specials).and_return([])
      allow(pkg).to receive(:pkgutil_bom_files).and_return([])
      allow(pkg).to receive(:pkgutil_bom_dirs).and_return([fake_dir])
      allow(pkg).to receive(:forget)

      pkg.uninstall

      expect(intact_symlink).to exist
      expect(broken_symlink).not_to exist
      expect(fake_dir).to exist
    end

    it "removes files incorrectly reportes as directories" do
      fake_dir  = Pathname.new(Dir.mktmpdir)
      fake_file = fake_dir.join("ima_file_pretending_to_be_a_dir").tap { |path| FileUtils.touch(path) }

      allow(pkg).to receive(:pkgutil_bom_specials).and_return([])
      allow(pkg).to receive(:pkgutil_bom_files).and_return([])
      allow(pkg).to receive(:pkgutil_bom_dirs).and_return([fake_file, fake_dir])
      allow(pkg).to receive(:forget)

      pkg.uninstall

      expect(fake_file).not_to exist
      expect(fake_dir).not_to exist
    end

    it "snags permissions on ornery dirs, but returns them afterwards" do
      fake_dir = Pathname.new(Dir.mktmpdir)
      fake_file = fake_dir.join("ima_installed_file").tap { |path| FileUtils.touch(path) }
      fake_dir.chmod(0000)

      allow(pkg).to receive(:pkgutil_bom_specials).and_return([])
      allow(pkg).to receive(:pkgutil_bom_files).and_return([fake_file])
      allow(pkg).to receive(:pkgutil_bom_dirs).and_return([fake_dir])
      allow(pkg).to receive(:forget)

      shutup do
        pkg.uninstall
      end

      expect(fake_dir).to be_a_directory
      expect(fake_file).not_to be_a_file
      expect((fake_dir.stat.mode % 01000).to_s(8)).to eq("0")
    end
  end
end

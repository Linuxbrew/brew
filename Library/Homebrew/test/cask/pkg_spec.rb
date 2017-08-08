describe Hbc::Pkg, :cask do
  describe "#uninstall" do
    let(:fake_system_command) { Hbc::NeverSudoSystemCommand }
    let(:empty_response) { double(stdout: "", plist: { "volume" => "/", "install-location" => "", "paths" => {} }) }
    let(:pkg) { described_class.new("my.fake.pkg", fake_system_command) }

    it "removes files and dirs referenced by the pkg" do
      some_files = Array.new(3) { Pathname.new(Tempfile.new("plain_file").path) }
      allow(pkg).to receive(:pkgutil_bom_files).and_return(some_files)

      some_specials = Array.new(3) { Pathname.new(Tempfile.new("special_file").path) }
      allow(pkg).to receive(:pkgutil_bom_specials).and_return(some_specials)

      some_dirs = Array.new(3) { mktmpdir }
      allow(pkg).to receive(:pkgutil_bom_dirs).and_return(some_dirs)

      root_dir = Pathname.new(mktmpdir)
      allow(pkg).to receive(:root).and_return(root_dir)

      allow(pkg).to receive(:forget)

      pkg.uninstall

      some_files.each do |file|
        expect(file).not_to exist
      end

      some_dirs.each do |dir|
        expect(dir).not_to exist
      end

      expect(root_dir).not_to exist
    end

    context "pkgutil" do
      it "forgets the pkg" do
        allow(fake_system_command).to receive(:run!).with(
          "/usr/sbin/pkgutil",
          args: ["--pkg-info-plist", "my.fake.pkg"],
        ).and_return(empty_response)

        expect(fake_system_command).to receive(:run!).with(
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
      fake_root = mktmpdir
      fake_dir  = mktmpdir
      fake_file = fake_dir.join("ima_file").tap { |path| FileUtils.touch(path) }

      intact_symlink = fake_dir.join("intact_symlink").tap { |path| path.make_symlink(fake_file) }
      broken_symlink = fake_dir.join("broken_symlink").tap { |path| path.make_symlink("im_nota_file") }

      allow(pkg).to receive(:pkgutil_bom_specials).and_return([])
      allow(pkg).to receive(:pkgutil_bom_files).and_return([])
      allow(pkg).to receive(:pkgutil_bom_dirs).and_return([fake_dir])
      allow(pkg).to receive(:root).and_return(fake_root)
      allow(pkg).to receive(:forget)

      pkg.uninstall

      expect(intact_symlink).to exist
      expect(broken_symlink).not_to exist
      expect(fake_dir).to exist
      expect(fake_root).not_to exist
    end

    it "snags permissions on ornery dirs, but returns them afterwards" do
      fake_root = mktmpdir
      fake_dir = mktmpdir
      fake_file = fake_dir.join("ima_unrelated_file").tap { |path| FileUtils.touch(path) }
      fake_dir.chmod(0000)

      allow(pkg).to receive(:pkgutil_bom_specials).and_return([])
      allow(pkg).to receive(:pkgutil_bom_files).and_return([])
      allow(pkg).to receive(:pkgutil_bom_dirs).and_return([fake_dir])
      allow(pkg).to receive(:root).and_return(fake_root)
      allow(pkg).to receive(:forget)

      pkg.uninstall

      expect(fake_dir).to be_a_directory
      expect((fake_dir.stat.mode % 01000)).to eq(0)

      fake_dir.chmod(0777)
      expect(fake_file).to be_a_file

      FileUtils.rm_r fake_dir
    end
  end

  describe "#info" do
    let(:fake_system_command) { class_double(Hbc::SystemCommand) }

    let(:volume) { "/" }
    let(:install_location) { "tmp" }

    let(:pkg_id) { "my.fancy.package.main" }

    let(:pkg_files) do
      %w[
        fancy/bin/fancy.exe
        fancy/var/fancy.data
      ]
    end
    let(:pkg_directories) do
      %w[
        fancy
        fancy/bin
        fancy/var
      ]
    end

    let(:pkg_info_plist) do
      <<-EOS.undent
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>install-location</key>
          <string>#{install_location}</string>
          <key>volume</key>
          <string>#{volume}</string>
          <key>paths</key>
          <dict>
            #{(pkg_files + pkg_directories).map { |f| "<key>#{f}</key><dict></dict>" }.join("")}
          </dict>
        </dict>
        </plist>
      EOS
    end

    it "correctly parses a Property List" do
      pkg = Hbc::Pkg.new(pkg_id, fake_system_command)

      expect(fake_system_command).to receive(:run!).with(
        "/usr/sbin/pkgutil",
      args: ["--pkg-info-plist", pkg_id],
      ).and_return(
        Hbc::SystemCommand::Result.new(nil, pkg_info_plist, nil, 0),
      )

      info = pkg.info

      expect(info["install-location"]).to eq(install_location)
      expect(info["volume"]).to eq(volume)
      expect(info["paths"].keys).to eq(pkg_files + pkg_directories)
    end
  end
end

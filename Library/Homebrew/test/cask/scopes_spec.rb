describe Hbc::Scopes, :cask do
  describe "installed" do
    it "returns a list installed Casks by loading Casks for all the dirs that exist in the caskroom" do
      allow(Hbc::CaskLoader).to receive(:load) { |token| "loaded-#{token}" }

      Hbc.caskroom.join("cask-bar").mkpath
      Hbc.caskroom.join("cask-foo").mkpath

      installed_casks = Hbc.installed

      expect(Hbc::CaskLoader).to have_received(:load).with("cask-bar")
      expect(Hbc::CaskLoader).to have_received(:load).with("cask-foo")
      expect(installed_casks).to eq(
        %w[
          loaded-cask-bar
          loaded-cask-foo
        ],
      )
    end

    it "optimizes performance by resolving to a fully qualified path before calling Hbc::CaskLoader.load" do
      fake_tapped_cask_dir = Pathname.new(Dir.mktmpdir).join("Casks")
      absolute_path_to_cask = fake_tapped_cask_dir.join("some-cask.rb")

      allow(Hbc::CaskLoader).to receive(:load)
      allow(Hbc).to receive(:all_tapped_cask_dirs) { [fake_tapped_cask_dir] }

      Hbc.caskroom.join("some-cask").mkdir
      fake_tapped_cask_dir.mkdir
      FileUtils.touch(absolute_path_to_cask)

      Hbc.installed

      expect(Hbc::CaskLoader).to have_received(:load).with(absolute_path_to_cask)
    end
  end
end

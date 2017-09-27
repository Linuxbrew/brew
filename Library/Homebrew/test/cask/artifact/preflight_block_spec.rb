describe Hbc::Artifact::PreflightBlock, :cask do
  describe "install_phase" do
    it "calls the specified block before installing, passing a Cask mini-dsl" do
      called = false
      yielded_arg = nil

      cask = Hbc::Cask.new("with-preflight") do
        preflight do |c|
          called = true
          yielded_arg = c
        end
      end

      described_class.for_cask(cask)
        .each { |artifact| artifact.install_phase(command: Hbc::NeverSudoSystemCommand, force: false) }

      expect(called).to be true
      expect(yielded_arg).to be_kind_of Hbc::DSL::Preflight
    end
  end

  describe "uninstall_phase" do
    it "calls the specified block before uninstalling, passing a Cask mini-dsl" do
      called = false
      yielded_arg = nil

      cask = Hbc::Cask.new("with-uninstall-preflight") do
        uninstall_preflight do |c|
          called = true
          yielded_arg = c
        end
      end

      described_class.for_cask(cask)
        .each { |artifact| artifact.uninstall_phase(command: Hbc::NeverSudoSystemCommand, force: false) }

      expect(called).to be true
      expect(yielded_arg).to be_kind_of Hbc::DSL::UninstallPreflight
    end
  end
end

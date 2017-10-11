describe Hbc::Artifact::PostflightBlock, :cask do
  describe "install_phase" do
    it "calls the specified block after installing, passing a Cask mini-dsl" do
      called = false
      yielded_arg = nil

      cask = Hbc::Cask.new("with-postflight") do
        postflight do |c|
          called = true
          yielded_arg = c
        end
      end

      cask.artifacts.select { |a| a.is_a?(described_class) }.each do |artifact|
        artifact.install_phase(command: Hbc::NeverSudoSystemCommand, force: false)
      end

      expect(called).to be true
      expect(yielded_arg).to be_kind_of(Hbc::DSL::Postflight)
    end
  end

  describe "uninstall_phase" do
    it "calls the specified block after uninstalling, passing a Cask mini-dsl" do
      called = false
      yielded_arg = nil

      cask = Hbc::Cask.new("with-uninstall-postflight") do
        uninstall_postflight do |c|
          called = true
          yielded_arg = c
        end
      end

      cask.artifacts.select { |a| a.is_a?(described_class) }.each do |artifact|
        artifact.uninstall_phase(command: Hbc::NeverSudoSystemCommand, force: false)
      end

      expect(called).to be true
      expect(yielded_arg).to be_kind_of(Hbc::DSL::UninstallPostflight)
    end
  end
end

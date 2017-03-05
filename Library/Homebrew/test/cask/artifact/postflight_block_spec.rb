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

      described_class.new(cask).install_phase

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

      described_class.new(cask).uninstall_phase

      expect(called).to be true
      expect(yielded_arg).to be_kind_of(Hbc::DSL::UninstallPostflight)
    end
  end
end

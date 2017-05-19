describe Hbc::CLI::Audit, :cask do
  let(:auditor) { double }
  let(:cask) { double }

  describe "selection of Casks to audit" do
    it "audits all Casks if no tokens are given" do
      allow(Hbc).to receive(:all).and_return([cask, cask])

      expect(auditor).to receive(:audit).twice.and_return(true)

      run_audit
    end

    it "audits specified Casks if tokens are given" do
      cask_token = "nice-app"
      expect(Hbc::CaskLoader).to receive(:load).with(cask_token).and_return(cask)

      expect(auditor).to receive(:audit)
        .with(cask, audit_download: false, check_token_conflicts: false)
        .and_return(true)

      run_audit(cask_token)
    end
  end

  describe "rules for downloading a Cask" do
    it "does not download the Cask per default" do
      allow(Hbc::CaskLoader).to receive(:load).and_return(cask)
      expect(auditor).to receive(:audit)
        .with(cask, audit_download: false, check_token_conflicts: false)
        .and_return(true)

      run_audit("casktoken")
    end

    it "download a Cask if --download flag is set" do
      allow(Hbc::CaskLoader).to receive(:load).and_return(cask)
      expect(auditor).to receive(:audit)
        .with(cask, audit_download: true, check_token_conflicts: false)
        .and_return(true)

      run_audit("casktoken", "--download")
    end
  end

  describe "rules for checking token conflicts" do
    it "does not check for token conflicts per default" do
      allow(Hbc::CaskLoader).to receive(:load).and_return(cask)
      expect(auditor).to receive(:audit)
        .with(cask, audit_download: false, check_token_conflicts: false)
        .and_return(true)

      run_audit("casktoken")
    end

    it "checks for token conflicts if --token-conflicts flag is set" do
      allow(Hbc::CaskLoader).to receive(:load).and_return(cask)
      expect(auditor).to receive(:audit)
        .with(cask, audit_download: false, check_token_conflicts: true)
        .and_return(true)

      run_audit("casktoken", "--token-conflicts")
    end
  end

  def run_audit(*args)
    Hbc::CLI::Audit.new(*args, auditor: auditor).run
  end
end

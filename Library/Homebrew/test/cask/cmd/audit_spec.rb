require_relative "shared_examples/invalid_option"

describe Cask::Cmd::Audit, :cask do
  let(:cask) { Cask::Cask.new(nil) }

  it_behaves_like "a command that handles invalid options"

  describe "selection of Casks to audit" do
    it "audits all Casks if no tokens are given" do
      allow(Cask::Cask).to receive(:to_a).and_return([cask, cask])

      expect(Cask::Auditor).to receive(:audit).twice.and_return(true)

      described_class.run
    end

    it "audits specified Casks if tokens are given" do
      cask_token = "nice-app"
      expect(Cask::CaskLoader).to receive(:load).with(cask_token).and_return(cask)

      expect(Cask::Auditor).to receive(:audit)
        .with(cask, audit_download: false, check_token_conflicts: false, quarantine: true)
        .and_return(true)

      described_class.run(cask_token)
    end
  end

  describe "rules for downloading a Cask" do
    it "does not download the Cask per default" do
      allow(Cask::CaskLoader).to receive(:load).and_return(cask)
      expect(Cask::Auditor).to receive(:audit)
        .with(cask, audit_download: false, check_token_conflicts: false, quarantine: true)
        .and_return(true)

      described_class.run("casktoken")
    end

    it "download a Cask if --download flag is set" do
      allow(Cask::CaskLoader).to receive(:load).and_return(cask)
      expect(Cask::Auditor).to receive(:audit)
        .with(cask, audit_download: true, check_token_conflicts: false, quarantine: true)
        .and_return(true)

      described_class.run("casktoken", "--download")
    end
  end

  describe "rules for checking token conflicts" do
    it "does not check for token conflicts per default" do
      allow(Cask::CaskLoader).to receive(:load).and_return(cask)
      expect(Cask::Auditor).to receive(:audit)
        .with(cask, audit_download: false, check_token_conflicts: false, quarantine: true)
        .and_return(true)

      described_class.run("casktoken")
    end

    it "checks for token conflicts if --token-conflicts flag is set" do
      allow(Cask::CaskLoader).to receive(:load).and_return(cask)
      expect(Cask::Auditor).to receive(:audit)
        .with(cask, audit_download: false, check_token_conflicts: true, quarantine: true)
        .and_return(true)

      described_class.run("casktoken", "--token-conflicts")
    end
  end
end

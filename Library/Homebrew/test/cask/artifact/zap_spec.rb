require_relative "uninstall_zap_shared_examples"

describe Hbc::Artifact::Zap, :cask do
  describe "#zap_phase" do
    include_examples "#uninstall_phase or #zap_phase"
  end
end

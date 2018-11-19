require_relative "shared_examples/uninstall_zap"

describe Cask::Artifact::Zap, :cask do
  describe "#zap_phase" do
    include_examples "#uninstall_phase or #zap_phase"
  end
end

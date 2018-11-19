require_relative "shared_examples/uninstall_zap"

describe Cask::Artifact::Uninstall, :cask do
  describe "#uninstall_phase" do
    include_examples "#uninstall_phase or #zap_phase"
  end
end

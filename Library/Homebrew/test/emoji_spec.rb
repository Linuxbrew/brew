require "emoji"

describe Emoji do
  describe "#install_badge" do
    subject { described_class.install_badge }

    it "returns 🍺 by default" do
      expect(subject).to eq "🍺"
    end

    it "returns the contents of HOMEBREW_INSTALL_BADGE if set" do
      ENV["HOMEBREW_INSTALL_BADGE"] = "foo"
      expect(subject).to eq "foo"
    end
  end
end

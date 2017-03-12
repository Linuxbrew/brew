require "formula_support"

describe KegOnlyReason do
  describe "#to_s" do
    it "returns the reason provided" do
      r = KegOnlyReason.new :provided_by_osx, "test"
      expect(r.to_s).to eq("test")
    end

    it "returns a default message when no reason is provided" do
      r = KegOnlyReason.new :provided_by_macos, ""
      expect(r.to_s).to match(/^macOS already provides/)
    end
  end
end

describe BottleDisableReason do
  specify ":unneeded" do
    bottle_disable_reason = BottleDisableReason.new :unneeded, nil
    expect(bottle_disable_reason).to be_unneeded
    expect(bottle_disable_reason.to_s).to eq("This formula doesn't require compiling.")
  end

  specify ":disabled" do
    bottle_disable_reason = BottleDisableReason.new :disable, "reason"
    expect(bottle_disable_reason).not_to be_unneeded
    expect(bottle_disable_reason.to_s).to eq("reason")
  end
end

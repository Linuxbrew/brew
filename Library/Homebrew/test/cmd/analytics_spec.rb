describe "brew analytics", :integration_test do
  before do
    HOMEBREW_REPOSITORY.cd do
      system "git", "init"
    end
  end

  it "is disabled when HOMEBREW_NO_ANALYTICS is set" do
    expect { brew "analytics", "HOMEBREW_NO_ANALYTICS" => "1" }
      .to output(/Analytics is disabled \(by HOMEBREW_NO_ANALYTICS\)/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  context "when HOMEBREW_NO_ANALYTICS is unset" do
    it "is disabled after running `brew analytics off`" do
      brew "analytics", "off"
      expect { brew "analytics", "HOMEBREW_NO_ANALYTICS" => nil }
        .to output(/Analytics is disabled/).to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end

    it "is enabled after running `brew analytics on`" do
      brew "analytics", "on"
      expect { brew "analytics", "HOMEBREW_NO_ANALYTICS" => nil }
        .to output(/Analytics is enabled/).to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end

  it "can generate a new UUID" do
    expect { brew "analytics", "regenerate-uuid" }.to be_a_success
  end
end

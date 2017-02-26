describe "brew uninstall", :integration_test do
  it "uninstalls a given Formula" do
    shutup do
      expect { brew "install", testball }.to be_a_success
    end

    expect { brew "uninstall", "--force", testball }
      .to output(/Uninstalling testball/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end

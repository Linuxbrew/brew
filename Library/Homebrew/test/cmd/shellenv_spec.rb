describe "brew shellenv", :integration_test do
  it "doesn't fail" do
    expect { brew "shellenv" }
      .to output(%r{#{HOMEBREW_PREFIX}/bin}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end

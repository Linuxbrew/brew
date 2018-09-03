describe "brew --cache", :integration_test do
  it "print the location of Homebrew's cache when no argument is given" do
    expect { brew "--cache" }
      .to output("#{HOMEBREW_CACHE}\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "prints all cache files for a given Formula" do
    expect { brew "--cache", testball }
      .to output(%r{#{HOMEBREW_CACHE}/downloads/[\da-f]{64}\-\-testball\-}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end

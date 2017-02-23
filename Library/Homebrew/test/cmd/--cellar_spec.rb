describe "brew --cellar", :integration_test do
  it "print the location of Homebrew's Cellar when no argument is given" do
    expect { brew "--cellar" }
      .to output("#{HOMEBREW_CELLAR}\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "returns the Cellar subdirectory for a given Formula" do
    expect { brew "--cellar", testball }
      .to output(%r{#{HOMEBREW_CELLAR}/testball}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end

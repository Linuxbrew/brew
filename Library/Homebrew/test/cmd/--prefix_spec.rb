describe "brew --prefix", :integration_test do
  it "prints the Homebrew prefix when no argument is given" do
    expect { brew "--prefix" }
      .to output("#{HOMEBREW_PREFIX}\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "prints a given Formula's prefix" do
    expect { brew "--prefix", testball }
      .to output(%r{#{HOMEBREW_CELLAR}/testball}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end

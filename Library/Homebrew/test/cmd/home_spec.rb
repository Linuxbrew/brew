describe "brew home", :integration_test do
  it "opens the Homebrew homepage when no argument is given" do
    expect { brew "home", "HOMEBREW_BROWSER" => "echo" }
      .to output("#{HOMEBREW_WWW}\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "opens the homepage for a given Formula" do
    setup_test_formula "testball"

    expect { brew "home", "testball", "HOMEBREW_BROWSER" => "echo" }
      .to output("#{Formula["testball"].homepage}\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end

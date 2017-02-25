describe "brew irb", :integration_test do
  it "starts an interactive Homebrew shell session" do
    setup_test_formula "testball"

    irb_test = HOMEBREW_TEMP/"irb-test.rb"
    irb_test.write <<-EOS.undent
      "testball".f
      :testball.f
      exit
    EOS

    expect { brew "irb", irb_test }
      .to output(/Interactive Homebrew Shell/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  specify "--examples" do
    expect { brew "irb", "--examples" }
      .to output(/'v8'\.f # => instance of the v8 formula/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end

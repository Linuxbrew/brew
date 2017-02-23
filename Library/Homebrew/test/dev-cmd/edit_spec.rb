describe "brew edit", :integration_test do
  it "opens a given Formula in an editor" do
    HOMEBREW_REPOSITORY.cd do
      shutup do
        system "git", "init"
      end
    end

    setup_test_formula "testball"

    expect { brew "edit", "testball", "HOMEBREW_EDITOR" => "/bin/cat" }
      .to output(/# something here/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end

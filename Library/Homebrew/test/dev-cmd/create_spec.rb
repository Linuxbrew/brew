describe "brew create", :integration_test do
  let(:url) { "file://#{TEST_FIXTURE_DIR}/tarballs/testball-0.1.tbz" }
  let(:formula_file) { CoreTap.new.formula_dir/"testball.rb" }

  it "creates a new Formula file for a given URL" do
    brew "create", url, "HOMEBREW_EDITOR" => "/bin/cat"

    expect(formula_file).to exist
    expect(formula_file.read).to match(%Q(sha256 "#{TESTBALL_SHA256}"))
  end
end

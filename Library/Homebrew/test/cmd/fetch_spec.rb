describe "brew fetch", :integration_test do
  it "downloads the Formula's URL" do
    setup_test_formula "testball"

    expect(HOMEBREW_CACHE/"testball-0.1.tbz").not_to exist

    expect { brew "fetch", "testball" }.to be_a_success

    expect(HOMEBREW_CACHE/"testball-0.1.tbz").to exist
  end
end

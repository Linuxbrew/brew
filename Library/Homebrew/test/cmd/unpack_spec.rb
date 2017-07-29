describe "brew unpack", :integration_test do
  it "unpacks a given Formula's archive" do
    setup_test_formula "testball"

    mktmpdir do |path|
      expect { brew "unpack", "testball", "--destdir=#{path}" }
        .to be_a_success

      expect(path/"testball-0.1").to be_a_directory
    end
  end
end

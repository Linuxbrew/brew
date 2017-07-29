describe "brew desc", :integration_test do
  let(:desc_cache) { HOMEBREW_CACHE/"desc_cache.json" }

  it "shows a given Formula's description" do
    setup_test_formula "testball"

    expect { brew "desc", "testball" }
      .to output("testball: Some test\n").to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "fails when both --search and --name are specified" do
    expect { brew "desc", "--search", "--name" }
      .to output(/Pick one, and only one/).to_stderr
      .and not_to_output.to_stdout
      .and be_a_failure
  end

  describe "--search" do
    it "fails when no search term is given" do
      expect { brew "desc", "--search" }
        .to output(/You must provide a search term/).to_stderr
        .and not_to_output.to_stdout
        .and be_a_failure
    end
  end

  describe "--description" do
    it "creates a description cache" do
      expect(desc_cache).not_to exist

      expect { brew "desc", "--description", "testball" }.to be_a_success

      expect(desc_cache).to exist
    end
  end
end

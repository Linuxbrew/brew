describe Hbc::CLI::Version, :cask do
  describe "::run" do
    it "outputs the current Homebrew-Cask version" do
      expect { described_class.run }
        .to output(/\AHomebrew-Cask.*\d+\.\d+\.\d+/).to_stdout
        .and not_to_output.to_stderr
    end

    it "does not support arguments" do
      expect { described_class.run(:foo, :bar) }.to raise_error(ArgumentError)
    end
  end
end

require_relative "../cli_parser"

describe Homebrew::CLI::Parser do
  describe "test switch options" do
    before do
      allow(ENV).to receive(:[]).with("HOMEBREW_PRY").and_return("1")
      allow(ENV).to receive(:[]).with("HOMEBREW_VERBOSE")
    end

    subject(:parser) {
      described_class.new do
        switch :verbose, description: "Flag for verbosity"
        switch "--more-verbose", description: "Flag for higher verbosity"
        switch "--pry", env: :pry
      end
    }

    it "parses short option" do
      parser.parse(["-v"])
      expect(Homebrew.args).to be_verbose
    end

    it "parses a single valid option" do
      parser.parse(["--verbose"])
      expect(Homebrew.args).to be_verbose
    end

    it "parses a valid option along with few unnamed args" do
      args = %w[--verbose unnamed args]
      parser.parse(args)
      expect(Homebrew.args).to be_verbose
      expect(args).to eq %w[--verbose unnamed args]
    end

    it "parses a single option and checks other options to be nil" do
      args = parser.parse(["--verbose"])
      expect(Homebrew.args).to be_verbose
      expect(args.more_verbose?).to be nil
    end

    it "raises an exception when an invalid option is passed" do
      expect { parser.parse(["--random"]) }.to raise_error(OptionParser::InvalidOption, /--random/)
    end

    it "maps environment var to an option" do
      args = parser.parse([])
      expect(args.pry?).to be true
    end
  end

  describe "test long flag options" do
    subject(:parser) {
      described_class.new do
        flag        "--filename", description: "Name of the file", required: true
        comma_array "--files",    description: "Comma separated filenames"
      end
    }

    it "parses a long flag option with its argument" do
      args = parser.parse(["--filename=random.txt"])
      expect(args.filename).to eq "random.txt"
    end

    it "raises an exception when a flag's required arg is not passed" do
      expect { parser.parse(["--filename"]) }.to raise_error(OptionParser::MissingArgument, /--filename/)
    end

    it "parses a comma array flag option" do
      args = parser.parse(["--files=random1.txt,random2.txt"])
      expect(args.files).to eq %w[random1.txt random2.txt]
    end
  end
end

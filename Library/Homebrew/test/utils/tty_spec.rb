require "utils"

describe Tty do
  describe "::strip_ansi" do
    it "removes ANSI escape codes from a string" do
      expect(subject.strip_ansi("\033\[36;7mhello\033\[0m")).to eq("hello")
    end
  end

  describe "::width" do
    it "returns an Integer" do
      expect(subject.width).to be_kind_of(Integer)
    end

    it "cannot be negative" do
      expect(subject.width).to be >= 0
    end
  end

  describe "::truncate" do
    it "truncates the text to the terminal width, minus 4, to account for '==> '" do
      allow(subject).to receive(:width).and_return(15)

      expect(subject.truncate("foobar something very long")).to eq("foobar some")
      expect(subject.truncate("truncate")).to eq("truncate")
    end

    it "doesn't truncate the text if the terminal is unsupported, i.e. the width is 0" do
      allow(subject).to receive(:width).and_return(0)
      expect(subject.truncate("foobar something very long")).to eq("foobar something very long")
    end
  end

  context "when $stdout is not a TTY" do
    before(:each) do
      allow($stdout).to receive(:tty?).and_return(false)
    end

    it "returns an empty string for all colors" do
      expect(subject.to_s).to eq("")
      expect(subject.red.to_s).to eq("")
      expect(subject.green.to_s).to eq("")
      expect(subject.yellow.to_s).to eq("")
      expect(subject.blue.to_s).to eq("")
      expect(subject.magenta.to_s).to eq("")
      expect(subject.cyan.to_s).to eq("")
      expect(subject.default.to_s).to eq("")
    end
  end

  context "when $stdout is a TTY" do
    before(:each) do
      allow($stdout).to receive(:tty?).and_return(true)
    end

    it "returns an empty string for all colors" do
      expect(subject.to_s).to eq("")
      expect(subject.red.to_s).to eq("\033[31m")
      expect(subject.green.to_s).to eq("\033[32m")
      expect(subject.yellow.to_s).to eq("\033[33m")
      expect(subject.blue.to_s).to eq("\033[34m")
      expect(subject.magenta.to_s).to eq("\033[35m")
      expect(subject.cyan.to_s).to eq("\033[36m")
      expect(subject.default.to_s).to eq("\033[39m")
    end
  end
end

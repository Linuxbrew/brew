require "spec_helper"

describe "brew cask --version" do
  it "respects the --version argument" do
    expect {
      expect {
        Hbc::CLI::NullCommand.new("--version").run
      }.not_to output.to_stderr
    }.to output(Hbc.full_version).to_stdout
  end
end

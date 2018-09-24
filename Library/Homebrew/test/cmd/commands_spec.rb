require "cmd/command"
require "cmd/commands"
require "fileutils"

describe "brew commands", :integration_test do
  it "prints a list of all available commands" do
    expect { brew "commands" }
      .to output(/Built-in commands/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "prints a list without headers with the --quiet flag" do
    expect { brew "commands", "--quiet" }
      .to be_a_success
      .and not_to_output.to_stderr
      .and not_to_output(/Built-in commands/).to_stdout
  end
end

RSpec.shared_context "custom internal commands" do
  let(:cmds) do
    [
      # internal commands
      HOMEBREW_LIBRARY_PATH/"cmd/rbcmd.rb",
      HOMEBREW_LIBRARY_PATH/"cmd/shcmd.sh",

      # internal developer-commands
      HOMEBREW_LIBRARY_PATH/"dev-cmd/rbdevcmd.rb",
      HOMEBREW_LIBRARY_PATH/"dev-cmd/shdevcmd.sh",
    ]
  end

  around do |example|
    begin
      cmds.each do |f|
        FileUtils.touch f
      end

      example.run
    ensure
      FileUtils.rm_f cmds
    end
  end
end

describe Homebrew do
  include_context "custom internal commands"

  specify "::internal_commands" do
    cmds = described_class.internal_commands
    expect(cmds).to include("rbcmd"), "Ruby commands files should be recognized"
    expect(cmds).to include("shcmd"), "Shell commands files should be recognized"
    expect(cmds).not_to include("rbdevcmd"), "Dev commands shouldn't be included"
  end

  specify "::internal_developer_commands" do
    cmds = described_class.internal_developer_commands
    expect(cmds).to include("rbdevcmd"), "Ruby commands files should be recognized"
    expect(cmds).to include("shdevcmd"), "Shell commands files should be recognized"
    expect(cmds).not_to include("rbcmd"), "Non-dev commands shouldn't be included"
  end

  specify "::external_commands" do
    mktmpdir do |dir|
      %w[brew-t1 brew-t2.rb brew-t3.py].each do |file|
        path = "#{dir}/#{file}"
        FileUtils.touch path
        FileUtils.chmod 0755, path
      end

      FileUtils.touch "#{dir}/brew-t4"

      ENV["PATH"] += "#{File::PATH_SEPARATOR}#{dir}"
      cmds = described_class.external_commands

      expect(cmds).to include("t1"), "Executable files should be included"
      expect(cmds).to include("t2"), "Executable Ruby files should be included"
      expect(cmds).not_to include("t3"), "Executable files with a non Ruby extension shouldn't be included"
      expect(cmds).not_to include("t4"), "Non-executable files shouldn't be included"
    end
  end
end

describe Commands do
  include_context "custom internal commands"

  describe "::path" do
    specify "returns the path for an internal command" do
      expect(described_class.path("rbcmd")).to eq(HOMEBREW_LIBRARY_PATH/"cmd/rbcmd.rb")
      expect(described_class.path("shcmd")).to eq(HOMEBREW_LIBRARY_PATH/"cmd/shcmd.sh")
      expect(described_class.path("idontexist1234")).to be nil
    end

    specify "returns the path for an internal developer-command" do
      expect(described_class.path("rbdevcmd")).to eq(HOMEBREW_LIBRARY_PATH/"dev-cmd/rbdevcmd.rb")
      expect(described_class.path("shdevcmd")).to eq(HOMEBREW_LIBRARY_PATH/"dev-cmd/shdevcmd.sh")
    end
  end
end

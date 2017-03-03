# monkeypatch for testing
module Hbc
  class CLI
    class Home
      def self.system(*command)
        system_commands << command
      end

      def self.reset!
        @system_commands = []
      end

      def self.system_commands
        @system_commands ||= []
      end
    end
  end
end

describe Hbc::CLI::Home, :cask do
  before do
    Hbc::CLI::Home.reset!
  end

  it "opens the homepage for the specified Cask" do
    Hbc::CLI::Home.run("local-caffeine")
    expect(Hbc::CLI::Home.system_commands).to eq [
      ["/usr/bin/open", "--", "http://example.com/local-caffeine"],
    ]
  end

  it "works for multiple Casks" do
    Hbc::CLI::Home.run("local-caffeine", "local-transmission")
    expect(Hbc::CLI::Home.system_commands).to eq [
      ["/usr/bin/open", "--", "http://example.com/local-caffeine"],
      ["/usr/bin/open", "--", "http://example.com/local-transmission"],
    ]
  end

  it "opens the project page when no Cask is specified" do
    Hbc::CLI::Home.run
    expect(Hbc::CLI::Home.system_commands).to eq [
      ["/usr/bin/open", "--", "http://caskroom.github.io/"],
    ]
  end
end

# monkeypatch for testing
module Hbc
  class CLI
    class Edit
      def self.exec_editor(*command)
        editor_commands << command
      end

      def self.reset!
        @editor_commands = []
      end

      def self.editor_commands
        @editor_commands ||= []
      end
    end
  end
end

describe Hbc::CLI::Edit, :cask do
  before(:each) do
    Hbc::CLI::Edit.reset!
  end

  it "opens the editor for the specified Cask" do
    Hbc::CLI::Edit.run("local-caffeine")
    expect(Hbc::CLI::Edit.editor_commands).to eq [
      [Hbc::CaskLoader.path("local-caffeine")],
    ]
  end

  it "throws away additional arguments and uses the first" do
    Hbc::CLI::Edit.run("local-caffeine", "local-transmission")
    expect(Hbc::CLI::Edit.editor_commands).to eq [
      [Hbc::CaskLoader.path("local-caffeine")],
    ]
  end

  it "raises an exception when the Cask doesnt exist" do
    expect {
      Hbc::CLI::Edit.run("notacask")
    }.to raise_error(Hbc::CaskUnavailableError)
  end

  describe "when no Cask is specified" do
    it "raises an exception" do
      expect {
        Hbc::CLI::Edit.run
      }.to raise_error(Hbc::CaskUnspecifiedError)
    end
  end

  describe "when no Cask is specified, but an invalid option" do
    it "raises an exception" do
      expect {
        Hbc::CLI::Edit.run("--notavalidoption")
      }.to raise_error(Hbc::CaskUnspecifiedError)
    end
  end
end

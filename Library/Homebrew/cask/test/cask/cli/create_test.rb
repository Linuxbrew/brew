require "test_helper"

# monkeypatch for testing
module Hbc
  class CLI
    class Create
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

describe Hbc::CLI::Create do
  before do
    Hbc::CLI::Create.reset!
  end

  after do
    %w[new-cask additional-cask another-cask yet-another-cask local-caff].each do |cask|
      path = Hbc.path(cask)
      path.delete if path.exist?
    end
  end

  it "opens the editor for the specified Cask" do
    Hbc::CLI::Create.run("new-cask")
    Hbc::CLI::Create.editor_commands.must_equal [
      [Hbc.path("new-cask")],
    ]
  end

  it "drops a template down for the specified Cask" do
    Hbc::CLI::Create.run("new-cask")
    template = File.read(Hbc.path("new-cask"))
    template.must_equal <<-EOS.undent
      cask 'new-cask' do
        version ''
        sha256 ''

        url 'https://'
        name ''
        homepage ''

        app ''
      end
    EOS
  end

  it "throws away additional Cask arguments and uses the first" do
    Hbc::CLI::Create.run("additional-cask", "another-cask")
    Hbc::CLI::Create.editor_commands.must_equal [
      [Hbc.path("additional-cask")],
    ]
  end

  it "throws away stray options" do
    Hbc::CLI::Create.run("--notavalidoption", "yet-another-cask")
    Hbc::CLI::Create.editor_commands.must_equal [
      [Hbc.path("yet-another-cask")],
    ]
  end

  it "raises an exception when the Cask already exists" do
    lambda {
      Hbc::CLI::Create.run("basic-cask")
    }.must_raise Hbc::CaskAlreadyCreatedError
  end

  it "allows creating Casks that are substrings of existing Casks" do
    Hbc::CLI::Create.run("local-caff")
    Hbc::CLI::Create.editor_commands.must_equal [
      [Hbc.path("local-caff")],
    ]
  end

  describe "when no Cask is specified" do
    it "raises an exception" do
      lambda {
        Hbc::CLI::Create.run
      }.must_raise Hbc::CaskUnspecifiedError
    end
  end

  describe "when no Cask is specified, but an invalid option" do
    it "raises an exception" do
      lambda {
        Hbc::CLI::Create.run("--notavalidoption")
      }.must_raise Hbc::CaskUnspecifiedError
    end
  end
end

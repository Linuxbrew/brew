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

describe Hbc::CLI::Create, :cask do
  before(:each) do
    Hbc::CLI::Create.reset!
  end

  after(:each) do
    %w[new-cask additional-cask another-cask yet-another-cask local-caff].each do |cask|
      path = Hbc::CaskLoader.path(cask)
      path.delete if path.exist?
    end
  end

  it "opens the editor for the specified Cask" do
    Hbc::CLI::Create.run("new-cask")
    expect(Hbc::CLI::Create.editor_commands).to eq [
      [Hbc::CaskLoader.path("new-cask")],
    ]
  end

  it "drops a template down for the specified Cask" do
    Hbc::CLI::Create.run("new-cask")
    template = File.read(Hbc::CaskLoader.path("new-cask"))
    expect(template).to eq <<-EOS.undent
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
    expect(Hbc::CLI::Create.editor_commands).to eq [
      [Hbc::CaskLoader.path("additional-cask")],
    ]
  end

  it "throws away stray options" do
    Hbc::CLI::Create.run("--notavalidoption", "yet-another-cask")
    expect(Hbc::CLI::Create.editor_commands).to eq [
      [Hbc::CaskLoader.path("yet-another-cask")],
    ]
  end

  it "raises an exception when the Cask already exists" do
    expect {
      Hbc::CLI::Create.run("basic-cask")
    }.to raise_error(Hbc::CaskAlreadyCreatedError)
  end

  it "allows creating Casks that are substrings of existing Casks" do
    Hbc::CLI::Create.run("local-caff")
    expect(Hbc::CLI::Create.editor_commands).to eq [
      [Hbc::CaskLoader.path("local-caff")],
    ]
  end

  describe "when no Cask is specified" do
    it "raises an exception" do
      expect {
        Hbc::CLI::Create.run
      }.to raise_error(Hbc::CaskUnspecifiedError)
    end
  end

  describe "when no Cask is specified, but an invalid option" do
    it "raises an exception" do
      expect {
        Hbc::CLI::Create.run("--notavalidoption")
      }.to raise_error(Hbc::CaskUnspecifiedError)
    end
  end
end

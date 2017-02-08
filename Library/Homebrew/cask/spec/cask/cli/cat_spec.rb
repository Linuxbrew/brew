require "spec_helper"

describe Hbc::CLI::Cat do
  describe "given a basic Cask" do
    let(:expected_output) {
      <<-EOS.undent
        cask 'basic-cask' do
          version '1.2.3'
          sha256 '8c62a2b791cf5f0da6066a0a4b6e85f62949cd60975da062df44adf887f4370b'

          url 'http://example.com/TestCask.dmg'
          homepage 'http://example.com/'

          app 'TestCask.app'
        end
      EOS
    }

    it "displays the Cask file content about the specified Cask" do
      expect {
        Hbc::CLI::Cat.run("basic-cask")
      }.to output(expected_output).to_stdout
    end

    it "throws away additional Cask arguments and uses the first" do
      expect {
        Hbc::CLI::Cat.run("basic-cask", "local-caffeine")
      }.to output(expected_output).to_stdout
    end

    it "throws away stray options" do
      expect {
        Hbc::CLI::Cat.run("--notavalidoption", "basic-cask")
      }.to output(expected_output).to_stdout
    end
  end

  it "raises an exception when the Cask does not exist" do
    expect {
      Hbc::CLI::Cat.run("notacask")
    }.to raise_error(Hbc::CaskUnavailableError)
  end

  describe "when no Cask is specified" do
    it "raises an exception" do
      expect {
        Hbc::CLI::Cat.run
      }.to raise_error(Hbc::CaskUnspecifiedError)
    end
  end

  describe "when no Cask is specified, but an invalid option" do
    it "raises an exception" do
      expect {
        Hbc::CLI::Cat.run("--notavalidoption")
      }.to raise_error(Hbc::CaskUnspecifiedError)
    end
  end
end

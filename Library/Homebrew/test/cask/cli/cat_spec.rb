describe Hbc::CLI::Cat, :cask do
  describe "given a basic Cask" do
    let(:basic_cask_content) {
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
      }.to output(basic_cask_content).to_stdout
    end

    it "can display multiple Casks" do
      expect {
        Hbc::CLI::Cat.run("basic-cask", "basic-cask")
      }.to output(basic_cask_content * 2).to_stdout
    end

    it "fails when option is unknown" do
      expect {
        Hbc::CLI::Cat.run("--notavalidoption", "basic-cask")
      }.to raise_error(/invalid option/)
    end
  end

  it "raises an exception when the Cask does not exist" do
    expect { Hbc::CLI::Cat.run("notacask") }
      .to output(/is unavailable/).to_stderr
      .and raise_error(Hbc::CaskError, "Cat incomplete.")
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
      }.to raise_error(/invalid option/)
    end
  end
end

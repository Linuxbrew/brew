require_relative "shared_examples/requires_cask_token"
require_relative "shared_examples/invalid_option"

describe Hbc::CLI::Info, :cask do
  it_behaves_like "a command that requires a Cask token"
  it_behaves_like "a command that handles invalid options"

  it "displays some nice info about the specified Cask" do
    expect {
      described_class.run("local-caffeine")
    }.to output(<<-EOS.undent).to_stdout
      local-caffeine: 1.2.3
      http://example.com/local-caffeine
      Not installed
      From: https://github.com/caskroom/homebrew-spec/blob/master/Casks/local-caffeine.rb
      ==> Name
      None
      ==> Artifacts
      Caffeine.app (App)
    EOS
  end

  describe "given multiple Casks" do
    let(:expected_output) {
      <<-EOS.undent
        local-caffeine: 1.2.3
        http://example.com/local-caffeine
        Not installed
        From: https://github.com/caskroom/homebrew-spec/blob/master/Casks/local-caffeine.rb
        ==> Name
        None
        ==> Artifacts
        Caffeine.app (App)
        local-transmission: 2.61
        http://example.com/local-transmission
        Not installed
        From: https://github.com/caskroom/homebrew-spec/blob/master/Casks/local-transmission.rb
        ==> Name
        None
        ==> Artifacts
        Transmission.app (App)
      EOS
    }

    it "displays the info" do
      expect {
        described_class.run("local-caffeine", "local-transmission")
      }.to output(expected_output).to_stdout
    end
  end

  it "should print caveats if the Cask provided one" do
    expect {
      described_class.run("with-caveats")
    }.to output(<<-EOS.undent).to_stdout
      with-caveats: 1.2.3
      http://example.com/local-caffeine
      Not installed
      From: https://github.com/caskroom/homebrew-spec/blob/master/Casks/with-caveats.rb
      ==> Name
      None
      ==> Artifacts
      Caffeine.app (App)
      ==> Caveats
      Here are some things you might want to know.

      Cask token: with-caveats

      Custom text via puts followed by DSL-generated text:
      To use with-caveats, you may need to add the /custom/path/bin directory
      to your PATH environment variable, eg (for bash shell):

        export PATH=/custom/path/bin:"$PATH"

    EOS
  end

  it 'should not print "Caveats" section divider if the caveats block has no output' do
    expect {
      described_class.run("with-conditional-caveats")
    }.to output(<<-EOS.undent).to_stdout
      with-conditional-caveats: 1.2.3
      http://example.com/local-caffeine
      Not installed
      From: https://github.com/caskroom/homebrew-spec/blob/master/Casks/with-conditional-caveats.rb
      ==> Name
      None
      ==> Artifacts
      Caffeine.app (App)
    EOS
  end

  it "prints languages specified in the Cask" do
    expect {
      described_class.run("with-languages")
    }.to output(<<-EOS.undent).to_stdout
      with-languages: 1.2.3
      http://example.com/local-caffeine
      Not installed
      From: https://github.com/caskroom/homebrew-spec/blob/master/Casks/with-languages.rb
      ==> Name
      None
      ==> Languages
      zh, en-US
      ==> Artifacts
      Caffeine.app (App)
    EOS
  end

  it 'does not print "Languages" section divider if the languages block has no output' do
    expect {
      described_class.run("without-languages")
    }.to output(<<-EOS.undent).to_stdout
      without-languages: 1.2.3
      http://example.com/local-caffeine
      Not installed
      From: https://github.com/caskroom/homebrew-spec/blob/master/Casks/without-languages.rb
      ==> Name
      None
      ==> Artifacts
      Caffeine.app (App)
    EOS
  end
end

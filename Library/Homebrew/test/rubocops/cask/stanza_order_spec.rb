require "rubocops/rubocop-cask"
require "test/rubocops/cask/shared_examples/cask_cop"

describe RuboCop::Cop::Cask::StanzaOrder do
  include CaskCop

  subject(:cop) { described_class.new }

  context "when there is only one stanza" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          version :latest
        end
      CASK
    end

    include_examples "does not report any offenses"
  end

  context "when no stanzas are out of order" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          version :latest
          sha256 :no_check
        end
      CASK
    end

    include_examples "does not report any offenses"
  end

  context "when one pair of stanzas is out of order" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          sha256 :no_check
          version :latest
        end
      CASK
    end
    let(:correct_source) do
      <<-CASK.undent
        cask 'foo' do
          version :latest
          sha256 :no_check
        end
      CASK
    end
    let(:expected_offenses) do
      [{
        message:  "`sha256` stanza out of order",
        severity: :convention,
        line:     2,
        column:   2,
        source:   "sha256 :no_check",
      }, {
        message:  "`version` stanza out of order",
        severity: :convention,
        line:     3,
        column:   2,
        source:   "version :latest",
      }]
    end

    include_examples "reports offenses"

    include_examples "autocorrects source"
  end

  context "when many stanzas are out of order" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          url 'https://foo.example.com/foo.zip'
          uninstall :quit => 'com.example.foo',
                    :kext => 'com.example.foo.kext'
          version :latest
          app 'Foo.app'
          sha256 :no_check
        end
      CASK
    end
    let(:correct_source) do
      <<-CASK.undent
        cask 'foo' do
          version :latest
          sha256 :no_check
          url 'https://foo.example.com/foo.zip'
          app 'Foo.app'
          uninstall :quit => 'com.example.foo',
                    :kext => 'com.example.foo.kext'
        end
      CASK
    end
    let(:expected_offenses) do
      [{
        message:  "`url` stanza out of order",
        severity: :convention,
        line:     2,
        column:   2,
        source:   "url 'https://foo.example.com/foo.zip'",
      }, {
        message:  "`uninstall` stanza out of order",
        severity: :convention,
        line:     3,
        column:   2,
        source:   "uninstall :quit => 'com.example.foo',\n" \
                "            :kext => 'com.example.foo.kext'",
      }, {
        message:  "`version` stanza out of order",
        severity: :convention,
        line:     5,
        column:   2,
        source:   "version :latest",
      }, {
        message:  "`sha256` stanza out of order",
        severity: :convention,
        line:     7,
        column:   2,
        source:   "sha256 :no_check",
      }]
    end

    include_examples "reports offenses"

    include_examples "autocorrects source"
  end

  context "when a stanza appears multiple times" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          name 'Foo'
          url 'https://foo.example.com/foo.zip'
          name 'FancyFoo'
          version :latest
          app 'Foo.app'
          sha256 :no_check
          name 'FunkyFoo'
        end
      CASK
    end
    let(:correct_source) do
      <<-CASK.undent
        cask 'foo' do
          version :latest
          sha256 :no_check
          url 'https://foo.example.com/foo.zip'
          name 'Foo'
          name 'FancyFoo'
          name 'FunkyFoo'
          app 'Foo.app'
        end
      CASK
    end

    it "preserves the original order" do
      expect_autocorrected_source(source, correct_source)
    end
  end

  context "when a stanza has a comment" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          version :latest
          # comment with an empty line between

          # comment directly above
          postflight do
            puts 'We have liftoff!'
          end
          sha256 :no_check # comment on same line
        end
      CASK
    end
    let(:correct_source) do
      <<-CASK.undent
        cask 'foo' do
          version :latest
          sha256 :no_check # comment on same line
          # comment with an empty line between

          # comment directly above
          postflight do
            puts 'We have liftoff!'
          end
        end
      CASK
    end

    include_examples "autocorrects source"
  end

  context "when the caveats stanza is out of order" do
    let(:source) do
      format(<<-CASK.undent, caveats: caveats.strip)
        cask 'foo' do
          name 'Foo'
          url 'https://foo.example.com/foo.zip'
          %{caveats}
          version :latest
          app 'Foo.app'
          sha256 :no_check
        end
      CASK
    end
    let(:correct_source) do
      format(<<-CASK.undent, caveats: caveats.strip)
        cask 'foo' do
          version :latest
          sha256 :no_check
          url 'https://foo.example.com/foo.zip'
          name 'Foo'
          app 'Foo.app'
          %{caveats}
        end
      CASK
    end

    context "when caveats is a one-line string" do
      let(:caveats) { "caveats 'This is a one-line caveat.'" }

      include_examples "autocorrects source"
    end

    context "when caveats is a heredoc" do
      let(:caveats) do
        <<-CAVEATS.undent
          caveats <<-EOS.undent
              This is a multiline caveat.

              Let's hope it doesn't cause any problems!
            EOS
        CAVEATS
      end

      include_examples "autocorrects source"
    end

    context "when caveats is a block" do
      let(:caveats) do
        <<-CAVEATS.undent
          caveats do
              puts 'This is a multiline caveat.'

              puts "Let's hope it doesn't cause any problems!"
            end
        CAVEATS
      end

      include_examples "autocorrects source"
    end
  end

  context "when the postflight stanza is out of order" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          name 'Foo'
          url 'https://foo.example.com/foo.zip'
          postflight do
            puts 'We have liftoff!'
          end
          version :latest
          app 'Foo.app'
          sha256 :no_check
        end
      CASK
    end
    let(:correct_source) do
      <<-CASK.undent
        cask 'foo' do
          version :latest
          sha256 :no_check
          url 'https://foo.example.com/foo.zip'
          name 'Foo'
          app 'Foo.app'
          postflight do
            puts 'We have liftoff!'
          end
        end
      CASK
    end

    include_examples "autocorrects source"
  end

  # TODO: detect out-of-order stanzas in nested expressions
  context "when stanzas are nested in a conditional expression" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          if true
            sha256 :no_check
            version :latest
          end
        end
      CASK
    end

    include_examples "does not report any offenses"
  end
end

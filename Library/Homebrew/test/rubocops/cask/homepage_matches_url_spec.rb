require "rubocops/rubocop-cask"
require "test/rubocops/cask/shared_examples/cask_cop"

describe RuboCop::Cop::Cask::HomepageMatchesUrl do
  include CaskCop

  subject(:cop) { described_class.new }

  context "when the url matches the homepage and there is no comment" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          url 'https://foo.brew.sh/foo.zip'
          homepage 'https://foo.brew.sh'
        end
      CASK
    end

    include_examples "does not report any offenses"
  end

  context "when the url matches the homepage and the url stanza has " \
          "a referrer and no interpolation" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          url 'https://foo.brew.sh/foo.zip',
              referrer: 'https://brew.sh/foo/'
          homepage 'https://foo.brew.sh'
        end
      CASK
    end

    include_examples "does not report any offenses"
  end

  context "when the url matches the homepage and the url stanza has " \
          "a referrer and interpolation" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          version '1.8.0_72,8.13.0.5'
          url "https://foo.brew.sh/foo-\#{version.after_comma}-\#{version.minor}.\#{version.patch}.\#{version.before_comma.sub(\%r{.*_}, '')}.zip",
              referrer: 'https://brew.sh/foo/'
          homepage 'https://foo.brew.sh'
        end
      CASK
    end

    include_examples "does not report any offenses"
  end

  context "when the url matches the homepage but there is a comment " \
          "which does not match the url" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          # this is just a comment with information
          url 'https://brew.sh/foo.zip'
          homepage 'https://brew.sh'
        end
      CASK
    end

    include_examples "does not report any offenses"
  end

  context "when the url matches the homepage " \
          "but there is a comment matching the url" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          # foo.brew.sh was verified as official when first introduced to the cask
          url 'https://foo.brew.sh/foo.zip'
          homepage 'https://foo.brew.sh'
        end
      CASK
    end
    let(:expected_offenses) do
      [{
        message:  "The URL's domain `foo.brew.sh` matches the homepage " \
                 "`foo.brew.sh`, the comment above the `url` stanza is " \
                 "unnecessary",
        severity: :convention,
        line:     2,
        column:   2,
        source:   "# foo.brew.sh was verified as official when " \
                "first introduced to the cask",
      }]
    end

    include_examples "reports offenses"
  end

  context "when the url does not match the homepage" do
    context "when there is a comment matching the url " \
            "but not matching the expected format" do
      let(:source) do
        <<-CASK.undent
          cask 'foo' do
            # brew.sh was verified as official
            url 'https://brew.sh/foo.zip'
            homepage 'https://foo.example.org'
          end
        CASK
      end
      let(:expected_offenses) do
        [{
          message:  "`# brew.sh was verified as official` does not " \
                   "match the expected comment format. For details, see " \
                  "https://github.com/Homebrew/homebrew-cask/blob/master/doc/" \
                  "cask_language_reference/stanzas/url.md#when-url-and-homepage-hostnames-differ-add-a-comment",
          severity: :convention,
          line:     2,
          column:   2,
          source:   "# brew.sh was verified as official",
        }]
      end

      include_examples "reports offenses"
    end

    context "when there is a comment matching the url " \
            "and does not have slashes" do
      let(:source) do
        <<-CASK.undent
          cask 'foo' do
            # brew.sh was verified as official when first introduced to the cask
            url 'https://brew.sh/foo.zip'
            homepage 'https://foo.example.org'
          end
        CASK
      end

      include_examples "does not report any offenses"
    end

    context "when there is a comment matching the url and has slashes" do
      let(:source) do
        <<-CASK.undent
          cask 'foo' do
            # brew.sh/vendor/app was verified as official when first introduced to the cask
            url 'https://downloads.brew.sh/vendor/app/foo.zip'
            homepage 'https://vendor.example.org/app/'
          end
        CASK
      end

      include_examples "does not report any offenses"
    end

    context "when there is a comment which does not match the url" do
      let(:source) do
        <<-CASK.undent
          cask 'foo' do
            # brew.sh was verified as official when first introduced to the cask
            url 'https://example.org/foo.zip'
            homepage 'https://foo.brew.sh'
          end
        CASK
      end
      let(:expected_offenses) do
        [{
          message:  "`brew.sh` does not match `example.org/foo.zip`",
          severity: :convention,
          line:     2,
          column:   2,
          source:   "# brew.sh was verified as official when " \
                  "first introduced to the cask",
        }]
      end

      include_examples "reports offenses"
    end

    context "when the comment is missing" do
      let(:source) do
        <<-CASK.undent
          cask 'foo' do
            url 'https://brew.sh/foo.zip'
            homepage 'https://example.org'
          end
        CASK
      end
      let(:expected_offenses) do
        [{
          message:  "`brew.sh` does not match `example.org`, a comment " \
                   "has to be added above the `url` stanza. For details, see " \
                   "https://github.com/Homebrew/homebrew-cask/blob/master/doc/" \
                   "cask_language_reference/stanzas/url.md#when-url-and-homepage-hostnames-differ-add-a-comment",
          severity: :convention,
          line:     2,
          column:   2,
          source:   "url 'https://brew.sh/foo.zip'",
        }]
      end

      include_examples "reports offenses"
    end
  end

  context "when there is no homepage" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          url 'https://brew.sh/foo.zip'
        end
      CASK
    end

    include_examples "does not report any offenses"
  end
end

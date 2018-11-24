require "rubocops/rubocop-cask"
require "test/rubocops/cask/shared_examples/cask_cop"

describe RuboCop::Cop::Cask::HomepageUrlTrailingSlash do
  include CaskCop

  subject(:cop) { described_class.new }

  context "when the homepage url ends with a slash" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          homepage 'https://foo.example.com/'
        end
      CASK
    end

    include_examples "does not report any offenses"
  end

  context "when the homepage url does not end with a slash but has a path" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          homepage 'https://foo.example.com/path'
        end
      CASK
    end

    include_examples "does not report any offenses"
  end

  context "when the homepage url does not end with a slash and has no path" do
    let(:source) do
      <<-CASK.undent
        cask 'foo' do
          homepage 'https://foo.example.com'
        end
      CASK
    end
    let(:correct_source) do
      <<-CASK.undent
        cask 'foo' do
          homepage 'https://foo.example.com/'
        end
      CASK
    end
    let(:expected_offenses) do
      [{
        message:  "'https://foo.example.com' must have a slash "\
                 "after the domain.",
        severity: :convention,
        line:     2,
        column:   11,
        source:   "'https://foo.example.com'",
      }]
    end

    include_examples "reports offenses"

    include_examples "autocorrects source"
  end
end

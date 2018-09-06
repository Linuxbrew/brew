require "rubocops/homepage_cop"

describe RuboCop::Cop::FormulaAudit::Homepage do
  subject(:cop) { described_class.new }

  context "When auditing homepage" do
    it "When there is no homepage" do
      source = <<~RUBY
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
        end
      RUBY

      expected_offenses = [{  message: "Formula should have a homepage.",
                              severity: :convention,
                              line: 1,
                              column: 0,
                              source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "Homepage with ftp" do
      source = <<~RUBY
        class Foo < Formula
          homepage "ftp://example.com/foo"
          url "https://example.com/foo-1.0.tgz"
        end
      RUBY

      expected_offenses = [{  message: "The homepage should start with http or https (URL is ftp://example.com/foo).",
                              severity: :convention,
                              line: 2,
                              column: 2,
                              source: source }]

      inspect_source(source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "Homepage URLs" do
      formula_homepages = {
        "bar" => "http://www.freedesktop.org/wiki/bar",
        "baz" => "http://www.freedesktop.org/wiki/Software/baz",
        "qux" => "https://code.google.com/p/qux",
        "quux" => "http://github.com/quux",
        "corge" => "http://savannah.nongnu.org/corge",
        "grault" => "http://grault.github.io/",
        "garply" => "http://www.gnome.org/garply",
        "sf1" => "http://foo.sourceforge.net/",
        "sf2" => "http://foo.sourceforge.net",
        "sf3" => "http://foo.sf.net/",
        "sf4" => "http://foo.sourceforge.io/",
        "waldo" => "http://www.gnu.org/waldo",
      }

      formula_homepages.each do |name, homepage|
        source = <<~RUBY
          class #{name.capitalize} < Formula
            homepage "#{homepage}"
            url "https://example.com/#{name}-1.0.tgz"
          end
        RUBY

        inspect_source(source)
        if homepage =~ %r{http:\/\/www\.freedesktop\.org}
          if homepage =~ /Software/
            expected_offenses = [{  message: "#{homepage} should be styled " \
                                             "`https://wiki.freedesktop.org/www/Software/project_name`",
                                    severity: :convention,
                                    line: 2,
                                    column: 2,
                                    source: source }]
          else
            expected_offenses = [{  message:  "#{homepage} should be styled " \
                                              "`https://wiki.freedesktop.org/project_name`",
                                    severity: :convention,
                                    line: 2,
                                    column: 2,
                                    source: source }]
          end
        elsif homepage =~ %r{https:\/\/code\.google\.com}
          expected_offenses = [{  message:  "#{homepage} should end with a slash",
                                  severity: :convention,
                                  line: 2,
                                  column: 2,
                                  source: source }]
        elsif homepage =~ /foo\.(sf|sourceforge)\.net/
          expected_offenses = [{  message:  "#{homepage} should be `https://foo.sourceforge.io/`",
                                  severity: :convention,
                                  line: 2,
                                  column: 2,
                                  source: source }]
        else
          expected_offenses = [{  message:  "Please use https:// for #{homepage}",
                                  severity: :convention,
                                  line: 2,
                                  column: 2,
                                  source: source }]
        end
        expected_offenses.zip([cop.offenses.last]).each do |expected, actual|
          expect_offense(expected, actual)
        end
      end
    end

    def expect_offense(expected, actual)
      expect(actual.message).to eq(expected[:message])
      expect(actual.severity).to eq(expected[:severity])
      expect(actual.line).to eq(expected[:line])
      expect(actual.column).to eq(expected[:column])
    end
  end
end

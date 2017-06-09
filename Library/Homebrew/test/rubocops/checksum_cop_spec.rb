require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/checksum_cop"

describe RuboCop::Cop::FormulaAudit::Checksum do
  subject(:cop) { described_class.new }

  context "When auditing spec checksums" do
    it "When the checksum is empty" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          stable do
            url "https://github.com/foo-lang/foo-compiler/archive/0.18.0.tar.gz"
            sha256 ""

            resource "foo-package" do
              url "https://github.com/foo-lang/foo-package/archive/0.18.0.tar.gz"
              sha256 ""
            end
          end
        end
      EOS

      expected_offenses = [{  message: "Stable: sha256 is empty",
                              severity: :convention,
                              line: 5,
                              column: 4,
                              source: source },
                           {  message: "Stable resource \"foo-package\": sha256 is empty",
                              severity: :convention,
                              line: 9,
                              column: 6,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "When the checksum is not 64 characters" do
      source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          stable do
            url "https://github.com/foo-lang/foo-compiler/archive/0.18.0.tar.gz"
            sha256 "5cf6e1ae0a645b426c0474cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea0e9ad"

            resource "foo-package" do
              url "https://github.com/foo-lang/foo-package/archive/0.18.0.tar.gz"
              sha256 "5cf6e1ae0a645b426c047aaa4cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea0e9"
            end
          end
        end
      EOS

      expected_offenses = [{  message: "Stable: sha256 should be 64 characters",
                              severity: :convention,
                              line: 5,
                              column: 12,
                              source: source },
                           {  message: "Stable resource \"foo-package\": sha256 should be 64 characters",
                              severity: :convention,
                              line: 9,
                              column: 14,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
  end
end

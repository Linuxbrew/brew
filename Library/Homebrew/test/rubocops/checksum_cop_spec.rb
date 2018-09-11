require "rubocops/checksum_cop"

describe RuboCop::Cop::FormulaAudit::Checksum do
  subject(:cop) { described_class.new }

  context "When auditing spec checksums" do
    it "When the checksum is empty" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          stable do
            url "https://github.com/foo-lang/foo-compiler/archive/0.18.0.tar.gz"
            sha256 ""
                   ^^ sha256 is empty

            resource "foo-package" do
              url "https://github.com/foo-lang/foo-package/archive/0.18.0.tar.gz"
              sha256 ""
                     ^^ sha256 is empty
            end
          end
        end
      RUBY
    end

    it "When the checksum is not 64 characters" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          stable do
            url "https://github.com/foo-lang/foo-compiler/archive/0.18.0.tar.gz"
            sha256 "5cf6e1ae0a645b426c0474cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea0e9ad"
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ sha256 should be 64 characters

            resource "foo-package" do
              url "https://github.com/foo-lang/foo-package/archive/0.18.0.tar.gz"
              sha256 "5cf6e1ae0a645b426c047aaa4cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea0e9"
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ sha256 should be 64 characters
            end
          end
        end
      RUBY
    end

    it "When the checksum has invalid chars" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          stable do
            url "https://github.com/foo-lang/foo-compiler/archive/0.18.0.tar.gz"
            sha256 "5cf6e1ae0a645b426c0k7cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea0e9a"
                                       ^ sha256 contains invalid characters

            resource "foo-package" do
              url "https://github.com/foo-lang/foo-package/archive/0.18.0.tar.gz"
              sha256 "5cf6e1ae0a645b426x047aa4cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea9"
                                       ^ sha256 contains invalid characters
            end
          end
        end
      RUBY
    end
  end
end

describe RuboCop::Cop::FormulaAudit::ChecksumCase do
  subject(:cop) { described_class.new }

  context "When auditing spec checksums" do
    it "When the checksum has upper case characters" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          stable do
            url "https://github.com/foo-lang/foo-compiler/archive/0.18.0.tar.gz"
            sha256 "5cf6e1ae0A645b426c0a7cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea0e9a"
                             ^ sha256 should be lowercase

            resource "foo-package" do
              url "https://github.com/foo-lang/foo-package/archive/0.18.0.tar.gz"
              sha256 "5cf6e1Ae0a645b426b047aa4cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea9"
                            ^ sha256 should be lowercase
            end
          end
        end
      RUBY
    end

    it "When auditing stable blocks outside spec blocks" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          resource "foo-outside" do
            url "https://github.com/foo-lang/foo-outside/archive/0.18.0.tar.gz"
            sha256 "A4cc7cd3f7d1605ffa1ac5755cf6e1ae0a645b426b047a6a39a8b2268ddc7ea9"
                    ^ sha256 should be lowercase
          end
          stable do
            url "https://github.com/foo-lang/foo-compiler/archive/0.18.0.tar.gz"
            sha256 "5cf6e1ae0a645b426c0a7cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea0e9a"

            resource "foo-package" do
              url "https://github.com/foo-lang/foo-package/archive/0.18.0.tar.gz"
              sha256 "5cf6e1ae0a645b426b047aa4cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea9"
            end
          end
        end
      RUBY
    end
  end

  context "When auditing checksum with autocorrect" do
    it "When there is uppercase sha256" do
      source = <<~RUBY
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          stable do
            url "https://github.com/foo-lang/foo-compiler/archive/0.18.0.tar.gz"
            sha256 "5cf6e1ae0A645b426c0a7cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea0e9a"

            resource "foo-package" do
              url "https://github.com/foo-lang/foo-package/archive/0.18.0.tar.gz"
              sha256 "5cf6e1Ae0a645b426b047aa4cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea9"
            end
          end
        end
      RUBY

      corrected_source = <<~RUBY
        class Foo < Formula
          url 'https://example.com/foo-1.0.tgz'
          stable do
            url "https://github.com/foo-lang/foo-compiler/archive/0.18.0.tar.gz"
            sha256 "5cf6e1ae0a645b426c0a7cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea0e9a"

            resource "foo-package" do
              url "https://github.com/foo-lang/foo-package/archive/0.18.0.tar.gz"
              sha256 "5cf6e1ae0a645b426b047aa4cc7cd3f7d1605ffa1ac5756a39a8b2268ddc7ea9"
            end
          end
        end
      RUBY

      new_source = autocorrect_source(source)
      expect(new_source).to eq(corrected_source)
    end
  end
end

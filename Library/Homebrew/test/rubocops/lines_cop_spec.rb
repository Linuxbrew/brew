require "rubocop"
require "rubocop/rspec/support"
require_relative "../../extend/string"
require_relative "../../rubocops/lines_cop"

describe RuboCop::Cop::FormulaAudit::Lines do
  subject(:cop) { described_class.new }

  context "When auditing lines" do
    it "with correctable deprecated dependencies" do
      formulae = [{
        "dependency" => :automake,
        "correct"    => "automake",
      }, {
        "dependency" => :autoconf,
        "correct"    => "autoconf",
      }, {
        "dependency" => :libtool,
        "correct"    => "libtool",
      }, {
        "dependency" => :apr,
        "correct"    => "apr-util",
      }, {
        "dependency" => :tex,
      }]

      formulae.each do |formula|
        source = <<-EOS.undent
        class Foo < Formula
          url 'http://example.com/foo-1.0.tgz'
          depends_on :#{formula["dependency"]}
        end
        EOS
        if formula.key?("correct")
          offense = ":#{formula["dependency"]} is deprecated. Usage should be \"#{formula["correct"]}\""
        else
          offense = ":#{formula["dependency"]} is deprecated"
        end
        expected_offenses = [{  message: offense,
                                severity: :convention,
                                line: 3,
                                column: 2,
                                source: source }]

        inspect_source(cop, source)

        expected_offenses.zip(cop.offenses.reverse).each do |expected, actual|
          expect_offense(expected, actual)
        end
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

describe RuboCop::Cop::FormulaAudit::ClassInheritance do
  subject(:cop) { described_class.new }

  context "When auditing lines" do
    it "with no space in class inheritance" do
      source = <<-EOS.undent
        class Foo<Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
        end
      EOS

      expected_offenses = [{  message: "Use a space in class inheritance: class Foo < Formula",
                              severity: :convention,
                              line: 1,
                              column: 10,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
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

describe RuboCop::Cop::FormulaAudit::Comments do
  subject(:cop) { described_class.new }

  context "When auditing formula" do
    it "with commented cmake call" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          # system "cmake", ".", *std_cmake_args
        end
      EOS

      expected_offenses = [{  message: "Commented cmake call found",
                              severity: :convention,
                              line: 4,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with default template comments" do
      source = <<-EOS.undent
        class Foo < Formula
          # PLEASE REMOVE
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
        end
      EOS

      expected_offenses = [{  message: "Please remove default template comments",
                              severity: :convention,
                              line: 2,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with commented out depends_on" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          # depends_on "foo"
        end
      EOS

      expected_offenses = [{  message: 'Commented-out dep "foo"',
                              severity: :convention,
                              line: 4,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
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

describe RuboCop::Cop::FormulaAudit::Miscellaneous do
  subject(:cop) { described_class.new }

  context "When auditing formula" do
    it "with FileUtils" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          FileUtils.mv "hello"
        end
      EOS

      expected_offenses = [{  message: "Don't need 'FileUtils.' before mv",
                              severity: :convention,
                              line: 4,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with long inreplace block vars" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          inreplace "foo" do |longvar|
            somerandomCall(longvar)
          end
        end
      EOS

      expected_offenses = [{  message: "\"inreplace <filenames> do |s|\" is preferred over \"|longvar|\".",
                              severity: :convention,
                              line: 4,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with invalid rebuild" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          bottle do
            rebuild 0
            sha256 "fe0679b932dd43a87fd415b609a7fbac7a069d117642ae8ebaac46ae1fb9f0b3" => :sierra
          end
        end
      EOS

      expected_offenses = [{  message: "'rebuild 0' should be removed",
                              severity: :convention,
                              line: 5,
                              column: 4,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with OS.linux? check" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          bottle do
            if OS.linux?
              nil
            end
            sha256 "fe0679b932dd43a87fd415b609a7fbac7a069d117642ae8ebaac46ae1fb9f0b3" => :sierra
          end
        end
      EOS

      expected_offenses = [{  message: "Don't use OS.linux?; Homebrew/core only supports macOS",
                              severity: :convention,
                              line: 5,
                              column: 7,
                              source: source }]

      inspect_source(cop, source, "/homebrew-core/")

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with fails_with :llvm" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          bottle do
            sha256 "fe0679b932dd43a87fd415b609a7fbac7a069d117642ae8ebaac46ae1fb9f0b3" => :sierra
          end
          fails_with :llvm do
            build 2335
            cause "foo"
          end
        end
      EOS

      expected_offenses = [{  message: "'fails_with :llvm' is now a no-op so should be removed",
                              severity: :convention,
                              line: 7,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with def test" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'

          def test
            assert_equals "1", "1"
          end
        end
      EOS

      expected_offenses = [{  message: "Use new-style test definitions (test do)",
                              severity: :convention,
                              line: 5,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with def options" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'

          def options
            [["--bar", "desc"]]
          end
        end
      EOS

      expected_offenses = [{  message: "Use new-style option definitions",
                              severity: :convention,
                              line: 5,
                              column: 2,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with deprecated skip_clean call" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          skip_clean :all
        end
      EOS

      expected_offenses = [{ message: "`skip_clean :all` is deprecated; brew no longer strips symbols\n" \
                                      "\tPass explicit paths to prevent Homebrew from removing empty folders.",
                             severity: :convention,
                             line: 4,
                             column: 2,
                             source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with build.universal?" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          if build.universal?
             "foo"
          end
        end
      EOS

      expected_offenses = [{  message: "macOS has been 64-bit only so build.universal? is deprecated.",
                              severity: :convention,
                              line: 4,
                              column: 5,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with ENV.universal_binary" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          if build?
             ENV.universal_binary
          end
        end
      EOS

      expected_offenses = [{  message: "macOS has been 64-bit only since 10.6 so ENV.universal_binary is deprecated.",
                              severity: :convention,
                              line: 5,
                              column: 5,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with ENV.universal_binary" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          if build?
             ENV.x11
          end
        end
      EOS

      expected_offenses = [{  message: 'Use "depends_on :x11" instead of "ENV.x11"',
                              severity: :convention,
                              line: 5,
                              column: 5,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with ruby-macho alternatives" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          system "install_name_tool", "-id"
        end
      EOS

      expected_offenses = [{  message: 'Use ruby-macho instead of calling "install_name_tool"',
                              severity: :convention,
                              line: 4,
                              column: 10,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with npm install without language::Node args" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          system "npm", "install"
        end
      EOS

      expected_offenses = [{  message: "Use Language::Node for npm install args",
                              severity: :convention,
                              line: 4,
                              column: 17,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with assert include" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          assert File.read("inbox").include?("Sample message 1")
        end
      EOS

      expected_offenses = [{  message: "Use `assert_match` instead of `assert ...include?`",
                              severity: :convention,
                              line: 4,
                              column: 9,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "depends_on with an instance as an argument" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          depends_on FOO::BAR.new
        end
      EOS

      expected_offenses = [{  message: "`depends_on` can take requirement classes instead of instances",
                              severity: :convention,
                              line: 4,
                              column: 13,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
    it "with old style OS check" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          depends_on :foo if MacOS.snow_leopard?
        end
      EOS

      expected_offenses = [{  message: "\"MacOS.snow_leopard?\" is deprecated, use a comparison to MacOS.version instead",
                              severity: :convention,
                              line: 4,
                              column: 21,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with non glob DIR" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          rm_rf Dir["src/{llvm,test,librustdoc,etc/snapshot.pyc}"]
          rm_rf Dir["src/snapshot.pyc"]
        end
      EOS

      expected_offenses = [{  message: "Dir([\"src/snapshot.pyc\"]) is unnecessary; just use \"src/snapshot.pyc\"",
                              severity: :convention,
                              line: 5,
                              column: 13,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
    it "with system call to fileUtils Method" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          system "mkdir", "foo"
        end
      EOS

      expected_offenses = [{  message: "Use the `mkdir` Ruby method instead of `system \"mkdir\", \"foo\"`",
                              severity: :convention,
                              line: 4,
                              column: 10,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end
    it "with a top-level function def " do
      source = <<-EOS.undent
        def test
           nil
        end
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
        end
      EOS

      expected_offenses = [{  message: "Define method test in the class body, not at the top-level",
                              severity: :convention,
                              line: 1,
                              column: 0,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with unless build.without?" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def post_install
            return unless build.without? "bar"
          end
        end
      EOS

      expected_offenses = [{  message: 'Use if build.with? "bar" instead of unless build.without? "bar"',
                              severity: :convention,
                              line: 5,
                              column: 18,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with unless build.with?" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def post_install
            return unless build.with? "bar"
          end
        end
      EOS

      expected_offenses = [{  message: 'Use if build.without? "bar" instead of unless build.with? "bar"',
                              severity: :convention,
                              line: 5,
                              column: 18,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with negated build.with?" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def post_install
            return if !build.with? "bar"
          end
        end
      EOS

      expected_offenses = [{  message: "Don't negate 'build.with?': use 'build.without?'",
                              severity: :convention,
                              line: 5,
                              column: 14,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
        expect_offense(expected, actual)
      end
    end

    it "with negated build.with?" do
      source = <<-EOS.undent
        class Foo < Formula
          desc "foo"
          url 'http://example.com/foo-1.0.tgz'
          def post_install
            return if !build.without? "bar"
          end
        end
      EOS

      expected_offenses = [{  message: "Don't negate 'build.without?': use 'build.with?'",
                              severity: :convention,
                              line: 5,
                              column: 14,
                              source: source }]

      inspect_source(cop, source)

      expected_offenses.zip(cop.offenses).each do |expected, actual|
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

require "rubocops/lines"

describe RuboCop::Cop::FormulaAudit::Lines do
  subject(:cop) { described_class.new }

  it "reports an offense when using depends_on :automake" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        url 'https://example.com/foo-1.0.tgz'
        depends_on :automake
        ^^^^^^^^^^^^^^^^^^^^ :automake is deprecated. Usage should be \"automake\".
      end
    RUBY
  end

  it "reports an offense when using depends_on :autoconf" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        url 'https://example.com/foo-1.0.tgz'
        depends_on :autoconf
        ^^^^^^^^^^^^^^^^^^^^ :autoconf is deprecated. Usage should be \"autoconf\".
      end
    RUBY
  end

  it "reports an offense when using depends_on :libtool" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        url 'https://example.com/foo-1.0.tgz'
        depends_on :libtool
        ^^^^^^^^^^^^^^^^^^^ :libtool is deprecated. Usage should be \"libtool\".
      end
    RUBY
  end

  it "reports an offense when using depends_on :apr" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        url 'https://example.com/foo-1.0.tgz'
        depends_on :apr
        ^^^^^^^^^^^^^^^ :apr is deprecated. Usage should be \"apr-util\".
      end
    RUBY
  end

  it "reports an offense when using depends_on :tex" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        url 'https://example.com/foo-1.0.tgz'
        depends_on :tex
        ^^^^^^^^^^^^^^^ :tex is deprecated.
      end
    RUBY
  end
end

describe RuboCop::Cop::FormulaAudit::ClassInheritance do
  subject(:cop) { described_class.new }

  it "reports an offense when not using spaces for class inheritance" do
    expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
      class Foo<Formula
                ^^^^^^^ Use a space in class inheritance: class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'
      end
    RUBY
  end
end

describe RuboCop::Cop::FormulaAudit::Comments do
  subject(:cop) { described_class.new }

  context "When auditing formula" do
    it "commented cmake call" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          # system "cmake", ".", *std_cmake_args
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Please remove default template comments
        end
      RUBY
    end

    it "default template comments" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          # PLEASE REMOVE
          ^^^^^^^^^^^^^^^ Please remove default template comments
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
        end
      RUBY
    end

    it "commented out depends_on" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          # depends_on "foo"
          ^^^^^^^^^^^^^^^^^^ Commented-out dependency "foo"
        end
      RUBY
    end
  end
end

describe RuboCop::Cop::FormulaAudit::AssertStatements do
  subject(:cop) { described_class.new }

  it "assert ...include usage" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'
        assert File.read("inbox").include?("Sample message 1")
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `assert_match` instead of `assert ...include?`
      end
    RUBY
  end

  it "assert ...exist? without a negation" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'
        assert File.exist? "default.ini"
               ^^^^^^^^^^^^^^^^^^^^^^^^^ Use `assert_predicate <path_to_file>, :exist?` instead of `assert File.exist? "default.ini"`
      end
    RUBY
  end

  it "assert ...exist? with a negation" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'
        assert !File.exist?("default.ini")
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `refute_predicate <path_to_file>, :exist?` instead of `assert !File.exist?("default.ini")`
      end
    RUBY
  end

  it "assert ...executable? without a negation" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'
        assert File.executable? f
               ^^^^^^^^^^^^^^^^^^ Use `assert_predicate <path_to_file>, :executable?` instead of `assert File.executable? f`
      end
    RUBY
  end
end

describe RuboCop::Cop::FormulaAudit::OptionDeclarations do
  subject(:cop) { described_class.new }

  it "unless build.without? conditional" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'
        def post_install
          return unless build.without? "bar"
                        ^^^^^^^^^^^^^^^^^^^^ Use if build.with? "bar" instead of unless build.without? "bar"
        end
      end
    RUBY
  end

  it "unless build.with? conditional" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'
        def post_install
          return unless build.with? "bar"
                        ^^^^^^^^^^^^^^^^^ Use if build.without? "bar" instead of unless build.with? "bar"
        end
      end
    RUBY
  end

  it "negated build.with? conditional" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'
        def post_install
          return if !build.with? "bar"
                    ^^^^^^^^^^^^^^^^^^ Don't negate 'build.with?': use 'build.without?'
        end
      end
    RUBY
  end

  it "negated build.without? conditional" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'
        def post_install
          return if !build.without? "bar"
                    ^^^^^^^^^^^^^^^^^^^^^ Don't negate 'build.without?': use 'build.with?'
        end
      end
    RUBY
  end

  it "unnecessary build.without? conditional" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'
        def post_install
          return if build.without? "--without-bar"
                                    ^^^^^^^^^^^^^ Don't duplicate 'without': Use `build.without? \"bar\"` to check for \"--without-bar\"
        end
      end
    RUBY
  end

  it "unnecessary build.with? conditional" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'
        def post_install
          return if build.with? "--with-bar"
                                 ^^^^^^^^^^ Don't duplicate 'with': Use `build.with? \"bar\"` to check for \"--with-bar\"
        end
      end
    RUBY
  end

  it "build.include? conditional" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'
        def post_install
          return if build.include? "without-bar"
                                    ^^^^^^^^^^^ Use build.without? \"bar\" instead of build.include? 'without-bar'
        end
      end
    RUBY
  end

  it "build.include? with dashed args conditional" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'
        def post_install
          return if build.include? "--bar"
                                    ^^^^^ Reference 'bar' without dashes
        end
      end
    RUBY
  end

  it "def options usage" do
    expect_offense(<<~RUBY)
      class Foo < Formula
        desc "foo"
        url 'https://example.com/foo-1.0.tgz'

        def options
        ^^^^^^^^^^^ Use new-style option definitions
          [["--bar", "desc"]]
        end
      end
    RUBY
  end
end

describe RuboCop::Cop::FormulaAudit::Miscellaneous do
  subject(:cop) { described_class.new }

  context "When auditing formula" do
    it "FileUtils usage" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          FileUtils.mv "hello"
          ^^^^^^^^^^^^^^^^^^^^ Don\'t need \'FileUtils.\' before mv
        end
      RUBY
    end

    it "long inreplace block vars" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          inreplace "foo" do |longvar|
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ \"inreplace <filenames> do |s|\" is preferred over \"|longvar|\".
            somerandomCall(longvar)
          end
        end
      RUBY
    end

    it "an invalid rebuild statement" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          bottle do
            rebuild 0
            ^^^^^^^^^ 'rebuild 0' should be removed
            sha256 "fe0679b932dd43a87fd415b609a7fbac7a069d117642ae8ebaac46ae1fb9f0b3" => :sierra
          end
        end
      RUBY
    end

    it "OS.linux? check" do
      expect_offense(<<~RUBY, "/homebrew-core/")
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          bottle do
            if OS.linux?
               ^^^^^^^^^ Don\'t use OS.linux?; Homebrew/core only supports macOS
              nil
            end
            sha256 "fe0679b932dd43a87fd415b609a7fbac7a069d117642ae8ebaac46ae1fb9f0b3" => :sierra
          end
        end
      RUBY
    end

    it "fails_with :llvm block" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          bottle do
            sha256 "fe0679b932dd43a87fd415b609a7fbac7a069d117642ae8ebaac46ae1fb9f0b3" => :sierra
          end
          fails_with :llvm do
          ^^^^^^^^^^^^^^^^ 'fails_with :llvm' is now a no-op so should be removed
            build 2335
            cause "foo"
          end
        end
      RUBY
    end

    it "def test's deprecated usage" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'

          def test
          ^^^^^^^^ Use new-style test definitions (test do)
            assert_equals "1", "1"
          end
        end
      RUBY
    end

    it "with deprecated skip_clean call" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          skip_clean :all
          ^^^^^^^^^^^^^^^ `skip_clean :all` is deprecated; brew no longer strips symbols. Pass explicit paths to prevent Homebrew from removing empty folders.
        end
      RUBY
    end

    it "build.universal? deprecated usage" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          if build.universal?
             ^^^^^^^^^^^^^^^^ macOS has been 64-bit only since 10.6 so build.universal? is deprecated.
             "foo"
          end
        end
      RUBY
    end

    it "build.universal? deprecation exempted formula" do
      expect_no_offenses(<<~RUBY, "/homebrew-core/Formula/wine.rb")
        class Wine < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          if build.universal?
             "foo"
          end
        end
      RUBY
    end

    it "deprecated ENV.universal_binary usage" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          if build?
             ENV.universal_binary
             ^^^^^^^^^^^^^^^^^^^^ macOS has been 64-bit only since 10.6 so ENV.universal_binary is deprecated.
          end
        end
      RUBY
    end

    it "ENV.universal_binary deprecation exempted formula" do
      expect_no_offenses(<<~RUBY, "/homebrew-core/Formula/wine.rb")
        class Wine < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          if build?
            ENV.universal_binary
          end
        end
      RUBY
    end

    it "deprecated ENV.x11 usage" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          if build?
             ENV.x11
             ^^^^^^^ Use "depends_on :x11" instead of "ENV.x11"
          end
        end
      RUBY
    end

    it "install_name_tool usage instead of ruby-macho" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          system "install_name_tool", "-id"
                  ^^^^^^^^^^^^^^^^^ Use ruby-macho instead of calling "install_name_tool"
        end
      RUBY
    end

    it "ruby-macho alternatives audit exempted formula" do
      expect_no_offenses(<<~RUBY, "/homebrew-core/Formula/cctools.rb")
        class Cctools < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          system "install_name_tool", "-id"
        end
      RUBY
    end

    it "npm install without language::Node args" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          system "npm", "install"
          ^^^^^^^^^^^^^^^^^^^^^^^ Use Language::Node for npm install args
        end
      RUBY
    end

    it "npm install without language::Node args in kibana(exempted formula)" do
      expect_no_offenses(<<~RUBY, "/homebrew-core/Formula/kibana@4.4.rb")
        class KibanaAT44 < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          system "npm", "install"
        end
      RUBY
    end

    it "depends_on with an instance as argument" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          depends_on FOO::BAR.new
                     ^^^^^^^^^^^^ `depends_on` can take requirement classes instead of instances
        end
      RUBY
    end

    it "old style OS check" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          depends_on :foo if MacOS.snow_leopard?
                             ^^^^^^^^^^^^^^^^^^^ \"MacOS.snow_leopard?\" is deprecated, use a comparison to MacOS.version instead
        end
      RUBY
    end

    it "non glob DIR usage" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          rm_rf Dir["src/{llvm,test,librustdoc,etc/snapshot.pyc}"]
          rm_rf Dir["src/snapshot.pyc"]
                     ^^^^^^^^^^^^^^^^ Dir(["src/snapshot.pyc"]) is unnecessary; just use "src/snapshot.pyc"
        end
      RUBY
    end

    it "system call to fileUtils Method" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          system "mkdir", "foo"
                  ^^^^^ Use the `mkdir` Ruby method instead of `system "mkdir", "foo"`
        end
      RUBY
    end

    it "top-level function def outside class body" do
      expect_offense(<<~RUBY)
        def test
        ^^^^^^^^ Define method test in the class body, not at the top-level
           nil
        end
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
        end
      RUBY
    end

    it "Using ARGV to check options" do
      expect_no_offenses(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          def install
            verbose = ARGV.verbose?
          end
        end
      RUBY
    end

    it 'man+"man8" usage' do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          def install
            man1.install man+"man8" => "faad.1"
                              ^^^^ "man+"man8"" should be "man8"
          end
        end
      RUBY
    end

    it "hardcoded gcc compiler system" do
      expect_offense(<<~'RUBY')
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          def install
            system "/usr/bin/gcc", "foo"
                    ^^^^^^^^^^^^ Use "#{ENV.cc}" instead of hard-coding "gcc"
          end
        end
      RUBY
    end

    it "hardcoded g++ compiler system" do
      expect_offense(<<~'RUBY')
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          def install
            system "/usr/bin/g++", "-o", "foo", "foo.cc"
                    ^^^^^^^^^^^^ Use "#{ENV.cxx}" instead of hard-coding "g++"
          end
        end
      RUBY
    end

    it "hardcoded llvm-g++ compiler COMPILER_PATH" do
      expect_offense(<<~'RUBY')
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          def install
            ENV["COMPILER_PATH"] = "/usr/bin/llvm-g++"
                                    ^^^^^^^^^^^^^^^^^ Use "#{ENV.cxx}" instead of hard-coding "llvm-g++"
          end
        end
      RUBY
    end

    it "hardcoded gcc compiler COMPILER_PATH" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          def install
            ENV["COMPILER_PATH"] = "/usr/bin/gcc"
                                    ^^^^^^^^^^^^ Use \"\#{ENV.cc}\" instead of hard-coding \"gcc\"
          end
        end
      RUBY
    end

    it "formula path shortcut : man" do
      expect_offense(<<~'RUBY')
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          def install
            mv "#{share}/man", share
                         ^^^^ "#{share}/man" should be "#{man}"
          end
        end
      RUBY
    end

    it "formula path shortcut : libexec" do
      expect_offense(<<~'RUBY')
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          def install
            mv "#{prefix}/libexec", share
                          ^^^^^^^^ "#{prefix}/libexec" should be "#{libexec}"
          end
        end
      RUBY
    end

    it "formula path shortcut : info" do
      expect_offense(<<~'RUBY')
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          def install
            system "./configure", "--INFODIR=#{prefix}/share/info"
                                                       ^^^^^^ "#{prefix}/share" should be "#{share}"
                                                       ^^^^^^^^^^^ "#{prefix}/share/info" should be "#{info}"
          end
        end
      RUBY
    end

    it "formula path shortcut : man8" do
      expect_offense(<<~'RUBY')
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          def install
            system "./configure", "--MANDIR=#{prefix}/share/man/man8"
                                                      ^^^^^^ "#{prefix}/share" should be "#{share}"
                                                      ^^^^^^^^^^^^^^^ "#{prefix}/share/man/man8" should be "#{man8}"
          end
        end
      RUBY
    end

    it "dependecies which have to vendored" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          depends_on "lpeg" => :lua51
                                ^^^^^ lua modules should be vendored rather than use deprecated depends_on \"lpeg\" => :lua51`
        end
      RUBY
    end

    it "manually setting env" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          system "export", "var=value"
                  ^^^^^^ Use ENV instead of invoking 'export' to modify the environment
        end
      RUBY
    end

    it "dependencies with invalid options which lead to force rebuild" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          depends_on "foo" => "with-bar"
                               ^^^^^^^^ Dependency foo should not use option with-bar
        end
      RUBY
    end

    it "dependencies with invalid options in array value which lead to force rebuild" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          depends_on "httpd" => [:build, :test]
          depends_on "foo" => [:optional, "with-bar"]
                                           ^^^^^^^^ Dependency foo should not use option with-bar
          depends_on "icu4c" => [:optional, "c++11"]
                                             ^^^^^ Dependency icu4c should not use option c++11
        end
      RUBY
    end

    it "inspecting version manually" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          if version == "HEAD"
             ^^^^^^^^^^^^^^^^^ Use 'build.head?' instead of inspecting 'version'
            foo()
          end
        end
      RUBY
    end

    it "deprecated ARGV.include? (--HEAD) usage" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          test do
            head = ARGV.include? "--HEAD"
                                  ^^^^^^ Use "if build.head?" instead
                   ^^^^ Use build instead of ARGV to check options
          end
        end
      RUBY
    end

    it "deprecated needs :openmp usage" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          needs :openmp
          ^^^^^^^^^^^^^ 'needs :openmp' should be replaced with 'depends_on \"gcc\"'
        end
      RUBY
    end

    it "deprecated MACOS_VERSION const usage" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          test do
            version = MACOS_VERSION
                      ^^^^^^^^^^^^^ Use MacOS.version instead of MACOS_VERSION
          end
        end
      RUBY
    end

    it "deprecated if build.with? conditional dependency" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          depends_on "foo" if build.with? "foo"
          ^^^^^^^^^^^^^^^^ Replace depends_on "foo" if build.with? "foo" with depends_on "foo" => :optional
        end
      RUBY
    end

    it "unless conditional dependency with build.without?" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          depends_on :foo unless build.without? "foo"
          ^^^^^^^^^^^^^^^ Replace depends_on :foo unless build.without? "foo" with depends_on :foo => :recommended
        end
      RUBY
    end

    it "unless conditional dependency with build.include?" do
      expect_offense(<<~RUBY)
        class Foo < Formula
          desc "foo"
          url 'https://example.com/foo-1.0.tgz'
          depends_on :foo unless build.include? "without-foo"
          ^^^^^^^^^^^^^^^ Replace depends_on :foo unless build.include? "without-foo" with depends_on :foo => :recommended
        end
      RUBY
    end
  end
end

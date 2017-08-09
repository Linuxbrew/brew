#:  * `create` <URL> [`--autotools`|`--cmake`|`--meson`] [`--no-fetch`] [`--set-name` <name>] [`--set-version` <version>] [`--tap` <user>`/`<repo>]:
#:    Generate a formula for the downloadable file at <URL> and open it in the editor.
#:    Homebrew will attempt to automatically derive the formula name
#:    and version, but if it fails, you'll have to make your own template. The `wget`
#:    formula serves as a simple example. For the complete API have a look at
#:    <http://www.rubydoc.info/github/Homebrew/brew/master/Formula>.
#:
#:    If `--autotools` is passed, create a basic template for an Autotools-style build.
#:    If `--cmake` is passed, create a basic template for a CMake-style build.
#:    If `--meson` is passed, create a basic template for a Meson-style build.
#:
#:    If `--no-fetch` is passed, Homebrew will not download <URL> to the cache and
#:    will thus not add the SHA256 to the formula for you. It will also not check
#:    the GitHub API for GitHub projects (to fill out the description and homepage).
#:
#:    The options `--set-name` and `--set-version` each take an argument and allow
#:    you to explicitly set the name and version of the package you are creating.
#:
#:    The option `--tap` takes a tap as its argument and generates the formula in
#:    the specified tap.

require "formula"
require "missing_formula"
require "digest"
require "erb"

module Homebrew
  module_function

  # Create a formula from a tarball URL
  def create
    raise UsageError if ARGV.named.empty?

    # Ensure that the cache exists so we can fetch the tarball
    HOMEBREW_CACHE.mkpath

    url = ARGV.named.first # Pull the first (and only) url from ARGV

    version = ARGV.next if ARGV.include? "--set-version"
    name = ARGV.next if ARGV.include? "--set-name"
    tap = ARGV.next if ARGV.include? "--tap"

    fc = FormulaCreator.new
    fc.name = name
    fc.version = version
    fc.tap = Tap.fetch(tap || "homebrew/core")
    raise TapUnavailableError, tap unless fc.tap.installed?
    fc.url = url

    fc.mode = if ARGV.include? "--cmake"
      :cmake
    elsif ARGV.include? "--autotools"
      :autotools
    elsif ARGV.include? "--meson"
      :meson
    end

    if fc.name.nil? || fc.name.strip.empty?
      stem = Pathname.new(url).stem
      print "Formula name [#{stem}]: "
      fc.name = __gets || stem
      fc.update_path
    end

    # Don't allow blacklisted formula, or names that shadow aliases,
    # unless --force is specified.
    unless ARGV.force?
      if reason = Homebrew::MissingFormula.blacklisted_reason(fc.name)
        raise "#{fc.name} is blacklisted for creation.\n#{reason}\nIf you really want to create this formula use --force."
      end

      if Formula.aliases.include? fc.name
        realname = Formulary.canonical_name(fc.name)
        raise <<-EOS.undent
          The formula #{realname} is already aliased to #{fc.name}
          Please check that you are not creating a duplicate.
          To force creation use --force.
          EOS
      end
    end

    fc.generate!

    puts "Please `brew audit --new-formula #{fc.name}` before submitting, thanks."
    exec_editor fc.path
  end

  def __gets
    gots = $stdin.gets.chomp
    gots.empty? ? nil : gots
  end
end

class FormulaCreator
  attr_reader :url, :sha256, :desc, :homepage
  attr_accessor :name, :version, :tap, :path, :mode

  def url=(url)
    @url = url
    path = Pathname.new(url)
    if @name.nil?
      case url
      when %r{github\.com/(\S+)/(\S+)\.git}
        @user = Regexp.last_match(1)
        @name = Regexp.last_match(2)
        @head = true
        @github = true
      when %r{github\.com/(\S+)/(\S+)/(archive|releases)/}
        @user = Regexp.last_match(1)
        @name = Regexp.last_match(2)
        @github = true
      else
        @name = path.basename.to_s[/(.*?)[-_.]?#{Regexp.escape(path.version.to_s)}/, 1]
      end
    end
    update_path
    if @version
      @version = Version.create(@version)
    else
      @version = Version.detect(url, {})
    end
  end

  def update_path
    return if @name.nil? || @tap.nil?
    @path = Formulary.path "#{@tap}/#{@name}"
  end

  def fetch?
    !ARGV.include?("--no-fetch")
  end

  def head?
    @head || ARGV.build_head?
  end

  def generate!
    raise "#{path} already exists" if path.exist?

    if version.nil? || version.null?
      opoo "Version cannot be determined from URL."
      puts "You'll need to add an explicit 'version' to the formula."
    elsif fetch?
      unless head?
        r = Resource.new
        r.url(url)
        r.version(version)
        r.owner = self
        @sha256 = r.fetch.sha256 if r.download_strategy == CurlDownloadStrategy
      end

      if @user && @name
        begin
          metadata = GitHub.repository(@user, @name)
          @desc = metadata["description"]
          @homepage = metadata["homepage"]
        rescue GitHub::HTTPNotFoundError
          # If there was no repository found assume the network connection is at
          # fault rather than the input URL.
          nil
        end
      end
    end

    path.write ERB.new(template, nil, ">").result(binding)
  end

  def template; <<-EOS.undent
    # Documentation: https://docs.brew.sh/Formula-Cookbook.html
    #                http://www.rubydoc.info/github/Homebrew/brew/master/Formula
    # PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

    class #{Formulary.class_s(name)} < Formula
      desc "#{desc}"
      homepage "#{homepage}"
    <% if head? %>
      head "#{url}"
    <% else %>
      url "#{url}"
    <% unless version.nil? or version.detected_from_url? %>
      version "#{version}"
    <% end %>
      sha256 "#{sha256}"
    <% end %>

    <% if mode == :cmake %>
      depends_on "cmake" => :build
    <% elsif mode == :meson %>
      depends_on "meson" => :build
      depends_on "ninja" => :build
    <% elsif mode.nil? %>
      # depends_on "cmake" => :build
    <% end %>

      def install
        # ENV.deparallelize  # if your formula fails when building in parallel

    <% if mode == :cmake %>
        system "cmake", ".", *std_cmake_args
    <% elsif mode == :autotools %>
        # Remove unrecognized options if warned by configure
        system "./configure", "--disable-debug",
                              "--disable-dependency-tracking",
                              "--disable-silent-rules",
                              "--prefix=\#{prefix}"
    <% elsif mode == :meson %>
        mkdir "build" do
          system "meson", "--prefix=\#{prefix}", ".."
          system "ninja"
          system "ninja", "test"
          system "ninja", "install"
        end
    <% else %>
        # Remove unrecognized options if warned by configure
        system "./configure", "--disable-debug",
                              "--disable-dependency-tracking",
                              "--disable-silent-rules",
                              "--prefix=\#{prefix}"
        # system "cmake", ".", *std_cmake_args
    <% end %>
    <% if mode != :meson %>
        system "make", "install" # if this fails, try separate make/make install steps
    <% end %>
      end

      test do
        # `test do` will create, run in and delete a temporary directory.
        #
        # This test will fail and we won't accept that! For Homebrew/homebrew-core
        # this will need to be a test that verifies the functionality of the
        # software. Run the test with `brew test #{name}`. Options passed
        # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
        #
        # The installed folder is not in the path, so use the entire path to any
        # executables being tested: `system "\#{bin}/program", "do", "something"`.
        system "false"
      end
    end
    EOS
  end
end

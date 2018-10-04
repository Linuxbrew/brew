require "digest"
require "erb"

module Homebrew
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
      !Homebrew.args.no_fetch?
    end

    def head?
      @head || Homebrew.args.HEAD?
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

    def template
      <<~ERB
        # Documentation: https://docs.brew.sh/Formula-Cookbook
        #                https://www.rubydoc.info/github/Homebrew/brew/master/Formula
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
          depends_on "meson-internal" => :build
          depends_on "ninja" => :build
          depends_on "python" => :build
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
            ENV.refurbish_args

            mkdir "build" do
              system "meson", "--prefix=\#{prefix}", ".."
              system "ninja"
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
      ERB
    end
  end
end

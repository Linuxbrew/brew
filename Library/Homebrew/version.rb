require "version/null"

class Version
  include Comparable

  def self.formula_optionally_versioned_regex(name, full: true)
    /#{"^" if full}#{Regexp.escape(name)}(@\d[\d.]*)?#{"$" if full}/
  end

  class Token
    include Comparable

    attr_reader :value

    def initialize(value)
      @value = value
    end

    def inspect
      "#<#{self.class.name} #{value.inspect}>"
    end

    def to_s
      value.to_s
    end

    def numeric?
      false
    end
  end

  class NullToken < Token
    def initialize(value = nil)
      super
    end

    def <=>(other)
      case other
      when NullToken
        0
      when NumericToken
        other.value.zero? ? 0 : -1
      when AlphaToken, BetaToken, PreToken, RCToken
        1
      else
        -1
      end
    end

    def inspect
      "#<#{self.class.name}>"
    end
  end

  NULL_TOKEN = NullToken.new

  class StringToken < Token
    PATTERN = /[a-z]+[0-9]*/i.freeze

    def initialize(value)
      @value = value.to_s
    end

    def <=>(other)
      case other
      when StringToken
        value <=> other.value
      when NumericToken, NullToken
        -Integer(other <=> self)
      end
    end
  end

  class NumericToken < Token
    PATTERN = /[0-9]+/i.freeze

    def initialize(value)
      @value = value.to_i
    end

    def <=>(other)
      case other
      when NumericToken
        value <=> other.value
      when StringToken
        1
      when NullToken
        -Integer(other <=> self)
      end
    end

    def numeric?
      true
    end
  end

  class CompositeToken < StringToken
    def rev
      value[/[0-9]+/].to_i
    end
  end

  class AlphaToken < CompositeToken
    PATTERN = /alpha[0-9]*|a[0-9]+/i.freeze

    def <=>(other)
      case other
      when AlphaToken
        rev <=> other.rev
      when BetaToken, RCToken, PreToken, PatchToken
        -1
      else
        super
      end
    end
  end

  class BetaToken < CompositeToken
    PATTERN = /beta[0-9]*|b[0-9]+/i.freeze

    def <=>(other)
      case other
      when BetaToken
        rev <=> other.rev
      when AlphaToken
        1
      when PreToken, RCToken, PatchToken
        -1
      else
        super
      end
    end
  end

  class PreToken < CompositeToken
    PATTERN = /pre[0-9]*/i.freeze

    def <=>(other)
      case other
      when PreToken
        rev <=> other.rev
      when AlphaToken, BetaToken
        1
      when RCToken, PatchToken
        -1
      else
        super
      end
    end
  end

  class RCToken < CompositeToken
    PATTERN = /rc[0-9]*/i.freeze

    def <=>(other)
      case other
      when RCToken
        rev <=> other.rev
      when AlphaToken, BetaToken, PreToken
        1
      when PatchToken
        -1
      else
        super
      end
    end
  end

  class PatchToken < CompositeToken
    PATTERN = /p[0-9]*/i.freeze

    def <=>(other)
      case other
      when PatchToken
        rev <=> other.rev
      when AlphaToken, BetaToken, RCToken, PreToken
        1
      else
        super
      end
    end
  end

  SCAN_PATTERN = Regexp.union(
    AlphaToken::PATTERN,
    BetaToken::PATTERN,
    PreToken::PATTERN,
    RCToken::PATTERN,
    PatchToken::PATTERN,
    NumericToken::PATTERN,
    StringToken::PATTERN,
  )

  class FromURL < Version
    def detected_from_url?
      true
    end
  end

  def self.detect(url, specs)
    if specs.key?(:tag)
      FromURL.new(specs[:tag][/((?:\d+\.)*\d+)/, 1])
    else
      FromURL.parse(url)
    end
  end

  def self.create(val)
    unless val.respond_to?(:to_str)
      raise TypeError, "Version value must be a string; got a #{val.class} (#{val})"
    end

    if val.to_str.start_with?("HEAD")
      HeadVersion.new(val)
    else
      Version.new(val)
    end
  end

  def self.parse(spec)
    version = _parse(spec)
    version.nil? ? NULL : new(version)
  end

  def self._parse(spec)
    spec = Pathname.new(spec) unless spec.is_a? Pathname

    spec_s = spec.to_s

    stem = if spec.directory?
      spec.basename
    elsif %r{((?:sourceforge\.net|sf\.net)/.*)/download$} =~ spec_s
      Pathname.new(spec.dirname).stem
    elsif /\.[^a-zA-Z]+$/ =~ spec_s
      Pathname.new(spec_s).basename
    else
      spec.stem
    end

    # date-based versioning
    # e.g. ltopers-v2017-04-14.tar.gz
    m = /-v?(\d{4}-\d{2}-\d{2})/.match(stem)
    return m.captures.first unless m.nil?

    # GitHub tarballs
    # e.g. https://github.com/foo/bar/tarball/v1.2.3
    # e.g. https://github.com/sam-github/libnet/tarball/libnet-1.1.4
    # e.g. https://github.com/isaacs/npm/tarball/v0.2.5-1
    # e.g. https://github.com/petdance/ack/tarball/1.93_02
    m = %r{github\.com/.+/(?:zip|tar)ball/(?:v|\w+-)?((?:\d+[-._])+\d*)$}.match(spec_s)
    return m.captures.first unless m.nil?

    # e.g. https://github.com/erlang/otp/tarball/OTP_R15B01 (erlang style)
    m = /[-_]([Rr]\d+[AaBb]\d*(?:-\d+)?)/.match(spec_s)
    return m.captures.first unless m.nil?

    # e.g. boost_1_39_0
    m = /((?:\d+_)+\d+)$/.match(stem)
    return m.captures.first.tr("_", ".") unless m.nil?

    # e.g. foobar-4.5.1-1
    # e.g. unrtf_0.20.4-1
    # e.g. ruby-1.9.1-p243
    m = /[-_]((?:\d+\.)*\d\.\d+-(?:p|rc|RC)?\d+)(?:[-._](?:bin|dist|stable|src|sources))?$/.match(stem)
    return m.captures.first unless m.nil?

    # URL with no extension
    # e.g. https://waf.io/waf-1.8.12
    # e.g. https://codeload.github.com/gsamokovarov/jump/tar.gz/v0.7.1
    m = /[-v]((?:\d+\.)*\d+)$/.match(spec_s)
    return m.captures.first unless m.nil?

    # e.g. lame-398-1
    m = /-((?:\d)+-\d+)/.match(stem)
    return m.captures.first unless m.nil?

    # e.g. foobar-4.5.1
    m = /-((?:\d+\.)*\d+)$/.match(stem)
    return m.captures.first unless m.nil?

    # e.g. foobar-4.5.1b
    m = /-((?:\d+\.)*\d+(?:[abc]|rc|RC)\d*)$/.match(stem)
    return m.captures.first unless m.nil?

    # e.g. foobar-4.5.0-alpha5, foobar-4.5.0-beta1, or foobar-4.50-beta
    m = /-((?:\d+\.)*\d+-(?:alpha|beta|rc)\d*)$/.match(stem)
    return m.captures.first unless m.nil?

    # e.g. https://ftpmirror.gnu.org/libidn/libidn-1.29-win64.zip
    # e.g. https://ftpmirror.gnu.org/libmicrohttpd/libmicrohttpd-0.9.17-w32.zip
    m = /-(\d+\.\d+(?:\.\d+)?)-w(?:in)?(?:32|64)$/.match(stem)
    return m.captures.first unless m.nil?

    # Opam packages
    # e.g. https://opam.ocaml.org/archives/sha.1.9+opam.tar.gz
    # e.g. https://opam.ocaml.org/archives/lablgtk.2.18.3+opam.tar.gz
    # e.g. https://opam.ocaml.org/archives/easy-format.1.0.2+opam.tar.gz
    m = /\.(\d+\.\d+(?:\.\d+)?)\+opam$/.match(stem)
    return m.captures.first unless m.nil?

    # e.g. https://ftpmirror.gnu.org/mtools/mtools-4.0.18-1.i686.rpm
    # e.g. https://ftpmirror.gnu.org/autogen/autogen-5.5.7-5.i386.rpm
    # e.g. https://ftpmirror.gnu.org/libtasn1/libtasn1-2.8-x86.zip
    # e.g. https://ftpmirror.gnu.org/libtasn1/libtasn1-2.8-x64.zip
    # e.g. https://ftpmirror.gnu.org/mtools/mtools_4.0.18_i386.deb
    m = /[-_](\d+\.\d+(?:\.\d+)?(?:-\d+)?)[-_.](?:i[36]86|x86|x64(?:[-_](?:32|64))?)$/.match(stem)
    return m.captures.first unless m.nil?

    # devel spec
    # e.g. https://registry.npmjs.org/@angular/cli/-/cli-1.3.0-beta.1.tgz
    # e.g. https://github.com/dlang/dmd/archive/v2.074.0-beta1.tar.gz
    # e.g. https://github.com/dlang/dmd/archive/v2.074.0-rc1.tar.gz
    # e.g. https://github.com/premake/premake-core/releases/download/v5.0.0-alpha10/premake-5.0.0-alpha10-src.zip
    m = /[-.vV]?((?:\d+\.)+\d+[-_.]?(?i:alpha|beta|pre|rc)\.?\d{,2})/.match(stem)
    return m.captures.first unless m.nil?

    # e.g. foobar4.5.1
    m = /((?:\d+\.)*\d+)$/.match(stem)
    return m.captures.first unless m.nil?

    # e.g. foobar-4.5.0-bin
    m = /-((?:\d+\.)+\d+[abc]?)[-._](?:bin|dist|stable|src|sources?)$/.match(stem)
    return m.captures.first unless m.nil?

    # dash version style
    # e.g. http://www.antlr.org/download/antlr-3.4-complete.jar
    # e.g. https://cdn.nuxeo.com/nuxeo-9.2/nuxeo-server-9.2-tomcat.zip
    # e.g. https://search.maven.org/remotecontent?filepath=com/facebook/presto/presto-cli/0.181/presto-cli-0.181-executable.jar
    # e.g. https://search.maven.org/remotecontent?filepath=org/fusesource/fuse-extra/fusemq-apollo-mqtt/1.3/fusemq-apollo-mqtt-1.3-uber.jar
    # e.g. https://search.maven.org/remotecontent?filepath=org/apache/orc/orc-tools/1.2.3/orc-tools-1.2.3-uber.jar
    m = /-((?:\d+\.)+\d+)-/.match(stem)
    return m.captures.first unless m.nil?

    # e.g. dash_0.5.5.1.orig.tar.gz (Debian style)
    m = /_((?:\d+\.)+\d+[abc]?)[.]orig$/.match(stem)
    return m.captures.first unless m.nil?

    # e.g. https://www.openssl.org/source/openssl-0.9.8s.tar.gz
    m = /-v?([^-]+)/.match(stem)
    return m.captures.first unless m.nil?

    # e.g. astyle_1.23_macosx.tar.gz
    m = /_([^_]+)/.match(stem)
    return m.captures.first unless m.nil?

    # e.g. http://mirrors.jenkins-ci.org/war/1.486/jenkins.war
    # e.g. https://github.com/foo/bar/releases/download/0.10.11/bar.phar
    # e.g. https://github.com/clojure/clojurescript/releases/download/r1.9.293/cljs.jar
    # e.g. https://github.com/fibjs/fibjs/releases/download/v0.6.1/fullsrc.zip
    # e.g. https://wwwlehre.dhbw-stuttgart.de/~sschulz/WORK/E_DOWNLOAD/V_1.9/E.tgz
    # e.g. https://github.com/JustArchi/ArchiSteamFarm/releases/download/2.3.2.0/ASF.zip
    # e.g. https://people.gnome.org/~newren/eg/download/1.7.5.2/eg
    m = %r{/([rvV]_?)?(\d\.\d+(\.\d+){,2})}.match(spec_s)
    return m.captures.second unless m.nil?

    # e.g. https://www.ijg.org/files/jpegsrc.v8d.tar.gz
    m = /\.v(\d+[a-z]?)/.match(stem)
    return m.captures.first unless m.nil?

    # e.g. https://secure.php.net/get/php-7.1.10.tar.bz2/from/this/mirror
    m = /[-.vV]?((?:\d+\.)+\d+(?:[-_.]?(?i:alpha|beta|pre|rc)\.?\d{,2})?)/.match(spec_s)
    return m.captures.first unless m.nil?
  end

  private_class_method :_parse

  def initialize(val)
    unless val.respond_to?(:to_str)
      raise TypeError, "Version value must be a string; got a #{val.class} (#{val})"
    end

    @version = val.to_str
  end

  def detected_from_url?
    false
  end

  def head?
    false
  end

  def null?
    false
  end

  def <=>(other)
    # Needed to retain API compatibility with older string comparisons
    # for compiler versions, etc.
    other = Version.new(other) if other.is_a? String
    # Used by the *_build_version comparisons, which formerly returned Fixnum
    other = Version.new(other.to_s) if other.is_a? Integer
    return 1 if other.nil?

    return 1 if other.respond_to?(:null?) && other.null?
    return unless other.is_a?(Version)
    return 0 if version == other.version
    return 1 if head? && !other.head?
    return -1 if !head? && other.head?
    return 0 if head? && other.head?

    ltokens = tokens
    rtokens = other.tokens
    max = max(ltokens.length, rtokens.length)
    l = r = 0

    while l < max
      a = ltokens[l] || NULL_TOKEN
      b = rtokens[r] || NULL_TOKEN

      if a == b
        l += 1
        r += 1
        next
      elsif a.numeric? && b.numeric?
        return a <=> b
      elsif a.numeric?
        return 1 if a > NULL_TOKEN

        l += 1
      elsif b.numeric?
        return -1 if b > NULL_TOKEN

        r += 1
      else
        return a <=> b
      end
    end

    0
  end
  alias eql? ==

  def hash
    version.hash
  end

  def to_f
    version.to_f
  end

  def to_i
    version.to_i
  end

  def to_s
    version.dup
  end
  alias to_str to_s

  protected

  attr_reader :version

  def tokens
    @tokens ||= tokenize
  end

  private

  def max(a, b)
    (a > b) ? a : b
  end

  def tokenize
    version.scan(SCAN_PATTERN).map! do |token|
      case token
      when /\A#{AlphaToken::PATTERN}\z/o   then AlphaToken
      when /\A#{BetaToken::PATTERN}\z/o    then BetaToken
      when /\A#{RCToken::PATTERN}\z/o      then RCToken
      when /\A#{PreToken::PATTERN}\z/o     then PreToken
      when /\A#{PatchToken::PATTERN}\z/o   then PatchToken
      when /\A#{NumericToken::PATTERN}\z/o then NumericToken
      when /\A#{StringToken::PATTERN}\z/o  then StringToken
      end.new(token)
    end
  end
end

class HeadVersion < Version
  attr_reader :commit

  def initialize(val)
    super
    @commit = @version[/^HEAD-(.+)$/, 1]
  end

  def update_commit(commit)
    @commit = commit
    @version = if commit
      "HEAD-#{commit}"
    else
      "HEAD"
    end
  end

  def head?
    true
  end
end

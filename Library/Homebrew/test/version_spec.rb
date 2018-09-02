require "version"

describe Version do
  specify ".formula_optionally_versioned_regex" do
    expect(described_class.formula_optionally_versioned_regex("foo")).to match("foo@1.2")
  end
end

describe Version::Token do
  specify "#inspect" do
    expect(described_class.new("foo").inspect).to eq('#<Version::Token "foo">')
  end

  specify "#to_s" do
    expect(described_class.new("foo").to_s).to eq("foo")
  end
end

describe Version::NULL do
  it "is always smaller" do
    expect(described_class).to be < Version.create("1")
  end

  it "is never greater" do
    expect(described_class).not_to be > Version.create("0")
  end

  it "isn't equal to itself" do
    expect(described_class).not_to eql(described_class)
  end

  it "creates an empty string" do
    expect(described_class.to_s).to eq("")
  end

  it "produces NaN as a Float" do
    # Float::NAN is not equal to itself so compare object IDs
    expect(described_class.to_f.object_id).to eql(Float::NAN.object_id)
  end
end

describe Version::NullToken do
  specify "#inspect" do
    expect(subject.inspect).to eq("#<Version::NullToken>")
  end

  it "is equal to itself" do
    expect(subject).to be == described_class.new
  end
end

describe Version do
  specify "comparison" do
    expect(described_class.create("0.1")).to be == described_class.create("0.1.0")
    expect(described_class.create("0.1")).to be < described_class.create("0.2")
    expect(described_class.create("1.2.3")).to be > described_class.create("1.2.2")
    expect(described_class.create("1.2.4")).to be < described_class.create("1.2.4.1")

    expect(described_class.create("1.2.3")).to be > described_class.create("1.2.3alpha4")
    expect(described_class.create("1.2.3")).to be > described_class.create("1.2.3beta2")
    expect(described_class.create("1.2.3")).to be > described_class.create("1.2.3rc3")
    expect(described_class.create("1.2.3")).to be < described_class.create("1.2.3-p34")
  end

  specify "HEAD" do
    expect(described_class.create("HEAD")).to be > described_class.create("1.2.3")
    expect(described_class.create("HEAD-abcdef")).to be > described_class.create("1.2.3")
    expect(described_class.create("1.2.3")).to be < described_class.create("HEAD")
    expect(described_class.create("1.2.3")).to be < described_class.create("HEAD-fedcba")
    expect(described_class.create("HEAD-abcdef")).to be == described_class.create("HEAD-fedcba")
    expect(described_class.create("HEAD")).to be == described_class.create("HEAD-fedcba")
  end

  specify "comparing alpha versions" do
    expect(described_class.create("1.2.3alpha")).to be < described_class.create("1.2.3")
    expect(described_class.create("1.2.3")).to be < described_class.create("1.2.3a")
    expect(described_class.create("1.2.3alpha4")).to be == described_class.create("1.2.3a4")
    expect(described_class.create("1.2.3alpha4")).to be == described_class.create("1.2.3A4")
    expect(described_class.create("1.2.3alpha4")).to be > described_class.create("1.2.3alpha3")
    expect(described_class.create("1.2.3alpha4")).to be < described_class.create("1.2.3alpha5")
    expect(described_class.create("1.2.3alpha4")).to be < described_class.create("1.2.3alpha10")

    expect(described_class.create("1.2.3alpha4")).to be < described_class.create("1.2.3beta2")
    expect(described_class.create("1.2.3alpha4")).to be < described_class.create("1.2.3rc3")
    expect(described_class.create("1.2.3alpha4")).to be < described_class.create("1.2.3")
    expect(described_class.create("1.2.3alpha4")).to be < described_class.create("1.2.3-p34")
  end

  specify "comparing beta versions" do
    expect(described_class.create("1.2.3beta2")).to be == described_class.create("1.2.3b2")
    expect(described_class.create("1.2.3beta2")).to be == described_class.create("1.2.3B2")
    expect(described_class.create("1.2.3beta2")).to be > described_class.create("1.2.3beta1")
    expect(described_class.create("1.2.3beta2")).to be < described_class.create("1.2.3beta3")
    expect(described_class.create("1.2.3beta2")).to be < described_class.create("1.2.3beta10")

    expect(described_class.create("1.2.3beta2")).to be > described_class.create("1.2.3alpha4")
    expect(described_class.create("1.2.3beta2")).to be < described_class.create("1.2.3rc3")
    expect(described_class.create("1.2.3beta2")).to be < described_class.create("1.2.3")
    expect(described_class.create("1.2.3beta2")).to be < described_class.create("1.2.3-p34")
  end

  specify "comparing pre versions" do
    expect(described_class.create("1.2.3pre9")).to be == described_class.create("1.2.3PRE9")
    expect(described_class.create("1.2.3pre9")).to be > described_class.create("1.2.3pre8")
    expect(described_class.create("1.2.3pre8")).to be < described_class.create("1.2.3pre9")
    expect(described_class.create("1.2.3pre9")).to be < described_class.create("1.2.3pre10")

    expect(described_class.create("1.2.3pre3")).to be > described_class.create("1.2.3alpha2")
    expect(described_class.create("1.2.3pre3")).to be > described_class.create("1.2.3alpha4")
    expect(described_class.create("1.2.3pre3")).to be > described_class.create("1.2.3beta3")
    expect(described_class.create("1.2.3pre3")).to be > described_class.create("1.2.3beta5")
    expect(described_class.create("1.2.3pre3")).to be < described_class.create("1.2.3rc2")
    expect(described_class.create("1.2.3pre3")).to be < described_class.create("1.2.3")
    expect(described_class.create("1.2.3pre3")).to be < described_class.create("1.2.3-p2")
  end

  specify "comparing RC versions" do
    expect(described_class.create("1.2.3rc3")).to be == described_class.create("1.2.3RC3")
    expect(described_class.create("1.2.3rc3")).to be > described_class.create("1.2.3rc2")
    expect(described_class.create("1.2.3rc3")).to be < described_class.create("1.2.3rc4")
    expect(described_class.create("1.2.3rc3")).to be < described_class.create("1.2.3rc10")

    expect(described_class.create("1.2.3rc3")).to be > described_class.create("1.2.3alpha4")
    expect(described_class.create("1.2.3rc3")).to be > described_class.create("1.2.3beta2")
    expect(described_class.create("1.2.3rc3")).to be < described_class.create("1.2.3")
    expect(described_class.create("1.2.3rc3")).to be < described_class.create("1.2.3-p34")
  end

  specify "comparing patch-level versions" do
    expect(described_class.create("1.2.3-p34")).to be == described_class.create("1.2.3-P34")
    expect(described_class.create("1.2.3-p34")).to be > described_class.create("1.2.3-p33")
    expect(described_class.create("1.2.3-p34")).to be < described_class.create("1.2.3-p35")
    expect(described_class.create("1.2.3-p34")).to be > described_class.create("1.2.3-p9")

    expect(described_class.create("1.2.3-p34")).to be > described_class.create("1.2.3alpha4")
    expect(described_class.create("1.2.3-p34")).to be > described_class.create("1.2.3beta2")
    expect(described_class.create("1.2.3-p34")).to be > described_class.create("1.2.3rc3")
    expect(described_class.create("1.2.3-p34")).to be > described_class.create("1.2.3")
  end

  specify "comparing unevenly-padded versions" do
    expect(described_class.create("2.1.0-p194")).to be < described_class.create("2.1-p195")
    expect(described_class.create("2.1-p195")).to be > described_class.create("2.1.0-p194")
    expect(described_class.create("2.1-p194")).to be < described_class.create("2.1.0-p195")
    expect(described_class.create("2.1.0-p195")).to be > described_class.create("2.1-p194")
    expect(described_class.create("2-p194")).to be < described_class.create("2.1-p195")
  end

  it "can be compared against nil" do
    expect(described_class.create("2.1.0-p194")).to be > nil
  end

  it "can be compared against Version::NULL" do
    expect(described_class.create("2.1.0-p194")).to be > Version::NULL
  end

  it "can be compared against strings" do
    expect(described_class.create("2.1.0-p194")).to be == "2.1.0-p194"
    expect(described_class.create("1")).to be == 1
  end

  specify "comparison returns nil for non-version" do
    v = described_class.create("1.0")
    expect(v <=> Object.new).to be nil
    expect { v > Object.new }.to raise_error(ArgumentError)
  end

  specify "erlang versions" do
    versions = %w[R16B R15B03-1 R15B03 R15B02 R15B01 R14B04 R14B03
                  R14B02 R14B01 R14B R13B04 R13B03 R13B02-1].reverse
    expect(versions.sort_by { |v| described_class.create(v) }).to eq(versions)
  end

  specify "hash equality" do
    v1 = described_class.create("0.1.0")
    v2 = described_class.create("0.1.0")
    v3 = described_class.create("0.1.1")

    expect(v1).to eql(v2)
    expect(v1).not_to eql(v3)
    expect(v1.hash).to eq(v2.hash)
    expect(v1.hash).not_to eq(v3.hash)

    h = { v1 => :foo }
    expect(h[v2]).to eq(:foo)
  end

  describe "::create" do
    it "accepts objects responding to #to_str" do
      value = double(to_str: "0.1")
      expect(described_class.create(value).to_s).to eq("0.1")
    end

    it "raises a TypeError for non-string objects" do
      expect { described_class.create(1.1) }.to raise_error(TypeError)
      expect { described_class.create(1) }.to raise_error(TypeError)
      expect { described_class.create(:symbol) }.to raise_error(TypeError)
    end

    it "parses a version from a string" do
      v = described_class.create("1.20")
      expect(v).not_to be_head
      expect(v.to_str).to eq("1.20")
    end

    specify "HEAD with commit" do
      v = described_class.create("HEAD-abcdef")
      expect(v.commit).to eq("abcdef")
      expect(v.to_str).to eq("HEAD-abcdef")
    end

    specify "HEAD without commit" do
      v = described_class.create("HEAD")
      expect(v.commit).to be nil
      expect(v.to_str).to eq("HEAD")
    end
  end

  specify "#detected_from_url?" do
    expect(described_class.create("1.0")).not_to be_detected_from_url
    expect(Version::FromURL.new("1.0")).to be_detected_from_url
  end

  specify "#head?" do
    v1 = described_class.create("HEAD-abcdef")
    v2 = described_class.create("HEAD")

    expect(v1).to be_head
    expect(v2).to be_head
  end

  specify "#update_commit" do
    v1 = described_class.create("HEAD-abcdef")
    v2 = described_class.create("HEAD")

    v1.update_commit("ffffff")
    expect(v1.commit).to eq("ffffff")
    expect(v1.to_str).to eq("HEAD-ffffff")

    v2.update_commit("ffffff")
    expect(v2.commit).to eq("ffffff")
    expect(v2.to_str).to eq("HEAD-ffffff")
  end

  describe "::parse" do
    it "returns a NULL version when the URL cannot be parsed" do
      expect(described_class.parse("https://example.com/blah.tar")).to be_null
      expect(described_class.parse("foo")).to be_null
    end
  end

  describe "::detect" do
    matcher :be_detected_from do |url, specs = {}|
      match do |expected|
        @detected = described_class.detect(url, specs)
        @detected == expected
      end

      failure_message do |expected|
        message = <<~EOS
          expected: %s
          detected: %s
        EOS
        format(message, expected, @detected)
      end
    end

    specify "version all dots" do
      expect(described_class.create("1.14"))
        .to be_detected_from("https://example.com/foo.bar.la.1.14.zip")
    end

    specify "version underscore separator" do
      expect(described_class.create("1.1"))
        .to be_detected_from("https://example.com/grc_1.1.tar.gz")
    end

    specify "boost version style" do
      expect(described_class.create("1.39.0"))
        .to be_detected_from("https://example.com/boost_1_39_0.tar.bz2")
    end

    specify "erlang version style" do
      expect(described_class.create("R13B"))
        .to be_detected_from("https://erlang.org/download/otp_src_R13B.tar.gz")
    end

    specify "another erlang version style" do
      expect(described_class.create("R15B01"))
        .to be_detected_from("https://github.com/erlang/otp/tarball/OTP_R15B01")
    end

    specify "yet another erlang version style" do
      expect(described_class.create("R15B03-1"))
        .to be_detected_from("https://github.com/erlang/otp/tarball/OTP_R15B03-1")
    end

    specify "p7zip version style" do
      expect(described_class.create("9.04"))
        .to be_detected_from("https://kent.dl.sourceforge.net/sourceforge/p7zip/p7zip_9.04_src_all.tar.bz2")
    end

    specify "new github style" do
      expect(described_class.create("1.1.4"))
        .to be_detected_from("https://github.com/sam-github/libnet/tarball/libnet-1.1.4")
    end

    specify "codeload style" do
      expect(described_class.create("0.7.1"))
        .to be_detected_from("https://codeload.github.com/gsamokovarov/jump/tar.gz/v0.7.1")
    end

    specify "elasticsearch alpha style" do
      expect(described_class.create("5.0.0-alpha5"))
        .to be_detected_from(
          "https://download.elastic.co/elasticsearch/release/org/elasticsearch" \
          "/distribution/tar/elasticsearch/5.0.0-alpha5/elasticsearch-5.0.0-alpha5.tar.gz",
        )
    end

    specify "gloox beta style" do
      expect(described_class.create("1.0-beta7"))
        .to be_detected_from("https://camaya.net/download/gloox-1.0-beta7.tar.bz2")
    end

    specify "sphinx beta style" do
      expect(described_class.create("1.10-beta"))
        .to be_detected_from("http://sphinxsearch.com/downloads/sphinx-1.10-beta.tar.gz")
    end

    specify "astyle version style" do
      expect(described_class.create("1.23"))
        .to be_detected_from("https://kent.dl.sourceforge.net/sourceforge/astyle/astyle_1.23_macosx.tar.gz")
    end

    specify "version dos2unix" do
      expect(described_class.create("3.1"))
        .to be_detected_from("http://www.sfr-fresh.com/linux/misc/dos2unix-3.1.tar.gz")
    end

    specify "version internal dash" do
      expect(described_class.create("1.1-2"))
        .to be_detected_from("https://example.com/foo-arse-1.1-2.tar.gz")
    end

    specify "version single digit" do
      expect(described_class.create("45"))
        .to be_detected_from("https://example.com/foo_bar.45.tar.gz")
    end

    specify "noseparator single digit" do
      expect(described_class.create("45"))
        .to be_detected_from("https://example.com/foo_bar45.tar.gz")
    end

    specify "version developer that hates us format" do
      expect(described_class.create("1.2.3"))
        .to be_detected_from("https://example.com/foo-bar-la.1.2.3.tar.gz")
    end

    specify "version regular" do
      expect(described_class.create("1.21"))
        .to be_detected_from("https://example.com/foo_bar-1.21.tar.gz")
    end

    specify "version sourceforge download" do
      expect(described_class.create("1.21"))
        .to be_detected_from("https://sourceforge.net/foo_bar-1.21.tar.gz/download")
      expect(described_class.create("1.21"))
        .to be_detected_from("https://sf.net/foo_bar-1.21.tar.gz/download")
    end

    specify "version github" do
      expect(described_class.create("1.0.5"))
        .to be_detected_from("https://github.com/lloyd/yajl/tarball/1.0.5")
    end

    specify "version github with high patch number" do
      expect(described_class.create("1.2.34"))
        .to be_detected_from("https://github.com/lloyd/yajl/tarball/v1.2.34")
    end

    specify "yet another version" do
      expect(described_class.create("0.15.1b"))
        .to be_detected_from("https://example.com/mad-0.15.1b.tar.gz")
    end

    specify "lame version style" do
      expect(described_class.create("398-2"))
        .to be_detected_from("https://kent.dl.sourceforge.net/sourceforge/lame/lame-398-2.tar.gz")
    end

    specify "ruby version style" do
      expect(described_class.create("1.9.1-p243"))
        .to be_detected_from("ftp://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.1-p243.tar.gz")
    end

    specify "omega version style" do
      expect(described_class.create("0.80.2"))
        .to be_detected_from("http://www.alcyone.com/binaries/omega/omega-0.80.2-src.tar.gz")
    end

    specify "rc style" do
      expect(described_class.create("1.2.2rc1"))
        .to be_detected_from("https://downloads.xiph.org/releases/vorbis/libvorbis-1.2.2rc1.tar.bz2")
    end

    specify "dash rc style" do
      expect(described_class.create("1.8.0-rc1"))
        .to be_detected_from("https://ftp.mozilla.org/pub/mozilla.org/js/js-1.8.0-rc1.tar.gz")
    end

    specify "angband version style" do
      expect(described_class.create("3.0.9b"))
        .to be_detected_from("http://rephial.org/downloads/3.0/angband-3.0.9b-src.tar.gz")
    end

    specify "stable suffix" do
      expect(described_class.create("1.4.14b"))
        .to be_detected_from("https://www.monkey.org/~provos/libevent-1.4.14b-stable.tar.gz")
    end

    specify "debian style 1" do
      expect(described_class.create("3.03"))
        .to be_detected_from("https://ftp.de.debian.org/debian/pool/main/s/sl/sl_3.03.orig.tar.gz")
    end

    specify "debian style 2" do
      expect(described_class.create("1.01b"))
        .to be_detected_from("https://ftp.de.debian.org/debian/pool/main/m/mmv/mmv_1.01b.orig.tar.gz")
    end

    specify "bottle style" do
      expect(described_class.create("4.8.0"))
        .to be_detected_from("https://homebrew.bintray.com/bottles/qt-4.8.0.lion.bottle.tar.gz")
    end

    specify "versioned bottle style" do
      expect(described_class.create("4.8.1"))
        .to be_detected_from("https://homebrew.bintray.com/bottles/qt-4.8.1.lion.bottle.1.tar.gz")
    end

    specify "erlang bottle style" do
      expect(described_class.create("R15B"))
        .to be_detected_from("https://homebrew.bintray.com/bottles/erlang-R15B.lion.bottle.tar.gz")
    end

    specify "another erlang bottle style" do
      expect(described_class.create("R15B01"))
        .to be_detected_from("https://homebrew.bintray.com/bottles/erlang-R15B01.mountain_lion.bottle.tar.gz")
    end

    specify "yet another erlang bottle style" do
      expect(described_class.create("R15B03-1"))
        .to be_detected_from("https://homebrew.bintray.com/bottles/erlang-R15B03-1.mountainlion.bottle.tar.gz")
    end

    specify "imagemagick style" do
      expect(described_class.create("6.7.5-7"))
        .to be_detected_from("https://downloads.sf.net/project/machomebrew/mirror/ImageMagick-6.7.5-7.tar.bz2")
    end

    specify "imagemagick bottle style" do
      expect(described_class.create("6.7.5-7"))
        .to be_detected_from("https://homebrew.bintray.com/bottles/imagemagick-6.7.5-7.lion.bottle.tar.gz")
    end

    specify "imagemagick versioned bottle style" do
      expect(described_class.create("6.7.5-7"))
        .to be_detected_from("https://homebrew.bintray.com/bottles/imagemagick-6.7.5-7.lion.bottle.1.tar.gz")
    end

    specify "date-based version style" do
      expect(described_class.create("2017-04-17"))
        .to be_detected_from("https://example.com/dada-v2017-04-17.tar.gz")
    end

    specify "devel spec version style" do
      expect(described_class.create("1.3.0-beta.1"))
        .to be_detected_from("https://registry.npmjs.org/@angular/cli/-/cli-1.3.0-beta.1.tgz")
      expect(described_class.create("2.074.0-beta1"))
        .to be_detected_from("https://github.com/dlang/dmd/archive/v2.074.0-beta1.tar.gz")
      expect(described_class.create("2.074.0-rc1"))
        .to be_detected_from("https://github.com/dlang/dmd/archive/v2.074.0-rc1.tar.gz")
      expect(described_class.create("5.0.0-alpha10"))
        .to be_detected_from(
          "https://github.com/premake/premake-core/releases/download/v5.0.0-alpha10/premake-5.0.0-alpha10-src.zip",
        )
    end

    specify "jenkins version style" do
      expect(described_class.create("1.486"))
        .to be_detected_from("https://mirrors.jenkins-ci.org/war/1.486/jenkins.war")
      expect(described_class.create("0.10.11"))
        .to be_detected_from("https://github.com/hechoendrupal/DrupalConsole/releases/download/0.10.11/drupal.phar")
    end

    specify "char prefixed, url-only version style" do
      expect(described_class.create("1.9.293"))
        .to be_detected_from("https://github.com/clojure/clojurescript/releases/download/r1.9.293/cljs.jar")
      expect(described_class.create("0.6.1"))
        .to be_detected_from("https://github.com/fibjs/fibjs/releases/download/v0.6.1/fullsrc.zip")
      expect(described_class.create("1.9"))
        .to be_detected_from("https://wwwlehre.dhbw-stuttgart.de/~sschulz/WORK/E_DOWNLOAD/V_1.9/E.tgz")
    end

    specify "w.x.y.z url-only version style" do
      expect(described_class.create("2.3.2.0"))
        .to be_detected_from("https://github.com/JustArchi/ArchiSteamFarm/releases/download/2.3.2.0/ASF.zip")
      expect(described_class.create("1.7.5.2"))
        .to be_detected_from("https://people.gnome.org/~newren/eg/download/1.7.5.2/eg")
    end

    specify "dash version style" do
      expect(described_class.create("3.4"))
        .to be_detected_from("https://www.antlr.org/download/antlr-3.4-complete.jar")
      expect(described_class.create("9.2"))
        .to be_detected_from("https://cdn.nuxeo.com/nuxeo-9.2/nuxeo-server-9.2-tomcat.zip")
      expect(described_class.create("0.181"))
        .to be_detected_from(
          "https://search.maven.org/remotecontent?filepath=" \
          "com/facebook/presto/presto-cli/0.181/presto-cli-0.181-executable.jar",
        )
      expect(described_class.create("1.2.3"))
        .to be_detected_from(
          "https://search.maven.org/remotecontent?filepath=org/apache/orc/orc-tools/1.2.3/orc-tools-1.2.3-uber.jar",
        )
    end

    specify "apache version style" do
      expect(described_class.create("1.2.0-rc2"))
        .to be_detected_from(
          "https://www.apache.org/dyn/closer.cgi?path=/cassandra/1.2.0/apache-cassandra-1.2.0-rc2-bin.tar.gz",
        )
    end

    specify "jpeg version style" do
      expect(described_class.create("8d"))
        .to be_detected_from("https://www.ijg.org/files/jpegsrc.v8d.tar.gz")
    end

    specify "ghc version style" do
      expect(described_class.create("7.0.4"))
        .to be_detected_from("https://www.haskell.org/ghc/dist/7.0.4/ghc-7.0.4-x86_64-apple-darwin.tar.bz2")
      expect(described_class.create("7.0.4"))
        .to be_detected_from("https://www.haskell.org/ghc/dist/7.0.4/ghc-7.0.4-i386-apple-darwin.tar.bz2")
    end

    specify "pypy version style" do
      expect(described_class.create("1.4.1"))
        .to be_detected_from("https://pypy.org/download/pypy-1.4.1-osx.tar.bz2")
    end

    specify "openssl version style" do
      expect(described_class.create("0.9.8s"))
        .to be_detected_from("https://www.openssl.org/source/openssl-0.9.8s.tar.gz")
    end

    specify "xaw3d version style" do
      expect(described_class.create("1.5E"))
        .to be_detected_from("ftp://ftp.visi.com/users/hawkeyd/X/Xaw3d-1.5E.tar.gz")
    end

    specify "assimp version style" do
      expect(described_class.create("2.0.863"))
        .to be_detected_from("https://downloads.sourceforge.net/project/assimp/assimp-2.0/assimp--2.0.863-sdk.zip")
    end

    specify "cmucl version style" do
      expect(described_class.create("20c"))
        .to be_detected_from(
          "https://common-lisp.net/project/cmucl/downloads/release/20c/cmucl-20c-x86-darwin.tar.bz2",
        )
    end

    specify "fann version style" do
      expect(described_class.create("2.1.0beta"))
        .to be_detected_from("https://downloads.sourceforge.net/project/fann/fann/2.1.0beta/fann-2.1.0beta.zip")
    end

    specify "grads version style" do
      expect(described_class.create("2.0.1"))
        .to be_detected_from("ftp://iges.org/grads/2.0/grads-2.0.1-bin-darwin9.8-intel.tar.gz")
    end

    specify "haxe version style" do
      expect(described_class.create("2.08"))
        .to be_detected_from("https://haxe.org/file/haxe-2.08-osx.tar.gz")
    end

    specify "imap version style" do
      expect(described_class.create("2007f"))
        .to be_detected_from("ftp://ftp.cac.washington.edu/imap/imap-2007f.tar.gz")
    end

    specify "suite3270 version style" do
      expect(described_class.create("3.3.12ga7"))
        .to be_detected_from(
          "https://downloads.sourceforge.net/project/x3270/x3270/3.3.12ga7/suite3270-3.3.12ga7-src.tgz",
        )
    end

    specify "wwwoffle version style" do
      expect(described_class.create("2.9h"))
        .to be_detected_from("http://www.gedanken.demon.co.uk/download-wwwoffle/wwwoffle-2.9h.tgz")
    end

    specify "synergy version style" do
      expect(described_class.create("1.3.6p2"))
        .to be_detected_from("http://synergy.googlecode.com/files/synergy-1.3.6p2-MacOSX-Universal.zip")
    end

    specify "fontforge version style" do
      expect(described_class.create("20120731"))
        .to be_detected_from(
          "https://downloads.sourceforge.net/project/fontforge/fontforge-source/fontforge_full-20120731-b.tar.bz2",
        )
    end

    specify "ezlupdate version style" do
      expect(described_class.create("2011.10"))
        .to be_detected_from(
          "https://github.com/downloads/ezsystems" \
          "/ezpublish-legacy/ezpublish_community_project-2011.10-with_ezc.tar.bz2",
        )
    end

    specify "aespipe version style" do
      expect(described_class.create("2.4c"))
        .to be_detected_from("http://loop-aes.sourceforge.net/aespipe/aespipe-v2.4c.tar.bz2")
    end

    specify "win version style" do
      expect(described_class.create("0.9.17"))
        .to be_detected_from("https://ftpmirror.gnu.org/libmicrohttpd/libmicrohttpd-0.9.17-w32.zip")
      expect(described_class.create("1.29"))
        .to be_detected_from("https://ftpmirror.gnu.org/libidn/libidn-1.29-win64.zip")
    end

    specify "with arch" do
      expect(described_class.create("4.0.18-1"))
        .to be_detected_from("https://ftpmirror.gnu.org/mtools/mtools-4.0.18-1.i686.rpm")
      expect(described_class.create("5.5.7-5"))
        .to be_detected_from("https://ftpmirror.gnu.org/autogen/autogen-5.5.7-5.i386.rpm")
      expect(described_class.create("2.8"))
        .to be_detected_from("https://ftpmirror.gnu.org/libtasn1/libtasn1-2.8-x86.zip")
      expect(described_class.create("2.8"))
        .to be_detected_from("https://ftpmirror.gnu.org/libtasn1/libtasn1-2.8-x64.zip")
      expect(described_class.create("4.0.18"))
        .to be_detected_from("https://ftpmirror.gnu.org/mtools/mtools_4.0.18_i386.deb")
    end

    specify "opam version" do
      expect(described_class.create("2.18.3"))
        .to be_detected_from("https://opam.ocaml.org/archives/lablgtk.2.18.3+opam.tar.gz")
      expect(described_class.create("1.9"))
        .to be_detected_from("https://opam.ocaml.org/archives/sha.1.9+opam.tar.gz")
      expect(described_class.create("0.99.2"))
        .to be_detected_from("https://opam.ocaml.org/archives/ppx_tools.0.99.2+opam.tar.gz")
      expect(described_class.create("1.0.2"))
        .to be_detected_from("https://opam.ocaml.org/archives/easy-format.1.0.2+opam.tar.gz")
    end

    specify "no extension version" do
      expect(described_class.create("1.8.12"))
        .to be_detected_from("https://waf.io/waf-1.8.12")
      expect(described_class.create("0.7.1"))
        .to be_detected_from("https://codeload.github.com/gsamokovarov/jump/tar.gz/v0.7.1")
      expect(described_class.create("0.9.1234"))
        .to be_detected_from("https://my.datomic.com/downloads/free/0.9.1234")
      expect(described_class.create("1.2.3"))
        .to be_detected_from("https://my.datomic.com/downloads/free/1.2.3")
    end

    specify "dash separated version" do
      expect(described_class.create("6-20151227"))
        .to be_detected_from("ftp://gcc.gnu.org/pub/gcc/snapshots/6-20151227/gcc-6-20151227.tar.bz2")
    end

    specify "semver in middle of URL" do
      expect(described_class.create("7.1.10"))
        .to be_detected_from("https://php.net/get/php-7.1.10.tar.gz/from/this/mirror")
    end

    specify "from URL" do
      expect(described_class.create("1.2.3"))
        .to be_detected_from("https://github.com/foo/bar.git", tag: "v1.2.3")
    end
  end
end

describe Pathname do
  specify "#version" do
    d = HOMEBREW_CELLAR/"foo-0.1.9"
    d.mkpath
    expect(d.version).to eq(Version.create("0.1.9"))
  end
end

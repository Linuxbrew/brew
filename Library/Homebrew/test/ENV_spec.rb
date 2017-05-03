require "extend/ENV"

shared_examples EnvActivation do
  subject { env.extend(described_class) }
  let(:env) { {}.extend(EnvActivation) }

  it "supports switching compilers" do
    subject.clang
    expect(subject["LD"]).to be nil
    expect(subject["CC"]).to eq(subject["OBJC"])
  end

  describe "#with_build_environment" do
    it "restores the environment" do
      before = subject.dup

      subject.with_build_environment do
        subject["foo"] = "bar"
      end

      expect(subject["foo"]).to be nil
      expect(subject).to eq(before)
    end

    it "ensures the environment is restored" do
      before = subject.dup

      expect {
        subject.with_build_environment do
          subject["foo"] = "bar"
          raise StandardError
        end
      }.to raise_error(StandardError)

      expect(subject["foo"]).to be nil
      expect(subject).to eq(before)
    end

    it "returns the value of the block" do
      expect(subject.with_build_environment { 1 }).to eq(1)
    end

    it "does not mutate the interface" do
      expected = subject.methods

      subject.with_build_environment do
        expect(subject.methods).to eq(expected)
      end

      expect(subject.methods).to eq(expected)
    end
  end

  describe "#append" do
    it "appends to an existing key" do
      subject["foo"] = "bar"
      subject.append "foo", "1"
      expect(subject["foo"]).to eq("bar 1")
    end

    it "appends to an existing empty key" do
      subject["foo"] = ""
      subject.append "foo", "1"
      expect(subject["foo"]).to eq("1")
    end

    it "appends to a non-existant key" do
      subject.append "foo", "1"
      expect(subject["foo"]).to eq("1")
    end

    # NOTE: this may be a wrong behavior; we should probably reject objects that
    # do not respond to #to_str. For now this documents existing behavior.
    it "coerces a value to a string" do
      subject.append "foo", 42
      expect(subject["foo"]).to eq("42")
    end
  end

  describe "#prepend" do
    it "prepends to an existing key" do
      subject["foo"] = "bar"
      subject.prepend "foo", "1"
      expect(subject["foo"]).to eq("1 bar")
    end

    it "prepends to an existing empty key" do
      subject["foo"] = ""
      subject.prepend "foo", "1"
      expect(subject["foo"]).to eq("1")
    end

    it "prepends to a non-existant key" do
      subject.prepend "foo", "1"
      expect(subject["foo"]).to eq("1")
    end

    # NOTE: this may be a wrong behavior; we should probably reject objects that
    # do not respond to #to_str. For now this documents existing behavior.
    it "coerces a value to a string" do
      subject.prepend "foo", 42
      expect(subject["foo"]).to eq("42")
    end
  end

  describe "#append_path" do
    it "appends to a path" do
      subject.append_path "FOO", "/usr/bin"
      expect(subject["FOO"]).to eq("/usr/bin")

      subject.append_path "FOO", "/bin"
      expect(subject["FOO"]).to eq("/usr/bin#{File::PATH_SEPARATOR}/bin")
    end
  end

  describe "#prepend_path" do
    it "prepends to a path" do
      subject.prepend_path "FOO", "/usr/libexec"
      expect(subject["FOO"]).to eq("/usr/libexec")

      subject.prepend_path "FOO", "/usr"
      expect(subject["FOO"]).to eq("/usr#{File::PATH_SEPARATOR}/usr/libexec")
    end
  end

  describe "#compiler" do
    it "allows switching compilers" do
      [:clang, :gcc_4_2, :gcc_4_0].each do |compiler|
        subject.public_send(compiler)
        expect(subject.compiler).to eq(compiler)
      end
    end
  end

  example "deparallelize_block_form_restores_makeflags" do
    subject["MAKEFLAGS"] = "-j4"

    subject.deparallelize do
      expect(subject["MAKEFLAGS"]).to be nil
    end

    expect(subject["MAKEFLAGS"]).to eq("-j4")
  end
end

describe Stdenv do
  include_examples EnvActivation
end

describe Superenv do
  include_examples EnvActivation

  it "initializes deps" do
    expect(subject.deps).to eq([])
    expect(subject.keg_only_deps).to eq([])
  end

  describe "#cxx11" do
    it "raises an error when the compiler isn't supported" do
      %w[gcc gcc-4.7].each do |compiler|
        subject["HOMEBREW_CC"] = compiler

        expect { subject.cxx11 }
          .to raise_error(/The selected compiler doesn't support C\+\+11:/)

        expect(subject["HOMEBREW_CCCFG"]).to be nil
      end
    end

    it "supports gcc-5" do
      subject["HOMEBREW_CC"] = "gcc-5"
      subject.cxx11
      expect(subject["HOMEBREW_CCCFG"]).to include("x")
    end

    example "supports gcc-6" do
      subject["HOMEBREW_CC"] = "gcc-6"
      subject.cxx11
      expect(subject["HOMEBREW_CCCFG"]).to include("x")
    end

    it "supports clang" do
      subject["HOMEBREW_CC"] = "clang"
      subject.cxx11
      expect(subject["HOMEBREW_CCCFG"]).to include("x")
      expect(subject["HOMEBREW_CCCFG"]).to include("g")
    end
  end
end

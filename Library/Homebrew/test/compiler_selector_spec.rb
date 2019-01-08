require "compilers"
require "software_spec"

describe CompilerSelector do
  subject { described_class.new(software_spec, versions, compilers) }

  let(:compilers) { [:clang, :gcc_4_2, :gnu] }
  let(:software_spec) { SoftwareSpec.new }
  let(:cc) { :clang }
  let(:versions) do
    double(
      gcc_4_2_build_version: Version.create("5666"),
      llvm_build_version:    Version::NULL,
      clang_build_version:   Version.create("425"),
    )
  end

  before do
    allow(versions).to receive(:non_apple_gcc_version) do |name|
      case name
      when "gcc-7" then Version.create("7.1")
      when "gcc-6" then Version.create("6.1")
      else Version::NULL
      end
    end
  end

  describe "#compiler" do
    it "defaults to cc" do
      expect(subject.compiler).to eq(cc)
    end

    it "returns clang if it fails with non-Apple gcc" do
      software_spec.fails_with(gcc: "7")
      expect(subject.compiler).to eq(:clang)
    end

    it "still returns gcc-7 if it fails with gcc without a specific version" do
      software_spec.fails_with(:clang)
      software_spec.fails_with(:gcc_4_2)
      expect(subject.compiler).to eq("gcc-7")
    end

    it "returns gcc if it fails with clang and llvm" do
      software_spec.fails_with(:clang)
      expect(subject.compiler).to eq(:gcc_4_2)
    end

    it "returns clang if it fails with gcc and llvm" do
      software_spec.fails_with(:gcc_4_2)
      expect(subject.compiler).to eq(:clang)
    end

    example "returns gcc if it fails with a specific gcc version" do
      software_spec.fails_with(:clang)
      software_spec.fails_with(gcc: "7")
      expect(subject.compiler).to eq(:gcc_4_2)
    end

    example "returns a lower version of gcc if it fails with the highest version" do
      software_spec.fails_with(:clang)
      software_spec.fails_with(:gcc_4_2)
      software_spec.fails_with(gcc: "7")
      expect(subject.compiler).to eq("gcc-6")
    end

    it "raises an error when gcc or llvm is missing" do
      allow(versions).to receive(:gcc_4_2_build_version).and_return(Version::NULL)

      software_spec.fails_with(:clang)
      software_spec.fails_with(gcc: "7")
      software_spec.fails_with(gcc: "6")

      expect { subject.compiler }.to raise_error(CompilerSelectionError)
    end
  end
end

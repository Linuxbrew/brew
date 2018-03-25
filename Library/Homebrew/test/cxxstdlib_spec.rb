require "formula"
require "cxxstdlib"

describe CxxStdlib do
  let(:clang) { described_class.create(:libstdcxx, :clang) }
  let(:gcc) { described_class.create(:libstdcxx, :gcc) }
  let(:gcc40) { described_class.create(:libstdcxx, :gcc_4_0) }
  let(:gcc42) { described_class.create(:libstdcxx, :gcc_4_2) }
  let(:gcc48) { described_class.create(:libstdcxx, "gcc-4.8") }
  let(:gcc49) { described_class.create(:libstdcxx, "gcc-4.9") }
  let(:lcxx) { described_class.create(:libcxx, :clang) }
  let(:purec) { described_class.create(nil, :clang) }

  describe "#compatible_with?" do
    specify "Apple libstdcxx intercompatibility" do
      expect(clang).to be_compatible_with(gcc)
      expect(clang).to be_compatible_with(gcc42)
    end

    specify "compatibility with itself" do
      expect(gcc).to be_compatible_with(gcc)
      expect(gcc48).to be_compatible_with(gcc48)
      expect(clang).to be_compatible_with(clang)
    end

    specify "Apple/GNU libstdcxx incompatibility" do
      expect(clang).not_to be_compatible_with(gcc48)
      expect(gcc48).not_to be_compatible_with(clang)
    end

    specify "GNU cross-version incompatibility" do
      expect(gcc48).not_to be_compatible_with(gcc49)
      expect(gcc49).not_to be_compatible_with(gcc48)
    end

    specify "libstdcxx and libcxx incompatibility" do
      expect(clang).not_to be_compatible_with(lcxx)
      expect(lcxx).not_to be_compatible_with(clang)
    end

    specify "compatibility for non-cxx software" do
      expect(purec).to be_compatible_with(clang)
      expect(clang).to be_compatible_with(purec)
      expect(purec).to be_compatible_with(purec)
      expect(purec).to be_compatible_with(gcc48)
      expect(gcc48).to be_compatible_with(purec)
    end
  end

  describe "#apple_compiler?" do
    it "returns true for Apple compilers" do
      expect(clang).to be_an_apple_compiler
      expect(gcc).to be_an_apple_compiler
      expect(gcc42).to be_an_apple_compiler
    end

    it "returns false for non-Apple compilers" do
      expect(gcc48).not_to be_an_apple_compiler
    end
  end

  describe "#type_string" do
    specify "formatting" do
      expect(clang.type_string).to eq("libstdc++")
      expect(lcxx.type_string).to eq("libc++")
    end
  end
end

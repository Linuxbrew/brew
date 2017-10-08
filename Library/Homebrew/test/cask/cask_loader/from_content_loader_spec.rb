describe Hbc::CaskLoader::FromContentLoader do
  alias_matcher :be_able_to_load, :be_can_load

  describe "::can_load?" do
    it "returns true for Casks specified with `cask \"token\" do … end`" do
      expect(described_class).to be_able_to_load <<~EOS
        cask "token" do
        end
      EOS
    end

    it "returns true for Casks specified with `cask \"token\" do; end`" do
      expect(described_class).to be_able_to_load <<~EOS
        cask "token" do; end
      EOS
    end

    it "returns true for Casks specified with `cask 'token' do … end`" do
      expect(described_class).to be_able_to_load <<~EOS
        cask 'token' do
        end
      EOS
    end

    it "returns true for Casks specified with `cask 'token' do; end`" do
      expect(described_class).to be_able_to_load <<~EOS
        cask 'token' do; end
      EOS
    end

    it "returns true for Casks specified with `cask(\"token\") { … }`" do
      expect(described_class).to be_able_to_load <<~EOS
        cask("token") {
        }
      EOS
    end

    it "returns true for Casks specified with `cask(\"token\") {}`" do
      expect(described_class).to be_able_to_load <<~EOS
        cask("token") {}
      EOS
    end

    it "returns true for Casks specified with `cask('token') { … }`" do
      expect(described_class).to be_able_to_load <<~EOS
        cask('token') {
        }
      EOS
    end

    it "returns true for Casks specified with `cask('token') {}`" do
      expect(described_class).to be_able_to_load <<~EOS
        cask('token') {}
      EOS
    end
  end
end

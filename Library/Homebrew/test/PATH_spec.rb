require "PATH"

describe PATH do
  describe "#initialize" do
    it "can take multiple arguments" do
      expect(described_class.new("/path1", "/path2")).to eq("/path1:/path2")
    end

    it "can parse a mix of arrays and arguments" do
      expect(described_class.new(["/path1", "/path2"], "/path3")).to eq("/path1:/path2:/path3")
    end

    it "splits an existing PATH" do
      expect(described_class.new("/path1:/path2")).to eq(["/path1", "/path2"])
    end
  end

  describe "#to_ary" do
    it "returns a PATH array" do
      expect(described_class.new("/path1", "/path2").to_ary).to eq(["/path1", "/path2"])
    end
  end

  describe "#to_str" do
    it "returns a PATH string" do
      expect(described_class.new("/path1", "/path2").to_str).to eq("/path1:/path2")
    end
  end

  describe "#prepend" do
    it "prepends a path to a PATH" do
      expect(described_class.new("/path1").prepend("/path2").to_str).to eq("/path2:/path1")
    end
  end

  describe "#append" do
    it "prepends a path to a PATH" do
      expect(described_class.new("/path1").append("/path2").to_str).to eq("/path1:/path2")
    end
  end

  describe "#validate" do
    it "returns a new PATH without non-existent paths" do
      allow(File).to receive(:directory?).with("/path1").and_return(true)
      allow(File).to receive(:directory?).with("/path2").and_return(false)

      path = described_class.new("/path1", "/path2")
      expect(path.validate.to_ary).to eq(["/path1"])
      expect(path.to_ary).to eq(["/path1", "/path2"])
    end
  end
end

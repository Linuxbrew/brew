require "formula"
require "software_spec"

describe Bottle::Filename do
  specify "#prefix" do
    expect(described_class.new("foo", "1.0", :tag, 0).prefix)
      .to eq("foo-1.0.tag")
  end

  specify "#suffix" do
    expect(described_class.new("foo", "1.0", :tag, 0).suffix)
      .to eq(".bottle.tar.gz")

    expect(described_class.new("foo", "1.0", :tag, 1).suffix)
      .to eq(".bottle.1.tar.gz")
  end

  specify "#to_s and #to_str" do
    expected = "foo-1.0.tag.bottle.tar.gz"

    expect(described_class.new("foo", "1.0", :tag, 0).to_s)
      .to eq(expected)

    expect(described_class.new("foo", "1.0", :tag, 0).to_str)
      .to eq(expected)
  end

  specify "::create" do
    f = formula do
      url "https://example.com/foo.tar.gz"
      version "1.0"
    end

    expect(described_class.create(f, :tag, 0).to_s)
      .to eq("formula_name-1.0.tag.bottle.tar.gz")
  end
end

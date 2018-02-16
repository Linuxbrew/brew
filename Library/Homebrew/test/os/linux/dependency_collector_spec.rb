require "dependency_collector"

describe DependencyCollector do
  alias_matcher :be_a_build_requirement, :be_build

  after(:each) do
    described_class.clear_cache
  end

  describe "#add" do
    it "creates a resource dependency from a '.zip' URL" do
      resource = Resource.new
      resource.url("http://example.com/foo.zip")
      expect(subject.add(resource)).to eq(Dependency.new("zip", [:build]))
    end

    it "creates a resource dependency from a '.bz2' URL" do
      resource = Resource.new
      resource.url("http://example.com/foo.tar.bz2")
      expect(subject.add(resource)).to eq(Dependency.new("bzip2", [:build]))
    end
  end
end

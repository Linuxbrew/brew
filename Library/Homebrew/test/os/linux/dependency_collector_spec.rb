require "dependency_collector"

describe DependencyCollector do
  alias_matcher :be_a_build_requirement, :be_build

  after do
    described_class.clear_cache
  end

  describe "#add" do
    resource = Resource.new

    context "when xz, unzip, and bzip2 are not available" do
      it "creates a resource dependency from a '.xz' URL" do
        resource.url("https://example.com/foo.xz")
        allow_any_instance_of(Object).to receive(:which).with("xz")
        expect(subject.add(resource)).to eq(Dependency.new("xz", [:build]))
      end

      it "creates a resource dependency from a '.zip' URL" do
        resource.url("https://example.com/foo.zip")
        allow_any_instance_of(Object).to receive(:which).with("unzip")
        expect(subject.add(resource)).to eq(Dependency.new("unzip", [:build]))
      end

      it "creates a resource dependency from a '.bz2' URL" do
        resource.url("https://example.com/foo.tar.bz2")
        allow_any_instance_of(Object).to receive(:which).with("bzip2")
        expect(subject.add(resource)).to eq(Dependency.new("bzip2", [:build]))
      end
    end

    context "when xz, zip, and bzip2 are available" do
      it "does not create a resource dependency from a '.xz' URL" do
        resource.url("https://example.com/foo.xz")
        allow_any_instance_of(Object).to receive(:which).with("xz").and_return(Pathname.new("foo"))
        expect(subject.add(resource)).to be nil
      end

      it "does not create a resource dependency from a '.zip' URL" do
        resource.url("https://example.com/foo.zip")
        allow_any_instance_of(Object).to receive(:which).with("unzip").and_return(Pathname.new("foo"))
        expect(subject.add(resource)).to be nil
      end

      it "does not create a resource dependency from a '.bz2' URL" do
        resource.url("https://example.com/foo.tar.bz2")
        allow_any_instance_of(Object).to receive(:which).with("bzip2").and_return(Pathname.new("foo"))
        expect(subject.add(resource)).to be nil
      end
    end
  end
end

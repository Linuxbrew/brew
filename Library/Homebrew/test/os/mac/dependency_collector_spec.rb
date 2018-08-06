require "dependency_collector"

describe DependencyCollector do
  alias_matcher :need_tar_xz_dependency, :be_tar_needs_xz_dependency

  after do
    described_class.clear_cache
  end

  specify "#tar_needs_xz_dependency?" do
    allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.9"))
    expect(described_class).not_to need_tar_xz_dependency
  end

  specify "LD64 pre-Leopard dependency" do
    allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.4"))
    expect(subject.build(:ld64)).to eq(LD64Dependency.new)
  end

  specify "LD64 Leopard or newer dependency" do
    allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.5"))
    expect(subject.build(:ld64)).to be nil
  end

  specify "Resource xz pre-Mavericks dependency" do
    allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.8"))
    resource = Resource.new
    resource.url("https://example.com/foo.tar.xz")
    expect(subject.add(resource)).to eq(Dependency.new("xz", [:build]))
  end

  specify "Resource xz Mavericks or newer dependency" do
    allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.9"))
    resource = Resource.new
    resource.url("https://example.com/foo.tar.xz")
    expect(subject.add(resource)).to be nil
  end

  specify "Resource dependency from a '.zip' URL" do
    resource = Resource.new
    resource.url("https://example.com/foo.zip")
    expect(subject.add(resource)).to be nil
  end

  specify "Resource dependency from a '.bz2' URL" do
    resource = Resource.new
    resource.url("https://example.com/foo.tar.bz2")
    expect(subject.add(resource)).to be nil
  end

  specify "Resource dependency from a '.git' URL" do
    resource = Resource.new
    resource.url("git://example.com/foo/bar.git")
    expect(subject.add(resource)).to be nil
  end

  specify "Resource dependency from a Subversion URL" do
    resource = Resource.new
    resource.url("svn://example.com/foo/bar")
    expect(subject.add(resource)).to be nil
  end
end

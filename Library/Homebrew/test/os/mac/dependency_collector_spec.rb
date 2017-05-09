require "dependency_collector"

describe DependencyCollector do
  alias_matcher :need_tar_xz_dependency, :be_tar_needs_xz_dependency

  after(:each) do
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

  specify "ant Mavericks or newer dependency" do
    allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.9"))
    subject.add ant: :build
    expect(subject.deps.find { |dep| dep.name == "ant" }).to eq(Dependency.new("ant", [:build]))
  end

  specify "ant pre-Mavericks dependency" do
    allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.7"))
    subject.add ant: :build
    expect(subject.deps.find { |dep| dep.name == "ant" }).to be nil
  end

  specify "Resource xz pre-Mavericks dependency" do
    allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.8"))
    resource = Resource.new
    resource.url("http://example.com/foo.tar.xz")
    expect(subject.add(resource)).to eq(Dependency.new("xz", [:build]))
  end

  specify "Resource xz Mavericks or newer dependency" do
    allow(MacOS).to receive(:version).and_return(MacOS::Version.new("10.9"))
    resource = Resource.new
    resource.url("http://example.com/foo.tar.xz")
    expect(subject.add(resource)).to be nil
  end
end

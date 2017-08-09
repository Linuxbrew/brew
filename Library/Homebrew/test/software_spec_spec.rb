require "software_spec"

describe SoftwareSpec do
  alias_matcher :have_defined_resource, :be_resource_defined
  alias_matcher :have_defined_option, :be_option_defined

  let(:owner) { double(name: "some_name", full_name: "some_name", tap: "homebrew/core") }

  describe "#resource" do
    it "defines a resource" do
      subject.resource("foo") { url "foo-1.0" }
      expect(subject).to have_defined_resource("foo")
    end

    it "sets itself to be the resource's owner" do
      subject.resource("foo") { url "foo-1.0" }
      subject.owner = owner
      subject.resources.each_value do |r|
        expect(r.owner).to eq(subject)
      end
    end

    it "receives the owner's version if it has no own version" do
      subject.url("foo-42")
      subject.resource("bar") { url "bar" }
      subject.owner = owner

      expect(subject.resource("bar").version).to eq("42")
    end

    it "raises an error when duplicate resources are defined" do
      subject.resource("foo") { url "foo-1.0" }
      expect {
        subject.resource("foo") { url "foo-1.0" }
      }.to raise_error(DuplicateResourceError)
    end

    it "raises an error when accessing missing resources" do
      subject.owner = owner
      expect {
        subject.resource("foo")
      }.to raise_error(ResourceMissingError)
    end
  end

  describe "#owner" do
    it "sets the owner" do
      subject.owner = owner
      expect(subject.owner).to eq(owner)
    end

    it "sets the name" do
      subject.owner = owner
      expect(subject.name).to eq(owner.name)
    end
  end

  describe "#option" do
    it "defines an option" do
      subject.option("foo")
      expect(subject).to have_defined_option("foo")
    end

    it "raises an error when it begins with dashes" do
      expect {
        subject.option("--foo")
      }.to raise_error(ArgumentError)
    end

    it "raises an error when name is empty" do
      expect {
        subject.option("")
      }.to raise_error(ArgumentError)
    end

    it "special cases the cxx11 option" do
      subject.option(:cxx11)
      expect(subject).to have_defined_option("c++11")
      expect(subject).not_to have_defined_option("cxx11")
    end

    it "supports options with descriptions" do
      subject.option("bar", "description")
      expect(subject.options.first.description).to eq("description")
    end

    it "defaults to an empty string when no description is given" do
      subject.option("foo")
      expect(subject.options.first.description).to eq("")
    end
  end

  describe "#deprecated_option" do
    it "allows specifying deprecated options" do
      subject.deprecated_option("foo" => "bar")
      expect(subject.deprecated_options).not_to be_empty
      expect(subject.deprecated_options.first.old).to eq("foo")
      expect(subject.deprecated_options.first.current).to eq("bar")
    end

    it "allows specifying deprecated options as a Hash from an Array/String to an Array/String" do
      subject.deprecated_option(["foo1", "foo2"] => "bar1", "foo3" => ["bar2", "bar3"])
      expect(subject.deprecated_options).to include(DeprecatedOption.new("foo1", "bar1"))
      expect(subject.deprecated_options).to include(DeprecatedOption.new("foo2", "bar1"))
      expect(subject.deprecated_options).to include(DeprecatedOption.new("foo3", "bar2"))
      expect(subject.deprecated_options).to include(DeprecatedOption.new("foo3", "bar3"))
    end

    it "raises an error when empty" do
      expect {
        subject.deprecated_option({})
      }.to raise_error(ArgumentError)
    end
  end

  describe "#depends_on" do
    it "allows specifying dependencies" do
      subject.depends_on("foo")
      expect(subject.deps.first.name).to eq("foo")
    end

    it "allows specifying optional dependencies" do
      subject.depends_on "foo" => :optional
      expect(subject).to have_defined_option("with-foo")
    end

    it "allows specifying recommended dependencies" do
      subject.depends_on "bar" => :recommended
      expect(subject).to have_defined_option("without-bar")
    end
  end

  specify "explicit options override defaupt depends_on option description" do
    subject.option("with-foo", "blah")
    subject.depends_on("foo" => :optional)
    expect(subject.options.first.description).to eq("blah")
  end

  describe "#patch" do
    it "adds a patch" do
      subject.patch(:p1, :DATA)
      expect(subject.patches.count).to eq(1)
      expect(subject.patches.first.strip).to eq(:p1)
    end
  end
end

describe HeadSoftwareSpec do
  specify "#version" do
    expect(subject.version).to eq(Version.create("HEAD"))
  end

  specify "#verify_download_integrity" do
    expect(subject.verify_download_integrity(Object.new)).to be nil
  end
end

describe BottleSpecification do
  specify "#sha256" do
    checksums = {
      snow_leopard_32: "deadbeef" * 8,
      snow_leopard: "faceb00c" * 8,
      lion: "baadf00d" * 8,
      mountain_lion: "8badf00d" * 8,
    }

    checksums.each_pair do |cat, digest|
      subject.sha256(digest => cat)
    end

    checksums.each_pair do |cat, digest|
      checksum, = subject.checksum_for(cat)
      expect(Checksum.new(:sha256, digest)).to eq(checksum)
    end
  end

  %w[root_url prefix cellar rebuild].each do |method|
    specify "##{method}" do
      object = Object.new
      subject.public_send(method, object)
      expect(subject.public_send(method)).to eq(object)
    end
  end
end

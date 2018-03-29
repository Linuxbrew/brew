require "extend/ENV"
require "requirement"

describe Requirement do
  alias_matcher :be_a_build_requirement, :be_a_build

  subject { klass.new }

  let(:klass) { Class.new(described_class) }

  describe "#tags" do
    subject { described_class.new(tags) }

    context "single tag" do
      let(:tags) { ["bar"] }

      its(:tags) { are_expected.to eq(tags) }
    end

    context "multiple tags" do
      let(:tags) { ["bar", "baz"] }

      its(:tags) { are_expected.to eq(tags) }
    end

    context "symbol tags" do
      let(:tags) { [:build] }

      its(:tags) { are_expected.to eq(tags) }
    end

    context "symbol and string tags" do
      let(:tags) { [:build, "bar"] }

      its(:tags) { are_expected.to eq(tags) }
    end
  end

  describe "#fatal?" do
    context "#fatal true is specified" do
      let(:klass) do
        Class.new(described_class) do
          fatal true
        end
      end

      it { is_expected.to be_fatal }
    end

    context "#fatal is omitted" do
      it { is_expected.not_to be_fatal }
    end
  end

  describe "#satisfied?" do
    context "#satisfy with block and build_env returns true" do
      let(:klass) do
        Class.new(described_class) do
          satisfy(build_env: false) do
            true
          end
        end
      end

      it { is_expected.to be_satisfied }
    end

    context "#satisfy with block and build_env returns false" do
      let(:klass) do
        Class.new(described_class) do
          satisfy(build_env: false) do
            false
          end
        end
      end

      it { is_expected.not_to be_satisfied }
    end

    context "#satisfy returns true" do
      let(:klass) do
        Class.new(described_class) do
          satisfy true
        end
      end

      it { is_expected.to be_satisfied }
    end

    context "#satisfy returns false" do
      let(:klass) do
        Class.new(described_class) do
          satisfy false
        end
      end

      it { is_expected.not_to be_satisfied }
    end

    context "#satisfy with block returning true and without :build_env" do
      let(:klass) do
        Class.new(described_class) do
          satisfy do
            true
          end
        end
      end

      it "sets up build environment" do
        expect(ENV).to receive(:with_build_environment).and_call_original
        subject.satisfied?
      end
    end

    context "#satisfy with block returning true and :build_env set to false" do
      let(:klass) do
        Class.new(described_class) do
          satisfy(build_env: false) do
            true
          end
        end
      end

      it "skips setting up build environment" do
        expect(ENV).not_to receive(:with_build_environment)
        subject.satisfied?
      end
    end

    context "#satisfy with block returning path and without :build_env" do
      let(:klass) do
        Class.new(described_class) do
          satisfy do
            Pathname.new("/foo/bar/baz")
          end
        end
      end

      it "infers path from #satisfy result" do
        expect(ENV).to receive(:prepend_path).with("PATH", Pathname.new("/foo/bar"))
        subject.satisfied?
        subject.modify_build_environment
      end
    end
  end

  describe "#build?" do
    context ":build tag is specified" do
      subject { described_class.new([:build]) }

      it { is_expected.to be_a_build_requirement }
    end

    context "#build omitted" do
      it { is_expected.not_to be_a_build_requirement }
    end
  end

  describe "#name and #option_names" do
    let(:const) { :FooRequirement }
    let(:klass) { self.class.const_get(const) }

    before do
      self.class.const_set(const, Class.new(described_class))
    end

    after do
      self.class.send(:remove_const, const)
    end

    its(:name) { is_expected.to eq("foo") }
    its(:option_names) { are_expected.to eq(["foo"]) }
  end

  describe "#modify_build_environment" do
    context "without env proc" do
      let(:klass) { Class.new(described_class) }

      it "returns nil" do
        expect(subject.modify_build_environment).to be nil
      end
    end
  end

  describe "#eql? and #==" do
    subject { described_class.new }

    it "returns true if the names and tags are equal" do
      other = described_class.new

      expect(subject).to eql(other)
      expect(subject).to eq(other)
    end

    it "returns false if names differ" do
      other = described_class.new
      allow(other).to receive(:name).and_return("foo")
      expect(subject).not_to eql(other)
      expect(subject).not_to eq(other)
    end

    it "returns false if tags differ" do
      other = described_class.new([:optional])

      expect(subject).not_to eql(other)
      expect(subject).not_to eq(other)
    end
  end

  describe "#hash" do
    subject { described_class.new }

    it "is equal if names and tags are equal" do
      other = described_class.new
      expect(subject.hash).to eq(other.hash)
    end

    it "differs if names differ" do
      other = described_class.new
      allow(other).to receive(:name).and_return("foo")
      expect(subject.hash).not_to eq(other.hash)
    end

    it "differs if tags differ" do
      other = described_class.new([:optional])
      expect(subject.hash).not_to eq(other.hash)
    end
  end
end

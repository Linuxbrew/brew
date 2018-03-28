require "dependable"

describe Dependable do
  alias_matcher :be_a_build_dependency, :be_build

  subject { double(tags: tags).extend(described_class) }

  let(:tags) { ["foo", "bar", :build] }

  specify "#options" do
    expect(subject.options.as_flags.sort).to eq(%w[--foo --bar].sort)
  end

  specify "#build?" do
    expect(subject).to be_a_build_dependency
  end

  specify "#optional?" do
    expect(subject).not_to be_optional
  end

  specify "#recommended?" do
    expect(subject).not_to be_recommended
  end
end

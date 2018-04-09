require "build_options"
require "options"

describe BuildOptions do
  alias_matcher :be_built_with, :be_with
  alias_matcher :be_built_without, :be_without

  subject { described_class.new(args, opts) }

  let(:bad_build) { described_class.new(bad_args, opts) }
  let(:args) { Options.create(%w[--with-foo --with-bar --without-qux]) }
  let(:opts) { Options.create(%w[--with-foo --with-bar --without-baz --without-qux]) }
  let(:bad_args) { Options.create(%w[--with-foo --with-bar --without-bas --without-qux --without-abc]) }

  specify "#include?" do
    expect(subject).to include("with-foo")
    expect(subject).not_to include("with-qux")
    expect(subject).not_to include("--with-foo")
  end

  specify "#with?" do
    expect(subject).to be_built_with("foo")
    expect(subject).to be_built_with("bar")
    expect(subject).to be_built_with("baz")
  end

  specify "#without?" do
    expect(subject).to be_built_without("qux")
    expect(subject).to be_built_without("xyz")
  end

  specify "#used_options" do
    expect(subject.used_options).to include("--with-foo")
    expect(subject.used_options).to include("--with-bar")
  end

  specify "#unused_options" do
    expect(subject.unused_options).to include("--without-baz")
  end

  specify "#invalid_options" do
    expect(subject.invalid_options).to be_empty
    expect(bad_build.invalid_options).to include("--without-bas")
    expect(bad_build.invalid_options).to include("--without-abc")
    expect(bad_build.invalid_options).not_to include("--with-foo")
    expect(bad_build.invalid_options).not_to include("--with-baz")
  end

  specify "#invalid_option_names" do
    expect(subject.invalid_option_names).to be_empty
    expect(bad_build.invalid_option_names).to eq(%w[--without-abc --without-bas])
  end
end

require "options"

describe Option do
  subject { described_class.new("foo") }

  specify "#to_s" do
    expect(subject.to_s).to eq("--foo")
  end

  specify "equality" do
    foo = described_class.new("foo")
    bar = described_class.new("bar")
    expect(subject).to eq(foo)
    expect(subject).not_to eq(bar)
    expect(subject).to eql(foo)
    expect(subject).not_to eql(bar)
  end

  specify "#description" do
    expect(subject.description).to be_empty
    expect(described_class.new("foo", "foo").description).to eq("foo")
  end

  specify "#inspect" do
    expect(subject.inspect).to eq("#<Option: \"--foo\">")
  end
end

describe DeprecatedOption do
  subject { described_class.new("foo", "bar") }

  specify "#old" do
    expect(subject.old).to eq("foo")
  end

  specify "#old_flag" do
    expect(subject.old_flag).to eq("--foo")
  end

  specify "#current" do
    expect(subject.current).to eq("bar")
  end

  specify "#current_flag" do
    expect(subject.current_flag).to eq("--bar")
  end

  specify "equality" do
    foobar = described_class.new("foo", "bar")
    boofar = described_class.new("boo", "far")
    expect(foobar).to eq(subject)
    expect(subject).to eq(foobar)
    expect(boofar).not_to eq(subject)
    expect(subject).not_to eq(boofar)
  end
end

describe Options do
  it "removes duplicate options" do
    subject << Option.new("foo")
    subject << Option.new("foo")
    expect(subject).to include("--foo")
    expect(subject.count).to eq(1)
  end

  it "preserves  existing member when adding a duplicate" do
    a = Option.new("foo", "bar")
    b = Option.new("foo", "qux")
    subject << a << b
    expect(subject.count).to eq(1)
    expect(subject.first).to be(a)
    expect(subject.first.description).to eq(a.description)
  end

  specify "#include?" do
    subject << Option.new("foo")
    expect(subject).to include("--foo")
    expect(subject).to include("foo")
    expect(subject).to include(Option.new("foo"))
  end

  describe "#+" do
    it "returns options" do
      expect(subject + described_class.new).to be_an_instance_of(described_class)
    end
  end

  describe "#-" do
    it "returns options" do
      expect(subject - described_class.new).to be_an_instance_of(described_class)
    end
  end

  specify "#&" do
    foo, bar, baz = %w[foo bar baz].map { |o| Option.new(o) }
    options = described_class.new << foo << bar
    subject << foo << baz
    expect((subject & options).to_a).to eq([foo])
  end

  specify "#|" do
    foo, bar, baz = %w[foo bar baz].map { |o| Option.new(o) }
    options = described_class.new << foo << bar
    subject << foo << baz
    expect((subject | options).sort).to eq([foo, bar, baz].sort)
  end

  specify "#*" do
    subject << Option.new("aa") << Option.new("bb") << Option.new("cc")
    expect((subject * "XX").split("XX").sort).to eq(%w[--aa --bb --cc])
  end

  describe "<<" do
    it "returns itself" do
      expect(subject << Option.new("foo")).to be subject
    end
  end

  specify "#as_flags" do
    subject << Option.new("foo")
    expect(subject.as_flags).to eq(%w[--foo])
  end

  specify "#to_a" do
    option = Option.new("foo")
    subject << option
    expect(subject.to_a).to eq([option])
  end

  specify "#to_ary" do
    option = Option.new("foo")
    subject << option
    expect(subject.to_ary).to eq([option])
  end

  specify "::create_with_array" do
    array = %w[--foo --bar]
    option1 = Option.new("foo")
    option2 = Option.new("bar")
    expect(described_class.create(array).sort).to eq([option1, option2].sort)
  end

  specify "#inspect" do
    expect(subject.inspect).to eq("#<Options: []>")
    subject << Option.new("foo")
    expect(subject.inspect).to eq("#<Options: [#<Option: \"--foo\">]>")
  end
end

require "dependencies"
require "dependency"

describe Dependencies do
  describe "#<<" do
    it "returns itself" do
      expect(subject << Dependency.new("foo")).to eq(subject)
    end

    it "preserves order" do
      hash = { 0 => "foo", 1 => "bar", 2 => "baz" }

      subject << Dependency.new(hash[0])
      subject << Dependency.new(hash[1])
      subject << Dependency.new(hash[2])

      subject.each_with_index do |dep, i|
        expect(dep.name).to eq(hash[i])
      end
    end
  end

  specify "#*" do
    subject << Dependency.new("foo")
    subject << Dependency.new("bar")
    expect(subject * ", ").to eq("foo, bar")
  end

  specify "#to_a" do
    dep = Dependency.new("foo")
    subject << dep
    expect(subject.to_a).to eq([dep])
  end

  specify "#to_ary" do
    dep = Dependency.new("foo")
    subject << dep
    expect(subject.to_ary).to eq([dep])
  end

  specify "type helpers" do
    foo = Dependency.new("foo")
    bar = Dependency.new("bar", [:optional])
    baz = Dependency.new("baz", [:build])
    qux = Dependency.new("qux", [:recommended])
    quux = Dependency.new("quux")
    subject << foo << bar << baz << qux << quux
    expect(subject.required).to eq([foo, quux])
    expect(subject.optional).to eq([bar])
    expect(subject.build).to eq([baz])
    expect(subject.recommended).to eq([qux])
    expect(subject.default.sort_by(&:name)).to eq([foo, baz, quux, qux].sort_by(&:name))
  end

  specify "equality" do
    a = Dependencies.new
    b = Dependencies.new

    dep = Dependency.new("foo")

    a << dep
    b << dep

    expect(a).to eq(b)
    expect(a).to eql(b)

    b << Dependency.new("bar", [:optional])

    expect(a).not_to eq(b)
    expect(a).not_to eql(b)
  end

  specify "#empty?" do
    expect(subject).to be_empty

    subject << Dependency.new("foo")
    expect(subject).not_to be_empty
  end

  specify "#inspect" do
    expect(subject.inspect).to eq("#<Dependencies: []>")

    subject << Dependency.new("foo")
    expect(subject.inspect).to eq("#<Dependencies: [#<Dependency: \"foo\" []>]>")
  end
end

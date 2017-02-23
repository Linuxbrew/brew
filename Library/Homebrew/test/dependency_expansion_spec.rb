require "dependency"

describe Dependency do
  def build_dep(name, tags = [], deps = [])
    dep = described_class.new(name.to_s, tags)
    allow(dep).to receive(:to_formula).and_return(double(deps: deps, name: name))
    dep
  end

  let(:foo) { build_dep(:foo) }
  let(:bar) { build_dep(:bar) }
  let(:baz) { build_dep(:baz) }
  let(:qux) { build_dep(:qux) }
  let(:deps) { [foo, bar, baz, qux] }
  let(:formula) { double(deps: deps, name: "f") }

  describe "::expand" do
    it "yields dependent and dependency pairs" do
      i = 0
      described_class.expand(formula) do |dependent, dep|
        expect(dependent).to eq(formula)
        expect(deps[i]).to eq(dep)
        i += 1
      end
    end

    it "returns the dependencies" do
      expect(described_class.expand(formula)).to eq(deps)
    end

    it "prunes all when given a block with ::prune" do
      expect(described_class.expand(formula) { described_class.prune }).to be_empty
    end

    it "can prune selectively" do
      deps = described_class.expand(formula) do |_, dep|
        described_class.prune if dep.name == "foo"
      end

      expect(deps).to eq([bar, baz, qux])
    end

    it "preserves dependency order" do
      allow(foo).to receive(:to_formula).and_return(double(name: "f", deps: [qux, baz]))
      expect(described_class.expand(formula)).to eq([qux, baz, foo, bar])
    end
  end

  it "skips optionals by default" do
    deps = [build_dep(:foo, [:optional]), bar, baz, qux]
    f = double(deps: deps, build: double(with?: false), name: "f")
    expect(described_class.expand(f)).to eq([bar, baz, qux])
  end

  it "keeps recommended dependencies by default" do
    deps = [build_dep(:foo, [:recommended]), bar, baz, qux]
    f = double(deps: deps, build: double(with?: true), name: "f")
    expect(described_class.expand(f)).to eq(deps)
  end

  it "merges repeated dependencies with differing options" do
    foo2 = build_dep(:foo, ["option"])
    baz2 = build_dep(:baz, ["option"])
    deps << foo2 << baz2
    deps = [foo2, bar, baz2, qux]
    deps.zip(described_class.expand(formula)) do |expected, actual|
      expect(expected.tags).to eq(actual.tags)
      expect(expected).to eq(actual)
    end
  end

  it "merges dependencies and perserves env_proc" do
    env_proc = double
    dep = described_class.new("foo", [], env_proc)
    allow(dep).to receive(:to_formula).and_return(double(deps: [], name: "foo"))
    deps.replace([dep])
    expect(described_class.expand(formula).first.env_proc).to eq(env_proc)
  end

  it "merges tags without duplicating them" do
    foo2 = build_dep(:foo, ["option"])
    foo3 = build_dep(:foo, ["option"])
    deps << foo2 << foo3

    expect(described_class.expand(formula).first.tags).to eq(%w[option])
  end

  it "skips parent but yields children with ::skip" do
    f = double(
      name: "f",
      deps: [
        build_dep(:foo, [], [bar, baz]),
        build_dep(:foo, [], [baz]),
      ],
    )

    deps = described_class.expand(f) do |_dependent, dep|
      described_class.skip if %w[foo qux].include? dep.name
    end

    expect(deps).to eq([bar, baz])
  end

  it "keeps dependency but prunes recursive dependencies with ::keep_but_prune_recursive_deps" do
    foo = build_dep(:foo, [:build], bar)
    baz = build_dep(:baz, [:build])
    f = double(name: "f", deps: [foo, baz])

    deps = described_class.expand(f) do |_dependent, dep|
      described_class.keep_but_prune_recursive_deps if dep.build?
    end

    expect(deps).to eq([foo, baz])
  end

  it "returns only the dependencies given as a collection as second argument" do
    expect(formula.deps).to eq([foo, bar, baz, qux])
    expect(described_class.expand(formula, [bar, baz])).to eq([bar, baz])
  end

  it "doesn't raise an error when a dependency is cyclic" do
    foo = build_dep(:foo)
    bar = build_dep(:bar, [], [foo])
    allow(foo).to receive(:to_formula).and_return(double(deps: [bar], name: foo.name))
    f = double(name: "f", deps: [foo, bar])
    expect { described_class.expand(f) }.not_to raise_error
  end

  it "cleans the expand stack" do
    foo = build_dep(:foo)
    allow(foo).to receive(:to_formula).and_raise(FormulaUnavailableError, foo.name)
    f = double(name: "f", deps: [foo])
    expect { described_class.expand(f) }.to raise_error(FormulaUnavailableError)
    expect(described_class.instance_variable_get(:@expand_stack)).to be_empty
  end
end

require "messages"
require "spec_helper"

describe Messages do
  before do
    @m = Messages.new
    f_foo = formula("foo") do
      url "https://example.com/foo-0.1.tgz"
    end
    f_bar = formula("bar") do
      url "https://example.com/bar-0.1.tgz"
    end
    f_baz = formula("baz") do
      url "https://example.com/baz-0.1.tgz"
    end
    @m.formula_installed(f_foo, 1.1)
    @m.record_caveats(f_foo, "Zsh completions were installed")
    @m.formula_installed(f_bar, 2.2)
    @m.record_caveats(f_bar, "Keg-only formula")
    @m.formula_installed(f_baz, 3.3)
    @m.record_caveats(f_baz, "A valid GOPATH is required to use the go command")
  end

  it "has the right installed-formula count" do
    expect(@m.formula_count).to equal(3)
  end

  it "has recorded caveats" do
    expect(@m.caveats).to_not be_empty
  end

  it "maintained the order of recorded caveats" do
    caveats_formula_order = @m.caveats.map { |x| x[:formula] }
    expect(caveats_formula_order).to eq(["foo", "bar", "baz"])
  end

  it "has recorded installation times" do
    expect(@m.install_times).to_not be_empty
  end

  it "maintained the order of install times" do
    formula_order = @m.install_times.map { |x| x[:formula] }
    expect(formula_order).to eq(["foo", "bar", "baz"])
  end

  it "recorded the right install times" do
    times = @m.install_times.map { |x| x[:time] }
    expect(times).to eq([1.1, 2.2, 3.3])
  end
end

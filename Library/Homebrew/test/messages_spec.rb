require "messages"
require "spec_helper"

describe Messages do

  before do
    @m = Messages.new
    f_foo = formula("foo") do
      url "http://example.com/foo-0.1.tgz"
    end
    f_bar = formula("bar") do
      url "http://example.com/bar-0.1.tgz"
    end
    f_baz = formula("baz") do
      url "http://example.com/baz-0.1.tgz"
    end
    @m.formula_installed(f_foo)
    @m.record_caveats(f_foo, "Zsh completions were installed")
    @m.formula_installed(f_bar)
    @m.record_caveats(f_bar, "Keg-only formula")
    @m.formula_installed(f_baz)
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

end
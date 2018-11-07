require "extend/ENV"

describe "brew reinstall", :integration_test do
  before do
    setup_test_formula "testball"

    expect { brew "install", "testball", "--with-foo" }.to be_a_success
  end

  it "reinstalls a Formula" do
    foo_dir = HOMEBREW_CELLAR/"testball/0.1/foo"
    expect(foo_dir).to exist
    foo_dir.rmtree

    expect { brew "reinstall", "testball" }
      .to output(/Reinstalling testball --with-foo/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect(foo_dir).to exist
  end

  it "reinstalls a Formula even when one of the options is invalid" do
    expect { brew "reinstall", "testball", "--with-fo" }
      .to output(/Error: invalid option: --with-fo/).to_stderr
      .and be_a_failure
  end

  it "refuses to reinstall a pinned Formula, but doesn't fail" do
    (HOMEBREW_CELLAR/"testball/0.1").mkpath
    HOMEBREW_PINNED_KEGS.mkpath
    FileUtils.ln_s HOMEBREW_CELLAR/"testball/0.1", HOMEBREW_PINNED_KEGS/"testball"

    expect { brew "reinstall", "testball" }
      .to output(/testball is pinned. You must unpin it to reinstall./).to_stderr
      .and not_to_output.to_stdout
      .and be_a_success

    HOMEBREW_PINNED_KEGS.rmtree
  end
end

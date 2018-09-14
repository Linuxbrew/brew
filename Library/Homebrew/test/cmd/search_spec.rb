require "cmd/search"

describe "brew search", :integration_test do
  before do
    setup_test_formula "testball"
  end

  it "lists all available Formulae when no argument is given" do
    expect { brew "search" }
      .to output(/testball/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "supports searching by name" do
    expect { brew "search", "testball" }
      .to output(/testball/).to_stdout
      .and be_a_success
  end

  it "supports searching a fully-qualified name " do
    expect { brew "search", "homebrew/homebrew-core/testball" }
      .to output(/testball/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  it "falls back to a GitHub tap search when no formula is found", :needs_network do
    setup_remote_tap "homebrew/cask"

    expect { brew "search", "homebrew/cask/firefox" }
      .to output(/firefox/).to_stdout
      .and be_a_success
  end

  describe "--desc" do
    let(:desc_cache) { HOMEBREW_CACHE/"desc_cache.json" }

    it "supports searching in descriptions and creates a description cache" do
      expect(desc_cache).not_to exist

      expect { brew "search", "--desc", "Some test" }
        .to output(/testball/).to_stdout
        .and not_to_output.to_stderr
        .and be_a_success

      expect(desc_cache).to exist
    end
  end

  {
    "macports" => "https://www.macports.org/ports.php?by=name&substr=testball",
    "fink" => "http://pdb.finkproject.org/pdb/browse.php?summary=testball",
    "debian" => "https://packages.debian.org/search?keywords=testball&searchon=names&suite=all&section=all",
    "opensuse" => "https://software.opensuse.org/search?q=testball",
    "fedora" => "https://apps.fedoraproject.org/packages/s/testball",
    "ubuntu" => "https://packages.ubuntu.com/search?keywords=testball&searchon=names&suite=all&section=all",
  }.each do |flag, url|
    specify "--#{flag}" do
      expect { brew "search", "--#{flag}", "testball", "HOMEBREW_BROWSER" => "echo" }
        .to output("#{url}\n").to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end
end

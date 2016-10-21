require "helper/integration_command_test_case"

class IntegrationCommandTestSearch < IntegrationCommandTestCase
  def test_search
    setup_test_formula "testball"
    desc_cache = HOMEBREW_CACHE/"desc_cache.json"
    refute_predicate desc_cache, :exist?, "Cached file should not exist"

    assert_match "testball", cmd("search")
    assert_match "testball", cmd("search", "testball")
    assert_match "testball", cmd("search", "homebrew/homebrew-core/testball")
    assert_match "testball", cmd("search", "--desc", "Some test")

    flags = {
      "macports" => "https://www.macports.org/ports.php?by=name&substr=testball",
      "fink" => "http://pdb.finkproject.org/pdb/browse.php?summary=testball",
      "debian" => "https://packages.debian.org/search?keywords=testball&searchon=names&suite=all&section=all",
      "opensuse" => "https://software.opensuse.org/search?q=testball",
      "fedora" => "https://admin.fedoraproject.org/pkgdb/packages/%2Atestball%2A/",
      "ubuntu" => "http://packages.ubuntu.com/search?keywords=testball&searchon=names&suite=all&section=all",
    }

    flags.each do |flag, url|
      assert_equal url, cmd("search", "--#{flag}",
        "testball", "HOMEBREW_BROWSER" => "echo")
    end

    assert_predicate desc_cache, :exist?, "Cached file should exist"
  end
end

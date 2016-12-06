class TestballBottle < Formula
  def initialize(name = "testball_bottle", path = Pathname.new(__FILE__).expand_path, spec = :stable, alias_path: nil)
    self.class.instance_eval do
      stable.url "file://#{TEST_FIXTURE_DIR}/tarballs/testball-0.1.tbz"
      stable.sha256 TESTBALL_SHA256
      stable.bottle do
        cellar :any_skip_relocation
        root_url "file://#{TEST_FIXTURE_DIR}/bottles"
        sha256 "9abc8ce779067e26556002c4ca6b9427b9874d25f0cafa7028e05b5c5c410cb4" => Utils::Bottles.tag
      end
      cxxstdlib_check :skip
    end
    super
  end

  def install
    prefix.install "bin"
    prefix.install "libexec"
  end
end

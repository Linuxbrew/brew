class Failball < Formula
  def initialize(name = "failball", path = Pathname.new(__FILE__).expand_path, spec = :stable, alias_path: nil)
    self.class.instance_eval do
      stable.url "file://#{TEST_FIXTURE_DIR}/tarballs/testball-0.1.tbz"
      stable.sha256 TESTBALL_SHA256
    end
    super
  end

  def install
    prefix.install "bin"
    prefix.install "libexec"

    # This should get marshalled into a BuildError.
    system "/usr/bin/false" if ENV["FAILBALL_BUILD_ERROR"]

    # This should get marshalled into a RuntimeError.
    raise "something that isn't a build error happened!"
  end
end

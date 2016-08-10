require "utils"

class Gpg
  # Should ideally be using `GPGRequirement.new.gpg2`, etc to get path here but
  # calling that directly leads to:
  # requirement.rb:139:in `which_all': uninitialized constant Requirement::ORIGINAL_PATHS (NameError)
  # when i.e. including the gpg syntax in wget. Not problematic if not used by formula code.
  # For now, the path determination blob of code has been semi-modified for here.
  # Look into this more.
  def self.gpg
    which("gpg") do |gpg|
      gpg_short_version = Utils.popen_read(gpg, "--version")[/\d\.\d/, 0]
      next unless gpg_short_version
      Version.create(gpg_short_version.to_s) == Version.create("2.0")
    end
  end

  def self.gpg2
    which("gpg2") do |gpg2|
      gpg2_short_version = Utils.popen_read(gpg2, "--version")[/\d\.\d/, 0]
      next unless gpg2_short_version
      Version.create(gpg2_short_version.to_s) == Version.create("2.0")
    end
  end

  GPG_EXECUTABLE = gpg2 || gpg

  def self.available?
    File.exist?(GPG_EXECUTABLE.to_s) && File.executable?(GPG_EXECUTABLE)
  end

  def self.create_test_key(path)
    odie "No GPG present to test against!" unless available?

    (path/"batch.gpg").write <<-EOS.undent
      Key-Type: RSA
      Key-Length: 2048
      Subkey-Type: RSA
      Subkey-Length: 2048
      Name-Real: Testing
      Name-Email: testing@foo.bar
      Expire-Date: 1d
      %commit
    EOS
    system GPG_EXECUTABLE, "--batch", "--gen-key", "batch.gpg"
  end
end

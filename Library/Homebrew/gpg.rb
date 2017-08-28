require "utils"

class Gpg
  def self.find_gpg(executable)
    which_all(executable).detect do |gpg|
      gpg_short_version = Utils.popen_read(gpg, "--version")[/\d\.\d/, 0]
      next unless gpg_short_version
      gpg_version = Version.create(gpg_short_version.to_s)
      @version = gpg_version
      gpg_version >= Version.create("2.0")
    end
  end

  def self.gpg
    find_gpg("gpg")
  end

  def self.gpg2
    find_gpg("gpg2")
  end

  GPG_EXECUTABLE = gpg || gpg2

  def self.available?
    File.executable?(GPG_EXECUTABLE.to_s)
  end

  def self.version
    @version if available?
  end

  def self.create_test_key(path)
    odie "No GPG present to test against!" unless available?

    (path/"batch.gpg").write <<-EOS.undent
      Key-Type: RSA
      Key-Length: 2048
      Subkey-Type: RSA
      Subkey-Length: 2048
      Passphrase: ''
      Name-Real: Testing
      Name-Email: testing@foo.bar
      Expire-Date: 1d
      %commit
    EOS
    system GPG_EXECUTABLE, "--batch", "--gen-key", "batch.gpg"
  end
end

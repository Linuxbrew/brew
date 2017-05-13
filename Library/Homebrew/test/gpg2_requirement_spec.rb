require "requirements/gpg2_requirement"
require "fileutils"

describe GPG2Requirement do
  let(:dir) { mktmpdir }

  describe "#satisfied?" do
    it "returns true if GPG2 is installed" do
      ENV["PATH"] = dir/"bin"
      (dir/"bin/gpg").write <<-EOS.undent
        #!/bin/bash
        echo 2.1.20
      EOS
      FileUtils.chmod 0755, dir/"bin/gpg"

      expect(subject).to be_satisfied
    end
  end
end

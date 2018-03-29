require "open3"

describe "Bash" do
  matcher :have_valid_bash_syntax do
    match do |file|
      stdout, stderr, status = Open3.capture3("/bin/bash", "-n", file)

      @actual = [file, stderr]

      stdout.empty? && status.success?
    end

    failure_message do |(file, stderr)|
      "expected that #{file} is a valid Bash file:\n#{stderr}"
    end
  end

  context "brew" do
    subject { HOMEBREW_LIBRARY_PATH.parent.parent/"bin/brew" }

    it { is_expected.to have_valid_bash_syntax }
  end

  context "every `.sh` file" do
    it "has valid bash syntax" do
      Pathname.glob("#{HOMEBREW_LIBRARY_PATH}/**/*.sh").each do |path|
        relative_path = path.relative_path_from(HOMEBREW_LIBRARY_PATH)
        next if relative_path.to_s.start_with?("shims/", "test/", "vendor/")

        expect(path).to have_valid_bash_syntax
      end
    end
  end

  context "Bash completion" do
    subject { HOMEBREW_LIBRARY_PATH.parent.parent/"completions/bash/brew" }

    it { is_expected.to have_valid_bash_syntax }
  end

  context "every shim script" do
    it "has valid bash syntax" do
      # These have no file extension, but can be identified by their shebang.
      (HOMEBREW_LIBRARY_PATH/"shims").find do |path|
        next if path.directory?
        next if path.symlink?
        next unless path.executable?
        next unless path.read(12) == "#!/bin/bash\n"

        expect(path).to have_valid_bash_syntax
      end
    end
  end
end

require "utils/shell"

describe Utils::Shell do
  describe "::shell_profile" do
    it "returns ~/.bash_profile by default" do
      ENV["SHELL"] = "/bin/another_shell"
      expect(subject.shell_profile).to eq("~/.bash_profile")
    end

    it "returns ~/.bash_profile for Sh" do
      ENV["SHELL"] = "/bin/another_shell"
      expect(subject.shell_profile).to eq("~/.bash_profile")
    end

    it "returns ~/.bash_profile for Bash" do
      ENV["SHELL"] = "/bin/bash"
      expect(subject.shell_profile).to eq("~/.bash_profile")
    end

    it "returns ~/.zshrc for Zsh" do
      ENV["SHELL"] = "/bin/zsh"
      expect(subject.shell_profile).to eq("~/.zshrc")
    end

    it "returns ~/.kshrc for Ksh" do
      ENV["SHELL"] = "/bin/ksh"
      expect(subject.shell_profile).to eq("~/.kshrc")
    end
  end

  describe "::path_to_shell" do
    it "supports a raw command name" do
      expect(subject.path_to_shell("bash")).to eq(:bash)
    end

    it "supports full paths" do
      expect(subject.path_to_shell("/bin/bash")).to eq(:bash)
    end

    it "supports versions" do
      expect(subject.path_to_shell("zsh-5.2")).to eq(:zsh)
    end

    it "strips newlines" do
      expect(subject.path_to_shell("zsh-5.2\n")).to eq(:zsh)
    end

    it "returns nil when input is invalid" do
      expect(subject.path_to_shell("")).to be nil
      expect(subject.path_to_shell("@@@@@@")).to be nil
      expect(subject.path_to_shell("invalid_shell-4.2")).to be nil
    end
  end

  specify "::sh_quote" do
    expect(subject.sh_quote("")).to eq("''")
    expect(subject.sh_quote("\\")).to eq("\\\\")
    expect(subject.sh_quote("\n")).to eq("'\n'")
    expect(subject.sh_quote("$")).to eq("\\$")
    expect(subject.sh_quote("word")).to eq("word")
  end

  specify "::csh_quote" do
    expect(subject.csh_quote("")).to eq("''")
    expect(subject.csh_quote("\\")).to eq("\\\\")
    # note this test is different than for sh
    expect(subject.csh_quote("\n")).to eq("'\\\n'")
    expect(subject.csh_quote("$")).to eq("\\$")
    expect(subject.csh_quote("word")).to eq("word")
  end

  describe "::prepend_path_in_shell_profile" do
    let(:path) { "/my/path" }

    it "supports Tcsh" do
      ENV["SHELL"] = "/bin/tcsh"
      expect(subject.prepend_path_in_shell_profile(path))
        .to start_with("echo 'setenv PATH #{path}:$")
    end

    it "supports Bash" do
      ENV["SHELL"] = "/bin/bash"
      expect(subject.prepend_path_in_shell_profile(path))
        .to start_with("echo 'export PATH=\"#{path}:$")
    end

    it "supports Fish" do
      ENV["SHELL"] = "/usr/local/bin/fish"
      expect(subject.prepend_path_in_shell_profile(path))
        .to start_with("echo 'set -g fish_user_paths \"#{path}\" $fish_user_paths' >>")
    end
  end
end

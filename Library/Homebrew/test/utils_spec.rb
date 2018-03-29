require "utils"

describe "globally-scoped helper methods" do
  let(:dir) { mktmpdir }

  def esc(code)
    /(\e\[\d+m)*\e\[#{code}m/
  end

  describe "#ofail" do
    it "sets Homebrew.failed to true" do
      expect {
        ofail "foo"
      }.to output("Error: foo\n").to_stderr

      expect(Homebrew).to have_failed
    end
  end

  describe "#odie" do
    it "exits with 1" do
      expect(self).to receive(:exit).and_return(1)
      expect {
        odie "foo"
      }.to output("Error: foo\n").to_stderr
    end
  end

  describe "#pretty_installed" do
    subject { pretty_installed("foo") }

    context "when $stdout is a TTY" do
      before { allow($stdout).to receive(:tty?).and_return(true) }

      context "with HOMEBREW_NO_EMOJI unset" do
        before { ENV.delete("HOMEBREW_NO_EMOJI") }

        it "returns a string with a colored checkmark" do
          expect(subject)
            .to match(/#{esc 1}foo #{esc 32}✔#{esc 0}/)
        end
      end

      context "with HOMEBREW_NO_EMOJI set" do
        before { ENV["HOMEBREW_NO_EMOJI"] = "1" }

        it "returns a string with colored info" do
          expect(subject)
            .to match(/#{esc 1}foo \(installed\)#{esc 0}/)
        end
      end
    end

    context "when $stdout is not a TTY" do
      before { allow($stdout).to receive(:tty?).and_return(false) }

      it "returns plain text" do
        expect(subject).to eq("foo")
      end
    end
  end

  describe "#pretty_uninstalled" do
    subject { pretty_uninstalled("foo") }

    context "when $stdout is a TTY" do
      before { allow($stdout).to receive(:tty?).and_return(true) }

      context "with HOMEBREW_NO_EMOJI unset" do
        before { ENV.delete("HOMEBREW_NO_EMOJI") }

        it "returns a string with a colored checkmark" do
          expect(subject)
            .to match(/#{esc 1}foo #{esc 31}✘#{esc 0}/)
        end
      end

      context "with HOMEBREW_NO_EMOJI set" do
        before { ENV["HOMEBREW_NO_EMOJI"] = "1" }

        it "returns a string with colored info" do
          expect(subject)
            .to match(/#{esc 1}foo \(uninstalled\)#{esc 0}/)
        end
      end
    end

    context "when $stdout is not a TTY" do
      before { allow($stdout).to receive(:tty?).and_return(false) }

      it "returns plain text" do
        expect(subject).to eq("foo")
      end
    end
  end

  describe "#interactive_shell" do
    let(:shell) { dir/"myshell" }

    it "starts an interactive shell session" do
      IO.write shell, <<~EOS
        #!/bin/sh
        echo called > "#{dir}/called"
      EOS

      FileUtils.chmod 0755, shell

      ENV["SHELL"] = shell

      expect { interactive_shell }.not_to raise_error
      expect(dir/"called").to exist
    end
  end

  describe "#with_custom_locale" do
    it "temporarily overrides the system locale" do
      ENV["LC_ALL"] = "en_US.UTF-8"

      with_custom_locale("C") do
        expect(ENV["LC_ALL"]).to eq("C")
      end

      expect(ENV["LC_ALL"]).to eq("en_US.UTF-8")
    end
  end

  describe "#run_as_not_developer" do
    it "temporarily unsets HOMEBREW_DEVELOPER" do
      ENV["HOMEBREW_DEVELOPER"] = "foo"

      run_as_not_developer do
        expect(ENV["HOMEBREW_DEVELOPER"]).to be nil
      end

      expect(ENV["HOMEBREW_DEVELOPER"]).to eq("foo")
    end
  end

  describe "#which" do
    let(:cmd) { dir/"foo" }

    before { FileUtils.touch cmd }

    it "returns the first executable that is found" do
      cmd.chmod 0744
      expect(which(File.basename(cmd), File.dirname(cmd))).to eq(cmd)
    end

    it "skips non-executables" do
      expect(which(File.basename(cmd), File.dirname(cmd))).to be nil
    end

    it "skips malformed path and doesn't fail" do
      # 'which' should not fail if a path is malformed
      # see https://github.com/Homebrew/legacy-homebrew/issues/32789 for an example
      cmd.chmod 0744

      # ~~ will fail because ~foo resolves to foo's home and there is no '~' user
      path = ["~~", File.dirname(cmd)].join(File::PATH_SEPARATOR)
      expect(which(File.basename(cmd), path)).to eq(cmd)
    end
  end

  describe "#which_all" do
    let(:cmd1) { dir/"foo" }
    let(:cmd2) { dir/"bar/foo" }
    let(:cmd3) { dir/"bar/baz/foo" }

    before do
      (dir/"bar/baz").mkpath

      FileUtils.touch cmd2

      [cmd1, cmd3].each do |cmd|
        FileUtils.touch cmd
        cmd.chmod 0744
      end
    end

    it "returns an array of all executables that are found" do
      path = [
        "#{dir}/bar/baz",
        "#{dir}/baz:#{dir}",
        "~baduserpath",
      ].join(File::PATH_SEPARATOR)
      expect(which_all("foo", path)).to eq([cmd3, cmd1])
    end
  end

  specify "#which_editor" do
    ENV["HOMEBREW_EDITOR"] = "vemate -w"
    ENV["HOMEBREW_PATH"] = dir

    editor = "#{dir}/vemate"
    FileUtils.touch editor
    FileUtils.chmod 0755, editor

    expect(which_editor).to eq("vemate -w")
  end

  specify "#gzip" do
    mktmpdir do |path|
      somefile = path/"somefile"
      FileUtils.touch somefile
      expect(gzip(somefile)[0].to_s).to eq("#{somefile}.gz")
      expect(Pathname.new("#{somefile}.gz")).to exist
    end
  end

  specify "#capture_stderr" do
    err = capture_stderr do
      $stderr.print "test"
    end

    expect(err).to eq("test")
  end

  describe "#pretty_duration" do
    it "converts seconds to a human-readable string" do
      expect(pretty_duration(1)).to eq("1 second")
      expect(pretty_duration(2.5)).to eq("2 seconds")
      expect(pretty_duration(42)).to eq("42 seconds")
      expect(pretty_duration(240)).to eq("4 minutes")
      expect(pretty_duration(252.45)).to eq("4 minutes 12 seconds")
    end
  end

  specify "#disk_usage_readable" do
    expect(disk_usage_readable(1)).to eq("1B")
    expect(disk_usage_readable(1000)).to eq("1000B")
    expect(disk_usage_readable(1024)).to eq("1KB")
    expect(disk_usage_readable(1025)).to eq("1KB")
    expect(disk_usage_readable(4_404_020)).to eq("4.2MB")
    expect(disk_usage_readable(4_509_715_660)).to eq("4.2GB")
  end

  describe "#number_readable" do
    it "returns a string with thousands separators" do
      expect(number_readable(1)).to eq("1")
      expect(number_readable(1_000)).to eq("1,000")
      expect(number_readable(1_000_000)).to eq("1,000,000")
    end
  end

  specify "#truncate_text_to_approximate_size" do
    glue = "\n[...snip...]\n" # hard-coded copy from truncate_text_to_approximate_size
    n = 20
    long_s = "x" * 40

    s = truncate_text_to_approximate_size(long_s, n)
    expect(s.length).to eq(n)
    expect(s).to match(/^x+#{Regexp.escape(glue)}x+$/)

    s = truncate_text_to_approximate_size(long_s, n, front_weight: 0.0)
    expect(s).to eq(glue + ("x" * (n - glue.length)))

    s = truncate_text_to_approximate_size(long_s, n, front_weight: 1.0)
    expect(s).to eq(("x" * (n - glue.length)) + glue)
  end

  describe "#odeprecated" do
    it "raises a MethodDeprecatedError" do
      ENV.delete("HOMEBREW_DEVELOPER")
      expect {
        odeprecated(
          "method", "replacement",
          caller: ["#{HOMEBREW_LIBRARY}/Taps/homebrew/homebrew-core/"],
          disable: true
        )
      }.to raise_error(MethodDeprecatedError, %r{method.*replacement.*homebrew/homebrew-core.*homebrew/core}m)
    end
  end

  describe "#with_env" do
    it "sets environment variables within the block" do
      expect(ENV["PATH"]).not_to eq("/bin")
      with_env(PATH: "/bin") do
        expect(ENV["PATH"]).to eq("/bin")
      end
    end

    it "restores ENV after the block" do
      with_env(PATH: "/bin") do
        expect(ENV["PATH"]).to eq("/bin")
      end
      expect(ENV["PATH"]).not_to eq("/bin")
    end

    it "restores ENV if an exception is raised" do
      expect {
        with_env(PATH: "/bin") do
          raise StandardError, "boom"
        end
      }.to raise_error(StandardError)

      expect(ENV["PATH"]).not_to eq("/bin")
    end
  end

  describe "#tap_and_name_comparison" do
    describe "both strings are only names" do
      it "alphabetizes the strings" do
        expect(%w[a b].sort(&tap_and_name_comparison)).to eq(%w[a b])
        expect(%w[b a].sort(&tap_and_name_comparison)).to eq(%w[a b])
      end
    end

    describe "both strings include tap" do
      it "alphabetizes the strings" do
        expect(%w[a/z/z b/z/z].sort(&tap_and_name_comparison)).to eq(%w[a/z/z b/z/z])
        expect(%w[b/z/z a/z/z].sort(&tap_and_name_comparison)).to eq(%w[a/z/z b/z/z])

        expect(%w[z/a/z z/b/z].sort(&tap_and_name_comparison)).to eq(%w[z/a/z z/b/z])
        expect(%w[z/b/z z/a/z].sort(&tap_and_name_comparison)).to eq(%w[z/a/z z/b/z])

        expect(%w[z/z/a z/z/b].sort(&tap_and_name_comparison)).to eq(%w[z/z/a z/z/b])
        expect(%w[z/z/b z/z/a].sort(&tap_and_name_comparison)).to eq(%w[z/z/a z/z/b])
      end
    end

    describe "only one string includes tap" do
      it "prefers the string without tap" do
        expect(%w[a/z/z z].sort(&tap_and_name_comparison)).to eq(%w[z a/z/z])
        expect(%w[z a/z/z].sort(&tap_and_name_comparison)).to eq(%w[z a/z/z])
      end
    end
  end
end

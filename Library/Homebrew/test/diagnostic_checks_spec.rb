require "diagnostic"

describe Homebrew::Diagnostic::Checks do
  specify "#inject_file_list" do
    expect(subject.inject_file_list([], "foo:\n")).to eq("foo:\n")
    expect(subject.inject_file_list(%w[/a /b], "foo:\n")).to eq("foo:\n  /a\n  /b\n")
  end

  specify "#check_build_from_source" do
    ENV["HOMEBREW_BUILD_FROM_SOURCE"] = "1"
    expect(subject.check_build_from_source)
      .to match("You have HOMEBREW_BUILD_FROM_SOURCE set.")
  end

  specify "#check_for_anaconda" do
    mktmpdir do |path|
      anaconda = "#{path}/anaconda"
      python = "#{path}/python"
      FileUtils.touch anaconda
      File.open(python, "w") do |file|
        file.write("#! #{`which bash`}\necho -n '#{python}'\n")
      end
      FileUtils.chmod 0755, anaconda
      FileUtils.chmod 0755, python

      ENV["PATH"] = "#{path}#{File::PATH_SEPARATOR}#{ENV["PATH"]}"

      expect(subject.check_for_anaconda).to match("Anaconda")
    end
  end

  specify "#check_access_directories" do
    begin
      dirs = [
        HOMEBREW_CACHE,
        HOMEBREW_CELLAR,
        HOMEBREW_REPOSITORY,
        HOMEBREW_LOGS,
        HOMEBREW_LOCKS,
      ]
      modes = {}
      dirs.each do |dir|
        modes[dir] = dir.stat.mode & 0777
        dir.chmod 0555
        expect(subject.check_access_directories).to match(dir.to_s)
      end
    ensure
      modes.each do |dir, mode|
        dir.chmod mode
      end
    end
  end

  specify "#check_user_path_1" do
    bin = HOMEBREW_PREFIX/"bin"
    sep = File::PATH_SEPARATOR
    # ensure /usr/bin is before HOMEBREW_PREFIX/bin in the PATH
    ENV["PATH"] = "/usr/bin#{sep}#{bin}#{sep}" +
                  ENV["PATH"].gsub(%r{(?:^|#{sep})(?:/usr/bin|#{bin})}, "")

    # ensure there's at least one file with the same name in both /usr/bin/ and
    # HOMEBREW_PREFIX/bin/
    (bin/File.basename(Dir["/usr/bin/*"].first)).mkpath

    expect(subject.check_user_path_1)
      .to match("/usr/bin occurs before #{HOMEBREW_PREFIX}/bin")
  end

  specify "#check_user_path_2" do
    ENV["PATH"] = ENV["PATH"].gsub \
      %r{(?:^|#{File::PATH_SEPARATOR})#{HOMEBREW_PREFIX}/bin}, ""

    expect(subject.check_user_path_1).to be nil
    expect(subject.check_user_path_2)
      .to match("Homebrew's bin was not found in your PATH.")
  end

  specify "#check_user_path_3" do
    begin
      sbin = HOMEBREW_PREFIX/"sbin"
      ENV["HOMEBREW_PATH"] =
        "#{HOMEBREW_PREFIX}/bin#{File::PATH_SEPARATOR}" +
        ENV["HOMEBREW_PATH"].gsub(/(?:^|#{Regexp.escape(File::PATH_SEPARATOR)})#{Regexp.escape(sbin)}/, "")
      (sbin/"something").mkpath

      expect(subject.check_user_path_1).to be nil
      expect(subject.check_user_path_2).to be nil
      expect(subject.check_user_path_3)
        .to match("Homebrew's sbin was not found in your PATH")
    ensure
      sbin.rmtree
    end
  end

  specify "#check_for_config_scripts" do
    mktmpdir do |path|
      file = "#{path}/foo-config"
      FileUtils.touch file
      FileUtils.chmod 0755, file
      ENV["HOMEBREW_PATH"] =
        ENV["PATH"] =
          "#{path}#{File::PATH_SEPARATOR}#{ENV["PATH"]}"

      expect(subject.check_for_config_scripts)
        .to match('"config" scripts exist')
    end
  end

  specify "#check_for_symlinked_cellar" do
    begin
      HOMEBREW_CELLAR.rmtree

      mktmpdir do |path|
        FileUtils.ln_s path, HOMEBREW_CELLAR

        expect(subject.check_for_symlinked_cellar).to match(path)
      end
    ensure
      HOMEBREW_CELLAR.unlink
      HOMEBREW_CELLAR.mkpath
    end
  end

  specify "#check_ld_vars catches LD vars" do
    ENV["LD_LIBRARY_PATH"] = "foo"
    expect(subject.check_ld_vars).to match("Setting DYLD_\\* or LD_\\* variables")
  end

  specify "#check_ld_vars catches DYLD vars" do
    ENV["DYLD_LIBRARY_PATH"] = "foo"
    expect(subject.check_ld_vars).to match("Setting DYLD_\\* or LD_\\* variables")
  end

  specify "#check_ld_vars catches LD and DYLD vars" do
    ENV["LD_LIBRARY_PATH"] = "foo"
    ENV["DYLD_LIBRARY_PATH"] = "foo"
    expect(subject.check_ld_vars).to match("Setting DYLD_\\* or LD_\\* variables")
  end

  specify "#check_ld_vars returns success when neither LD nor DYLD vars are set" do
    expect(subject.check_ld_vars).to be nil
  end

  specify "#check_tmpdir" do
    ENV["TMPDIR"] = "/i/don/t/exis/t"
    expect(subject.check_tmpdir).to match("doesn't exist")
  end

  specify "#check_for_external_cmd_name_conflict" do
    mktmpdir do |path1|
      mktmpdir do |path2|
        [path1, path2].each do |path|
          cmd = "#{path}/brew-foo"
          FileUtils.touch cmd
          FileUtils.chmod 0755, cmd
        end

        allow(Tap).to receive(:cmd_directories).and_return([path1, path2])

        expect(subject.check_for_external_cmd_name_conflict)
          .to match("brew-foo")
      end
    end
  end
end

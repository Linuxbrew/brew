require "diagnostic"

describe Homebrew::Diagnostic::Checks do
  specify "#inject_file_list" do
    expect(subject.inject_file_list([], "foo:\n")).to eq("foo:\n")
    expect(subject.inject_file_list(%w[/a /b], "foo:\n")).to eq("foo:\n  /a\n  /b\n")
  end

  specify "#check_path_for_trailing_slashes" do
    ENV["HOMEBREW_PATH"] += File::PATH_SEPARATOR + "/foo/bar/"
    expect(subject.check_path_for_trailing_slashes)
      .to match("Some directories in your path end in a slash")
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

  specify "#check_access_homebrew_repository" do
    begin
      mode = HOMEBREW_REPOSITORY.stat.mode & 0777
      HOMEBREW_REPOSITORY.chmod 0555

      expect(subject.check_access_homebrew_repository)
        .to match("#{HOMEBREW_REPOSITORY} is not writable.")
    ensure
      HOMEBREW_REPOSITORY.chmod mode
    end
  end

  specify "#check_access_lock_dir" do
    begin
      prev_mode = HOMEBREW_LOCK_DIR.stat.mode
      mode = HOMEBREW_LOCK_DIR.stat.mode & 0777
      HOMEBREW_LOCK_DIR.chmod 0555
      expect(HOMEBREW_LOCK_DIR.stat.mode).not_to eq(prev_mode)

      expect(subject.check_access_lock_dir)
        .to match("#{HOMEBREW_LOCK_DIR} isn't writable.")
    ensure
      HOMEBREW_LOCK_DIR.chmod mode
    end
  end

  specify "#check_access_logs" do
    begin
      mode = HOMEBREW_LOGS.stat.mode & 0777
      HOMEBREW_LOGS.chmod 0555

      expect(subject.check_access_logs)
        .to match("#{HOMEBREW_LOGS} isn't writable.")
    ensure
      HOMEBREW_LOGS.chmod mode
    end
  end

  specify "#check_access_cache" do
    begin
      mode = HOMEBREW_CACHE.stat.mode & 0777
      HOMEBREW_CACHE.chmod 0555
      expect(subject.check_access_cache)
        .to match("#{HOMEBREW_CACHE} isn't writable.")
    ensure
      HOMEBREW_CACHE.chmod mode
    end
  end

  specify "#check_access_cellar" do
    begin
      mode = HOMEBREW_CELLAR.stat.mode & 0777
      HOMEBREW_CELLAR.chmod 0555

      expect(subject.check_access_cellar)
        .to match("#{HOMEBREW_CELLAR} isn't writable.")
    ensure
      HOMEBREW_CELLAR.chmod mode
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

  specify "#check_user_curlrc" do
    mktmpdir do |path|
      FileUtils.touch "#{path}/.curlrc"
      ENV["CURL_HOME"] = path

      expect(subject.check_user_curlrc).to match("You have a curlrc file")
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

  specify "#check_dyld_vars" do
    ENV["DYLD_INSERT_LIBRARIES"] = "foo"
    expect(subject.check_dyld_vars).to match("Setting DYLD_INSERT_LIBRARIES")
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

        ENV["PATH"] = [path1, path2, ENV["PATH"]].join File::PATH_SEPARATOR

        expect(subject.check_for_external_cmd_name_conflict)
          .to match("brew-foo")
      end
    end
  end
end

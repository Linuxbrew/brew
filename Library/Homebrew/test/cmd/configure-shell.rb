describe "brew configure-shell", :integration_test do
  # Put everything in a temp dir that will be used as $HOME so that ~/.profile does not refer to a real ~/.profile
  let!(:testing_path) { mktmpdir }
  # Put all of the paths of files that can be affected into variables to make the rest of this code cleaner
  let(:brew_env) { HOMEBREW_PREFIX/"etc/brew.env" }
  let(:profile) { "#{testing_path}/.profile" }
  let(:bash_profile) { "#{testing_path}/.bash_profile" }
  let(:zprofile) { "#{testing_path}/.zprofile" }

  def run_cmd
    brew "configure-shell", "HOME" => testing_path
  end

  it "writes to .profile and friends if they exist, or at least writes to .profile if none exist" do
    # ~/.profile and friends do not exist right now, so running the command should create ~/.profile
    expect { run_cmd }
      .to be_a_success
      .and output(%r{Modified ~/\.profile})
      .to_stdout
      .and not_to_output.to_stderr
    expect(File.read(profile)).to include("# Added by brew configure-shell\n")
    expect(File.file?(bash_profile)).to be false
    expect(File.file?(zprofile)).to be false

    # Now try to write to 2 other files, and assert that .profile gets skipped
    [bash_profile, zprofile].each { |file| FileUtils.touch file }
    expect { run_cmd }
      .to be_a_success
      .and output(%r{Skipped ~/\.profile})
      .to_stdout
      .and not_to_output.to_stderr

    [bash_profile, zprofile].each do |file|
      expect(File.read(file)).to include("# Added by brew configure-shell\n")
    end
  end

  it "is idempotent for .profile and friends" do
    FileUtils.touch profile
    expect { run_cmd }
      .to be_a_success
      .and output(%r{Modified ~/\.profile})
      .to_stdout
      .and not_to_output.to_stderr
    expect { run_cmd }
      .to be_a_success
      .and output(%r{Skipped ~/\.profile})
      .to_stdout
      .and not_to_output.to_stderr

    expect((File.read profile).scan(/(Added by brew configure\-shell\n)/).count).to eq(1)
  end

  it "makes brew.env file, and won't overwrite it" do
    # Remove any existing brew.env and run the command again and the brew.env file should be created
    FileUtils.rm brew_env if File.file?(brew_env)
    expect { run_cmd }
      .to be_a_success
      .and not_to_output.to_stderr
    expect(File.file?(brew_env)).to be true

    # Make brew.env be a blank file
    File.write brew_env, ""
    # Running the command again should result in an error because the file exists and has different contents
    expect { run_cmd }
      .to be_a_failure
      .and output(/already exists/i).to_stderr
  end
end

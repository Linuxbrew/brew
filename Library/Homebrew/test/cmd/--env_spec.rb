describe "brew --env", :integration_test do
  it "prints the Homebrew build environment variables" do
    expect { brew "--env" }
      .to output(/CMAKE_PREFIX_PATH="#{Regexp.escape(HOMEBREW_PREFIX)}[:"]/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end

  describe "--shell=bash" do
    it "prints the Homebrew build environment variables in Bash syntax" do
      expect { brew "--env", "--shell=bash" }
        .to output(/export CMAKE_PREFIX_PATH="#{Regexp.quote(HOMEBREW_PREFIX)}"/).to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end

  describe "--shell=fish" do
    it "prints the Homebrew build environment variables in Fish syntax" do
      expect { brew "--env", "--shell=fish" }
        .to output(/set [-]gx CMAKE_PREFIX_PATH "#{Regexp.quote(HOMEBREW_PREFIX)}"/).to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end

  describe "--shell=tcsh" do
    it "prints the Homebrew build environment variables in Tcsh syntax" do
      expect { brew "--env", "--shell=tcsh" }
        .to output(/setenv CMAKE_PREFIX_PATH #{Regexp.quote(HOMEBREW_PREFIX)};/).to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end

  describe "--plain" do
    it "prints the Homebrew build environment variables without quotes" do
      expect { brew "--env", "--plain" }
        .to output(/CMAKE_PREFIX_PATH: #{Regexp.quote(HOMEBREW_PREFIX)}/).to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end
end

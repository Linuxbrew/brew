#:  * `configure-shell`:
#:    Configure the shell to include Homebrew into your PATH, MANPATH, and INFOPATH.
#:    A brew.env file will be created that will be sourced in your ~/.profile
#:    (or your .bash_profile or .zprofile - only existing files will be modified)

module Homebrew
  module_function

  def configure_shell
    # Ensure the directory for the brew.env file exists
    FileUtils.mkdir_p HOMEBREW_PREFIX/"etc"

    # Contents for the brew.env file
    brew_env = <<~EOS
      # Homebrew environment
      # Created by running brew configure-shell
      export PATH="#{HOMEBREW_PREFIX}/bin:#{HOMEBREW_PREFIX}/sbin:$PATH"
      export MANPATH="#{HOMEBREW_PREFIX}/share/man:$MANPATH"
      export INFOPATH="#{HOMEBREW_PREFIX}/share/info:$INFOPATH"
    EOS

    # Write brew.env as long as it doesn't already exist. If it does, exit with an error
    env_path = HOMEBREW_PREFIX/"etc/brew.env"
    File.write env_path, brew_env unless File.file?(env_path)
    if File.read(env_path) != brew_env
      odie <<~EOS
        "#{env_path} already exists. If you wish to replace this file,
        remove this file and run brew configure-shell again."
      EOS
    end

    # Now that brew.env has been written, tell the current user's ~/.profile and friends to source it
    profile_and_friends = [".profile", ".bash_profile", ".zprofile"]
                          .map { |file| "#{ENV["HOME"]}/#{file}" }
                          .select { |profile_path| File.file? profile_path }

    # Make sure there's at least one of those files!
    if profile_and_friends.empty?
      FileUtils.touch "#{ENV["HOME"]}/.profile"
      profile_and_friends = ["#{ENV["HOME"]}/.profile"]
    end

    # Now actually modify the current user's ~/.profile and friends to source brew.env
    profile_and_friends.each do |profile_path|
      profile_contents = File.read profile_path
      add_to_profile = "\nsource #{env_path} # Added by brew configure-shell\n"
      if profile_contents.include? add_to_profile
        puts "Skipped #{profile_path.sub(ENV["HOME"], "~")} because it's already configured"
      else
        File.write profile_path, profile_contents + add_to_profile
        puts "Modified #{profile_path.sub(ENV["HOME"], "~")}"
      end
    end

    oh1 "To configure your current shell session, please run..."
    puts "  source #{env_path}"
  end
end

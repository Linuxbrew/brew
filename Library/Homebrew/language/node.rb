module Language
  module Node
    def self.npm_cache_config
      "cache=#{HOMEBREW_CACHE}/npm_cache"
    end

    def self.pack_for_installation
      # Homebrew assumes the buildpath/testpath will always be disposable
      # and from npm 5.0.0 the logic changed so that when a directory is
      # fed to `npm install` only symlinks are created linking back to that
      # directory, consequently breaking that assumption. We require a tarball
      # because npm install creates a "real" installation when fed a tarball.
      output = Utils.popen_read("npm pack --ignore-scripts")
      if !$CHILD_STATUS.exitstatus.zero? || output.lines.empty?
        raise "npm failed to pack #{Dir.pwd}"
      end
      output.lines.last.chomp
    end

    def self.setup_npm_environment
      # guard that this is only run once
      return if @env_set
      @env_set = true
      # explicitly use our npm and node-gyp executables instead of the user
      # managed ones in HOMEBREW_PREFIX/lib/node_modules which might be broken
      begin
        ENV.prepend_path "PATH", Formula["node"].opt_libexec/"bin"
      rescue FormulaUnavailableError
        nil
      end
    end

    def self.std_npm_install_args(libexec)
      setup_npm_environment
      # tell npm to not install .brew_home by adding it to the .npmignore file
      # (or creating a new one if no .npmignore file already exists)
      open(".npmignore", "a") { |f| f.write("\n.brew_home\n") }

      pack = pack_for_installation

      # npm install args for global style module format installed into libexec
      %W[
        -ddd
        --global
        --build-from-source
        --#{npm_cache_config}
        --prefix=#{libexec}
        #{Dir.pwd}/#{pack}
      ]
    end

    def self.local_npm_install_args
      setup_npm_environment
      # npm install args for local style module format
      %W[
        -ddd
        --build-from-source
        --#{npm_cache_config}
      ]
    end
  end
end

module Language
  module Node
    def self.npm_cache_config
      "cache=#{HOMEBREW_CACHE}/npm_cache\n"
    end

    def self.setup_npm_environment
      npmrc = Pathname.new("#{ENV["HOME"]}/.npmrc")
      # only run setup_npm_environment once per formula
      return if npmrc.exist?
      # explicitly set npm's cache path to HOMEBREW_CACHE/npm_cache to fix
      # issues caused by overriding $HOME (long build times, high disk usage)
      # https://github.com/Homebrew/brew/pull/37#issuecomment-208840366
      npmrc.write npm_cache_config
      # explicitly use our npm and node-gyp executables instead of the user
      # managed ones in HOMEBREW_PREFIX/lib/node_modules which might be broken
      ENV.prepend_path "PATH", Formula["node"].opt_libexec/"npm/bin"
    end

    def self.std_npm_install_args(libexec)
      setup_npm_environment
      # tell npm to not install .brew_home by adding it to the .npmignore file
      # (or creating a new one if no .npmignore file already exists)
      open(".npmignore", "a") { |f| f.write("\n.brew_home\n") }
      # npm install args for global style module format installed into libexec
      ["--verbose", "--global", "--prefix=#{libexec}", "."]
    end

    def self.local_npm_install_args
      setup_npm_environment
      # npm install args for local style module format
      ["--verbose"]
    end
  end
end

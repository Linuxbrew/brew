#:  * `sh` [`--env=std`]:
#:    Instantiate a Homebrew build environment. Uses our years-battle-hardened
#:    Homebrew build logic to help your `./configure && make && make install`
#:    or even your `gem install` succeed. Especially handy if you run Homebrew
#:    in an Xcode-only configuration since it adds tools like `make` to your `PATH`
#:    which otherwise build-systems would not find.

require "extend/ENV"
require "formula"

module Homebrew
  module_function

  def sh
    ENV.activate_extensions!

    if superenv?
      ENV.set_x11_env_if_installed
      ENV.deps = Formula.installed.select { |f| f.keg_only? && f.opt_prefix.directory? }
    end
    ENV.setup_build_environment
    if superenv?
      # superenv stopped adding brew's bin but generally user's will want it
      ENV["PATH"] = ENV["PATH"].split(File::PATH_SEPARATOR).insert(1, "#{HOMEBREW_PREFIX}/bin").join(File::PATH_SEPARATOR)
    end
    ENV["PS1"] = 'brew \[\033[1;32m\]\w\[\033[0m\]$ '
    ENV["VERBOSE"] = "1"
    puts <<-EOS.undent_________________________________________________________72
         Your shell has been configured to use Homebrew's build environment:
         this should help you build stuff. Notably though, the system versions of
         gem and pip will ignore our configuration and insist on using the
         environment they were built under (mostly). Sadly, scons will also
         ignore our configuration.
         When done, type `exit'.
         EOS
    $stdout.flush
    exec ENV["SHELL"]
  end
end

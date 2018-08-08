#:  * `prof` [<ruby options>]:
#:    Run Homebrew with the Ruby profiler.
#:    For example:
#       brew prof readall

module Homebrew
  module_function

  def prof
    Homebrew.install_gem_setup_path! "ruby-prof"
    FileUtils.mkdir_p "prof"
    brew_rb = (HOMEBREW_LIBRARY_PATH/"brew.rb").resolved_path
    exec "ruby-prof", "--printer=multi", "--file=prof", brew_rb, "--", *ARGV
  end
end

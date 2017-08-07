#:  * `postinstall` <formula>:
#:    Rerun the post-install steps for <formula>.

require "sandbox"

module Homebrew
  module_function

  def postinstall
    ARGV.resolved_formulae.each do |f|
      ohai "Postinstalling #{f}"
      run_post_install(f)
    end
  end

  def run_post_install(formula)
    args = %W[
      nice #{RUBY_PATH}
      -W0
      -I #{HOMEBREW_LOAD_PATH}
      --
      #{HOMEBREW_LIBRARY_PATH}/postinstall.rb
      #{formula.path}
    ].concat(ARGV.options_only)

    if formula.head?
      args << "--HEAD"
    elsif formula.devel?
      args << "--devel"
    end

    Utils.safe_fork do
      if Sandbox.formula?(formula)
        sandbox = Sandbox.new
        formula.logs.mkpath
        sandbox.record_log(formula.logs/"postinstall.sandbox.log")
        sandbox.allow_write_temp_and_cache
        sandbox.allow_write_log(formula)
        sandbox.allow_write_xcode
        sandbox.deny_write_homebrew_repository
        sandbox.allow_write_cellar(formula)
        Keg::TOP_LEVEL_DIRECTORIES.each do |dir|
          sandbox.allow_write_path "#{HOMEBREW_PREFIX}/#{dir}"
        end
        sandbox.exec(*args)
      else
        exec(*args)
      end
    end
  end
end

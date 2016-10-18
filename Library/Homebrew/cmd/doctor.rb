#:  * `doctor`:
#:    Check your system for potential problems. Doctor exits with a non-zero status
#:    if any problems are found.

# Undocumented options:
#     -D activates debugging and profiling of the audit methods (not the same as --debug)

require "diagnostic"

module Homebrew
  module_function

  def doctor
    inject_dump_stats!(Diagnostic::Checks, /^check_*/) if ARGV.switch? "D"

    checks = Diagnostic::Checks.new

    if ARGV.include? "--list-checks"
      puts checks.all.sort
      exit
    end

    if ARGV.named.empty?
      slow_checks = %w[
        check_for_broken_symlinks
        check_missing_deps
        check_for_linked_keg_only_brews
      ]
      methods = (checks.all.sort - slow_checks) + slow_checks
    else
      methods = ARGV.named
    end

    first_warning = true
    methods.each do |method|
      $stderr.puts "Checking #{method}" if ARGV.debug?
      unless checks.respond_to?(method)
        Homebrew.failed = true
        puts "No check available by the name: #{method}"
        next
      end

      out = checks.send(method)
      next if out.nil? || out.empty?
      if first_warning
        $stderr.puts <<-EOS.undent
          #{Tty.bold}Please note that these warnings are just used to help the Homebrew maintainers
          with debugging if you file an issue. If everything you use Homebrew for is
          working fine: please don't worry and just ignore them. Thanks!#{Tty.reset}
        EOS
      end

      $stderr.puts
      opoo out
      Homebrew.failed = true
      first_warning = false
    end

    puts "Your system is ready to brew." unless Homebrew.failed?
  end
end

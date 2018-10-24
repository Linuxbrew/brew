#:  * `doctor`:
#:    Check your system for potential problems. Doctor exits with a non-zero status
#:    if any potential problems are found. Please note that these warnings are just
#:    used to help the Homebrew maintainers with debugging if you file an issue. If
#:    everything you use Homebrew for is working fine: please don't worry or file
#:    an issue; just ignore this.

# Undocumented options:
#     `-D` activates debugging and profiling of the audit methods (not the same as `--debug`)
#     `--list-checks` lists all audit methods

require "diagnostic"
require "cli_parser"

module Homebrew
  module_function

  def doctor_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `doctor` [<options>]

        Check your system for potential problems. Doctor exits with a non-zero status
        if any potential problems are found. Please note that these warnings are just
        used to help the Homebrew maintainers with debugging if you file an issue. If
        everything you use Homebrew for is working fine: please don't worry or file
        an issue; just ignore this.
      EOS
      switch "--list-checks",
        description: "List all audit methods."
      switch "-D", "--audit-debug",
        description: "Enable debugging and profiling of audit methods."
      switch :verbose
      switch :debug
    end
  end

  def doctor
    doctor_args.parse

    inject_dump_stats!(Diagnostic::Checks, /^check_*/) if args.audit_debug?

    checks = Diagnostic::Checks.new

    if args.list_checks?
      puts checks.all.sort
      exit
    end

    if ARGV.named.empty?
      slow_checks = %w[
        check_for_broken_symlinks
        check_missing_deps
      ]
      methods = (checks.all.sort - slow_checks) + slow_checks
    else
      methods = ARGV.named
    end

    first_warning = true
    methods.each do |method|
      $stderr.puts "Checking #{method}" if args.debug?
      unless checks.respond_to?(method)
        Homebrew.failed = true
        puts "No check available by the name: #{method}"
        next
      end

      out = checks.send(method)
      next if out.nil? || out.empty?

      if first_warning
        $stderr.puts <<~EOS
          #{Tty.bold}Please note that these warnings are just used to help the Homebrew maintainers
          with debugging if you file an issue. If everything you use Homebrew for is
          working fine: please don't worry or file an issue; just ignore this. Thanks!#{Tty.reset}
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

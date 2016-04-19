# `brew readall` tries to import all formulae one-by-one.
# This can be useful for debugging issues across all formulae
# when making significant changes to formula.rb,
# or to determine if any current formulae have Ruby issues

require "formula"
require "tap"
require "thread"

module Homebrew
  def readall
    if ARGV.delete("--syntax")
      ruby_files = Queue.new
      scan_files = %W[
        #{HOMEBREW_LIBRARY}/*.rb
        #{HOMEBREW_LIBRARY}/Homebrew/**/*.rb
      ]
      Dir.glob(scan_files).each do |rb|
        next if rb.include?("/vendor/")
        ruby_files << rb
      end

      failed = false
      workers = (0...Hardware::CPU.cores).map do
        Thread.new do
          begin
            while rb = ruby_files.pop(true)
              # As a side effect, print syntax errors/warnings to `$stderr`.
              failed = true if syntax_errors_or_warnings?(rb)
            end
          rescue ThreadError # ignore empty queue error
          end
        end
      end
      workers.each(&:join)
      Homebrew.failed = failed
    end

    formulae = []
    alias_dirs = []
    if ARGV.named.empty?
      formulae = Formula.files
      alias_dirs = Tap.map(&:alias_dir)
    else
      tap = Tap.fetch(ARGV.named.first)
      raise TapUnavailableError, tap.name unless tap.installed?
      formulae = tap.formula_files
      alias_dirs = [tap.alias_dir]
    end

    if ARGV.delete("--aliases")
      alias_dirs.each do |alias_dir|
        next unless alias_dir.directory?
        Pathname.glob("#{alias_dir}/*").each do |f|
          next unless f.symlink?
          next if f.file?
          onoe "Broken alias: #{f}"
          Homebrew.failed = true
        end
      end
    end

    formulae.each do |file|
      begin
        Formulary.factory(file)
      rescue Interrupt
        raise
      rescue Exception => e
        onoe "problem in #{file}"
        puts e
        Homebrew.failed = true
      end
    end
  end

  private

  def syntax_errors_or_warnings?(rb)
    # Retrieve messages about syntax errors/warnings printed to `$stderr`, but
    # discard a `Syntax OK` printed to `$stdout` (in absence of syntax errors).
    messages = Utils.popen_read("#{RUBY_PATH} -c -w #{rb} 2>&1 >/dev/null")
    $stderr.print messages

    # Only syntax errors result in a non-zero status code. To detect syntax
    # warnings we also need to inspect the output to `$stderr`.
    !$?.success? || !messages.chomp.empty?
  end
end

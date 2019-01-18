#:  * `switch` <formula> <version>:
#:    Symlink all of the specific <version> of <formula>'s install to Homebrew prefix.

require "formula"
require "keg"
require "cli_parser"

module Homebrew
  module_function

  def switch_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `switch` <formula> <version>

        Symlink all of the specific <version> of <formula>'s install to Homebrew prefix.
      EOS
      switch_option :verbose
      switch_option :debug
    end
  end

  def switch
    switch_args.parse
    name = args.remaining.first

    usage = "Usage: brew switch <formula> <version>"

    unless name
      onoe usage
      exit 1
    end

    rack = Formulary.to_rack(name)

    unless rack.directory?
      onoe "#{name} not found in the Cellar."
      exit 2
    end

    versions = rack.subdirs
                   .map { |d| Keg.new(d).version }
                   .sort
                   .join(", ")
    version = args.remaining.second

    if !version || args.remaining.length > 2
      onoe usage
      puts "#{name} installed versions: #{versions}"
      exit 1
    end

    unless (rack/version).directory?
      onoe "#{name} does not have a version \"#{version}\" in the Cellar."
      puts "#{name} installed versions: #{versions}"
      exit 3
    end

    # Unlink all existing versions
    rack.subdirs.each do |v|
      keg = Keg.new(v)
      puts "Cleaning #{keg}"
      keg.unlink
    end

    keg = Keg.new(rack/version)

    # Link new version, if not keg-only
    if Formulary.keg_only?(rack)
      keg.optlink
      puts "Opt link created for #{keg}"
    else
      puts "#{keg.link} links created for #{keg}"
    end
  end
end

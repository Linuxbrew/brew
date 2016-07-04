#
# Description: check linkage of installed keg
# Usage:
#   brew linkage <formulae>
#
# Only works on installed formulae. An error is raised if it is run on uninstalled
# formulae.
#
# Options:
#  --test      - testing version: only display broken libraries and possibly
#                undeclared dependencies; exit non-zero if any breakage was
#                found (i.e. any of these yield a nonempty result).
#  --reverse   - For each dylib the keg references, print the dylib followed by the
#                binaries which link to it.

require "set"
require "keg"
require "formula"

module Homebrew
  def linkage
    ARGV.kegs.each do |keg|
      ohai "Checking #{keg.name} linkage" if ARGV.kegs.size > 1
      result = LinkageChecker.new(keg)
      if ARGV.include?("--test")
        result.display_test_output
        if result.broken_dylibs? || result.undeclared_deps?
          Homebrew.failed = true
        end
      elsif ARGV.include?("--reverse")
        result.display_reverse_output
      else
        result.display_normal_output
      end
    end
  end

  class LinkageChecker
    attr_reader :keg
    attr_reader :brewed_dylibs, :system_dylibs, :broken_dylibs, :variable_dylibs
    attr_reader :undeclared_deps, :reverse_links

    def initialize(keg)
      @keg = keg
      @brewed_dylibs = Hash.new { |h, k| h[k] = Set.new }
      @system_dylibs = Set.new
      @broken_dylibs = Set.new
      @variable_dylibs = Set.new
      @undeclared_deps = []
      @reverse_links = Hash.new { |h, k| h[k] = Set.new }
      check_dylibs
    end

    def check_dylibs
      @keg.find do |file|
        next if file.symlink? || file.directory?
        next unless file.dylib? || file.mach_o_executable? || file.mach_o_bundle?
        file.dynamically_linked_libraries.each do |dylib|
          @reverse_links[dylib] << file
          if dylib.start_with? "@"
            @variable_dylibs << dylib
          else
            begin
              owner = Keg.for Pathname.new(dylib)
            rescue NotAKegError
              @system_dylibs << dylib
            rescue Errno::ENOENT
              @broken_dylibs << dylib
            else
              @brewed_dylibs[owner.name] << dylib
            end
          end
        end
      end

      begin
        f = Formulary.from_rack(keg.rack)
        f.build = Tab.for_keg(keg)
        filter_out = proc do |dep|
          dep.build? || (dep.optional? && !dep.option_names.any? { |n| f.build.with?(n) })
        end
        declared_deps = f.deps.reject { |dep| filter_out.call(dep) }.map(&:name) +
                        f.requirements.reject { |req| filter_out.call(req) }.map(&:default_formula).compact
        @undeclared_deps = @brewed_dylibs.keys - declared_deps.map { |dep| dep.split("/").last }
        @undeclared_deps -= [f.name]
      rescue FormulaUnavailableError
        opoo "Formula unavailable: #{keg.name}"
      end
    end

    def display_normal_output
      display_items "System libraries", @system_dylibs
      display_items "Homebrew libraries", @brewed_dylibs
      display_items "Variable-referenced libraries", @variable_dylibs
      display_items "Missing libraries", @broken_dylibs
      display_items "Possible undeclared dependencies", @undeclared_deps
    end

    def display_reverse_output
      return if @reverse_links.empty?
      sorted = @reverse_links.sort
      sorted.each do |dylib, files|
        puts dylib
        files.each do |f|
          unprefixed = f.to_s.strip_prefix "#{@keg.to_s}/"
          puts "  #{unprefixed}"
        end
        puts unless dylib == sorted.last[0]
      end
    end

    def display_test_output
      display_items "Missing libraries", @broken_dylibs
      puts "No broken dylib links" if @broken_dylibs.empty?
      display_items "Possible undeclared dependencies", @undeclared_deps
      puts "No undeclared dependencies" if @undeclared_deps.empty?
    end

    def broken_dylibs?
      !@broken_dylibs.empty?
    end

    def undeclared_deps?
      !@undeclared_deps.empty?
    end

    private

    # Display a list of things.
    # Things may either be an array, or a hash of (label -> array)
    def display_items(label, things)
      return if things.empty?
      puts "#{label}:"
      if things.is_a? Hash
        things.sort.each do |list_label, list|
          list.sort.each do |item|
            puts "  #{item} (#{list_label})"
          end
        end
      else
        things.sort.each do |item|
          puts "  #{item}"
        end
      end
    end
  end
end

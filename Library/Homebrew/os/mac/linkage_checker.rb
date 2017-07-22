require "set"
require "keg"
require "formula"

class LinkageChecker
  attr_reader :keg, :formula
  attr_reader :brewed_dylibs, :system_dylibs, :broken_dylibs, :variable_dylibs
  attr_reader :undeclared_deps, :reverse_links

  def initialize(keg, formula = nil)
    @keg = keg
    @formula = formula || resolve_formula(keg)
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

      # weakly loaded dylibs may not actually exist on disk, so skip them
      # when checking for broken linkage
      file.dynamically_linked_libraries(except: :LC_LOAD_WEAK_DYLIB).each do |dylib|
        @reverse_links[dylib] << file
        if dylib.start_with? "@"
          @variable_dylibs << dylib
        else
          begin
            owner = Keg.for Pathname.new(dylib)
          rescue NotAKegError
            @system_dylibs << dylib
          rescue Errno::ENOENT
            next if harmless_broken_link?(dylib)
            @broken_dylibs << dylib
          else
            tap = Tab.for_keg(owner).tap
            f = if tap.nil? || tap.core_tap?
              owner.name
            else
              "#{tap}/#{owner.name}"
            end
            @brewed_dylibs[f] << dylib
          end
        end
      end
    end

    @undeclared_deps = check_undeclared_deps if formula
  end

  def check_undeclared_deps
    filter_out = proc do |dep|
      next true if dep.build?
      next false unless dep.optional? || dep.recommended?
      formula.build.without?(dep)
    end
    declared_deps = formula.deps.reject { |dep| filter_out.call(dep) }.map(&:name)
    declared_requirement_deps = formula.requirements.reject { |req| filter_out.call(req) }.map(&:default_formula).compact
    declared_dep_names = (declared_deps + declared_requirement_deps).map { |dep| dep.split("/").last }
    undeclared_deps = @brewed_dylibs.keys.reject do |full_name|
      name = full_name.split("/").last
      next true if name == formula.name
      declared_dep_names.include?(name)
    end
    undeclared_deps.sort do |a, b|
      if a.include?("/") && !b.include?("/")
        1
      elsif !a.include?("/") && b.include?("/")
        -1
      else
        a <=> b
      end
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
        unprefixed = f.to_s.strip_prefix "#{@keg}/"
        puts "  #{unprefixed}"
      end
      puts unless dylib == sorted.last[0]
    end
  end

  def display_test_output
    display_items "Missing libraries", @broken_dylibs
    puts "No broken dylib links" if @broken_dylibs.empty?
  end

  def broken_dylibs?
    !@broken_dylibs.empty?
  end

  def undeclared_deps?
    !@undeclared_deps.empty?
  end

  private

  # Whether or not dylib is a harmless broken link, meaning that it's
  # okay to skip (and not report) as broken.
  def harmless_broken_link?(dylib)
    # libgcc_s_* is referenced by programs that use the Java Service Wrapper,
    # and is harmless on x86(_64) machines
    [
      "/usr/lib/libgcc_s_ppc64.1.dylib",
      "/opt/local/lib/libgcc/libgcc_s.1.dylib",
    ].include?(dylib)
  end

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

  def resolve_formula(keg)
    Formulary.from_keg(keg)
  rescue FormulaUnavailableError
    opoo "Formula unavailable: #{keg.name}"
  end
end

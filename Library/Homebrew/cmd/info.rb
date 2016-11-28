#:  * `info` <formula>:
#:    Display information about <formula>.
#:
#:  * `info` `--github` <formula>:
#:    Open a browser to the GitHub History page for formula <formula>.
#:
#:    To view formula history locally: `brew log -p <formula>`.
#:
#:  * `info` `--json=`<version> (`--all`|`--installed`|<formulae>):
#:    Print a JSON representation of <formulae>. Currently the only accepted value
#:    for <version> is `v1`.
#:
#:    Pass `--all` to get information on all formulae, or `--installed` to get
#:    information on all installed formulae.
#:
#:    See the docs for examples of using the JSON:
#:    <https://github.com/Homebrew/brew/blob/master/docs/Querying-Brew.md>

require "blacklist"
require "caveats"
require "options"
require "formula"
require "keg"
require "tab"
require "utils/json"

module Homebrew
  module_function

  def info
    # eventually we'll solidify an API, but we'll keep old versions
    # awhile around for compatibility
    if ARGV.json == "v1"
      print_json
    elsif ARGV.flag? "--github"
      exec_browser(*ARGV.formulae.map { |f| github_info(f) })
    else
      print_info
    end
  end

  def print_info
    if ARGV.named.empty?
      if HOMEBREW_CELLAR.exist?
        count = Formula.racks.length
        puts "#{count} keg#{plural(count)}, #{HOMEBREW_CELLAR.abv}"
      end
    else
      ARGV.named.each_with_index do |f, i|
        puts unless i.zero?
        begin
          if f.include?("/") || File.exist?(f)
            info_formula Formulary.factory(f)
          else
            info_formula Formulary.find_with_priority(f)
          end
        rescue FormulaUnavailableError
          # No formula with this name, try a blacklist lookup
          raise unless (blacklist = blacklisted?(f))
          puts blacklist
        end
      end
    end
  end

  def print_json
    ff = if ARGV.include? "--all"
      Formula
    elsif ARGV.include? "--installed"
      Formula.installed
    else
      ARGV.formulae
    end
    json = ff.map(&:to_hash)
    puts Utils::JSON.dump(json)
  end

  def github_remote_path(remote, path)
    if remote =~ %r{^(?:https?://|git(?:@|://))github\.com[:/](.+)/(.+?)(?:\.git)?$}
      "https://github.com/#{$1}/#{$2}/blob/master/#{path}"
    else
      "#{remote}/#{path}"
    end
  end

  def github_info(f)
    if f.tap
      if remote = f.tap.remote
        path = f.path.relative_path_from(f.tap.path)
        github_remote_path(remote, path)
      else
        f.path
      end
    else
      f.path
    end
  end

  def info_formula(f)
    specs = []

    if stable = f.stable
      s = "stable #{stable.version}"
      s += " (bottled)" if stable.bottled?
      specs << s
    end

    if devel = f.devel
      s = "devel #{devel.version}"
      s += " (bottled)" if devel.bottled?
      specs << s
    end

    specs << "HEAD" if f.head

    attrs = []
    attrs << "pinned at #{f.pinned_version}" if f.pinned?
    attrs << "keg-only" if f.keg_only?

    puts "#{f.full_name}: #{specs * ", "}#{" [#{attrs * ", "}]" unless attrs.empty?}"
    puts f.desc if f.desc
    puts Formatter.url(f.homepage) if f.homepage

    conflicts = f.conflicts.map(&:name).sort!
    puts "Conflicts with: #{conflicts*", "}" unless conflicts.empty?

    kegs = f.installed_kegs.sort_by(&:version)
    if kegs.empty?
      puts "Not installed"
    else
      kegs.each do |keg|
        puts "#{keg} (#{keg.abv})#{" *" if keg.linked?}"
        tab = Tab.for_keg(keg).to_s
        puts "  #{tab}" unless tab.empty?
      end
    end

    puts "From: #{Formatter.url(github_info(f))}"

    unless f.deps.empty?
      ohai "Dependencies"
      %w[build required recommended optional].map do |type|
        deps = f.deps.send(type).uniq
        puts "#{type.capitalize}: #{decorate_dependencies deps}" unless deps.empty?
      end
    end

    unless f.requirements.to_a.empty?
      ohai "Requirements"
      %w[build required recommended optional].map do |type|
        reqs = f.requirements.select(&:"#{type}?")
        next if reqs.to_a.empty?
        puts "#{type.capitalize}: #{decorate_requirements(reqs)}"
      end
    end

    unless f.options.empty?
      ohai "Options"
      Homebrew.dump_options_for_formula f
    end

    c = Caveats.new(f)
    ohai "Caveats", c.caveats unless c.empty?
  end

  def decorate_dependencies(dependencies)
    deps_status = dependencies.collect do |dep|
      if dep.satisfied?([])
        pretty_installed(dep_display_s(dep))
      else
        pretty_uninstalled(dep_display_s(dep))
      end
    end
    deps_status.join(", ")
  end

  def decorate_requirements(requirements)
    req_status = requirements.collect do |req|
      req_s = req.display_s
      req.satisfied? ? pretty_installed(req_s) : pretty_uninstalled(req_s)
    end
    req_status.join(", ")
  end

  def dep_display_s(dep)
    return dep.name if dep.option_tags.empty?
    "#{dep.name} #{dep.option_tags.map { |o| "--#{o}" }.join(" ")}"
  end
end

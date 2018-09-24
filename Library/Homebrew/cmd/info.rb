#:  * `info`:
#:    Display brief statistics for your Homebrew installation.
#:
#:  * `info` <formula>  (`--verbose`):
#:    Display information about <formula> and analytics data (provided neither
#:    `HOMEBREW_NO_ANALYTICS` or `HOMEBREW_NO_GITHUB_API` are set)
#:
#:    Pass `--verbose` to see more detailed analytics data.
#:
#:  * `info` `--github` <formula>:
#:    Open a browser to the GitHub History page for <formula>.
#:
#:    To view formula history locally: `brew log -p <formula>`
#:
#:  * `info` `--json=`<version> (`--all`|`--installed`|<formulae>):
#:    Print a JSON representation of <formulae>. Currently the only accepted value
#:    for <version> is `v1`.
#:
#:    Pass `--all` to get information on all formulae, or `--installed` to get
#:    information on all installed formulae.
#:
#:    See the docs for examples of using the JSON output:
#:    <https://docs.brew.sh/Querying-Brew>

require "missing_formula"
require "caveats"
require "options"
require "formula"
require "keg"
require "tab"
require "json"

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
        puts "#{Formatter.pluralize(count, "keg")}, #{HOMEBREW_CELLAR.abv}"
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
        rescue FormulaUnavailableError => e
          ofail e.message
          # No formula with this name, try a missing formula lookup
          if (reason = MissingFormula.reason(f))
            $stderr.puts reason
          end
        end
      end
    end
  end

  def print_json
    ff = if ARGV.include? "--all"
      Formula.sort
    elsif ARGV.include? "--installed"
      Formula.installed.sort
    else
      ARGV.formulae
    end
    json = ff.map(&:to_hash)
    puts JSON.generate(json)
  end

  def github_remote_path(remote, path)
    if remote =~ %r{^(?:https?://|git(?:@|://))github\.com[:/](.+)/(.+?)(?:\.git)?$}
      "https://github.com/#{Regexp.last_match(1)}/#{Regexp.last_match(2)}/blob/master/#{path}"
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

    conflicts = f.conflicts.map do |c|
      reason = " (because #{c.reason})" if c.reason
      "#{c.name}#{reason}"
    end.sort!
    unless conflicts.empty?
      puts <<~EOS
        Conflicts with:
          #{conflicts.join("\n  ")}
      EOS
    end

    kegs = f.installed_kegs
    heads, versioned = kegs.partition { |k| k.version.head? }
    kegs = [
      *heads.sort_by { |k| -Tab.for_keg(k).time.to_i },
      *versioned.sort_by(&:version),
    ]
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

    if !f.options.empty? || f.head || f.devel
      ohai "Options"
      Homebrew.dump_options_for_formula f
    end

    caveats = Caveats.new(f)
    ohai "Caveats", caveats.to_s unless caveats.empty?

    output_analytics(f)
  end

  def output_analytics(f)
    return if ENV["HOMEBREW_NO_ANALYTICS"]
    return if ENV["HOMEBREW_NO_GITHUB_API"]

    formulae_json_url = "https://formulae.brew.sh/api/formula/#{f}.json"
    output, = curl_output("--max-time", "3", formulae_json_url)
    return if output.empty?

    json = begin
      JSON.parse(output)
    rescue JSON::ParserError
      nil
    end
    return if json.nil? || json.empty? || json["analytics"].empty?

    ohai "Analytics"
    if ARGV.verbose?
      json["analytics"].each do |category, value|
        value.each do |range, results|
          oh1 "#{category} (#{range})"
          results.each do |name_with_options, count|
            puts "#{name_with_options}: #{number_readable(count)}"
          end
        end
      end
      return
    end

    json["analytics"].each do |category, value|
      analytics = value.map do |range, results|
        "#{number_readable(results.values.inject("+"))} (#{range})"
      end
      puts "#{category}: #{analytics.join(", ")}"
    end
  end

  def decorate_dependencies(dependencies)
    deps_status = dependencies.map do |dep|
      if dep.satisfied?([])
        pretty_installed(dep_display_s(dep))
      else
        pretty_uninstalled(dep_display_s(dep))
      end
    end
    deps_status.join(", ")
  end

  def decorate_requirements(requirements)
    req_status = requirements.map do |req|
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

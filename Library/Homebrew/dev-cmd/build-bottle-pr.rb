module Homebrew
  # Submit a pull request to build a bottle for a formula.
  # Usage:
  #    brew build-bottle formula ...
  # Options:
  #    --remote=$USER      Specify the GitHub remote
  #    --tag=x86_64_linux  Specify the bottle tag
  #    --limit=10          Maximum number of PRs

  def open_pull_request?(formula)
    prs = GitHub.issues_matching(formula,
      :type => "pr", :state => "open", :repo => formula.tap.slug)
    prs = prs.select { |pr| pr["title"].start_with? "#{formula}: " }
    if prs.any?
      ohai "#{formula}: Skipping because a PR is open"
      prs.each { |pr| puts "#{pr["title"]} (#{pr["html_url"]})" }
    end
    prs.any?
  end

  def limit
    @@limit ||= (ARGV.value("limit") || "10").to_i
  end

  # The number of bottled formula.
  @@n = 0

  def build_bottle(formula)
    remote = ARGV.value("remote") || ENV["GITHUB_USER"] || ENV["USER"]
    tag = (ARGV.value("tag") || "x86_64_linux").to_sym
    return ohai "#{formula}: Skipping because a bottle is not needed" if formula.bottle_unneeded?
    return ohai "#{formula}: Skipping because bottles are disabled" if formula.bottle_disabled?
    return ohai "#{formula}: Skipping because it has a bottle" if formula.bottle_specification.tag?(tag)
    return if open_pull_request? formula

    @@n += 1
    return ohai "#{@@n}. #{formula}: Skipping because GitHub rate limits pull requests" if @@n > limit

    message = "#{formula}: Build a bottle for Linuxbrew"
    oh1 "#{@@n}. #{message}"
    return if ARGV.dry_run?

    cd formula.tap.formula_dir
    File.open(formula.path, "r+") do |f|
      s = f.read
      f.rewind
      f.write "# #{message}\n#{s}"
    end
    branch = "bottle-#{formula}"
    safe_system "git", "checkout", "-b", branch, "master"
    safe_system "git", "commit", formula.path, "-m", message
    safe_system "git", "push", remote, branch
    safe_system "hub", "pull-request", "--browse",
      "-h", "#{remote}:#{branch}", "-m", message
    safe_system "git", "checkout", "master"
    safe_system "git", "branch", "-D", branch
  end

  def shell(cmd)
      output = `#{cmd}`
      raise ErrorDuringExecution.new(cmd) unless $?.success?
      output
  end

  def brew(args)
    shell "#{HOMEBREW_PREFIX}/bin/brew #{args}"
  end

  def build_bottle_pr
    formulae = ARGV.formulae
    unless ARGV.one?
      deps = brew("deps -n --union #{formulae.join ' '}").split
      formulae = deps.map { |f| Formula[f] } + formulae
    end
    formulae.each { |f| build_bottle f }
  end
end

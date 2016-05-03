module Homebrew
  # Submit a pull request to build a bottle for a formula.
  # Usage:
  #    brew build-bottle formula ...
  # Options:
  #    --remote=$USER      Specify the GitHub remote
  #    --tag=x86_64_linux  Specify the bottle tag
  def build_bottle(formula)
    remote = ARGV.value("remote") || ENV["GITHUB_USER"] || ENV["USER"]
    tag = (ARGV.value("tag") || "x86_64_linux").to_sym
    return ohai "#{formula}: Skipping because a bottle is not needed" if formula.bottle_unneeded?
    return ohai "#{formula}: Skipping because bottles are disabled" if formula.bottle_disabled?
    return ohai "#{formula}: Skipping because it has a bottle" if formula.bottle_specification.tag?(tag)
    message = "#{formula}: Build a bottle for Linuxbrew"
    oh1 message
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

  def build_bottle_pr
    ARGV.resolved_formulae.each { |f| build_bottle f }
  end
end

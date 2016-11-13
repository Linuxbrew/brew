#: @hide_from_man_page
#:  * `boneyard-formula-pr` [`--dry-run`] [`--local`] [`--reason=<reason>`] <formula-name> :
#:    Creates a pull request to boneyard a formula.
#:
#:    If `--dry-run` is passed, print what would be done rather than doing it.
#:
#:    If `--local` is passed, perform only local operations (i.e. don't push or create PR).
#:
#:    If `--reason=<reason>` is passed, append this to the commit/PR message.

require "formula"
require "utils/json"
require "fileutils"

begin
  require "json"
rescue LoadError
  puts "Homebrew does not provide Ruby dependencies; install with:"
  puts "  gem install json"
  odie "Dependency json is not installed."
end

module Homebrew
  module_function

  def boneyard_formula_pr
    local_only = ARGV.include?("--local")
    formula = ARGV.formulae.first
    reason = ARGV.value("reason")
    odie "No formula found!" unless formula

    formula_relpath = formula.path.relative_path_from(formula.tap.path)
    formula_file = "#{formula.name}.rb"
    bottle_block = File.read(formula.path).include? "  bottle do"
    boneyard_tap = Tap.fetch("homebrew", "boneyard")
    tap_migrations_path = formula.tap.path/"tap_migrations.json"
    if ARGV.dry_run?
      puts "brew update"
      puts "brew tap #{boneyard_tap.name}"
      puts "cd #{formula.tap.path}"
      cd formula.tap.path
      puts "cp #{formula_relpath} #{boneyard_tap.path}"
      puts "git rm #{formula_relpath}"
      unless File.exist? tap_migrations_path
        puts "Creating tap_migrations.json for #{formula.tap.name}"
        puts "git add #{tap_migrations_path}"
      end
      puts "Loading tap_migrations.json"
      puts "Adding #{formula.name} to tap_migrations.json"
    else
      safe_system HOMEBREW_BREW_FILE, "update"
      safe_system HOMEBREW_BREW_FILE, "tap", boneyard_tap.name
      cd formula.tap.path
      cp formula_relpath, boneyard_tap.formula_dir
      safe_system "git", "rm", formula_relpath
      unless File.exist? tap_migrations_path
        tap_migrations_path.write <<-EOS.undent
          {
          }
        EOS
        safe_system "git", "add", tap_migrations_path
      end
      tap_migrations = Utils::JSON.load(File.read(tap_migrations_path))
      tap_migrations[formula.name] = boneyard_tap.name
      tap_migrations = tap_migrations.sort.inject({}) { |acc, elem| acc.merge!(elem[0] => elem[1]) }
      tap_migrations_path.atomic_write(JSON.pretty_generate(tap_migrations) + "\n")
    end
    unless which("hub") || local_only
      if ARGV.dry_run?
        puts "brew install hub"
      else
        safe_system HOMEBREW_BREW_FILE, "install", "hub"
      end
    end
    branch = "#{formula.name}-boneyard"

    reason = " because #{reason}" if reason

    if ARGV.dry_run?
      puts "cd #{formula.tap.path}"
      puts "git checkout --no-track -b #{branch} origin/master"
      puts "git commit --no-edit --verbose --message=\"#{formula.name}: migrate to boneyard\" -- #{formula_relpath} #{tap_migrations_path.basename}"

      unless local_only
        puts "hub fork --no-remote"
        puts "hub fork"
        puts "hub fork (to read $HUB_REMOTE)"
        puts "git push $HUB_REMOTE #{branch}:#{branch}"
        puts "hub pull-request -m $'#{formula.name}: migrate to boneyard\\n\\nCreated with `brew boneyard-formula-pr`#{reason}.'"
      end
    else
      cd formula.tap.path
      safe_system "git", "checkout", "--no-track", "-b", branch, "origin/master"
      safe_system "git", "commit", "--no-edit", "--verbose",
        "--message=#{formula.name}: migrate to boneyard",
        "--", formula_relpath, tap_migrations_path.basename

      unless local_only
        safe_system "hub", "fork", "--no-remote"
        quiet_system "hub", "fork"
        remote = Utils.popen_read("hub fork 2>&1")[/fatal: remote (.+) already exists\./, 1]
        odie "cannot get remote from 'hub'!" unless remote
        safe_system "git", "push", remote, "#{branch}:#{branch}"
        pr_message = <<-EOS.undent
          #{formula.name}: migrate to boneyard

          Created with `brew boneyard-formula-pr`#{reason}.
        EOS
        pr_url = Utils.popen_read("hub", "pull-request", "-m", pr_message).chomp
      end
    end

    if ARGV.dry_run?
      puts "cd #{boneyard_tap.path}"
      puts "git checkout --no-track -b #{branch} origin/master"
      if bottle_block
        puts "Removing bottle block"
      else
        puts "No bottle block to remove"
      end
      puts "git add #{formula_file}"
      puts "git commit --no-edit --verbose --message=\"#{formula.name}: migrate from #{formula.tap.repo}\" -- #{formula_file}"

      unless local_only
        puts "hub fork --no-remote"
        puts "hub fork"
        puts "hub fork (to read $HUB_REMOTE)"
        puts "git push $HUB_REMOTE #{branch}:#{branch}"
        puts "hub pull-request --browse -m $'#{formula.name}: migrate from #{formula.tap.repo}\\n\\nGoes together with $PR_URL\\n\\nCreated with `brew boneyard-formula-pr`#{reason}.'"
      end
    else
      cd boneyard_tap.formula_dir
      safe_system "git", "checkout", "--no-track", "-b", branch, "origin/master"
      if bottle_block
        Utils::Inreplace.inreplace formula_file, /  bottle do.+?end\n\n/m, ""
      end
      safe_system "git", "add", formula_file
      safe_system "git", "commit", "--no-edit", "--verbose",
        "--message=#{formula.name}: migrate from #{formula.tap.repo}",
        "--", formula_file

      unless local_only
        safe_system "hub", "fork", "--no-remote"
        quiet_system "hub", "fork"
        remote = Utils.popen_read("hub fork 2>&1")[/fatal: remote (.+) already exists\./, 1]
        odie "cannot get remote from 'hub'!" unless remote
        safe_system "git", "push", remote, "#{branch}:#{branch}"
        safe_system "hub", "pull-request", "--browse", "-m", <<-EOS.undent
          #{formula.name}: migrate from #{formula.tap.repo}

          Goes together with #{pr_url}.

          Created with `brew boneyard-formula-pr`#{reason}.
        EOS
      end
    end
  end
end

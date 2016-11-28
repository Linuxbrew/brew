#:  * `man` [`--fail-if-changed`]:
#:    Generate Homebrew's manpages.
#:
#:    If `--fail-if-changed` is passed, the command will return a failing
#:    status code if changes are detected in the manpage outputs.
#:    This can be used for CI to be notified when the manpages are out of date.
#:    Additionally, the date used in new manpages will match those in the existing
#:    manpages (to allow comparison without factoring in the date).

require "formula"
require "erb"
require "ostruct"

module Homebrew
  module_function

  SOURCE_PATH = HOMEBREW_LIBRARY_PATH/"manpages"
  TARGET_MAN_PATH = HOMEBREW_REPOSITORY/"manpages"
  TARGET_DOC_PATH = HOMEBREW_REPOSITORY/"docs"

  def man
    raise UsageError unless ARGV.named.empty?

    if ARGV.flag? "--link"
      odie "`brew man --link` is now done automatically by `brew update`."
    else
      regenerate_man_pages
    end

    if system "git", "-C", HOMEBREW_REPOSITORY, "diff", "--quiet", "docs/brew.1.html", "manpages"
      puts "No changes to manpage output detected."
    elsif ARGV.include?("--fail-if-changed")
      Homebrew.failed = true
    end
  end

  def regenerate_man_pages
    Homebrew.install_gem_setup_path! "ronn"

    markup = build_man_page
    convert_man_page(markup, TARGET_DOC_PATH/"brew.1.html")
    convert_man_page(markup, TARGET_MAN_PATH/"brew.1")

    cask_markup = (SOURCE_PATH/"brew-cask.1.md").read
    convert_man_page(cask_markup, TARGET_MAN_PATH/"brew-cask.1")
  end

  def path_glob_commands(glob)
    Pathname.glob(glob)
            .sort_by { |source_file| sort_key_for_path(source_file) }
            .map do |source_file|
      source_file.read.lines
                 .grep(/^#:/)
                 .map { |line| line.slice(2..-1) }
                 .join
    end
            .reject { |s| s.strip.empty? || s.include?("@hide_from_man_page") }
  end

  def build_man_page
    template = (SOURCE_PATH/"brew.1.md.erb").read
    variables = OpenStruct.new

    variables[:commands] = path_glob_commands("#{HOMEBREW_LIBRARY_PATH}/cmd/*.{rb,sh}")
    variables[:developer_commands] = path_glob_commands("#{HOMEBREW_LIBRARY_PATH}/dev-cmd/*.{rb,sh}")
    readme = HOMEBREW_REPOSITORY/"README.md"
    variables[:lead_maintainer] = readme.read[/(Homebrew's lead maintainer .*\.)/, 1]
                                        .gsub(/\[([^\]]+)\]\([^)]+\)/, '\1')
    variables[:maintainers] = readme.read[/(Homebrew's current maintainers .*\.)/, 1]
                                    .gsub(/\[([^\]]+)\]\([^)]+\)/, '\1')
    variables[:former_maintainers] = readme.read[/(Former maintainers .*\.)/, 1]
                                           .gsub(/\[([^\]]+)\]\([^)]+\)/, '\1')

    ERB.new(template, nil, ">").result(variables.instance_eval { binding })
  end

  def sort_key_for_path(path)
    # Options after regular commands (`~` comes after `z` in ASCII table).
    path.basename.to_s.sub(/\.(rb|sh)$/, "").sub(/^--/, "~~")
  end

  def convert_man_page(markup, target)
    manual = target.basename(".1")
    organisation = "Homebrew"

    # Set the manpage date to the existing one if we're checking for changes.
    # This avoids the only change being e.g. a new date.
    date = if ARGV.include?("--fail-if-changed") &&
              target.extname == ".1" && target.exist?
      /"(\d{1,2})" "([A-Z][a-z]+) (\d{4})" "#{organisation}" "#{manual}"/ =~ target.read
      Date.parse("#{$1} #{$2} #{$3}")
    else
      Date.today
    end
    date = date.strftime("%Y-%m-%d")

    shared_args = %W[
      --pipe
      --organization=#{organisation}
      --manual=#{target.basename(".1")}
      --date=#{date}
    ]

    format_flag, format_desc = target_path_to_format(target)

    puts "Writing #{format_desc} to #{target}"
    Utils.popen(["ronn", format_flag] + shared_args, "rb+") do |ronn|
      ronn.write markup
      ronn.close_write
      target.atomic_write ronn.read
    end
  end

  def target_path_to_format(target)
    case target.basename
    when /\.html?$/ then ["--fragment", "HTML fragment"]
    when /\.\d$/    then ["--roff", "man page"]
    else
      odie "Failed to infer output format from '#{target.basename}'."
    end
  end
end

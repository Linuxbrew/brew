#:  * `man`:
#:    Generate Homebrew's manpages.

require "formula"
require "erb"
require "ostruct"

module Homebrew
  SOURCE_PATH = HOMEBREW_LIBRARY_PATH/"manpages"
  TARGET_MAN_PATH = HOMEBREW_REPOSITORY/"share/man/man1"
  TARGET_DOC_PATH = HOMEBREW_REPOSITORY/"share/doc/homebrew"

  def man
    raise UsageError unless ARGV.named.empty?

    if ARGV.flag? "--link"
      odie "`brew man --link` is now done automatically by `brew update`."
    else
      regenerate_man_pages
    end
  end

  private

  def regenerate_man_pages
    Homebrew.install_gem_setup_path! "ronn"

    markup = build_man_page
    convert_man_page(markup, TARGET_DOC_PATH/"brew.1.html")
    convert_man_page(markup, TARGET_MAN_PATH/"brew.1")

    cask_markup = (HOMEBREW_LIBRARY/"Homebrew/manpages/brew-cask.1.md").read
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
    variables[:maintainers] = (HOMEBREW_REPOSITORY/"README.md")
                              .read[/Homebrew's current maintainers are (.*)\./, 1]
                              .scan(/\[([^\]]*)\]/).flatten

    ERB.new(template, nil, ">").result(variables.instance_eval { binding })
  end

  def sort_key_for_path(path)
    # Options after regular commands (`~` comes after `z` in ASCII table).
    path.basename.to_s.sub(/\.(rb|sh)$/, "").sub(/^--/, "~~")
  end

  def convert_man_page(markup, target)
    shared_args = %W[
      --pipe
      --organization=Homebrew
      --manual=#{target.basename(".1")}
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

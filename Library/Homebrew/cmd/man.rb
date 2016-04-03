require "formula"

module Homebrew
  SOURCE_PATH=HOMEBREW_REPOSITORY/"Library/Homebrew/manpages"
  TARGET_PATH=HOMEBREW_REPOSITORY/"share/man/man1"
  DOC_PATH=HOMEBREW_REPOSITORY/"share/doc/homebrew"
  LINKED_PATH=HOMEBREW_PREFIX/"share/man/man1"

  def man
    abort <<-EOS.undent unless ARGV.named.empty?
      This command updates the brew manpage and does not take formula names.
    EOS

    if ARGV.flag? "--link"
      abort <<-EOS.undent if TARGET_PATH == LINKED_PATH
        The target path is the same as the linked one, aborting.
      EOS
      Dir["#{TARGET_PATH}/*.1"].each do |page|
        FileUtils.ln_s page, LINKED_PATH
        return
      end
    else
      Homebrew.install_gem_setup_path! "ronn"

      puts "Writing HTML fragments to #{DOC_PATH}"
      puts "Writing manpages to #{TARGET_PATH}"

      header = (SOURCE_PATH/"header.1.md").read
      footer = (SOURCE_PATH/"footer.1.md").read
      sub_commands = Pathname.glob("#{HOMEBREW_LIBRARY_PATH}/cmd/*.{rb,sh}").
        sort_by { |source_file| source_file.basename.sub(/\.(rb|sh)$/, "") }.
        map { |source_file|
          source_file.read.
            split("\n").
            grep(/^#:/).
            map { |line| line.slice(2..-1) }.
            join("\n")
        }.
        reject { |s| s.strip.empty? }.
        join("\n\n")

      target_md = SOURCE_PATH/"brew.1.md"
      target_md.atomic_write(header + sub_commands + footer)

      args = %W[
        --pipe
        --organization=Homebrew
        --manual=brew
        #{SOURCE_PATH}/brew.1.md
      ]

      target_html = DOC_PATH/"brew.1.html"
      target_html.atomic_write Utils.popen_read("ronn", "--fragment", *args)

      target_man = TARGET_PATH/"brew.1"
      target_man.atomic_write Utils.popen_read("ronn", "--roff", *args)
    end
  end
end

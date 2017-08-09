#:  * `bottle` [`--verbose`] [`--no-rebuild`|`--keep-old`] [`--skip-relocation`] [`--root-url=`<URL>] [`--force-core-tap`] <formulae>:
#:    Generate a bottle (binary package) from a formula installed with
#:    `--build-bottle`.
#:
#:    If the formula specifies a rebuild version, it will be incremented in the
#:    generated DSL. Passing `--keep-old` will attempt to keep it at its
#:    original value, while `--no-rebuild` will remove it.
#:
#:    If `--verbose` (or `-v`) is passed, print the bottling commands and any warnings
#:    encountered.
#:
#:    If `--skip-relocation` is passed, do not check if the bottle can be marked
#:    as relocatable.
#:
#:    If `--root-url` is passed, use the specified <URL> as the root of the
#:    bottle's URL instead of Homebrew's default.
#:
#:    If `--force-core-tap` is passed, build a bottle even if <formula> is not
#:    in homebrew/core or any installed taps.
#:
#:  * `bottle` `--merge` [`--keep-old`] [`--write` [`--no-commit`]] <formulae>:
#:    Generate a bottle from a formula and print the new DSL merged into the
#:    existing formula.
#:
#:    If `--write` is passed, write the changes to the formula file. A new
#:    commit will then be generated unless `--no-commit` is passed.

require "formula"
require "utils/bottles"
require "tab"
require "keg"
require "formula_versions"
require "utils/inreplace"
require "erb"
require "extend/pathname"

BOTTLE_ERB = <<-EOS.freeze
  bottle do
    <% if !root_url.start_with?(BottleSpecification::DEFAULT_DOMAIN) %>
    root_url "<%= root_url %>"
    <% end %>
    <% if prefix != BottleSpecification::DEFAULT_PREFIX %>
    prefix "<%= prefix %>"
    <% end %>
    <% if cellar.is_a? Symbol %>
    cellar :<%= cellar %>
    <% elsif cellar != BottleSpecification::DEFAULT_CELLAR %>
    cellar "<%= cellar %>"
    <% end %>
    <% if rebuild > 0 %>
    rebuild <%= rebuild %>
    <% end %>
    <% checksums.each do |checksum_type, checksum_values| %>
    <% checksum_values.each do |checksum_value| %>
    <% checksum, macos = checksum_value.shift %>
    <%= checksum_type %> "<%= checksum %>" => :<%= macos %>
    <% end %>
    <% end %>
  end
EOS

MAXIMUM_STRING_MATCHES = 100

module Homebrew
  module_function

  def keg_contain?(string, keg, ignores)
    @put_string_exists_header, @put_filenames = nil

    print_filename = lambda do |str, filename|
      unless @put_string_exists_header
        opoo "String '#{str}' still exists in these files:"
        @put_string_exists_header = true
      end

      @put_filenames ||= []

      return if @put_filenames.include? filename

      puts Formatter.error(filename.to_s)
      @put_filenames << filename
    end

    result = false

    keg.each_unique_file_matching(string) do |file|
      # skip document file.
      next if Metafiles::EXTENSIONS.include? file.extname

      linked_libraries = Keg.file_linked_libraries(file, string)
      result ||= !linked_libraries.empty?

      if ARGV.verbose?
        print_filename.call(string, file) unless linked_libraries.empty?
        linked_libraries.each do |lib|
          puts " #{Tty.bold}-->#{Tty.reset} links to #{lib}"
        end
      end

      text_matches = []

      # Use strings to search through the file for each string
      Utils.popen_read("strings", "-t", "x", "-", file.to_s) do |io|
        until io.eof?
          str = io.readline.chomp
          next if ignores.any? { |i| i =~ str }
          next unless str.include? string
          offset, match = str.split(" ", 2)
          next if linked_libraries.include? match # Don't bother reporting a string if it was found by otool

          result = true
          text_matches << [match, offset]
        end
      end

      next unless ARGV.verbose? && !text_matches.empty?
      print_filename.call(string, file)
      text_matches.first(MAXIMUM_STRING_MATCHES).each do |match, offset|
        puts " #{Tty.bold}-->#{Tty.reset} match '#{match}' at offset #{Tty.bold}0x#{offset}#{Tty.reset}"
      end

      if text_matches.size > MAXIMUM_STRING_MATCHES
        puts "Only the first #{MAXIMUM_STRING_MATCHES} matches were output"
      end
    end

    keg_contain_absolute_symlink_starting_with?(string, keg) || result
  end

  def keg_contain_absolute_symlink_starting_with?(string, keg)
    absolute_symlinks_start_with_string = []
    keg.find do |pn|
      next unless pn.symlink? && (link = pn.readlink).absolute?
      absolute_symlinks_start_with_string << pn if link.to_s.start_with?(string)
    end

    if ARGV.verbose?
      unless absolute_symlinks_start_with_string.empty?
        opoo "Absolute symlink starting with #{string}:"
        absolute_symlinks_start_with_string.each do |pn|
          puts "  #{pn} -> #{pn.resolved_path}"
        end
      end
    end

    !absolute_symlinks_start_with_string.empty?
  end

  def bottle_output(bottle)
    erb = ERB.new BOTTLE_ERB
    erb.result(bottle.instance_eval { binding }).gsub(/^\s*$\n/, "")
  end

  def bottle_formula(f)
    unless f.installed?
      return ofail "Formula not installed or up-to-date: #{f.full_name}"
    end

    tap = f.tap

    unless tap
      unless ARGV.include?("--force-core-tap")
        return ofail "Formula not from core or any taps: #{f.full_name}"
      end

      tap = CoreTap.instance
    end

    if f.bottle_disabled?
      ofail "Formula has disabled bottle: #{f.full_name}"
      puts f.bottle_disable_reason
      return
    end

    unless Utils::Bottles.built_as? f
      return ofail "Formula not installed with '--build-bottle': #{f.full_name}"
    end

    return ofail "Formula has no stable version: #{f.full_name}" unless f.stable

    if ARGV.include?("--no-rebuild") || !f.tap
      rebuild = 0
    elsif ARGV.include? "--keep-old"
      rebuild = f.bottle_specification.rebuild
    else
      ohai "Determining #{f.full_name} bottle rebuild..."
      versions = FormulaVersions.new(f)
      rebuilds = versions.bottle_version_map("origin/master")[f.pkg_version]
      rebuilds.pop if rebuilds.last.to_i > 0
      rebuild = rebuilds.empty? ? 0 : rebuilds.max.to_i + 1
    end

    filename = Bottle::Filename.create(f, Utils::Bottles.tag, rebuild)
    bottle_path = Pathname.pwd/filename

    tar_filename = filename.to_s.sub(/.gz$/, "")
    tar_path = Pathname.pwd/tar_filename

    prefix = HOMEBREW_PREFIX.to_s
    repository = HOMEBREW_REPOSITORY.to_s
    cellar = HOMEBREW_CELLAR.to_s

    ohai "Bottling #{filename}..."

    keg = Keg.new(f.prefix)
    relocatable = false
    skip_relocation = false

    keg.lock do
      original_tab = nil
      changed_files = nil

      begin
        keg.delete_pyc_files!

        unless ARGV.include? "--skip-relocation"
          changed_files = keg.replace_locations_with_placeholders
        end

        Tab.clear_cache
        tab = Tab.for_keg(keg)
        original_tab = tab.dup
        tab.poured_from_bottle = false
        tab.HEAD = nil
        tab.time = nil
        tab.changed_files = changed_files
        tab.write

        keg.find do |file|
          if file.symlink?
            # Ruby does not support `File.lutime` yet.
            # Shellout using `touch` to change modified time of symlink itself.
            system "/usr/bin/touch", "-h",
                   "-t", tab.source_modified_time.strftime("%Y%m%d%H%M.%S"), file
          else
            file.utime(tab.source_modified_time, tab.source_modified_time)
          end
        end

        cd cellar do
          safe_system "tar", "cf", tar_path, "#{f.name}/#{f.pkg_version}"
          tar_path.utime(tab.source_modified_time, tab.source_modified_time)
          relocatable_tar_path = "#{f}-bottle.tar"
          mv tar_path, relocatable_tar_path
          # Use gzip, faster to compress than bzip2, faster to uncompress than bzip2
          # or an uncompressed tarball (and more bandwidth friendly).
          safe_system "gzip", "-f", relocatable_tar_path
          mv "#{relocatable_tar_path}.gz", bottle_path
        end

        if bottle_path.size > 1 * 1024 * 1024
          ohai "Detecting if #{filename} is relocatable..."
        end

        if prefix == "/usr/local"
          prefix_check = File.join(prefix, "opt")
        else
          prefix_check = prefix
        end

        ignores = []
        if f.deps.any? { |dep| dep.name == "go" }
          ignores << %r{#{Regexp.escape(HOMEBREW_CELLAR)}/go/[\d\.]+/libexec}
        end

        relocatable = true
        if ARGV.include? "--skip-relocation"
          skip_relocation = true
        else
          relocatable = false if keg_contain?(prefix_check, keg, ignores)
          relocatable = false if keg_contain?(repository, keg, ignores)
          relocatable = false if keg_contain?(cellar, keg, ignores)
          if prefix != prefix_check
            relocatable = false if keg_contain_absolute_symlink_starting_with?(prefix, keg)
            relocatable = false if keg_contain?("#{prefix}/etc", keg, ignores)
            relocatable = false if keg_contain?("#{prefix}/var", keg, ignores)
          end
          skip_relocation = relocatable && !keg.require_relocation?
        end
        puts if !relocatable && ARGV.verbose?
      rescue Interrupt
        ignore_interrupts { bottle_path.unlink if bottle_path.exist? }
        raise
      ensure
        ignore_interrupts do
          original_tab.write if original_tab
          unless ARGV.include? "--skip-relocation"
            keg.replace_placeholders_with_locations changed_files
          end
        end
      end
    end

    root_url = ARGV.value("root-url")
    # Use underscored version for legacy reasons. Remove at some point.
    root_url ||= ARGV.value("root_url")

    bottle = BottleSpecification.new
    bottle.tap = tap
    bottle.root_url(root_url) if root_url
    if relocatable
      if skip_relocation
        bottle.cellar :any_skip_relocation
      else
        bottle.cellar :any
      end
    else
      bottle.cellar cellar
      bottle.prefix prefix
    end
    bottle.rebuild rebuild
    sha256 = bottle_path.sha256
    bottle.sha256 sha256 => Utils::Bottles.tag

    old_spec = f.bottle_specification
    if ARGV.include?("--keep-old") && !old_spec.checksums.empty?
      mismatches = [:root_url, :prefix, :cellar, :rebuild].reject do |key|
        old_spec.send(key) == bottle.send(key)
      end
      mismatches.delete(:cellar) if old_spec.cellar == :any && bottle.cellar == :any_skip_relocation
      bottle.cellar :any if OS.linux? && old_spec.cellar == :any && bottle.cellar == :any_skip_relocation
      unless mismatches.empty?
        if bottle.prefix == "/home/linuxbrew/.linuxbrew"
          bottle.cellar old_spec.cellar
          bottle.prefix old_spec.prefix
          opoo "--keep-old is passed but there are changes in: #{mismatches.join ", "}"
        else
          bottle_path.unlink if bottle_path.exist?

          mismatches.map! do |key|
            old_value = old_spec.send(key).inspect
            value = bottle.send(key).inspect
            "#{key}: old: #{old_value}, new: #{value}"
          end

          odie <<-EOS.undent
            --keep-old was passed but there are changes in:
            #{mismatches.join("\n")}
          EOS
        end
      end
    end

    output = bottle_output bottle

    puts "./#{filename}"
    puts output

    return unless ARGV.include? "--json"
    json = {
      f.full_name => {
        "formula" => {
          "pkg_version" => f.pkg_version.to_s,
          "path" => f.path.to_s.strip_prefix("#{HOMEBREW_REPOSITORY}/"),
        },
        "bottle" => {
          "root_url" => bottle.root_url,
          "prefix" => bottle.prefix,
          "cellar" => bottle.cellar.to_s,
          "rebuild" => bottle.rebuild,
          "tags" => {
            Utils::Bottles.tag.to_s => {
              "filename" => filename.to_s,
              "sha256" => sha256,
            },
          },
        },
        "bintray" => {
          "package" => Utils::Bottles::Bintray.package(f.name),
          "repository" => Utils::Bottles::Bintray.repository(tap),
        },
      },
    }
    File.open("#{filename.prefix}.bottle.json", "w") do |file|
      file.write JSON.generate json
    end
  end

  def merge
    write = ARGV.include? "--write"

    bottles_hash = ARGV.named.reduce({}) do |hash, json_file|
      deep_merge_hashes hash, JSON.parse(IO.read(json_file))
    end

    bottles_hash.each do |formula_name, bottle_hash|
      ohai formula_name

      bottle = BottleSpecification.new
      bottle.root_url bottle_hash["bottle"]["root_url"]
      cellar = bottle_hash["bottle"]["cellar"]
      cellar = cellar.to_sym if ["any", "any_skip_relocation"].include?(cellar)
      bottle.cellar cellar
      bottle.prefix bottle_hash["bottle"]["prefix"]
      bottle.rebuild bottle_hash["bottle"]["rebuild"]
      bottle_hash["bottle"]["tags"].each do |tag, tag_hash|
        bottle.sha256 tag_hash["sha256"] => tag.to_sym
      end

      output = bottle_output bottle

      if write
        path = Pathname.new((HOMEBREW_REPOSITORY/bottle_hash["formula"]["path"]).to_s)
        update_or_add = nil

        Utils::Inreplace.inreplace(path) do |s|
          if s.include? "bottle do"
            update_or_add = "update"
            if ARGV.include? "--keep-old"
              mismatches = []
              bottle_block_contents = s[/  bottle do(.+?)end\n/m, 1]
              bottle_block_contents.lines.each do |line|
                line = line.strip
                next if line.empty?
                key, old_value_original, _, tag = line.split " ", 4
                valid_key = %w[root_url prefix cellar rebuild sha1 sha256].include? key
                next unless valid_key

                old_value = old_value_original.to_s.delete ":'\""
                tag = tag.to_s.delete ":"

                unless tag.empty?
                  if !bottle_hash["bottle"]["tags"][tag].to_s.empty?
                    mismatches << "#{key} => #{tag}"
                  else
                    bottle.send(key, old_value => tag.to_sym)
                  end
                  next
                end

                value_original = bottle_hash["bottle"][key]
                value = value_original.to_s
                next if key == "cellar" && old_value == "any" && value == "any_skip_relocation"
                next unless old_value.empty? || value != old_value
                old_value = old_value_original.inspect
                value = value_original.inspect
                mismatches << "#{key}: old: #{old_value}, new: #{value}"
              end

              unless mismatches.empty?
                message = <<-EOS.undent
                  --keep-old was passed but there are changes in:
                  #{mismatches.join("\n")}
                EOS
                if ARGV.include? "--keep-going"
                  opoo message
                  update_or_add = nil
                  break
                else
                  odie message
                end
              end
              output = bottle_output bottle
            end
            puts output
            string = s.sub!(/  bottle do.+?end\n/m, output)
            odie "Bottle block update failed!" unless string
          else
            if ARGV.include? "--keep-old"
              odie "--keep-old was passed but there was no existing bottle block!"
            end
            puts output
            update_or_add = "add"
            if s.include? "stable do"
              indent = s.slice(/^( +)stable do/, 1).length
              string = s.sub!(/^ {#{indent}}stable do(.|\n)+?^ {#{indent}}end\n/m, '\0' + output + "\n")
            else
              string = s.sub!(
                /(
                  (\ {2}\#[^\n]*\n)*                                             # comments
                  \ {2}(                                                         # two spaces at the beginning
                    (url|head)\ ['"][\S\ ]+['"]                                  # url or head with a string
                    (
                      ,[\S\ ]*$                                                  # url may have options
                      (\n^\ {3}[\S\ ]+$)*                                        # options can be in multiple lines
                    )?|
                    (homepage|desc|sha1|sha256|version|mirror)\ ['"][\S\ ]+['"]| # specs with a string
                    revision\ \d+                                                # revision with a number
                  )\n+                                                           # multiple empty lines
                 )+
               /mx, '\0' + output + "\n"
              )
            end
            odie "Bottle block addition failed!" unless string
          end
        end

        unless ARGV.include?("--no-commit") || update_or_add.nil?
          short_name = formula_name.split("/", -1).last
          pkg_version = bottle_hash["formula"]["pkg_version"]

          path.parent.cd do
            safe_system "git", "commit", "--no-edit", "--verbose",
              "--message=#{short_name}: #{update_or_add} #{pkg_version} bottle#{" for Linuxbrew" if OS.linux?}.",
              "--", path
          end
        end
      else
        puts output
      end
    end
  end

  def ensure_formula_installed!(formula)
    return if Formula[formula].installed?
    ohai "Installing #{formula}..."
    safe_system HOMEBREW_BREW_FILE, "install", formula
  rescue FormulaUnavailableError
    # Fix for brew tests, which uses NullLoader.
    nil
  end

  def bottle
    if ARGV.include? "--merge"
      merge
    else
      ensure_formula_installed! "patchelf" if OS.linux?
      ARGV.resolved_formulae.each do |f|
        bottle_formula f
      end
    end
  end
end

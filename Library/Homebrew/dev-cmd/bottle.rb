#:  * `bottle` [`--verbose`] [`--no-rebuild`] [`--keep-old`] [`--skip-relocation`] [`--root-url=<root_url>`]:
#:  * `bottle` `--merge` [`--no-commit`] [`--keep-old`] [`--write`]:
#:
#:    Generate a bottle (binary package) from a formula installed with
#:    `--build-bottle`.

require "formula"
require "utils/bottles"
require "tab"
require "keg"
require "formula_versions"
require "utils/inreplace"
require "erb"
require "extend/pathname"

BOTTLE_ERB = <<-EOS
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
    <% checksum, osx = checksum_value.shift %>
    <%= checksum_type %> "<%= checksum %>" => :<%= osx %>
    <% end %>
    <% end %>
  end
EOS

MAXIMUM_STRING_MATCHES = 100

module Homebrew
  def keg_contain?(string, keg, ignores)
    @put_string_exists_header, @put_filenames = nil

    def print_filename(string, filename)
      unless @put_string_exists_header
        opoo "String '#{string}' still exists in these files:"
        @put_string_exists_header = true
      end

      @put_filenames ||= []
      unless @put_filenames.include? filename
        puts "#{Tty.red}#{filename}#{Tty.reset}"
        @put_filenames << filename
      end
    end

    result = false

    keg.each_unique_file_matching(string) do |file|
      # skip document file.
      next if Metafiles::EXTENSIONS.include? file.extname

      linked_libraries = Keg.file_linked_libraries(file, string)
      result ||= !linked_libraries.empty?

      if ARGV.verbose?
        print_filename(string, file) unless linked_libraries.empty?
        linked_libraries.each do |lib|
          puts " #{Tty.gray}-->#{Tty.reset} links to #{lib}"
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

      if ARGV.verbose? && !text_matches.empty?
        print_filename string, file
        text_matches.first(MAXIMUM_STRING_MATCHES).each do |match, offset|
          puts " #{Tty.gray}-->#{Tty.reset} match '#{match}' at offset #{Tty.em}0x#{offset}#{Tty.reset}"
        end

        if text_matches.size > MAXIMUM_STRING_MATCHES
          puts "Only the first #{MAXIMUM_STRING_MATCHES} matches were output"
        end
      end
    end

    keg_contain_absolute_symlink_starting_with?(string, keg) || result
  end

  def keg_contain_absolute_symlink_starting_with?(string, keg)
    absolute_symlinks_start_with_string = []
    keg.find do |pn|
      if pn.symlink? && (link = pn.readlink).absolute?
        if link.to_s.start_with?(string)
          absolute_symlinks_start_with_string << pn
        end
      end
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

    unless f.tap
      return ofail "Formula not from core or any taps: #{f.full_name}"
    end

    if f.bottle_disabled?
      ofail "Formula has disabled bottle: #{f.full_name}"
      puts f.bottle_disable_reason
      return
    end

    unless Utils::Bottles::built_as? f
      return ofail "Formula not installed with '--build-bottle': #{f.full_name}"
    end

    unless f.stable
      return ofail "Formula has no stable version: #{f.full_name}"
    end

    if ARGV.include? "--no-rebuild"
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
    cellar = HOMEBREW_CELLAR.to_s

    ohai "Bottling #{filename}..."

    keg = Keg.new(f.prefix)
    relocatable = false
    skip_relocation = false

    keg.lock do
      original_tab = nil

      begin
        unless ARGV.include? "--skip-relocation"
          keg.relocate_dynamic_linkage prefix, Keg::PREFIX_PLACEHOLDER,
            cellar, Keg::CELLAR_PLACEHOLDER
          keg.relocate_text_files prefix, Keg::PREFIX_PLACEHOLDER,
            cellar, Keg::CELLAR_PLACEHOLDER
        end

        keg.delete_pyc_files!

        Tab.clear_cache
        tab = Tab.for_keg(keg)
        original_tab = tab.dup
        tab.poured_from_bottle = false
        tab.HEAD = nil
        tab.time = nil
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

        if bottle_path.size > 1*1024*1024
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
          relocatable = false if keg_contain?(cellar, keg, ignores)
          if prefix != prefix_check
            relocatable = false if keg_contain_absolute_symlink_starting_with?(prefix, keg)
          end
          skip_relocation = relocatable && !keg.require_install_name_tool?
        end
        puts if !relocatable && ARGV.verbose?
      rescue Interrupt
        ignore_interrupts { bottle_path.unlink if bottle_path.exist? }
        raise
      ensure
        ignore_interrupts do
          original_tab.write if original_tab
          unless ARGV.include? "--skip-relocation"
            keg.relocate_dynamic_linkage Keg::PREFIX_PLACEHOLDER, prefix,
              Keg::CELLAR_PLACEHOLDER, cellar
            keg.relocate_text_files Keg::PREFIX_PLACEHOLDER, prefix,
              Keg::CELLAR_PLACEHOLDER, cellar
          end
        end
      end
    end

    root_url = ARGV.value("root-url")
    # Use underscored version for legacy reasons. Remove at some point.
    root_url ||= ARGV.value("root_url")

    bottle = BottleSpecification.new
    bottle.tap = f.tap
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
      mismatches = [:root_url, :prefix, :cellar, :rebuild].select do |key|
        old_spec.send(key) != bottle.send(key)
      end
      mismatches.delete(:cellar) if old_spec.cellar == :any && bottle.cellar == :any_skip_relocation
      unless mismatches.empty?
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

    output = bottle_output bottle

    puts "./#{filename}"
    puts output

    if ARGV.include? "--json"
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
            }
          },
          "bintray" => {
            "package" => Utils::Bottles::Bintray.package(f.name),
            "repository" => Utils::Bottles::Bintray.repository(f.tap),
          },
        },
      }
      File.open("#{filename.prefix}.bottle.json", "w") do |file|
        file.write Utils::JSON.dump json
      end
    end
  end

  def merge
    write = ARGV.include? "--write"

    bottles_hash = ARGV.named.reduce({}) do |hash, json_file|
      deep_merge_hashes hash, Utils::JSON.load(IO.read(json_file))
    end

    bottles_hash.each do |formula_name, bottle_hash|
      ohai formula_name

      bottle = BottleSpecification.new
      bottle.root_url bottle_hash["bottle"]["root_url"]
      cellar = bottle_hash["bottle"]["cellar"]
      if cellar == "any" || cellar == "any_skip_relocation"
        cellar = cellar.to_sym
      end
      bottle.cellar cellar
      bottle.prefix bottle_hash["bottle"]["prefix"]
      bottle.rebuild bottle_hash["bottle"]["rebuild"]
      bottle_hash["bottle"]["tags"].each do |tag, tag_hash|
        bottle.sha256 tag_hash["sha256"] => tag.to_sym
      end

      output = bottle_output bottle

      if write
        path = Pathname.new("#{HOMEBREW_REPOSITORY/bottle_hash["formula"]["path"]}")
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

                if !tag.empty?
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
                if old_value.empty? || value != old_value
                  old_value = old_value_original.inspect
                  value = value_original.inspect
                  mismatches << "#{key}: old: #{old_value}, new: #{value}"
                end
              end

              unless mismatches.empty?
                odie <<-EOS.undent
                  --keep-old was passed but there are changes in:
                  #{mismatches.join("\n")}
                EOS
                odie "--keep-old was passed but there were changes in #{mismatches.join(", ")}!"
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
              indent = s.slice(/^ +stable do/).length - "stable do".length
              string = s.sub!(/^ {#{indent}}stable do(.|\n)+?^ {#{indent}}end\n/m, '\0' + output + "\n")
            else
              string = s.sub!(
                /(
                  \ {2}(                                                         # two spaces at the beginning
                    (url|head)\ ['"][\S\ ]+['"]                                  # url or head with a string
                    (
                      ,[\S\ ]*$                                                  # url may have options
                      (\n^\ {3}[\S\ ]+$)*                                        # options can be in multiple lines
                    )?|
                    (homepage|desc|sha1|sha256|version|mirror)\ ['"][\S\ ]+['"]| # specs with a string
                    rebuild\ \d+                                                 # rebuild with a number
                  )\n+                                                           # multiple empty lines
                 )+
               /mx, '\0' + output + "\n")
            end
            odie "Bottle block addition failed!" unless string
          end
        end

        unless ARGV.include? "--no-commit"
          short_name = formula_name.split("/", -1).last
          pkg_version = bottle_hash["formula"]["pkg_version"]

          path.parent.cd do
            safe_system "git", "commit", "--no-edit", "--verbose",
              "--message=#{short_name}: #{update_or_add} #{pkg_version} bottle.",
              "--", path
          end
        end
      else
        puts output
      end
    end
  end

  def bottle
    if ARGV.include? "--merge"
      merge
    else
      ARGV.resolved_formulae.each do |f|
        bottle_formula f
      end
    end
  end
end

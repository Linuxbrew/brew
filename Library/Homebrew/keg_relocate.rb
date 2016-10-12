class Keg
  PREFIX_PLACEHOLDER = "@@HOMEBREW_PREFIX@@".freeze
  CELLAR_PLACEHOLDER = "@@HOMEBREW_CELLAR@@".freeze
  REPOSITORY_PLACEHOLDER = "@@HOMEBREW_REPOSITORY@@".freeze

  def fix_dynamic_linkage
    symlink_files.each do |file|
      link = file.readlink
      # Don't fix relative symlinks
      next unless link.absolute?
      if link.to_s.start_with?(HOMEBREW_CELLAR.to_s) || link.to_s.start_with?(HOMEBREW_PREFIX.to_s)
        FileUtils.ln_sf(link.relative_path_from(file.parent), file)
      end
    end
  end
  alias generic_fix_dynamic_linkage fix_dynamic_linkage

  def relocate_dynamic_linkage(_old_prefix, _new_prefix, _old_cellar, _new_cellar)
    []
  end

  def relocate_text_files(old_prefix, new_prefix, old_cellar, new_cellar,
                          old_repository, new_repository)
    files = text_files | libtool_files

    files.group_by { |f| f.stat.ino }.each_value do |first, *rest|
      s = first.open("rb", &:read)
      changed = s.gsub!(old_cellar, new_cellar)
      changed = s.gsub!(old_prefix, new_prefix) || changed
      changed = s.gsub!(old_repository, new_repository) || changed

      next unless changed

      begin
        first.atomic_write(s)
      rescue SystemCallError
        first.ensure_writable do
          first.open("wb") { |f| f.write(s) }
        end
      else
        rest.each { |file| FileUtils.ln(first, file, force: true) }
      end
    end
  end

  def detect_cxx_stdlibs(_options = {})
    []
  end

  def each_unique_file_matching(string)
    Utils.popen_read("/usr/bin/fgrep", "-lr", string, to_s) do |io|
      hardlinks = Set.new

      until io.eof?
        file = Pathname.new(io.readline.chomp)
        next if file.symlink?
        yield file if hardlinks.add? file.stat.ino
      end
    end
  end

  def lib
    path.join("lib")
  end

  def text_files
    text_files = []
    return text_files unless File.exist?("/usr/bin/file")

    # file has known issues with reading files on other locales. Has
    # been fixed upstream for some time, but a sufficiently new enough
    # file with that fix is only available in macOS Sierra.
    # http://bugs.gw.com/view.php?id=292
    with_custom_locale("C") do
      files = path.find.reject { |pn|
        pn.symlink? || pn.directory? || Metafiles::EXTENSIONS.include?(pn.extname)
      }
      output, _status = Open3.capture2("/usr/bin/xargs -0 /usr/bin/file --no-dereference --brief",
                                       stdin_data: files.join("\0"))
      output.each_line.with_index do |line, i|
        next unless line.include?("text")
        text_files << files[i]
      end
    end

    text_files
  end

  def libtool_files
    libtool_files = []

    path.find do |pn|
      next if pn.symlink? || pn.directory? || pn.extname != ".la"
      libtool_files << pn
    end
    libtool_files
  end

  def symlink_files
    symlink_files = []
    path.find do |pn|
      symlink_files << pn if pn.symlink?
    end

    symlink_files
  end

  def self.file_linked_libraries(_file, _string)
    []
  end
end

require "extend/os/keg_relocate"

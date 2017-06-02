class Keg
  PREFIX_PLACEHOLDER = "@@HOMEBREW_PREFIX@@".freeze
  CELLAR_PLACEHOLDER = "@@HOMEBREW_CELLAR@@".freeze
  REPOSITORY_PLACEHOLDER = "@@HOMEBREW_REPOSITORY@@".freeze

  Relocation = Struct.new(:old_prefix, :old_cellar, :old_repository,
                          :new_prefix, :new_cellar, :new_repository) do
    # Use keyword args instead of positional args for initialization
    def initialize(**kwargs)
      super(*members.map { |k| kwargs[k] })
    end
  end

  def fix_dynamic_linkage
    symlink_files.each do |file|
      link = file.readlink
      # Don't fix relative symlinks
      next unless link.absolute?
      link_starts_cellar = link.to_s.start_with?(HOMEBREW_CELLAR.to_s)
      link_starts_prefix = link.to_s.start_with?(HOMEBREW_PREFIX.to_s)
      next if !link_starts_cellar && !link_starts_prefix
      new_src = link.relative_path_from(file.parent)
      file.unlink
      FileUtils.ln_s(new_src, file)
    end
  end
  alias generic_fix_dynamic_linkage fix_dynamic_linkage

  def relocate_dynamic_linkage(_relocation)
    []
  end

  def replace_locations_with_placeholders
    relocation = Relocation.new(
      old_prefix: HOMEBREW_PREFIX.to_s,
      old_cellar: HOMEBREW_CELLAR.to_s,
      old_repository: HOMEBREW_REPOSITORY.to_s,
      new_prefix: PREFIX_PLACEHOLDER,
      new_cellar: CELLAR_PLACEHOLDER,
      new_repository: REPOSITORY_PLACEHOLDER,
    )
    relocate_dynamic_linkage(relocation)
    replace_text_in_files(relocation)
  end

  def replace_placeholders_with_locations(files, skip_linkage: false)
    relocation = Relocation.new(
      old_prefix: PREFIX_PLACEHOLDER,
      old_cellar: CELLAR_PLACEHOLDER,
      old_repository: REPOSITORY_PLACEHOLDER,
      new_prefix: HOMEBREW_PREFIX.to_s,
      new_cellar: HOMEBREW_CELLAR.to_s,
      new_repository: HOMEBREW_REPOSITORY.to_s,
    )
    relocate_dynamic_linkage(relocation) unless skip_linkage
    replace_text_in_files(relocation, files: files)
  end

  def replace_text_in_files(relocation, files: nil)
    files ||= text_files | libtool_files

    changed_files = []
    files.map(&path.method(:join)).group_by { |f| f.stat.ino }.each_value do |first, *rest|
      s = first.open("rb", &:read)

      replacements = {
        relocation.old_prefix => relocation.new_prefix,
        relocation.old_cellar => relocation.new_cellar,
        relocation.old_repository => relocation.new_repository,
      }
      changed = s.gsub!(Regexp.union(replacements.keys), replacements)
      next unless changed
      changed_files += [first, *rest].map { |file| file.relative_path_from(path) }

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
    changed_files
  end

  def detect_cxx_stdlibs(_options = {})
    []
  end

  def recursive_fgrep_args
    # for GNU grep; overridden for BSD grep on OS X
    "-lr"
  end
  alias generic_recursive_fgrep_args recursive_fgrep_args

  def each_unique_file_matching(string)
    Utils.popen_read("/usr/bin/fgrep", recursive_fgrep_args, string, to_s) do |io|
      hardlinks = Set.new

      until io.eof?
        file = Pathname.new(io.readline.chomp)
        next if file.symlink?
        yield file if hardlinks.add? file.stat.ino
      end
    end
  end

  def lib
    path/"lib"
  end

  def text_files
    text_files = []
    return text_files unless File.exist?("/usr/bin/file")

    # file has known issues with reading files on other locales. Has
    # been fixed upstream for some time, but a sufficiently new enough
    # file with that fix is only available in macOS Sierra.
    # https://bugs.gw.com/view.php?id=292
    with_custom_locale("C") do
      files = Set.new path.find.reject { |pn|
        next true if pn.symlink?
        next true if pn.directory?
        next false if pn.basename.to_s == "orig-prefix.txt" # for python virtualenvs
        next true if Metafiles::EXTENSIONS.include?(pn.extname)
        if pn.text_executable?
          text_files << pn
          next true
        end
        false
      }
      output, _status = Open3.capture2("/usr/bin/xargs -0 /usr/bin/file --no-dereference --print0",
                                       stdin_data: files.to_a.join("\0"))
      # `file` output sometimes contains data from the file, which may include
      # invalid UTF-8 entities, so tell Ruby this is just a bytestring
      output.force_encoding(Encoding::ASCII_8BIT)
      output.each_line do |line|
        path, info = line.split("\0", 2)
        # `file` sometimes prints more than one line of output per file;
        # subsequent lines do not contain a null-byte separator, so `info`
        # will be `nil` for those lines
        next unless info
        next unless info.include?("text")
        path = Pathname.new(path)
        next unless files.include?(path)
        text_files << path
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

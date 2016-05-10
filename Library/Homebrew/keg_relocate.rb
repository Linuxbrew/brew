class Keg
  PREFIX_PLACEHOLDER = "@@HOMEBREW_PREFIX@@".freeze
  CELLAR_PLACEHOLDER = "@@HOMEBREW_CELLAR@@".freeze

  def fix_install_names
    return unless OS.mac?
    mach_o_files.each do |file|
      file.ensure_writable do
        change_dylib_id(dylib_id_for(file), file) if file.dylib?

        each_install_name_for(file) do |bad_name|
          # Don't fix absolute paths unless they are rooted in the build directory
          next if bad_name.start_with?("/") && !bad_name.start_with?(HOMEBREW_TEMP.to_s)

          new_name = fixed_name(file, bad_name)
          change_install_name(bad_name, new_name, file) unless new_name == bad_name
        end
      end
    end

    symlink_files.each do |file|
      link = file.readlink
      # Don't fix relative symlinks
      next unless link.absolute?
      if link.to_s.start_with?(HOMEBREW_CELLAR.to_s) || link.to_s.start_with?(HOMEBREW_PREFIX.to_s)
        FileUtils.ln_sf(link.relative_path_from(file.parent), file)
      end
    end
  end

  def relocate_install_names(old_prefix, new_prefix, old_cellar, new_cellar)
    return if name == "glibc"
    mach_o_files.each do |file|
      file.ensure_writable do
        change_rpath(file, new_prefix)
        next unless OS.mac?

        if file.dylib?
          id = dylib_id_for(file).sub(old_prefix, new_prefix)
          change_dylib_id(id, file)
        end

        each_install_name_for(file) do |old_name|
          if old_name.start_with? old_cellar
            new_name = old_name.sub(old_cellar, new_cellar)
          elsif old_name.start_with? old_prefix
            new_name = old_name.sub(old_prefix, new_prefix)
          end

          change_install_name(old_name, new_name, file) if new_name
        end
      end
    end
  end

  def relocate_text_files(old_prefix, new_prefix, old_cellar, new_cellar)
    files = text_files | libtool_files

    files.group_by { |f| f.stat.ino }.each_value do |first, *rest|
      s = first.open("rb", &:read)
      changed = s.gsub!(old_cellar, new_cellar)
      changed = s.gsub!(old_prefix, new_prefix) || changed

      next unless changed

      begin
        first.atomic_write(s)
      rescue SystemCallError
        first.ensure_writable do
          first.open("wb") { |f| f.write(s) }
        end
      else
        rest.each { |file| FileUtils.ln(first, file, :force => true) }
      end
    end
  end

  def change_rpath(file, new_prefix)
    return unless OS.linux?
    # Patching patchelf using itself fails with "Text file busy" or SIGBUS.
    return if name == "patchelf"
    begin
      patchelf = Formula["patchelf"]
    rescue FormulaUnavailableError
      # Fix for brew tests, which uses NullLoader.
      return
    end
    return unless patchelf.installed?
    cmd = "#{patchelf.bin}/patchelf --set-rpath #{new_prefix}/lib"
    old_rpath = `#{patchelf.bin}/patchelf --print-rpath #{file}`.strip
    raise ErrorDuringExecution.new(cmd) unless $?.success?
    if file.mach_o_executable?
      old_interpreter = `#{patchelf.bin}/patchelf --print-interpreter #{file}`.split("\n")
      raise ErrorDuringExecution.new(cmd) unless $?.success?
      interpreter = new_prefix == PREFIX_PLACEHOLDER ?
        "/lib64/ld-linux-x86-64.so.2" :
        "#{HOMEBREW_PREFIX}/lib/ld.so"
      cmd << " --set-interpreter #{interpreter}" unless old_i == interpreter
    end
    cmd << " #{file}"
    if old_rpath == "#{new_prefix}/lib" && old_interpreter == interpreter
      puts "Skipping relocation of #{file} (RPATH already set)" if ARGV.debug?
    else
      puts "Setting RPATH of #{file}" if ARGV.debug?
      safe_system cmd
    end
  end

  # Detects the C++ dynamic libraries in place, scanning the dynamic links
  # of the files within the keg.
  # Note that this doesn't attempt to distinguish between libstdc++ versions,
  # for instance between Apple libstdc++ and GNU libstdc++
  def detect_cxx_stdlibs(options = {})
    skip_executables = options.fetch(:skip_executables, false)
    results = Set.new

    mach_o_files.each do |file|
      next if file.mach_o_executable? && skip_executables
      dylibs = file.dynamically_linked_libraries
      results << :libcxx unless dylibs.grep(/libc\+\+.+\.dylib/).empty?
      results << :libstdcxx unless dylibs.grep(/libstdc\+\+.+\.dylib/).empty?
    end

    results.to_a
  end

  def each_unique_file_matching(string)
    Utils.popen_read("fgrep", "-lr", string, to_s) do |io|
      hardlinks = Set.new

      until io.eof?
        file = Pathname.new(io.readline.chomp)
        next if file.symlink?
        yield file if hardlinks.add? file.stat.ino
      end
    end
  end

  # If file is a dylib or bundle itself, look for the dylib named by
  # bad_name relative to the lib directory, so that we can skip the more
  # expensive recursive search if possible.
  def fixed_name(file, bad_name)
    if bad_name.start_with? PREFIX_PLACEHOLDER
      bad_name.sub(PREFIX_PLACEHOLDER, HOMEBREW_PREFIX.to_s)
    elsif bad_name.start_with? CELLAR_PLACEHOLDER
      bad_name.sub(CELLAR_PLACEHOLDER, HOMEBREW_CELLAR.to_s)
    elsif (file.dylib? || file.mach_o_bundle?) && (file.parent + bad_name).exist?
      "@loader_path/#{bad_name}"
    elsif file.mach_o_executable? && (lib + bad_name).exist?
      "#{lib}/#{bad_name}"
    elsif (abs_name = find_dylib(bad_name)) && abs_name.exist?
      abs_name.to_s
    else
      opoo "Could not fix #{bad_name} in #{file}"
      bad_name
    end
  end

  def lib
    path.join("lib")
  end

  def each_install_name_for(file, &block)
    dylibs = file.dynamically_linked_libraries
    dylibs.reject! { |fn| fn =~ /^@(loader_|executable_|r)path/ }
    dylibs.each(&block)
  end

  def dylib_id_for(file)
    return nil unless OS.mac?
    # The new dylib ID should have the same basename as the old dylib ID, not
    # the basename of the file itself.
    basename = File.basename(file.dylib_id)
    relative_dirname = file.dirname.relative_path_from(path)
    opt_record.join(relative_dirname, basename).to_s
  end

  # Matches framework references like `XXX.framework/Versions/YYY/XXX` and
  # `XXX.framework/XXX`, both with or without a slash-delimited prefix.
  FRAMEWORK_RX = %r{(?:^|/)(([^/]+)\.framework/(?:Versions/[^/]+/)?\2)$}.freeze

  def find_dylib_suffix_from(bad_name)
    if (framework = bad_name.match(FRAMEWORK_RX))
      framework[1]
    else
      File.basename(bad_name)
    end
  end

  def find_dylib(bad_name)
    return unless lib.directory?
    suffix = "/#{find_dylib_suffix_from(bad_name)}"
    lib.find { |pn| break pn if pn.to_s.end_with?(suffix) }
  end

  def mach_o_files
    mach_o_files = []
    path.find do |pn|
      next if pn.symlink? || pn.directory?
      mach_o_files << pn if pn.dylib? || pn.mach_o_bundle? || pn.mach_o_executable?
    end

    mach_o_files
  end

  def text_files
    text_files = []
    path.find do |pn|
      next if pn.symlink? || pn.directory?
      next if Metafiles::EXTENSIONS.include? pn.extname
      if Utils.popen_read("file", "--brief", pn).include?("text") ||
         pn.text_executable?
        text_files << pn
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
end

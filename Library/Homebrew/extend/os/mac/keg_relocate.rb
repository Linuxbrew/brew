class Keg
  class << self
    undef file_linked_libraries

    def file_linked_libraries(file, string)
      # Check dynamic library linkage. Importantly, do not perform for static
      # libraries, which will falsely report "linkage" to themselves.
      if file.mach_o_executable? || file.dylib? || file.mach_o_bundle?
        file.dynamically_linked_libraries.select { |lib| lib.include? string }
      else
        []
      end
    end
  end

  undef relocate_dynamic_linkage, detect_cxx_stdlibs

  def relocate_dynamic_linkage(relocation)
    mach_o_files.each do |file|
      file.ensure_writable do
        if file.dylib?
          id = dylib_id_for(file).sub(relocation.old_prefix, relocation.new_prefix)
          change_dylib_id(id, file)
        end

        each_install_name_for(file) do |old_name|
          if old_name.start_with? relocation.old_cellar
            new_name = old_name.sub(relocation.old_cellar, relocation.new_cellar)
          elsif old_name.start_with? relocation.old_prefix
            new_name = old_name.sub(relocation.old_prefix, relocation.new_prefix)
          end

          change_install_name(old_name, new_name, file) if new_name
        end
      end
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

  def fix_dynamic_linkage
    mach_o_files.each do |file|
      file.ensure_writable do
        change_dylib_id(dylib_id_for(file), file) if file.dylib?

        each_install_name_for(file) do |bad_name|
          # Don't fix absolute paths unless they are rooted in the build directory
          next if bad_name.start_with?("/") &&
                  !bad_name.start_with?(HOMEBREW_TEMP.to_s) &&
                  !bad_name.start_with?(HOMEBREW_TEMP.realpath.to_s)

          new_name = fixed_name(file, bad_name)
          change_install_name(bad_name, new_name, file) unless new_name == bad_name
        end
      end
    end

    generic_fix_dynamic_linkage
  end

  # If file is a dylib or bundle itself, look for the dylib named by
  # bad_name relative to the lib directory, so that we can skip the more
  # expensive recursive search if possible.
  def fixed_name(file, bad_name)
    if bad_name.start_with? PREFIX_PLACEHOLDER
      bad_name.sub(PREFIX_PLACEHOLDER, HOMEBREW_PREFIX)
    elsif bad_name.start_with? CELLAR_PLACEHOLDER
      bad_name.sub(CELLAR_PLACEHOLDER, HOMEBREW_CELLAR)
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

  def each_install_name_for(file, &block)
    dylibs = file.dynamically_linked_libraries
    dylibs.reject! { |fn| fn =~ /^@(loader_|executable_|r)path/ }
    dylibs.each(&block)
  end

  def dylib_id_for(file)
    # The new dylib ID should have the same basename as the old dylib ID, not
    # the basename of the file itself.
    basename = File.basename(file.dylib_id)
    relative_dirname = file.dirname.relative_path_from(path)
    (opt_record/relative_dirname/basename).to_s
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
    hardlinks = Set.new
    mach_o_files = []
    path.find do |pn|
      next if pn.symlink? || pn.directory?
      next unless pn.dylib? || pn.mach_o_bundle? || pn.mach_o_executable?
      # if we've already processed a file, ignore its hardlinks (which have the same dev ID and inode)
      # this prevents relocations from being performed on a binary more than once
      next unless hardlinks.add? [pn.stat.dev, pn.stat.ino]

      mach_o_files << pn
    end

    mach_o_files
  end

  def recursive_fgrep_args
    # Don't recurse into symlinks; the man page says this is the default, but
    # it's wrong. -O is a BSD-grep-only option.
    "-lrO"
  end
end

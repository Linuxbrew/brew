class Keg
  def relocate_dynamic_linkage(relocation)
    # Patching the dynamic linker of glibc breaks it.
    return if name == "glibc"

    # Patching patchelf using itself fails with "Text file busy" or SIGBUS.
    return if name == "patchelf"

    elf_files.each do |file|
      file.ensure_writable do
        change_rpath(file, relocation.old_prefix, relocation.new_prefix)
      end
    end
  end

  def change_rpath(file, old_prefix, new_prefix)
    return if !file.elf? || !file.dynamic_elf?

    patchelf = DevelopmentTools.locate "patchelf"
    cmd_rpath = [patchelf, "--print-rpath", file]
    old_rpath = Utils.popen_read(*cmd_rpath, err: :out).strip

    # patchelf requires that the ELF file have a .dynstr section.
    # Skip ELF files that do not have a .dynstr section.
    return if ["cannot find section .dynstr", "strange: no string table"].include?(old_rpath)
    unless $CHILD_STATUS.success?
      raise ErrorDuringExecution.new(cmd_rpath, status: $CHILD_STATUS, output: [[:stderr, old_rpath]])
    end

    rpath = old_rpath
            .split(":")
            .map { |x| x.sub(old_prefix, new_prefix) }
            .select { |x| x.start_with?(new_prefix, "$ORIGIN") }

    lib_path = "#{new_prefix}/lib"
    rpath << lib_path unless rpath.include? lib_path
    new_rpath = rpath.join(":")
    cmd = [patchelf, "--force-rpath", "--set-rpath", new_rpath]

    if file.binary_executable?
      old_interpreter = Utils.safe_popen_read(patchelf, "--print-interpreter", file).strip
      new_interpreter = if File.readable? "#{new_prefix}/lib/ld.so"
        "#{new_prefix}/lib/ld.so"
      else
        old_interpreter.sub old_prefix, new_prefix
      end
      cmd << "--set-interpreter" << new_interpreter if old_interpreter != new_interpreter
    end

    return if old_rpath == new_rpath && old_interpreter == new_interpreter

    safe_system(*cmd, file)
  end

  def detect_cxx_stdlibs(options = {})
    skip_executables = options.fetch(:skip_executables, false)
    results = Set.new
    elf_files.each do |file|
      next unless file.dynamic_elf?
      next if file.binary_executable? && skip_executables

      dylibs = file.dynamically_linked_libraries
      results << :libcxx if dylibs.any? { |s| s.include? "libc++.so" }
      results << :libstdcxx if dylibs.any? { |s| s.include? "libstdc++.so" }
    end
    results.to_a
  end

  def elf_files
    hardlinks = Set.new
    elf_files = []
    path.find do |pn|
      next if pn.symlink? || pn.directory?
      next if !pn.dylib? && !pn.binary_executable?

      # If we've already processed a file, ignore its hardlinks (which have the
      # same dev ID and inode). This prevents relocations from being performed
      # on a binary more than once.
      next unless hardlinks.add? [pn.stat.dev, pn.stat.ino]

      elf_files << pn
    end
    elf_files
  end

  def self.relocation_formulae
    ["patchelf"]
  end

  def self.bottle_dependencies
    @bottle_dependencies ||= begin
      formulae = relocation_formulae
      gcc = Formula["gcc"]
      if !ENV["HOMEBREW_FORCE_HOMEBREW_ON_LINUX"] &&
         DevelopmentTools.non_apple_gcc_version("gcc") < gcc.version.to_i
        formulae += gcc.recursive_dependencies.map(&:name)
        formulae << gcc.name
      end
      formulae
    end
  end
end

class Keg
  def relocate_dynamic_linkage(relocation)
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
    return unless file.elf? && file.dynamic?

    begin
      patchelf = Formula["patchelf"].bin/"patchelf"
    rescue FormulaUnavailableError
      # Fix for brew tests, which uses NullLoader.
      return
    end

    cmd_rpath = "#{patchelf} --print-rpath '#{file}' 2>&1"
    old_rpath = Utils.popen_read(*cmd_rpath).strip
    return if old_rpath == "cannot find section .dynstr"
    raise ErrorDuringExecution, "#{cmd_rpath}\n#{old_rpath}" unless $?.success?
    rpath = old_rpath.split(":").map { |x| x.sub(old_prefix, new_prefix) }.select do |x|
      x.start_with?(new_prefix, "$ORIGIN")
    end

    lib_path = "#{new_prefix}/lib"
    rpath << lib_path unless rpath.include? lib_path
    new_rpath = rpath.join(":")
    cmd = [patchelf, "--set-rpath", new_rpath]

    if file.mach_o_executable?
      cmd_interpreter = [patchelf, "--print-interpreter", file]
      old_interpreter = Utils.popen_read(*cmd_interpreter).strip
      raise ErrorDuringExecution, cmd_interpreter unless $?.success?
      new_interpreter = new_prefix == PREFIX_PLACEHOLDER ? "/lib64/ld-linux-x86-64.so.2" : "#{HOMEBREW_PREFIX}/lib/ld.so"
      cmd << "--set-interpreter" << new_interpreter unless old_interpreter == new_interpreter
    end

    return if old_rpath == new_rpath && old_interpreter == new_interpreter
    safe_system(*cmd, file)
  end

  # Detects the C++ dynamic libraries in place, scanning the dynamic links
  # of the files within the keg.
  # Note that this doesn't attempt to distinguish between libstdc++ versions,
  # for instance between Apple libstdc++ and GNU libstdc++
  def detect_cxx_stdlibs(options = {})
    skip_executables = options.fetch(:skip_executables, false)
    results = Set.new

    elf_files.each do |file|
      next if !file.dynamic? || file.mach_o_executable? && skip_executables
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
      next unless pn.dylib? || pn.mach_o_executable?
      # If we've already processed a file, ignore its hardlinks (which have the
      # same dev ID and inode). This prevents relocations from being performed
      # on a binary more than once.
      next unless hardlinks.add? [pn.stat.dev, pn.stat.ino]
      elf_files << pn
    end

    elf_files
  end

  # For test/test_keg.rb
  alias mach_o_files elf_files
end

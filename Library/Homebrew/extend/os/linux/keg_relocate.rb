class Keg
  def relocate_dynamic_linkage(relocation)
    return if name == "glibc"
    elf_files.each do |file|
      file.ensure_writable do
        change_rpath(file, relocation.old_prefix, relocation.new_prefix)
      end
    end
  end

  def change_rpath(file, old_prefix, new_prefix)
    return unless file.elf? && file.dynamic?

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
    raise ErrorDuringExecution, cmd unless $?.success?
    lib_path = "#{new_prefix}/lib"
    rpath = old_rpath.split(":").map { |x| x.sub(old_prefix, new_prefix) }.select do |x|
      x.start_with?(new_prefix, "$ORIGIN")
    end
    rpath << lib_path unless rpath.include? lib_path
    new_rpath = rpath.join(":")
    cmd = ["#{patchelf.bin}/patchelf", "--set-rpath", new_rpath]
    if file.mach_o_executable?
      old_interpreter = `#{patchelf.bin}/patchelf --print-interpreter #{file}`.strip
      raise ErrorDuringExecution, cmd unless $?.success?
      interpreter = new_prefix == PREFIX_PLACEHOLDER ? "/lib64/ld-linux-x86-64.so.2" : "#{HOMEBREW_PREFIX}/lib/ld.so"
      cmd << "--set-interpreter" << interpreter unless old_interpreter == interpreter
    end
    cmd << file
    if old_rpath == "#{new_prefix}/lib" && old_interpreter == interpreter
      puts "Skipping relocation of #{file} (RPATH already set)" if ARGV.debug?
    else
      puts "Setting RPATH of #{file}" if ARGV.debug?
      safe_system(*cmd)
    end
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

class Keg
  def change_dylib_id(id, file)
    @require_relocation = true
    puts "Changing dylib ID of #{file}\n  from #{file.dylib_id}\n    to #{id}" if ARGV.debug?
    MachO::Tools.change_dylib_id(file, id, strict: false)
  rescue MachO::MachOError
    onoe <<-EOS.undent
      Failed changing dylib ID of #{file}
        from #{file.dylib_id}
          to #{id}
    EOS
    raise
  end

  def change_install_name(old, new, file)
    @require_relocation = true
    puts "Changing install name in #{file}\n  from #{old}\n    to #{new}" if ARGV.debug?
    MachO::Tools.change_install_name(file, old, new, strict: false)
  rescue MachO::MachOError
    onoe <<-EOS.undent
      Failed changing install name in #{file}
        from #{old}
          to #{new}
    EOS
    raise
  end

  def require_relocation?
    @require_relocation
  end
end

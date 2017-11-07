class Pathname
  # @private
  def elf?
    # See: https://en.wikipedia.org/wiki/Executable_and_Linkable_Format#File_header
    read(4) == "\x7fELF"
  end

  # @private
  def dynamic_elf?
    if which "readelf"
      popen_read("readelf", "-l", to_path).include?(" DYNAMIC ")
    elsif which "file"
      !popen_read("file", "-L", "-b", to_path)[/dynamic|shared/].nil?
    else
      raise StandardError, "Neither `readelf` nor `file` is available "\
        "to determine whether '#{self}' is dynamically or statically linked."
    end
  end
end

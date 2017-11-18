class Pathname
  if OS.mac?
    require "os/mac/mach"
    include MachOShim
  elsif OS.linux?
    require "os/linux/elf"
    include ELF
  end
end

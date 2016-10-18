class Pathname
  if OS.mac?
    require "os/mac/mach"
    include MachO
  elsif OS.linux?
    require "os/linux/elf"
    include ELF
  end
end

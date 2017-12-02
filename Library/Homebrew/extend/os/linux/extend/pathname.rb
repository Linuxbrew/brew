require "os/linux/elf"

class Pathname
  prepend ELFShim
end

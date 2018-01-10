require "os/mac/mach"

class Pathname
  prepend MachOShim
end

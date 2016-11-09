require "os/mac/mach"

class Pathname
  include MachOShim
end

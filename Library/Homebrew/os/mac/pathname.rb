require "os/mac/shared_mach"

class Pathname
  if OS.mac? && !ENV["HOMEBREW_NO_RUBY_MACHO"]
    require "os/mac/ruby_mach"
    include RubyMachO
  else
    require "os/mac/cctools_mach"
    include CctoolsMachO
  end

  include SharedMachO
end

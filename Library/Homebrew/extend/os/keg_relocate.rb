require "keg_relocate"

if OS.mac?
  require "extend/os/mac/keg_relocate"
elsif OS.linux?
  require "extend/os/linux/keg_relocate"
end

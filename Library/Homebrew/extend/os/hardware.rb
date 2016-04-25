if OS.mac?
  require "extend/os/mac/hardware/cpu"
elsif OS.linux?
  require "extend/os/linux/hardware/cpu"
end

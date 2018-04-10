if OS.mac?
  require "extend/os/mac/diagnostic"
elsif OS.linux?
  require "extend/os/linux/diagnostic"
end

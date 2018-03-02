require "dependency_collector"
if OS.mac?
  require "extend/os/mac/dependency_collector"
elsif OS.linux?
  require "extend/os/linux/dependency_collector"
end

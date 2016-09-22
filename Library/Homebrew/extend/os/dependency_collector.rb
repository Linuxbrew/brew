require "dependency_collector"

if OS.mac?
  require "extend/os/mac/dependency_collector"
end

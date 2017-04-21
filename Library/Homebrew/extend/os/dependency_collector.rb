require "dependency_collector"
require "extend/os/mac/dependency_collector" if OS.mac?
require "extend/os/linux/dependency_collector" if OS.linux?

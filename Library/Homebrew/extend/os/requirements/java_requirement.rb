require "requirements/java_requirement"

if OS.mac?
  require "extend/os/mac/requirements/java_requirement"
elsif OS.linux?
  require "extend/os/linux/requirements/java_requirement"
end

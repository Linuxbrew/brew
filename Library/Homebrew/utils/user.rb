require "delegate"
require "etc"

require "system_command"

class User < DelegateClass(String)
  def gui?
    out, _, status = system_command "who"
    return false unless status.success?
    out.lines
       .map(&:split)
       .any? { |user, type,| user == self && type == "console" }
  end

  def self.current
    @current ||= new(Etc.getpwuid(Process.euid).name)
  end
end

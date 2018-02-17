require "requirement"

class X11Requirement < Requirement
  alias old_message message

  def message
    old_message + <<~EOS
      To install it, run:
        brew install linuxbrew/xorg/xorg
    EOS
  end
end

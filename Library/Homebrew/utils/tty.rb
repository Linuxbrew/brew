module Tty
  module_function

  def strip_ansi(string)
    string.gsub(/\033\[\d+(;\d+)*m/, "")
  end

  def width
    @width ||= begin
      width = `/bin/stty size 2>/dev/null`.split[1]
      width = `/usr/bin/tput cols 2>/dev/null`.split[0] if width.to_i.zero?
      width ||= 80
      width.to_i
    end
  end

  def truncate(string)
    (w = width).zero? ? string.to_s : string.to_s[0, w - 4]
  end

  COLOR_CODES = {
    red: 31,
    green: 32,
    yellow: 33,
    blue: 34,
    magenta: 35,
    cyan: 36,
    default: 39,
  }.freeze

  STYLE_CODES = {
    reset: 0,
    bold: 1,
    italic: 3,
    underline: 4,
    strikethrough: 9,
    no_underline: 24,
  }.freeze

  CODES = COLOR_CODES.merge(STYLE_CODES).freeze

  def append_to_escape_sequence(code)
    @escape_sequence ||= []
    @escape_sequence << code
    self
  end

  def current_escape_sequence
    return "" if @escape_sequence.nil?

    "\033[#{@escape_sequence.join(";")}m"
  end

  def reset_escape_sequence!
    @escape_sequence = nil
  end

  CODES.each do |name, code|
    define_singleton_method(name) do
      append_to_escape_sequence(code)
    end
  end

  def to_s
    if !ENV["HOMEBREW_COLOR"] && (ENV["HOMEBREW_NO_COLOR"] || !$stdout.tty?)
      return ""
    end

    current_escape_sequence
  ensure
    reset_escape_sequence!
  end
end

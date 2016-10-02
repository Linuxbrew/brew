require "utils/tty"

module Formatter
  module_function

  def arrow(string, color: nil)
    prefix("==>", string, color)
  end

  def headline(string, color: nil)
    arrow("#{Tty.bold}#{string}#{Tty.reset}", color: color)
  end

  def identifier(string)
    "#{Tty.green}#{string}#{Tty.reset}"
  end

  def success(string, label: nil)
    label(label, string, :green)
  end

  def warning(string, label: nil)
    label(label, string, :yellow)
  end

  def error(string, label: nil)
    label(label, string, :red)
  end

  def url(string)
    "#{Tty.underline}#{string}#{Tty.no_underline}"
  end

  def label(label, string, color)
    label = "#{label}:" unless label.nil?
    prefix(label, string, color)
  end
  private_class_method :label

  def prefix(prefix, string, color)
    if prefix.nil? && color.nil?
      string
    elsif prefix.nil?
      "#{Tty.send(color)}#{string}#{Tty.reset}"
    elsif color.nil?
      "#{prefix} #{string}"
    else
      "#{Tty.send(color)}#{prefix}#{Tty.reset} #{string}"
    end
  end
  private_class_method :prefix
end

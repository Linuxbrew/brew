# Contains backports from newer versions of Ruby
require_relative "../vendor/backports/string"

class String
  # String.chomp, but if result is empty: returns nil instead.
  # Allows `chuzzle || foo` short-circuits.
  def chuzzle
    s = chomp
    s unless s.empty?
  end

  def strip_prefix(prefix)
    start_with?(prefix) ? self[prefix.length..-1] : self
  end
end

class NilClass
  def chuzzle; end
end

# used by the inreplace function (in utils.rb)
module StringInreplaceExtension
  attr_accessor :errors

  def self.extended(str)
    str.errors = []
  end

  def sub!(before, after)
    result = super
    unless result
      errors << "expected replacement of #{before.inspect} with #{after.inspect}"
    end
    result
  end

  # Warn if nothing was replaced
  def gsub!(before, after, audit_result = true)
    result = super(before, after)
    if audit_result && result.nil?
      errors << "expected replacement of #{before.inspect} with #{after.inspect}"
    end
    result
  end

  # Looks for Makefile style variable definitions and replaces the
  # value with "new_value", or removes the definition entirely.
  def change_make_var!(flag, new_value)
    return if gsub!(/^#{Regexp.escape(flag)}[ \t]*=[ \t]*(.*)$/, "#{flag}=#{new_value}", false)
    errors << "expected to change #{flag.inspect} to #{new_value.inspect}"
  end

  # Removes variable assignments completely.
  def remove_make_var!(flags)
    Array(flags).each do |flag|
      # Also remove trailing \n, if present.
      unless gsub!(/^#{Regexp.escape(flag)}[ \t]*=.*$\n?/, "", false)
        errors << "expected to remove #{flag.inspect}"
      end
    end
  end

  # Finds the specified variable
  def get_make_var(flag)
    self[/^#{Regexp.escape(flag)}[ \t]*=[ \t]*(.*)$/, 1]
  end
end

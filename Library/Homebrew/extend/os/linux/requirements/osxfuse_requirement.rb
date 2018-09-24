require "requirement"

class OsxfuseRequirement < Requirement
  download "https://github.com/libfuse/libfuse"

  satisfy(build_env: false) do
    next true if libfuse_formula_exists? && Formula["libfuse"].installed?

    includedirs = %w[
      /usr/include
      /usr/local/include
    ]
    next true if (includedirs.map do |dir|
      File.exist? "#{dir}/fuse.h"
    end).any?

    false
  end

  def message
    msg = "libfuse is required to install this formula.\n"
    if libfuse_formula_exists?
      msg + <<~EOS
        Run "brew install libfuse" to install it.
      EOS
    else
      msg + super
    end
  end

  private

  def libfuse_formula_exists?
    begin
      Formula["libfuse"]
    rescue FormulaUnavailableError
      return false
    end
    true
  end
end

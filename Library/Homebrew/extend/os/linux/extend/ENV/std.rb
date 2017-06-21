module Stdenv
  # needed by XorgRequirement
  def x11; end

  def libxml2
    append "CPPFLAGS", "-I#{Formula["libxml2"].include/"libxml2"}"
  rescue FormulaUnavailableError
    nil
  end
end

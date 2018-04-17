class CompilerSelector
  def gnu_gcc_versions
    v = Formulary.factory("gcc").version.to_s.slice(/\d/)
    GNU_GCC_VERSIONS - [v] + [v]
  rescue FormulaUnavailableError
    GNU_GCC_VERSIONS
  end
end

require "tap"

class Tap
  def core_formula_repository?
    odeprecated "Tap#core_formula_repository?", "Tap#core_tap?"
    core_tap?
  end
end

CoreFormulaRepository = CoreTap

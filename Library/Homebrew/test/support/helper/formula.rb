require "formulary"

module Test
  module Helper
    module Formula
      def formula(name = "formula_name", path: Formulary.core_path(name), spec: :stable, alias_path: nil, &block)
        Class.new(::Formula, &block).new(name, path, spec, alias_path: alias_path)
      end

      # Use a stubbed {Formulary::FormulaLoader} to make a given formula be found
      # when loading from {Formulary} with `ref`.
      def stub_formula_loader(formula, ref = formula.full_name)
        loader = double(get_formula: formula)
        allow(Formulary).to receive(:loader_for).with(ref, from: :keg).and_return(loader)
        allow(Formulary).to receive(:loader_for).with(ref, from: nil).and_return(loader)
      end
    end
  end
end

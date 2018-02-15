RSpec.describe Formula do
  describe "#runtime_dependencies" do
    it "includes non-declared direct dependencies" do
      formula = Class.new(Testball).new
      dependency = formula("dependency") { url "f-1.0" }

      formula.brew { formula.install }
      keg = Keg.for(formula.prefix)
      keg.link

      brewed_dylibs = { dependency.name => Set["some.dylib"] }
      linkage_checker = double("linkage checker", brewed_dylibs: brewed_dylibs)
      allow(LinkageChecker).to receive(:new).with(keg, any_args)
        .and_return(linkage_checker)

      expect(formula.runtime_dependencies).to include an_object_having_attributes(name: dependency.name)
    end
  end
end

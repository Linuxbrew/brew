require "requirements/language_module_requirement"

describe LanguageModuleRequirement do
  specify "unique dependencies are not equal" do
    x = described_class.new(:node, "less")
    y = described_class.new(:node, "coffee-script")
    expect(x).not_to eq(y)
    expect(x.hash).not_to eq(y.hash)
  end

  context "when module and import name differ" do
    subject { described_class.new(:python, mod_name, import_name) }
    let(:mod_name) { "foo" }
    let(:import_name) { "bar" }

    its(:message) { is_expected.to include(mod_name) }
    its(:the_test) { is_expected.to include("import #{import_name}") }
  end

  context "when the language is Perl" do
    it "does not satisfy invalid dependencies" do
      expect(described_class.new(:perl, "notapackage")).not_to be_satisfied
    end

    it "satisfies valid dependencies" do
      expect(described_class.new(:perl, "Env")).to be_satisfied
    end
  end

  context "when the language is Python", :needs_python do
    it "does not satisfy invalid dependencies" do
      expect(described_class.new(:python, "notapackage")).not_to be_satisfied
    end

    it "satisfies valid dependencies" do
      expect(described_class.new(:python, "datetime")).to be_satisfied
    end
  end

  context "when the language is Ruby" do
    it "does not satisfy invalid dependencies" do
      expect(described_class.new(:ruby, "notapackage")).not_to be_satisfied
    end

    it "satisfies valid dependencies" do
      expect(described_class.new(:ruby, "date")).to be_satisfied
    end
  end
end

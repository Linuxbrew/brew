require "description_cache_store"

describe DescriptionCacheStore do
  subject(:cache_store) { described_class.new(database) }

  let(:database) { double("database") }
  let(:formula_name) { "test_name" }
  let(:description) { "test_description" }

  describe "#update!" do
    it "sets the formula description" do
      expect(database).to receive(:set).with(formula_name, description)
      cache_store.update!(formula_name, description)
    end
  end

  describe "#delete!" do
    it "deletes the formula description" do
      expect(database).to receive(:delete).with(formula_name)
      cache_store.delete!(formula_name)
    end
  end

  describe "#update_from_report!" do
    let(:report) { double(select_formula: [], empty?: false) }

    it "reads from the report" do
      expect(database).to receive(:empty?).at_least(:once).and_return(false)
      cache_store.update_from_report!(report)
    end
  end

  describe "#update_from_formula_names!" do
    it "sets the formulae descriptions" do
      f = formula do
        url "url-1"
        desc "desc"
      end
      expect(Formulary).to receive(:factory).with(f.name).and_return(f)
      expect(database).to receive(:empty?).and_return(false)
      expect(database).to receive(:set).with(f.name, f.desc)
      cache_store.update_from_formula_names!([f.name])
    end
  end

  describe "#delete_from_formula_names!" do
    it "deletes the formulae descriptions" do
      expect(database).to receive(:empty?).and_return(false)
      expect(database).to receive(:delete).with(formula_name)
      cache_store.delete_from_formula_names!([formula_name])
    end
  end
end

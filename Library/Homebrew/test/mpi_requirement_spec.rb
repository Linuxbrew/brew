require "compat/requirements"

describe MPIRequirement, :needs_compat do
  describe "::new" do
    subject { described_class.new(wrappers + tags) }
    let(:wrappers) { [:cc, :cxx, :f77] }
    let(:tags) { [:optional, "some-other-tag"] }

    it "stores wrappers as tags" do
      expect(subject.tags).to eq(wrappers + tags)
    end
  end
end

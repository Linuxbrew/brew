require "requirements/mpi_requirement"

describe MPIRequirement do
  describe "::new" do
    subject { described_class.new(*(wrappers + tags)) }
    let(:wrappers) { [:cc, :cxx, :f77] }
    let(:tags) { [:optional, "some-other-tag"] }

    it "untangles wrappers and tags" do
      expect(subject.lang_list).to eq(wrappers)
      expect(subject.tags).to eq(tags)
    end
  end
end

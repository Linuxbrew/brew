describe Cask::CaskLoader::FromPathLoader do
  describe "#load" do
    context "when the file does not contain a cask" do
      let(:path) {
        (mktmpdir/"cask.rb").tap do |path|
          path.write <<~RUBY
            true
          RUBY
        end
      }

      it "raises an error" do
        expect {
          described_class.new(path).load
        }.to raise_error(Cask::CaskUnreadableError, /does not contain a cask/)
      end
    end

    context "when the file calls a non-existent method" do
      let(:path) {
        (mktmpdir/"cask.rb").tap do |path|
          path.write <<~RUBY
            this_method_does_not_exist
          RUBY
        end
      }

      it "raises an error" do
        expect {
          described_class.new(path).load
        }.to raise_error(Cask::CaskUnreadableError, /undefined local variable or method/)
      end
    end
  end
end

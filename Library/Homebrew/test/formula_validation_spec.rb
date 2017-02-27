require "formula"

describe Formula do
  describe "::new" do
    matcher :fail_with_invalid do |attr|
      match do |actual|
        expect {
          begin
            actual.call
          rescue => e
            expect(e.attr).to eq(attr)
            raise e
          end
        }.to raise_error(FormulaValidationError)
      end

      def supports_block_expectations?
        true
      end
    end

    it "cant override the `brew` method" do
      expect {
        formula do
          def brew; end
        end
      }.to raise_error(RuntimeError, /You cannot override Formula#brew/)
    end

    it "validates the `name`" do
      expect {
        formula "name with spaces" do
          url "foo"
          version "1.0"
        end
      }.to fail_with_invalid :name
    end

    it "validates the `url`" do
      expect {
        formula do
          url ""
          version "1"
        end
      }.to fail_with_invalid :url
    end

    it "validates the `version`" do
      expect {
        formula do
          url "foo"
          version "version with spaces"
        end
      }.to fail_with_invalid :version

      expect {
        formula do
          url "foo"
          version ""
        end
      }.to fail_with_invalid :version

      expect {
        formula do
          url "foo"
          version nil
        end
      }.to fail_with_invalid :version
    end

    specify "devel-only is valid" do
      f = formula do
        devel do
          url "foo"
          version "1.0"
        end
      end

      expect(f).to be_devel
    end

    specify "head-only is valid" do
      f = formula do
        head "foo"
      end

      expect(f).to be_head
    end

    it "fails when Formula is empty" do
      expect { formula {} }.to raise_error(FormulaSpecificationError)
    end
  end
end

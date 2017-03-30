require "formula"

describe Formula do
  describe "::new" do
    it "selects stable by default" do
      f = formula do
        url "foo-1.0"
        devel { url "foo-1.1a" }
        head "foo"
      end

      expect(f).to be_stable
    end

    it "selects stable when exclusive" do
      f = formula { url "foo-1.0" }
      expect(f).to be_stable
    end

    it "selects devel before HEAD" do
      f = formula do
        devel { url "foo-1.1a" }
        head "foo"
      end

      expect(f).to be_devel
    end

    it "selects devel when exclusive" do
      f = formula { devel { url "foo-1.1a" } }
      expect(f).to be_devel
    end

    it "selects HEAD when exclusive" do
      f = formula { head "foo" }
      expect(f).to be_head
    end

    it "does not select an incomplete spec" do
      f = formula do
        sha256 TEST_SHA256
        version "1.0"
        head "foo"
      end

      expect(f).to be_head
    end

    it "does not set an incomplete stable spec" do
      f = formula do
        sha256 TEST_SHA256
        devel { url "foo-1.1a" }
        head "foo"
      end

      expect(f.stable).to be nil
      expect(f).to be_devel
    end

    it "selects HEAD when requested" do
      f = formula("test", spec: :head) do
        url "foo-1.0"
        devel { url "foo-1.1a" }
        head "foo"
      end

      expect(f).to be_head
    end

    it "selects devel when requested" do
      f = formula("test", spec: :devel) do
        url "foo-1.0"
        devel { url "foo-1.1a" }
        head "foo"
      end

      expect(f).to be_devel
    end

    it "does not set an incomplete devel spec" do
      f = formula do
        url "foo-1.0"
        devel { version "1.1a" }
        head "foo"
      end

      expect(f.devel).to be nil
      expect(f).to be_stable
    end

    it "does not raise an error for a missing spec" do
      f = formula("test", spec: :devel) do
        url "foo-1.0"
        head "foo"
      end

      expect(f).to be_stable
    end
  end
end

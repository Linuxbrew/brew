require "linkage_cache_store"

describe LinkageCacheStore do
  let(:keg_name) { "keg_name" }
  let(:database) { double("database") }

  subject { LinkageCacheStore.new(keg_name, database) }

  describe "#keg_exists?" do
    context "`keg_name` exists in cache" do
      before(:each) do
        expect(database).to receive(:get).with(keg_name).and_return("")
      end

      it "returns `true`" do
        expect(subject.keg_exists?).to be(true)
      end
    end

    context "`keg_name` does not exist in cache" do
      before(:each) do
        expect(database).to receive(:get).with(keg_name).and_return(nil)
      end

      it "returns `false`" do
        expect(subject.keg_exists?).to be(false)
      end
    end
  end

  describe "#update!" do
    context "a `value` is a `Hash`" do
      it "sets the cache for the `keg_name`" do
        expect(database).to receive(:set).with(keg_name, anything)
        subject.update!(a_value: { key: ["value"] })
      end
    end

    context "a `value` is an `Array`" do
      it "sets the cache for the `keg_name`" do
        expect(database).to receive(:set).with(keg_name, anything)
        subject.update!(a_value: ["value"])
      end
    end

    context "a `value` is not an `Array` or `Hash`" do
      it "raises a `TypeError` if a `value` is not an `Array` or `Hash`" do
        expect { subject.update!(key: 1) }.to raise_error(TypeError)
      end
    end
  end

  describe "#flush_cache!" do
    it "calls `delete` on the `database` with `keg_name` as parameter" do
      expect(database).to receive(:delete).with(keg_name)
      subject.flush_cache!
    end
  end

  describe "#fetch_type" do
    context "`HASH_LINKAGE_TYPES.include?(type)`" do
      before(:each) do
        expect(database).to receive(:get).with(keg_name).and_return(nil)
      end

      it "returns a `Hash` of values" do
        expect(subject.fetch_type(:brewed_dylibs)).to be_an_instance_of(Hash)
      end
    end

    context "`ARRAY_LINKAGE_TYPES.include?(type)`" do
      before(:each) do
        expect(database).to receive(:get).with(keg_name).and_return(nil)
      end

      it "returns an `Array` of values" do
        expect(subject.fetch_type(:system_dylibs)).to be_an_instance_of(Array)
      end
    end

    context "`type` not in `HASH_LINKAGE_TYPES` or `ARRAY_LINKAGE_TYPES`" do
      it "raises a `TypeError` if the `type` is not supported" do
        expect { subject.fetch_type(:bad_type) }.to raise_error(TypeError)
      end
    end
  end
end

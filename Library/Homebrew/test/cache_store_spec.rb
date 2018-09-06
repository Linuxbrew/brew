require "cache_store"

describe CacheStoreDatabase do
  subject { CacheStoreDatabase.new(:sample) }

  describe "self.use" do
    let(:type) { :test }

    it "creates a new `DatabaseCache` instance" do
      cache_store = double("cache_store", close_if_open!: nil)
      expect(CacheStoreDatabase).to receive(:new).with(type).and_return(cache_store)
      expect(cache_store).to receive(:close_if_open!)
      CacheStoreDatabase.use(type) { |_db| }
    end
  end

  describe "#set" do
    let(:db) { double("db", :[]= => nil) }

    before(:each) do
      allow(File).to receive(:write)
      allow(subject).to receive(:created?).and_return(true)
      expect(db).to receive(:has_key?).with(:foo).and_return(false)
      allow(subject).to receive(:db).and_return(db)
    end

    it "sets the value in the `CacheStoreDatabase`" do
      expect(db).to_not have_key(:foo)
      subject.set(:foo, "bar")
    end
  end

  describe "#get" do
    context "database created" do
      let(:db) { double("db", :[] => "bar") }

      before(:each) do
        allow(subject).to receive(:created?).and_return(true)
        expect(db).to receive(:has_key?).with(:foo).and_return(true)
        allow(subject).to receive(:db).and_return(db)
      end

      it "gets value in the `CacheStoreDatabase` corresponding to the key" do
        expect(db).to have_key(:foo)
        expect(subject.get(:foo)).to eq("bar")
      end
    end

    context "database not created" do
      let(:db) { double("db", :[] => nil) }

      before(:each) do
        allow(subject).to receive(:created?).and_return(false)
        allow(subject).to receive(:db).and_return(db)
      end

      it "does not get value in the `CacheStoreDatabase` corresponding to key" do
        expect(subject.get(:foo)).to_not be("bar")
      end

      it "does not call `db[]` if `CacheStoreDatabase.created?` is `false`" do
        expect(db).not_to receive(:[])
        subject.get(:foo)
      end
    end
  end

  describe "#delete" do
    context "database created" do
      let(:db) { double("db", :[] => { foo: "bar" }) }

      before(:each) do
        allow(subject).to receive(:created?).and_return(true)
        allow(subject).to receive(:db).and_return(db)
      end

      it "deletes value in the `CacheStoreDatabase` corresponding to the key" do
        expect(db).to receive(:delete).with(:foo)
        subject.delete(:foo)
      end
    end

    context "database not created" do
      let(:db) { double("db", delete: nil) }

      before(:each) do
        allow(subject).to receive(:created?).and_return(false)
        allow(subject).to receive(:db).and_return(db)
      end

      it "does not call `db.delete` if `CacheStoreDatabase.created?` is `false`" do
        expect(db).not_to receive(:delete)
        subject.delete(:foo)
      end
    end
  end

  describe "#close_if_open!" do
    context "database open" do
      before(:each) do
        subject.instance_variable_set(:@db, instance_double(DBM, close: nil))
      end

      it "does not raise an error when `close` is called on the database" do
        expect { subject.close_if_open! }.to_not raise_error(NoMethodError)
      end
    end

    context "database not open" do
      before(:each) do
        subject.instance_variable_set(:@db, nil)
      end

      it "does not raise an error when `close` is called on the database" do
        expect { subject.close_if_open! }.to_not raise_error(NoMethodError)
      end
    end
  end

  describe "#created?" do
    let(:cache_path) { "path/to/homebrew/cache/sample.db" }

    before(:each) do
      allow(subject).to receive(:cache_path).and_return(cache_path)
    end

    context "`File.exist?(cache_path)` returns `true`" do
      before(:each) do
        allow(File).to receive(:exist?).with(cache_path).and_return(true)
      end

      it "returns `true`" do
        expect(subject.created?).to be(true)
      end
    end

    context "`File.exist?(cache_path)` returns `false`" do
      before(:each) do
        allow(File).to receive(:exist?).with(cache_path).and_return(false)
      end

      it "returns `false`" do
        expect(subject.created?).to be(false)
      end
    end
  end
end

require "formula"
require "caveats"

describe Caveats do
  subject { described_class.new(f) }
  let(:f) { formula { url "foo-1.0" } }

  specify "#f" do
    expect(subject.f).to eq(f)
  end

  describe "#empty?" do
    it "returns true if the Formula has no caveats" do
      expect(subject).to be_empty
    end

    it "returns false if the Formula has caveats" do
      f = formula do
        url "foo-1.0"

        def caveats
          "something"
        end
      end

      expect(described_class.new(f)).not_to be_empty
    end
  end

  describe "#caveats" do
    context "when f.plist is not nil" do
      it "prints plist startup information when f.plist_startup is not nil" do
        f = formula do
          url "foo-1.0"
          def plist
            "plist_test.plist"
          end
          plist_options startup: true
        end
        expect(described_class.new(f).caveats).to include("startup:\n  sudo brew")
      end

      it "prints plist login information when f.plist_startup is nil" do
        f = formula do
          url "foo-1.0"
          def plist
            "plist_test.plist"
          end
        end
        expect(described_class.new(f).caveats).to include("login:\n  brew")
      end
    end

    context "when f.keg_only is not nil" do
      it "tells formula is keg_only and gives information about command to be run when f.bin and f.sbin are directories" do
        Path = Pathname.new("path")
        f = formula do
          url "foo-1.0"
          keg_only "some reason"
        end

        allow(f).to receive(:bin).and_return(Path)
        allow(f.bin).to receive(:directory?).and_return(true)

        allow(f).to receive(:sbin).and_return(Path)
        allow(f.sbin).to receive(:directory?).and_return(true)

        caveats = described_class.new(f).caveats

        expect(caveats).to include("keg-only")
        expect(caveats).to include(f.opt_bin.to_s)
        expect(caveats).to include(f.opt_sbin.to_s)
      end
    end
  end
end

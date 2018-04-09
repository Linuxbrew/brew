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
    context "when f.plist is not nil", :needs_macos do
      it "prints plist startup information when f.plist_startup is not nil" do
        f = formula do
          url "foo-1.0"
          def plist
            "plist_test.plist"
          end
          plist_options startup: true
        end
        expect(described_class.new(f).caveats).to include("startup")
      end

      it "prints plist login information when f.plist_startup is nil" do
        f = formula do
          url "foo-1.0"
          def plist
            "plist_test.plist"
          end
        end
        expect(described_class.new(f).caveats).to include("login")
      end

      it "gives information about restarting services after upgrade" do
        f = formula do
          url "foo-1.0"
          def plist
            "plist_test.plist"
          end
          plist_options startup: true
        end
        f_obj = described_class.new(f)
        plist_path = mktmpdir/"plist"
        FileUtils.touch plist_path
        allow(f_obj).to receive(:plist_path).and_return(plist_path)
        allow(plist_path).to receive(:symlink?).and_return(true)
        expect(f_obj.caveats).to include("restart #{f.full_name}")
        expect(f_obj.caveats).to include("sudo")
      end

      context "when plist_path is not a file nor symlinked and plist_startup is false" do
        let(:f) {
          formula do
            url "foo-1.0"
            def plist
              "plist_test.plist"
            end
          end
        }
        let(:f_obj) { described_class.new(f) }
        let(:caveats) { f_obj.caveats }
        let(:plist_path) { mktmpdir/"plist" }

        before do
          FileUtils.touch plist_path
          allow(f_obj).to receive(:plist_path).and_return(plist_path)
          allow(plist_path).to receive(:symlink?).and_return(true)
        end

        it "tells command to run after upgrade" do
          allow(Kernel).to receive(:system).with(any_args).and_return(true)
          expect(caveats).to include("restart #{f.full_name} after an upgrade")
        end

        it "tells command to run to start formula" do
          expect(caveats).to include("To start #{f.full_name}:")
        end
      end

      it "gives information about plist_manual" do
        f = formula do
          url "foo-1.0"
          def plist
            "plist_test.plist"
          end
          plist_options manual: "foo"
        end
        caveats = described_class.new(f).caveats

        expect(caveats).to include("background service")
        expect(caveats).to include(f.plist_manual)
      end

      it "warns about brew failing under tmux" do
        f = formula do
          url "foo-1.0"
          def plist
            "plist_test.plist"
          end
        end
        allow(ENV).to receive(:[]).with("TMUX").and_return(true)
        allow(Homebrew).to receive(:_system).with("/usr/bin/pbpaste").and_return(false)
        caveats = described_class.new(f).caveats

        expect(caveats).to include("WARNING:")
        expect(caveats).to include("tmux")
      end
    end

    context "when f.keg_only is not nil" do
      let(:f) {
        formula do
          url "foo-1.0"
          keg_only "some reason"
        end
      }
      let(:caveats) { described_class.new(f).caveats }

      it "tells formula is keg_only" do
        expect(caveats).to include("keg-only")
      end

      it "gives command to be run when f.bin is a directory" do
        Pathname.new(f.bin).mkpath
        expect(caveats).to include(f.opt_bin.to_s)
      end

      it "gives command to be run when f.sbin is a directory" do
        Pathname.new(f.sbin).mkpath
        expect(caveats).to include(f.opt_sbin.to_s)
      end

      context "when f.lib or f.include is a directory" do
        it "gives command to be run when f.lib is a directory" do
          Pathname.new(f.lib).mkpath
          expect(caveats).to include("-L#{f.opt_lib}")
        end

        it "gives command to be run when f.include is a directory" do
          Pathname.new(f.include).mkpath
          expect(caveats).to include("-I#{f.opt_include}")
        end

        it "gives PKG_CONFIG_PATH when f.lib/'pkgconfig' and f.share/'pkgconfig' are directories" do
          allow_any_instance_of(Object).to receive(:which).with(any_args).and_return(Pathname.new("blah"))

          Pathname.new(f.share/"pkgconfig").mkpath
          Pathname.new(f.lib/"pkgconfig").mkpath

          expect(caveats).to include("#{f.opt_lib}/pkgconfig")
          expect(caveats).to include("#{f.opt_share}/pkgconfig")
        end
      end
    end

    context "shell completions" do
      let(:f) {
        formula do
          url "foo-1.0"
        end
      }
      let(:caveats) { described_class.new(f).caveats }
      let(:path) { f.prefix.resolved_path }

      before do
        allow_any_instance_of(Pathname).to receive(:children).and_return([Pathname.new("child")])
        allow_any_instance_of(Object).to receive(:which).with(any_args).and_return(Pathname.new("shell"))
      end

      it "gives dir where bash completions have been installed" do
        (path/"etc/bash_completion.d").mkpath
        expect(caveats).to include(HOMEBREW_PREFIX/"etc/bash_completion.d")
      end

      it "gives dir where zsh completions have been installed" do
        (path/"share/zsh/site-functions").mkpath
        expect(caveats).to include(HOMEBREW_PREFIX/"share/zsh/site-functions")
      end

      it "gives dir where fish completions have been installed" do
        (path/"share/fish/vendor_completions.d").mkpath
        expect(caveats).to include(HOMEBREW_PREFIX/"share/fish/vendor_completions.d")
      end
    end
  end
end

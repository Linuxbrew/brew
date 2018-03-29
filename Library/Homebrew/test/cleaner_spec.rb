require "cleaner"
require "formula"

describe Cleaner do
  include FileUtils

  subject { described_class.new(f) }

  let(:f) { formula("cleaner_test") { url "foo-1.0" } }

  before do
    f.prefix.mkpath
  end

  describe "#clean" do
    it "cleans files" do
      f.bin.mkpath
      f.lib.mkpath

      if OS.mac?
        cp "#{TEST_FIXTURE_DIR}/mach/a.out", f.bin
        cp Dir["#{TEST_FIXTURE_DIR}/mach/*.dylib"], f.lib
      elsif OS.linux?
        cp "#{TEST_FIXTURE_DIR}/elf/hello", f.bin
        cp Dir["#{TEST_FIXTURE_DIR}/elf/libhello.so.0"], f.lib
      end

      subject.clean

      if OS.mac?
        expect((f.bin/"a.out").stat.mode).to eq(0100555)
        expect((f.lib/"fat.dylib").stat.mode).to eq(0100444)
        expect((f.lib/"x86_64.dylib").stat.mode).to eq(0100444)
        expect((f.lib/"i386.dylib").stat.mode).to eq(0100444)
      elsif OS.linux?
        expect((f.bin/"hello").stat.mode).to eq(0100555)
        expect((f.lib/"libhello.so.0").stat.mode).to eq(0100555)
      end
    end

    it "prunes the prefix if it is empty" do
      subject.clean
      expect(f.prefix).not_to be_a_directory
    end

    it "prunes empty directories" do
      subdir = f.bin/"subdir"
      subdir.mkpath

      subject.clean

      expect(f.bin).not_to be_a_directory
      expect(subdir).not_to be_a_directory
    end

    it "removes a symlink when its target was pruned before" do
      dir = f.prefix/"b"
      symlink = f.prefix/"a"

      dir.mkpath
      ln_s dir.basename, symlink

      subject.clean

      expect(dir).not_to exist
      expect(symlink).not_to be_a_symlink
      expect(symlink).not_to exist
    end

    it "removes symlinks pointing to an empty directory" do
      dir = f.prefix/"b"
      symlink = f.prefix/"c"

      dir.mkpath
      ln_s dir.basename, symlink

      subject.clean

      expect(dir).not_to exist
      expect(symlink).not_to be_a_symlink
      expect(symlink).not_to exist
    end

    it "removes broken symlinks" do
      symlink = f.prefix/"symlink"
      ln_s "target", symlink

      subject.clean

      expect(symlink).not_to be_a_symlink
    end

    it "removes '.la' files" do
      file = f.lib/"foo.la"

      f.lib.mkpath
      touch file

      subject.clean

      expect(file).not_to exist
    end

    it "removes 'perllocal' files" do
      file = f.lib/"perl5/darwin-thread-multi-2level/perllocal.pod"

      (f.lib/"perl5/darwin-thread-multi-2level").mkpath
      touch file

      subject.clean

      expect(file).not_to exist
    end

    it "removes '.packlist' files" do
      file = f.lib/"perl5/darwin-thread-multi-2level/auto/test/.packlist"

      (f.lib/"perl5/darwin-thread-multi-2level/auto/test").mkpath
      touch file

      subject.clean

      expect(file).not_to exist
    end

    it "removes 'charset.alias' files" do
      file = f.lib/"charset.alias"

      f.lib.mkpath
      touch file

      subject.clean

      expect(file).not_to exist
    end
  end

  describe "::skip_clean" do
    it "adds paths that should be skipped" do
      f.class.skip_clean "bin"
      f.bin.mkpath

      subject.clean

      expect(f.bin).to be_a_directory
    end

    it "also skips empty sub-directories under the added paths" do
      f.class.skip_clean "bin"
      subdir = f.bin/"subdir"
      subdir.mkpath

      subject.clean

      expect(f.bin).to be_a_directory
      expect(subdir).to be_a_directory
    end

    it "allows skipping broken symlinks" do
      f.class.skip_clean "symlink"
      symlink = f.prefix/"symlink"
      ln_s "target", symlink

      subject.clean

      expect(symlink).to be_a_symlink
    end

    it "allows skipping symlinks pointing to an empty directory" do
      f.class.skip_clean "c"
      dir = f.prefix/"b"
      symlink = f.prefix/"c"

      dir.mkpath
      ln_s dir.basename, symlink

      subject.clean

      expect(dir).not_to exist
      expect(symlink).to be_a_symlink
      expect(symlink).not_to exist
    end

    it "allows skipping symlinks whose target was pruned before" do
      f.class.skip_clean "a"
      dir = f.prefix/"b"
      symlink = f.prefix/"a"

      dir.mkpath
      ln_s dir.basename, symlink

      subject.clean

      expect(dir).not_to exist
      expect(symlink).to be_a_symlink
      expect(symlink).not_to exist
    end

    it "allows skipping '.la' files" do
      file = f.lib/"foo.la"

      f.class.skip_clean :la
      f.lib.mkpath
      touch file

      subject.clean

      expect(file).to exist
    end

    it "allows skipping sub-directories" do
      dir = f.lib/"subdir"
      f.class.skip_clean "lib/subdir"

      dir.mkpath

      subject.clean

      expect(dir).to be_a_directory
    end

    it "allows skipping paths relative to prefix" do
      dir1 = f.bin/"a"
      dir2 = f.lib/"bin/a"

      f.class.skip_clean "bin/a"
      dir1.mkpath
      dir2.mkpath

      subject.clean

      expect(dir1).to exist
      expect(dir2).not_to exist
    end
  end
end

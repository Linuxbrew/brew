require "keg"

describe Keg do
  include FileUtils

  subject { described_class.new(keg_path) }

  let(:keg_path) { HOMEBREW_CELLAR/"a/1.0" }
  let(:file) { keg_path/"lib/i386.dylib" }

  before(:each) do
    (keg_path/"lib").mkpath
    cp dylib_path("i386"), file
    subject.link
  end

  after(:each) { subject.unlink }

  describe "#change_dylib_id" do
    it "does nothing if given id is same as file's dylib id" do
      id = file.dylib_id
      file.change_dylib_id(id)
      expect(file.dylib_id).to eq(id)
    end
  end

  describe "#change_install_name" do
    it "does nothing if given name is same as file's install name" do
      file.ensure_writable do
        subject.each_install_name_for(file) do |name|
          file.change_install_name(name, name)
          expect(name).to eq(name)
        end
      end
    end

    it "does nothing when install name start with '/'" do
      file.ensure_writable do
        subject.each_install_name_for(file) do |name|
          new_name = subject.fixed_name(file, name)
          file.change_install_name(name, new_name)
          expect(name).not_to eq(new_name)
        end
      end
    end
  end

  describe "#require_relocation?" do
    it "is set to false at initialization" do
      expect(subject.require_relocation?).to be false
    end

    it "is set to true after linkage is fixed" do
      subject.fix_dynamic_linkage
      expect(subject.require_relocation?).to be true
    end
  end
end

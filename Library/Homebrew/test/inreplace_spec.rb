require "extend/string"
require "tempfile"
require "utils/inreplace"

describe StringInreplaceExtension do
  subject { string.extend(described_class) }

  describe "#change_make_var!" do
    context "flag" do
      context "with spaces" do
        let(:string) do
          <<~EOS
            OTHER=def
            FLAG = abc
            FLAG2=abc
          EOS
        end

        it "is successfully replaced" do
          subject.change_make_var! "FLAG", "def"
          expect(subject).to eq <<~EOS
            OTHER=def
            FLAG=def
            FLAG2=abc
          EOS
        end

        it "is successfully appended" do
          subject.change_make_var! "FLAG", "\\1 def"
          expect(subject).to eq <<~EOS
            OTHER=def
            FLAG=abc def
            FLAG2=abc
          EOS
        end
      end

      context "with tabs" do
        let(:string) do
          <<~EOS
            CFLAGS\t=\t-Wall -O2
            LDFLAGS\t=\t-lcrypto -lssl
          EOS
        end

        it "is successfully replaced" do
          subject.change_make_var! "CFLAGS", "-O3"
          expect(subject).to eq <<~EOS
            CFLAGS=-O3
            LDFLAGS\t=\t-lcrypto -lssl
          EOS
        end
      end
    end

    context "empty flag between other flags" do
      let(:string) do
        <<~EOS
          OTHER=def
          FLAG =
          FLAG2=abc
        EOS
      end

      it "is successfully replaced" do
        subject.change_make_var! "FLAG", "def"
        expect(subject).to eq <<~EOS
          OTHER=def
          FLAG=def
          FLAG2=abc
        EOS
      end
    end

    context "empty flag" do
      let(:string) do
        <<~EOS
          FLAG =
          mv file_a file_b
        EOS
      end

      it "is successfully replaced" do
        subject.change_make_var! "FLAG", "def"
        expect(subject).to eq <<~EOS
          FLAG=def
          mv file_a file_b
        EOS
      end
    end

    context "shell-style variable" do
      let(:string) do
        <<~EOS
          OTHER=def
          FLAG=abc
          FLAG2=abc
        EOS
      end

      it "is successfully replaced" do
        subject.change_make_var! "FLAG", "def"
        expect(subject).to eq <<~EOS
          OTHER=def
          FLAG=def
          FLAG2=abc
        EOS
      end
    end
  end

  describe "#remove_make_var!" do
    context "flag" do
      context "with spaces" do
        let(:string) do
          <<~EOS
            OTHER=def
            FLAG = abc
            FLAG2 = def
          EOS
        end

        it "is successfully removed" do
          subject.remove_make_var! "FLAG"
          expect(subject).to eq <<~EOS
            OTHER=def
            FLAG2 = def
          EOS
        end
      end

      context "with tabs" do
        let(:string) do
          <<~EOS
            CFLAGS\t=\t-Wall -O2
            LDFLAGS\t=\t-lcrypto -lssl
          EOS
        end

        it "is successfully removed" do
          subject.remove_make_var! "LDFLAGS"
          expect(subject).to eq <<~EOS
            CFLAGS\t=\t-Wall -O2
          EOS
        end
      end
    end

    context "multiple flags" do
      let(:string) do
        <<~EOS
          OTHER=def
          FLAG = abc
          FLAG2 = def
          OTHER2=def
        EOS
      end

      specify "are be successfully removed" do
        subject.remove_make_var! ["FLAG", "FLAG2"]
        expect(subject).to eq <<~EOS
          OTHER=def
          OTHER2=def
        EOS
      end
    end
  end

  describe "#get_make_var" do
    context "with spaces" do
      let(:string) do
        <<~EOS
          CFLAGS = -Wall -O2
          LDFLAGS = -lcrypto -lssl
        EOS
      end

      it "extracts the value for a given variable" do
        expect(subject.get_make_var("CFLAGS")).to eq("-Wall -O2")
      end
    end

    context "with tabs" do
      let(:string) do
        <<~EOS
          CFLAGS\t=\t-Wall -O2
          LDFLAGS\t=\t-lcrypto -lssl
        EOS
      end

      it "extracts the value for a given variable" do
        expect(subject.get_make_var("CFLAGS")).to eq("-Wall -O2")
      end
    end
  end

  describe "#sub!" do
    let(:string) { "foo" }

    it "replaces the first occurence" do
      subject.sub!("o", "e")
      expect(subject).to eq("feo")
    end
  end

  describe "#gsub!" do
    let(:string) { "foo" }

    it "replaces the all occurences" do
      subject.gsub!("o", "e") # rubocop:disable Performance/StringReplacement
      expect(subject).to eq("fee")
    end
  end
end

describe Utils::Inreplace do
  let(:file) { Tempfile.new("test") }

  before do
    file.write <<~EOS
      a
      b
      c
    EOS
  end

  after { file.unlink }

  it "raises error if there is nothing to replace" do
    expect {
      described_class.inreplace file.path, "d", "f"
    }.to raise_error(Utils::InreplaceError)
  end

  it "raises error if there is nothing to replace" do
    expect {
      described_class.inreplace(file.path) do |s|
        s.gsub!("d", "f") # rubocop:disable Performance/StringReplacement
      end
    }.to raise_error(Utils::InreplaceError)
  end

  it "raises error if there is nothing to replace" do
    expect {
      described_class.inreplace(file.path) do |s|
        s.change_make_var! "VAR", "value"
        s.remove_make_var! "VAR2"
      end
    }.to raise_error(Utils::InreplaceError)
  end
end

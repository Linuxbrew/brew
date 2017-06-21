require "extend/string"

describe String do
  describe "#undent" do
    it "removes leading whitespace, taking the first line as reference" do
      string = <<-EOS.unindent
                hi
                ........my friend over
                  there
      EOS

      expect(string).to eq("hi\n........my friend over\n  there\n")
    end

    it "removes nothing if the text is not indented" do
      string = <<-EOS.unindent
        hi
        I'm not indented
      EOS

      expect(string).to eq("hi\nI'm not indented\n")
    end

    it "can be nested" do
      nested_string = <<-EOS.undent
        goodbye
      EOS

      string = <<-EOS.undent
        hello
        #{nested_string}
      EOS

      expect(string).to eq("hello\ngoodbye\n\n")
    end
  end
end

describe StringInreplaceExtension do
  subject { string.extend(described_class) }
  let(:string) { "foobar" }

  describe "#sub!" do
    it "adds an error to #errors when no replacement was made" do
      subject.sub! "not here", "test"
      expect(subject.errors).to eq(['expected replacement of "not here" with "test"'])
    end
  end
end

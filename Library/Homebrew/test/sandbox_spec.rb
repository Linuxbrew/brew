require "sandbox"

RSpec::Matchers.define_negated_matcher :not_matching, :matching

describe Sandbox do
  let(:dir) { @dir = Pathname.new(Dir.mktmpdir) }
  let(:file) { dir/"foo" }

  before(:each) do
    skip "Sandbox not implemented." unless described_class.available?
  end

  after(:each) do
    dir.rmtree unless @dir.nil?
  end

  specify "#formula?" do
    f = formula { url "foo-1.0" }
    f2 = formula { url "bar-1.0" }
    allow(f2).to receive(:tap).and_return(Tap.fetch("test/tap"))

    ENV["HOMEBREW_SANDBOX"] = "1"
    expect(described_class).to be_formula(f), "Formulae should be sandboxed if --sandbox was passed."

    ENV.delete("HOMEBREW_SANDBOX")
    expect(described_class).to be_formula(f), "Formulae should be sandboxed if in a sandboxed tap."
    expect(described_class).not_to be_formula(f2), "Formulae should not be sandboxed if not in a sandboxed tap."
  end

  specify "#test?" do
    ENV.delete("HOMEBREW_NO_SANDBOX")
    expect(described_class).to be_test, "Tests should be sandboxed unless --no-sandbox was passed."
  end

  specify "#allow_write" do
    subject.allow_write file
    subject.exec "touch", file

    expect(file).to exist
  end

  describe "#exec" do
    it "fails when writing to file not specified with ##allow_write" do
      shutup do
        expect {
          subject.exec "touch", file
        }.to raise_error(ErrorDuringExecution)
      end

      expect(file).not_to exist
    end

    it "complains on failure" do
      ENV["HOMEBREW_VERBOSE"] = "1"

      expect(Utils).to receive(:popen_read).and_return("foo")

      expect { subject.exec "false" }
        .to raise_error(ErrorDuringExecution)
        .and output(/foo/).to_stdout
    end

    it "ignores bogus Python error" do
      ENV["HOMEBREW_VERBOSE"] = "1"

      with_bogus_error = <<-EOS.undent
        foo
        Mar 17 02:55:06 sandboxd[342]: Python(49765) deny file-write-unlink /System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/distutils/errors.pyc
        bar
      EOS
      expect(Utils).to receive(:popen_read).and_return(with_bogus_error)

      expect { subject.exec "false" }
        .to raise_error(ErrorDuringExecution)
        .and output(a_string_matching(/foo/).and(matching(/bar/).and(not_matching(/Python/)))).to_stdout
    end
  end
end

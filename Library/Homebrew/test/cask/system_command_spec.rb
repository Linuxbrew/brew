describe Hbc::SystemCommand, :cask do
  describe "#initialize" do
    let(:env_args) { ["bash", "-c", 'printf "%s" "${A?}" "${B?}" "${C?}"'] }

    describe "given some environment variables" do
      subject {
        described_class.new(
          "env",
          args: env_args,
          env: { "A" => "1", "B" => "2", "C" => "3" },
          must_succeed: true,
        )
      }

      its("run!.stdout") { is_expected.to eq("123") }

      describe "the resulting command line" do
        it "does not include the given variables" do
          expect(Open3)
            .to receive(:popen3)
            .with(a_hash_including("PATH"), ["env"] * 2, *env_args, {})
            .and_call_original

          subject.run!
        end
      end
    end

    describe "given some environment variables and sudo: true" do
      subject {
        described_class.new(
          "env",
          args: env_args,
          env: { "A" => "1", "B" => "2", "C" => "3" },
          must_succeed: true,
          sudo: true,
        )
      }

      describe "the resulting command line" do
        it "includes the given variables explicitly" do
          expect(Open3)
            .to receive(:popen3)
            .with(an_instance_of(Hash), ["/usr/bin/sudo"] * 2,
                "-E", a_string_starting_with("PATH="),
                "A=1", "B=2", "C=3", "--", "env", *env_args, {})
            .and_wrap_original do |original_popen3, *_, &block|
              original_popen3.call("/usr/bin/true", &block)
            end

          subject.run!
        end
      end
    end
  end

  describe "when the exit code is 0" do
    describe "its result" do
      subject { described_class.run("/usr/bin/true") }

      it { is_expected.to be_a_success }
      its(:exit_status) { is_expected.to eq(0) }
    end
  end

  describe "when the exit code is 1" do
    let(:command) { "/usr/bin/false" }

    describe "and the command must succeed" do
      it "throws an error" do
        expect {
          described_class.run!(command)
        }.to raise_error(Hbc::CaskCommandFailedError)
      end
    end

    describe "and the command does not have to succeed" do
      describe "its result" do
        subject { described_class.run(command) }

        it { is_expected.not_to be_a_success }
        its(:exit_status) { is_expected.to eq(1) }
      end
    end
  end

  describe "given a pathname" do
    let(:command) { "/bin/ls" }
    let(:path)    { Pathname(Dir.mktmpdir) }

    before do
      FileUtils.touch(path.join("somefile"))
    end

    describe "its result" do
      subject { described_class.run(command, args: [path]) }

      it { is_expected.to be_a_success }
      its(:stdout) { is_expected.to eq("somefile\n") }
    end
  end

  describe "with both STDOUT and STDERR output from upstream" do
    let(:command) { "/bin/bash" }
    let(:options) {
      { args: [
        "-c",
        "for i in $(seq 1 2 5); do echo $i; echo $(($i + 1)) >&2; done",
      ] }
    }

    shared_examples "it returns '1 2 3 4 5 6'" do
      describe "its result" do
        subject { described_class.run(command, options) }

        it { is_expected.to be_a_success }
        its(:stdout) { is_expected.to eq([1, 3, 5, nil].join("\n")) }
        its(:stderr) { is_expected.to eq([2, 4, 6, nil].join("\n")) }
      end
    end

    describe "with default options" do
      it "echoes only STDERR" do
        expected = [2, 4, 6].map { |i| "#{i}\n" }.join
        expect {
          described_class.run(command, options)
        }.to output(expected).to_stderr
      end

      include_examples("it returns '1 2 3 4 5 6'")
    end

    describe "with print_stdout" do
      before do
        options.merge!(print_stdout: true)
      end

      it "echoes both STDOUT and STDERR" do
        expect { described_class.run(command, options) }
          .to output("1\n3\n5\n").to_stdout
          .and output("2\n4\n6\n").to_stderr
      end

      include_examples("it returns '1 2 3 4 5 6'")
    end

    describe "without print_stderr" do
      before do
        options.merge!(print_stderr: false)
      end

      it "echoes nothing" do
        expect {
          described_class.run(command, options)
        }.to output("").to_stdout
      end

      include_examples("it returns '1 2 3 4 5 6'")
    end

    describe "with print_stdout but without print_stderr" do
      before do
        options.merge!(print_stdout: true, print_stderr: false)
      end

      it "echoes only STDOUT" do
        expected = [1, 3, 5].map { |i| "#{i}\n" }.join
        expect {
          described_class.run(command, options)
        }.to output(expected).to_stdout
      end

      include_examples("it returns '1 2 3 4 5 6'")
    end
  end

  describe "with a very long STDERR output" do
    let(:command) { "/bin/bash" }
    let(:options) {
      { args: [
        "-c",
        "for i in $(seq 1 2 100000); do echo $i; echo $(($i + 1)) >&2; done",
      ] }
    }

    it "returns without deadlocking" do
      wait(15).for {
        described_class.run(command, options)
      }.to be_a_success
    end
  end

  describe "given an invalid variable name" do
    it "raises an ArgumentError" do
      expect { described_class.run("true", env: { "1ABC" => true }) }
        .to raise_error(ArgumentError, /variable name/)
    end
  end
end

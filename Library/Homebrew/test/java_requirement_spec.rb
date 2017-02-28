require "requirements/java_requirement"

describe JavaRequirement do
  subject { described_class.new([]) }

  before(:each) do
    ENV["JAVA_HOME"] = nil
  end

  describe "#message" do
    its(:message) { is_expected.to match(/Java is required to install this formula./) }
  end

  describe "#inspect" do
    subject { described_class.new(%w[1.7+]) }
    its(:inspect) { is_expected.to eq('#<JavaRequirement: "java" [] version="1.7+">') }
  end

  describe "#display_s" do
    context "without specific version" do
      its(:display_s) { is_expected.to eq("java") }
    end

    context "with version 1.8" do
      subject { described_class.new(%w[1.8]) }
      its(:display_s) { is_expected.to eq("java = 1.8") }
    end

    context "with version 1.8+" do
      subject { described_class.new(%w[1.8+]) }
      its(:display_s) { is_expected.to eq("java >= 1.8") }
    end
  end

  describe "#satisfied?" do
    subject { described_class.new(%w[1.8]) }

    it "returns false if no `java` executable can be found" do
      allow(File).to receive(:executable?).and_return(false)
      expect(subject).not_to be_satisfied
    end

    it "returns true if #preferred_java returns a path" do
      allow(subject).to receive(:preferred_java).and_return(Pathname.new("/usr/bin/java"))
      expect(subject).to be_satisfied
    end

    context "when #possible_javas contains paths" do
      let(:path) { mktmpdir }
      let(:java) { path/"java" }

      def setup_java_with_version(version)
        IO.write java, <<-EOS.undent
          #!/bin/sh
          echo 'java version "#{version}"'
        EOS
        FileUtils.chmod "+x", java
      end

      before(:each) do
        allow(subject).to receive(:possible_javas).and_return([java])
      end

      context "and 1.7 is required" do
        subject { described_class.new(%w[1.7]) }

        it "returns false if all are lower" do
          setup_java_with_version "1.6.0_5"
          expect(subject).not_to be_satisfied
        end

        it "returns true if one is equal" do
          setup_java_with_version "1.7.0_5"
          expect(subject).to be_satisfied
        end

        it "returns false if all are higher" do
          setup_java_with_version "1.8.0_5"
          expect(subject).not_to be_satisfied
        end
      end

      context "and 1.7+ is required" do
        subject { described_class.new(%w[1.7+]) }

        it "returns false if all are lower" do
          setup_java_with_version "1.6.0_5"
          expect(subject).not_to be_satisfied
        end

        it "returns true if one is equal" do
          setup_java_with_version "1.7.0_5"
          expect(subject).to be_satisfied
        end

        it "returns true if one is higher" do
          setup_java_with_version "1.8.0_5"
          expect(subject).to be_satisfied
        end
      end
    end
  end
end

require "build_environment"

describe BuildEnvironment do
  alias_matcher :use_userpaths, :be_userpaths

  let(:env) { described_class.new }

  describe "#<<" do
    it "returns itself" do
      expect(env << :foo).to be env
    end
  end

  describe "#merge" do
    it "returns itself" do
      expect(env.merge([])).to be env
    end
  end

  describe "#std?" do
    it "returns true if the environment contains :std" do
      env << :std
      expect(env).to be_std
    end

    it "returns false if the environment does not contain :std" do
      expect(env).not_to be_std
    end
  end

  describe "#userpaths?" do
    it "returns true if the environment contains :userpaths" do
      env << :userpaths
      expect(env).to use_userpaths
    end

    it "returns false if the environment does not contain :userpaths" do
      expect(env).not_to use_userpaths
    end
  end

  describe BuildEnvironment::DSL do
    subject { double.extend(described_class) }

    context "single argument" do
      before(:each) do
        subject.instance_eval do
          env :userpaths
        end
      end

      its(:env) { is_expected.to use_userpaths }
    end

    context "multiple arguments" do
      before(:each) do
        subject.instance_eval do
          env :userpaths, :std
        end
      end

      its(:env) { is_expected.to be_std }
      its(:env) { is_expected.to use_userpaths }
    end
  end
end

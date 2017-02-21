require "requirements/java_requirement"
require "fileutils"

describe JavaRequirement do
  subject { described_class.new(%w[1.8]) }
  let(:java_home) { Dir.mktmpdir }
  let(:java_home_path) { Pathname.new(java_home) }

  before(:each) do
    FileUtils.mkdir java_home_path/"bin"
    FileUtils.touch java_home_path/"bin/java"
    allow(subject).to receive(:preferred_java).and_return(java_home_path/"bin/java")
    expect(subject).to be_satisfied
  end

  after(:each) { java_home_path.rmtree }

  specify "Apple Java environment" do
    expect(ENV).to receive(:prepend_path)
    expect(ENV).to receive(:append_to_cflags)

    subject.modify_build_environment
    expect(ENV["JAVA_HOME"]).to eq(java_home)
  end

  specify "Oracle Java environment" do
    FileUtils.mkdir java_home_path/"include"
    expect(ENV).to receive(:prepend_path)
    expect(ENV).to receive(:append_to_cflags).twice

    subject.modify_build_environment
    expect(ENV["JAVA_HOME"]).to eq(java_home)
  end
end

require "language/node"

describe Language::Node do
  describe "#setup_npm_environment" do
    it "does nothing when npmrc exists" do
      expect(subject.setup_npm_environment).to be_nil
    end

    it "calls prepend_path when npmrc does not exist" do
      allow(Formula).to receive(:[]).with("node").and_return(formula { url "foo-1.0" })
      allow_any_instance_of(Pathname).to receive(:exist?).and_return(false)
      allow(ENV).to receive(:prepend_path).with("PATH", Formula["node"].opt_libexec/"bin").and_return("prepend_path called")
      expect(subject.setup_npm_environment).to eq("prepend_path called")
    end
  end

  describe "#std_npm_install_args" do
    npm_install_arg = "libexec"

    it "raises error with non zero exitstatus" do
      expect { subject.std_npm_install_args(npm_install_arg) }.to raise_error("npm failed to pack #{Dir.pwd}")
    end

    it "does not raise error with a zero exitstatus" do
      allow(Utils).to receive(:popen_read).with("npm pack").and_return("pack")
      allow_any_instance_of(Process::Status).to receive(:exitstatus).and_return(0)
      resp = subject.std_npm_install_args(npm_install_arg)
      expect(resp).to include("--prefix=#{npm_install_arg}", "#{Dir.pwd}/pack")
    end
  end

  specify "#local_npm_install_args" do
    resp = subject.local_npm_install_args
    expect(resp).to include("--verbose")
  end
end

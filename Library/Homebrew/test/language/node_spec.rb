require "language/node"

describe Language::Node do
  specify "#npm_cache_config" do
  	shutup do
  		ret_val = described_class.npm_cache_config
  		expect(ret_val).to eq("cache=#{HOMEBREW_CACHE}/npm_cache\n")
  	end
  end

  describe "#pack_for_installation" do
  	it "raises error with non zero exitstatus" do
      shutup do
  			expect{described_class.pack_for_installation}.to raise_error
  		end
  	end

  	it "does not raise error with a zero exitstatus" do
  		shutup do
  			allow_any_instance_of(Process::Status).to receive(:exitstatus).and_return(0)
  			expect{described_class.pack_for_installation}.not_to raise_error
  		end	
  	end
  end

  describe "#setup_npm_environment" do
    it "npmrc exists" do
      shutup do
        expect(described_class.setup_npm_environment).to be_nil
      end
    end

    it "npmrc does not exist" do
      shutup do
        allow_any_instance_of(Pathname).to receive(:exist?).and_return(false)
        described_class.setup_npm_environment 
      end
    end
  end

  specify "#std_npm_install_args" do
    shutup do
      npm_install_arg = "libexec"
      allow_any_instance_of(Process::Status).to receive(:exitstatus).and_return(0)
      resp = described_class.std_npm_install_args npm_install_arg
      expect(resp).to eq(["--verbose", "--global", "--prefix=#{npm_install_arg}", "#{Dir.pwd}/"])
    end
  end

  specify "#local_npm_install_args" do
    shutup do
      resp = described_class.local_npm_install_args
      expect(resp).to eq(["--verbose"])
    end
  end

end
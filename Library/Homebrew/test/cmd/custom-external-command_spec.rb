describe "brew custom-external-command", :integration_test do
  it "is supported" do
    mktmpdir do |path|
      cmd = "custom-external-command-#{rand}"
      file = path/"brew-#{cmd}"

      file.write <<~EOS
        #!/bin/sh
        echo 'I am #{cmd}.'
      EOS
      FileUtils.chmod "+x", file

      expect { brew cmd, "PATH" => "#{path}#{File::PATH_SEPARATOR}#{ENV["PATH"]}" }
        .to output("I am #{cmd}.\n").to_stdout
        .and not_to_output.to_stderr
        .and be_a_success
    end
  end
end

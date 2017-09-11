require "hbc/staged"

shared_examples Hbc::Staged do
  let(:existing_path) { Pathname.new("/path/to/file/that/exists") }
  let(:non_existent_path) { Pathname.new("/path/to/file/that/does/not/exist") }

  before(:each) do
    allow(existing_path).to receive(:exist?).and_return(true)
    allow(existing_path).to receive(:expand_path)
      .and_return(existing_path)
    allow(non_existent_path).to receive(:exist?).and_return(false)
    allow(non_existent_path).to receive(:expand_path)
      .and_return(non_existent_path)
  end

  it "can run system commands with list-form arguments" do
    Hbc::FakeSystemCommand.expects_command(
      ["echo", "homebrew-cask", "rocks!"],
    )

    staged.system_command("echo", args: ["homebrew-cask", "rocks!"])
  end

  it "can get the Info.plist file for the primary app" do
    expect(staged.info_plist_file).to eq Hbc.appdir.join("TestCask.app/Contents/Info.plist")
  end

  it "can execute commands on the Info.plist file" do
    allow(staged).to receive(:bundle_identifier).and_return("com.example.BasicCask")

    Hbc::FakeSystemCommand.expects_command(
      ["/usr/libexec/PlistBuddy", "-c", "Print CFBundleIdentifier", staged.info_plist_file],
    )

    staged.plist_exec("Print CFBundleIdentifier")
  end

  it "can set a key in the Info.plist file" do
    allow(staged).to receive(:bundle_identifier).and_return("com.example.BasicCask")

    Hbc::FakeSystemCommand.expects_command(
      ["/usr/libexec/PlistBuddy", "-c", "Set :JVMOptions:JVMVersion 1.6+", staged.info_plist_file],
    )

    staged.plist_set(":JVMOptions:JVMVersion", "1.6+")
  end

  it "can set the permissions of a file" do
    fake_pathname = existing_path
    allow(staged).to receive(:Pathname).and_return(fake_pathname)

    Hbc::FakeSystemCommand.expects_command(
      ["/bin/chmod", "-R", "--", "777", fake_pathname],
    )

    staged.set_permissions(fake_pathname.to_s, "777")
  end

  it "can set the permissions of multiple files" do
    fake_pathname = existing_path
    allow(staged).to receive(:Pathname).and_return(fake_pathname)

    Hbc::FakeSystemCommand.expects_command(
      ["/bin/chmod", "-R", "--", "777", fake_pathname, fake_pathname],
    )

    staged.set_permissions([fake_pathname.to_s, fake_pathname.to_s], "777")
  end

  it "cannot set the permissions of a file that does not exist" do
    fake_pathname = non_existent_path
    allow(staged).to receive(:Pathname).and_return(fake_pathname)
    staged.set_permissions(fake_pathname.to_s, "777")
  end

  it "can set the ownership of a file" do
    fake_pathname = existing_path

    allow(staged).to receive(:current_user).and_return("fake_user")
    allow(staged).to receive(:Pathname).and_return(fake_pathname)

    Hbc::FakeSystemCommand.expects_command(
      ["/usr/bin/sudo", "-E", "--", "/usr/sbin/chown", "-R", "--", "fake_user:staff", fake_pathname],
    )

    staged.set_ownership(fake_pathname.to_s)
  end

  it "can set the ownership of multiple files" do
    fake_pathname = existing_path

    allow(staged).to receive(:current_user).and_return("fake_user")
    allow(staged).to receive(:Pathname).and_return(fake_pathname)

    Hbc::FakeSystemCommand.expects_command(
      ["/usr/bin/sudo", "-E", "--", "/usr/sbin/chown", "-R", "--", "fake_user:staff", fake_pathname, fake_pathname],
    )

    staged.set_ownership([fake_pathname.to_s, fake_pathname.to_s])
  end

  it "can set the ownership of a file with a different user and group" do
    fake_pathname = existing_path

    allow(staged).to receive(:Pathname).and_return(fake_pathname)

    Hbc::FakeSystemCommand.expects_command(
      ["/usr/bin/sudo", "-E", "--", "/usr/sbin/chown", "-R", "--", "other_user:other_group", fake_pathname],
    )

    staged.set_ownership(fake_pathname.to_s, user: "other_user", group: "other_group")
  end

  it "cannot set the ownership of a file that does not exist" do
    allow(staged).to receive(:current_user).and_return("fake_user")
    fake_pathname = non_existent_path
    allow(staged).to receive(:Pathname).and_return(fake_pathname)

    staged.set_ownership(fake_pathname.to_s)
  end
end

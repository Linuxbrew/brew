require "cask/staged"

shared_examples Cask::Staged do
  let(:existing_path) { Pathname.new("/path/to/file/that/exists") }
  let(:non_existent_path) { Pathname.new("/path/to/file/that/does/not/exist") }

  before do
    allow(existing_path).to receive(:exist?).and_return(true)
    allow(existing_path).to receive(:expand_path)
      .and_return(existing_path)
    allow(non_existent_path).to receive(:exist?).and_return(false)
    allow(non_existent_path).to receive(:expand_path)
      .and_return(non_existent_path)
  end

  it "can run system commands with list-form arguments" do
    FakeSystemCommand.expects_command(
      ["echo", "homebrew-cask", "rocks!"],
    )

    staged.system_command("echo", args: ["homebrew-cask", "rocks!"])
  end

  it "can set the permissions of a file" do
    fake_pathname = existing_path
    allow(staged).to receive(:Pathname).and_return(fake_pathname)

    FakeSystemCommand.expects_command(
      ["/bin/chmod", "-R", "--", "777", fake_pathname],
    )

    staged.set_permissions(fake_pathname.to_s, "777")
  end

  it "can set the permissions of multiple files" do
    fake_pathname = existing_path
    allow(staged).to receive(:Pathname).and_return(fake_pathname)

    FakeSystemCommand.expects_command(
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

    allow(User).to receive(:current).and_return(User.new("fake_user"))
    allow(staged).to receive(:Pathname).and_return(fake_pathname)

    FakeSystemCommand.expects_command(
      sudo("/usr/sbin/chown", "-R", "--", "fake_user:staff", fake_pathname),
    )

    staged.set_ownership(fake_pathname.to_s)
  end

  it "can set the ownership of multiple files" do
    fake_pathname = existing_path

    allow(User).to receive(:current).and_return(User.new("fake_user"))
    allow(staged).to receive(:Pathname).and_return(fake_pathname)

    FakeSystemCommand.expects_command(
      sudo("/usr/sbin/chown", "-R", "--", "fake_user:staff", fake_pathname, fake_pathname),
    )

    staged.set_ownership([fake_pathname.to_s, fake_pathname.to_s])
  end

  it "can set the ownership of a file with a different user and group" do
    fake_pathname = existing_path

    allow(staged).to receive(:Pathname).and_return(fake_pathname)

    FakeSystemCommand.expects_command(
      sudo("/usr/sbin/chown", "-R", "--", "other_user:other_group", fake_pathname),
    )

    staged.set_ownership(fake_pathname.to_s, user: "other_user", group: "other_group")
  end

  it "cannot set the ownership of a file that does not exist" do
    allow(User).to receive(:current).and_return(User.new("fake_user"))
    fake_pathname = non_existent_path
    allow(staged).to receive(:Pathname).and_return(fake_pathname)

    staged.set_ownership(fake_pathname.to_s)
  end
end

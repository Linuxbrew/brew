describe Hbc::CLI::Doctor, :cask do
  it "displays some nice info about the environment" do
    expect {
      Hbc::CLI::Doctor.run
    }.to output(/\A==> Homebrew-Cask Version/).to_stdout
  end

  it "raises an exception when arguments are given" do
    expect {
      Hbc::CLI::Doctor.run("argument")
    }.to raise_error(ArgumentError)
  end
end

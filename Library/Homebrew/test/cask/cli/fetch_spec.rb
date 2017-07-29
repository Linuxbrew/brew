describe Hbc::CLI::Fetch, :cask do
  let(:local_transmission) {
    Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-transmission.rb")
  }

  let(:local_caffeine) {
    Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/local-caffeine.rb")
  }

  it "allows download the installer of a Cask" do
    Hbc::CLI::Fetch.run("local-transmission", "local-caffeine")
    expect(Hbc::CurlDownloadStrategy.new(local_transmission).cached_location).to exist
    expect(Hbc::CurlDownloadStrategy.new(local_caffeine).cached_location).to exist
  end

  it "prevents double fetch (without nuking existing installation)" do
    download_stategy = Hbc::CurlDownloadStrategy.new(local_transmission)

    Hbc::Download.new(local_transmission).perform
    old_ctime = File.stat(download_stategy.cached_location).ctime

    Hbc::CLI::Fetch.run("local-transmission")
    new_ctime = File.stat(download_stategy.cached_location).ctime

    expect(old_ctime.to_i).to eq(new_ctime.to_i)
  end

  it "allows double fetch with --force" do
    Hbc::Download.new(local_transmission).perform

    download_stategy = Hbc::CurlDownloadStrategy.new(local_transmission)
    old_ctime = File.stat(download_stategy.cached_location).ctime
    sleep(1)

    Hbc::CLI::Fetch.run("local-transmission", "--force")
    download_stategy = Hbc::CurlDownloadStrategy.new(local_transmission)
    new_ctime = File.stat(download_stategy.cached_location).ctime

    expect(new_ctime.to_i).to be > old_ctime.to_i
  end

  it "properly handles Casks that are not present" do
    expect {
      Hbc::CLI::Fetch.run("notacask")
    }.to raise_error(Hbc::CaskError, "Fetch incomplete.")
  end

  describe "when no Cask is specified" do
    it "raises an exception" do
      expect {
        Hbc::CLI::Fetch.run
      }.to raise_error(Hbc::CaskUnspecifiedError)
    end
  end

  describe "when no Cask is specified, but an invalid option" do
    it "raises an exception" do
      expect {
        Hbc::CLI::Fetch.run("--notavalidoption")
      }.to raise_error(/invalid option/)
    end
  end
end

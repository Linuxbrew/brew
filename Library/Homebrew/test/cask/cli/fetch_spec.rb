require_relative "shared_examples/requires_cask_token"
require_relative "shared_examples/invalid_option"

describe Hbc::CLI::Fetch, :cask do
  let(:local_transmission) {
    Hbc::CaskLoader.load(cask_path("local-transmission"))
  }

  let(:local_caffeine) {
    Hbc::CaskLoader.load(cask_path("local-caffeine"))
  }

  it_behaves_like "a command that requires a Cask token"
  it_behaves_like "a command that handles invalid options"

  it "allows download the installer of a Cask" do
    described_class.run("local-transmission", "local-caffeine")
    expect(Hbc::CurlDownloadStrategy.new(local_transmission).cached_location).to exist
    expect(Hbc::CurlDownloadStrategy.new(local_caffeine).cached_location).to exist
  end

  it "prevents double fetch (without nuking existing installation)" do
    download_stategy = Hbc::CurlDownloadStrategy.new(local_transmission)

    Hbc::Download.new(local_transmission).perform
    old_ctime = File.stat(download_stategy.cached_location).ctime

    described_class.run("local-transmission")
    new_ctime = File.stat(download_stategy.cached_location).ctime

    expect(old_ctime.to_i).to eq(new_ctime.to_i)
  end

  it "allows double fetch with --force" do
    Hbc::Download.new(local_transmission).perform

    download_stategy = Hbc::CurlDownloadStrategy.new(local_transmission)
    old_ctime = File.stat(download_stategy.cached_location).ctime
    sleep(1)

    described_class.run("local-transmission", "--force")
    download_stategy = Hbc::CurlDownloadStrategy.new(local_transmission)
    new_ctime = File.stat(download_stategy.cached_location).ctime

    expect(new_ctime.to_i).to be > old_ctime.to_i
  end

  it "properly handles Casks that are not present" do
    expect {
      described_class.run("notacask")
    }.to raise_error(Hbc::CaskUnavailableError)
  end
end

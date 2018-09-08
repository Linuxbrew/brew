require_relative "shared_examples/requires_cask_token"
require_relative "shared_examples/invalid_option"

describe Cask::Cmd::Fetch, :cask do
  let(:local_transmission) {
    Cask::CaskLoader.load(cask_path("local-transmission"))
  }

  let(:local_caffeine) {
    Cask::CaskLoader.load(cask_path("local-caffeine"))
  }

  it_behaves_like "a command that requires a Cask token"
  it_behaves_like "a command that handles invalid options"

  it "allows downloading the installer of a Cask" do
    transmission_location = CurlDownloadStrategy.new(
      local_transmission.url.to_s, local_transmission.token, local_transmission.version,
      cache: Cask::Cache.path, **local_transmission.url.specs
    ).cached_location
    caffeine_location = CurlDownloadStrategy.new(
      local_caffeine.url.to_s, local_caffeine.token, local_caffeine.version,
      cache: Cask::Cache.path, **local_caffeine.url.specs
    ).cached_location

    expect(transmission_location).not_to exist
    expect(caffeine_location).not_to exist

    described_class.run("local-transmission", "local-caffeine")

    expect(transmission_location).to exist
    expect(caffeine_location).to exist
  end

  it "prevents double fetch (without nuking existing installation)" do
    cached_location = Cask::Download.new(local_transmission).perform

    old_ctime = File.stat(cached_location).ctime

    described_class.run("local-transmission", "--no-quarantine")
    new_ctime = File.stat(cached_location).ctime

    expect(old_ctime.to_i).to eq(new_ctime.to_i)
  end

  it "allows double fetch with --force" do
    cached_location = Cask::Download.new(local_transmission).perform

    old_ctime = File.stat(cached_location).ctime
    sleep(1)

    described_class.run("local-transmission", "--force", "--no-quarantine")
    new_ctime = File.stat(cached_location).ctime

    expect(new_ctime.to_i).to be > old_ctime.to_i
  end

  it "properly handles Casks that are not present" do
    expect {
      described_class.run("notacask")
    }.to raise_error(Cask::CaskUnavailableError)
  end
end

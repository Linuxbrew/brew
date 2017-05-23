describe Hbc::CLI::Cleanup, :cask do
  let(:cache_location) { Pathname.new(Dir.mktmpdir).realpath }
  let(:outdated_only) { false }

  subject { described_class.new(*cask_tokens, cache_location: cache_location) }

  before(:each) do
    allow_any_instance_of(described_class).to receive(:outdated_only?).and_return(outdated_only)
  end

  after do
    cache_location.rmtree
  end

  describe "cleanup" do
    let(:cask_token) { "caffeine" }
    let(:cask_tokens) { [cask_token] }

    it "removes cached downloads of given casks" do
      cached_downloads = [
        cache_location.join("#{cask_token}--latest.zip"),
        cache_location.join("transmission--2.61.dmg"),
      ]

      cached_downloads.each(&FileUtils.method(:touch))

      cleanup_size = cached_downloads[0].disk_usage

      expect {
        subject.run
      }.to output(<<-EOS.undent).to_stdout
        ==> Removing cached downloads for #{cask_token}
        #{cached_downloads[0]}
        ==> This operation has freed approximately #{disk_usage_readable(cleanup_size)} of disk space.
      EOS

      expect(cached_downloads[0].exist?).to eq(false)
      expect(cached_downloads[1].exist?).to eq(true)
    end

    context "when no argument is given" do
      let(:cask_tokens) { [] }

      it "removes all cached downloads" do
        cached_download = cache_location.join("SomeDownload.dmg")
        FileUtils.touch(cached_download)
        cleanup_size = subject.disk_cleanup_size

        expect {
          subject.run
        }.to output(<<-EOS.undent).to_stdout
          ==> Removing cached downloads
          #{cached_download}
          ==> This operation has freed approximately #{disk_usage_readable(cleanup_size)} of disk space.
        EOS

        expect(cached_download.exist?).to eq(false)
      end

      context "and :outdated_only is specified" do
        let(:outdated_only) { true }

        it "does not remove cache files newer than 10 days old" do
          cached_download = cache_location.join("SomeNewDownload.dmg")
          FileUtils.touch(cached_download)

          expect {
            subject.run
          }.to output(<<-EOS.undent).to_stdout
            ==> Removing cached downloads older than 10 days old
            Nothing to do
          EOS

          expect(cached_download.exist?).to eq(true)
        end
      end
    end
  end
end

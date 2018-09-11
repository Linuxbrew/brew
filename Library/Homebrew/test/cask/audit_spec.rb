describe Cask::Audit, :cask do
  def include_msg?(messages, msg)
    if msg.is_a?(Regexp)
      Array(messages).any? { |m| m =~ msg }
    else
      Array(messages).include?(msg)
    end
  end

  matcher :pass do
    match do |audit|
      !audit.errors? && !audit.warnings?
    end
  end

  matcher :fail do
    match(&:errors?)
  end

  matcher :warn do
    match do |audit|
      audit.warnings? && !audit.errors?
    end
  end

  matcher :fail_with do |error_msg|
    match do |audit|
      include_msg?(audit.errors, error_msg)
    end
  end

  matcher :warn_with do |warning_msg|
    match do |audit|
      include_msg?(audit.warnings, warning_msg)
    end
  end

  let(:cask) { instance_double(Cask::Cask) }
  let(:download) { false }
  let(:check_token_conflicts) { false }
  let(:fake_system_command) { class_double(SystemCommand) }
  let(:audit) {
    Cask::Audit.new(cask, download:              download,
                          check_token_conflicts: check_token_conflicts,
                          command:               fake_system_command)
  }

  describe "#result" do
    subject { audit.result }

    context "when there are errors" do
      before do
        audit.add_error "bad"
      end

      it { is_expected.to match(/failed/) }
    end

    context "when there are warnings" do
      before do
        audit.add_warning "eh"
      end

      it { is_expected.to match(/warning/) }
    end

    context "when there are errors and warnings" do
      before do
        audit.add_error "bad"
        audit.add_warning "eh"
      end

      it { is_expected.to match(/failed/) }
    end

    context "when there are no errors or warnings" do
      it { is_expected.to match(/passed/) }
    end
  end

  describe "#run!" do
    subject { audit.run! }

    let(:cask) { Cask::CaskLoader.load(cask_token) }

    describe "required stanzas" do
      %w[version sha256 url name homepage].each do |stanza|
        context "when missing #{stanza}" do
          let(:cask_token) { "missing-#{stanza}" }

          it { is_expected.to fail_with(/#{stanza} stanza is required/) }
        end
      end
    end

    describe "pkg allow_untrusted checks" do
      let(:warning_msg) { "allow_untrusted is not permitted in official Homebrew Cask taps" }

      context "when the Cask has no pkg stanza" do
        let(:cask_token) { "basic-cask" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask does not have allow_untrusted" do
        let(:cask_token) { "with-uninstall-pkgutil" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask has allow_untrusted" do
        let(:cask_token) { "with-allow-untrusted" }

        it { is_expected.to warn_with(warning_msg) }
      end
    end

    describe "when the Cask stanza requires uninstall" do
      let(:warning_msg) { "installer and pkg stanzas require an uninstall stanza" }

      context "when the Cask does not require an uninstall" do
        let(:cask_token) { "basic-cask" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the pkg Cask has an uninstall" do
        let(:cask_token) { "with-uninstall-pkgutil" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the installer Cask has an uninstall" do
        let(:cask_token) { "installer-with-uninstall" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the installer Cask does not have an uninstall" do
        let(:cask_token) { "with-installer-manual" }

        it { is_expected.to warn_with(warning_msg) }
      end

      context "when the pkg Cask does not have an uninstall" do
        let(:cask_token) { "pkg-without-uninstall" }

        it { is_expected.to warn_with(warning_msg) }
      end
    end

    describe "preflight stanza checks" do
      let(:warning_msg) { "only a single preflight stanza is allowed" }

      context "when the Cask has no preflight stanza" do
        let(:cask_token) { "with-zap-rmdir" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask has only one preflight stanza" do
        let(:cask_token) { "with-preflight" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask has multiple preflight stanzas" do
        let(:cask_token) { "with-preflight-multi" }

        it { is_expected.to warn_with(warning_msg) }
      end
    end

    describe "uninstall_postflight stanza checks" do
      let(:warning_msg) { "only a single postflight stanza is allowed" }

      context "when the Cask has no postflight stanza" do
        let(:cask_token) { "with-zap-rmdir" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask has only one postflight stanza" do
        let(:cask_token) { "with-postflight" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask has multiple postflight stanzas" do
        let(:cask_token) { "with-postflight-multi" }

        it { is_expected.to warn_with(warning_msg) }
      end
    end

    describe "uninstall stanza checks" do
      let(:warning_msg) { "only a single uninstall stanza is allowed" }

      context "when the Cask has no uninstall stanza" do
        let(:cask_token) { "with-zap-rmdir" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask has only one uninstall stanza" do
        let(:cask_token) { "with-uninstall-rmdir" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask has multiple uninstall stanzas" do
        let(:cask_token) { "with-uninstall-multi" }

        it { is_expected.to warn_with(warning_msg) }
      end
    end

    describe "uninstall_preflight stanza checks" do
      let(:warning_msg) { "only a single uninstall_preflight stanza is allowed" }

      context "when the Cask has no uninstall_preflight stanza" do
        let(:cask_token) { "with-zap-rmdir" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask has only one uninstall_preflight stanza" do
        let(:cask_token) { "with-uninstall-preflight" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask has multiple uninstall_preflight stanzas" do
        let(:cask_token) { "with-uninstall-preflight-multi" }

        it { is_expected.to warn_with(warning_msg) }
      end
    end

    describe "uninstall_postflight stanza checks" do
      let(:warning_msg) { "only a single uninstall_postflight stanza is allowed" }

      context "when the Cask has no uninstall_postflight stanza" do
        let(:cask_token) { "with-zap-rmdir" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask has only one uninstall_postflight stanza" do
        let(:cask_token) { "with-uninstall-postflight" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask has multiple uninstall_postflight stanzas" do
        let(:cask_token) { "with-uninstall-postflight-multi" }

        it { is_expected.to warn_with(warning_msg) }
      end
    end

    describe "zap stanza checks" do
      let(:warning_msg) { "only a single zap stanza is allowed" }

      context "when the Cask has no zap stanza" do
        let(:cask_token) { "with-uninstall-rmdir" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask has only one zap stanza" do
        let(:cask_token) { "with-zap-rmdir" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask has multiple zap stanzas" do
        let(:cask_token) { "with-zap-multi" }

        it { is_expected.to warn_with(warning_msg) }
      end
    end

    describe "version checks" do
      let(:error_msg) { "you should use version :latest instead of version 'latest'" }

      context "when version is 'latest'" do
        let(:cask_token) { "version-latest-string" }

        it { is_expected.to fail_with(error_msg) }
      end

      context "when version is :latest" do
        let(:cask_token) { "version-latest-with-checksum" }

        it { is_expected.not_to fail_with(error_msg) }
      end
    end

    describe "sha256 checks" do
      context "when version is :latest and sha256 is not :no_check" do
        let(:cask_token) { "version-latest-with-checksum" }

        it { is_expected.to fail_with("you should use sha256 :no_check when version is :latest") }
      end

      context "when sha256 is not a legal SHA-256 digest" do
        let(:cask_token) { "invalid-sha256" }

        it { is_expected.to fail_with("sha256 string must be of 64 hexadecimal characters") }
      end

      context "when sha256 is sha256 for empty string" do
        let(:cask_token) { "sha256-for-empty-string" }

        it { is_expected.to fail_with(/cannot use the sha256 for an empty string/) }
      end
    end

    describe "appcast checkpoint check" do
      let(:error_msg) { "Appcast checkpoints have been removed from Homebrew Cask" }

      context "when the Cask does not have a checkpoint" do
        let(:cask_token) { "with-appcast" }

        it { is_expected.not_to fail_with(error_msg) }
      end

      context "when the Cask has a checkpoint" do
        let(:cask_token) { "appcast-with-checkpoint" }

        it { is_expected.to fail_with(error_msg) }
      end
    end

    describe "hosting with appcast checks" do
      let(:appcast_warning) { /please add an appcast/ }

      context "when the download does not use hosting with an appcast" do
        let(:cask_token) { "basic-cask" }

        it { is_expected.not_to warn_with(appcast_warning) }
      end

      context "when the download uses GitHub releases and has an appcast" do
        let(:cask_token) { "github-with-appcast" }

        it { is_expected.not_to warn_with(appcast_warning) }
      end

      context "when the download uses GitHub releases and does not have an appcast" do
        let(:cask_token) { "github-without-appcast" }

        it { is_expected.to warn_with(appcast_warning) }
      end

      context "when the download is hosted on SourceForge and has an appcast" do
        let(:cask_token) { "sourceforge-with-appcast" }

        it { is_expected.not_to warn_with(appcast_warning) }
      end

      context "when the download is hosted on SourceForge and does not have an appcast" do
        let(:cask_token) { "sourceforge-correct-url-format" }

        it { is_expected.to warn_with(appcast_warning) }
      end

      context "when the download is hosted on DevMate and has an appcast" do
        let(:cask_token) { "devmate-with-appcast" }

        it { is_expected.not_to warn_with(appcast_warning) }
      end

      context "when the download is hosted on DevMate and does not have an appcast" do
        let(:cask_token) { "devmate-without-appcast" }

        it { is_expected.to warn_with(appcast_warning) }
      end

      context "when the download is hosted on HockeyApp and has an appcast" do
        let(:cask_token) { "hockeyapp-with-appcast" }

        it { is_expected.not_to warn_with(appcast_warning) }
      end

      context "when the download is hosted on HockeyApp and does not have an appcast" do
        let(:cask_token) { "hockeyapp-without-appcast" }

        it { is_expected.to warn_with(appcast_warning) }
      end
    end

    describe "latest with appcast checks" do
      let(:warning_msg) { "Casks with an appcast should not use version :latest" }

      context "when the Cask is :latest and does not have an appcast" do
        let(:cask_token) { "version-latest" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask is versioned and has an appcast" do
        let(:cask_token) { "with-appcast" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask is :latest and has an appcast" do
        let(:cask_token) { "latest-with-appcast" }

        it { is_expected.to warn_with(warning_msg) }
      end
    end

    describe "latest with auto_updates checks" do
      let(:warning_msg) { "Casks with `version :latest` should not use `auto_updates`" }

      context "when the Cask is :latest and does not have auto_updates" do
        let(:cask_token) { "version-latest" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask is versioned and does not have auto_updates" do
        let(:cask_token) { "basic-cask" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask is versioned and has auto_updates" do
        let(:cask_token) { "auto-updates" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "when the Cask is :latest and has auto_updates" do
        let(:cask_token) { "latest-with-auto-updates" }

        it { is_expected.to warn_with(warning_msg) }
      end
    end

    describe "preferred download URL formats" do
      let(:warning_msg) { /URL format incorrect/ }

      context "with incorrect SourceForge URL format" do
        let(:cask_token) { "sourceforge-incorrect-url-format" }

        it { is_expected.to warn_with(warning_msg) }
      end

      context "with correct SourceForge URL format" do
        let(:cask_token) { "sourceforge-correct-url-format" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "with correct SourceForge URL format for version :latest" do
        let(:cask_token) { "sourceforge-version-latest-correct-url-format" }

        it { is_expected.not_to warn_with(warning_msg) }
      end

      context "with incorrect OSDN URL format" do
        let(:cask_token) { "osdn-incorrect-url-format" }

        it { is_expected.to warn_with(warning_msg) }
      end

      context "with correct OSDN URL format" do
        let(:cask_token) { "osdn-correct-url-format" }

        it { is_expected.not_to warn_with(warning_msg) }
      end
    end

    describe "generic artifact checks" do
      context "with relative target" do
        let(:cask_token) { "generic-artifact-relative-target" }

        it { is_expected.to fail_with(/target must be absolute path for Generic Artifact/) }
      end

      context "with absolute target" do
        let(:cask_token) { "generic-artifact-absolute-target" }

        it { is_expected.not_to fail_with(/target required for Generic Artifact/) }
      end
    end

    describe "url checks" do
      context "given a block" do
        let(:cask_token) { "booby-trap" }

        context "when loading the cask" do
          it "does not evaluate the block" do
            expect { cask }.not_to raise_error
          end
        end

        context "when doing the audit" do
          it "evaluates the block" do
            expect(subject).to fail_with(/Boom/)
          end
        end
      end
    end

    describe "token conflicts" do
      let(:cask_token) { "with-binary" }
      let(:check_token_conflicts) { true }

      before do
        expect(audit).to receive(:core_formula_names).and_return(formula_names)
      end

      context "when cask token conflicts with a core formula" do
        let(:formula_names) { %w[with-binary other-formula] }

        it { is_expected.to warn_with(/possible duplicate/) }
      end

      context "when cask token does not conflict with a core formula" do
        let(:formula_names) { %w[other-formula] }

        it { is_expected.not_to warn_with(/possible duplicate/) }
      end
    end

    describe "audit of downloads" do
      let(:cask_token) { "with-binary" }
      let(:cask) { Cask::CaskLoader.load(cask_token) }
      let(:download) { instance_double(Cask::Download) }
      let(:verify) { class_double(Cask::Verify).as_stubbed_const }
      let(:error_msg) { "Download Failed" }

      context "when download and verification succeed" do
        before do
          expect(download).to receive(:perform)
          expect(verify).to receive(:all)
        end

        it { is_expected.not_to fail_with(/#{error_msg}/) }
      end

      context "when download fails" do
        before do
          expect(download).to receive(:perform).and_raise(StandardError.new(error_msg))
        end

        it { is_expected.to fail_with(/#{error_msg}/) }
      end

      context "when verification fails" do
        before do
          expect(download).to receive(:perform)
          expect(verify).to receive(:all).and_raise(StandardError.new(error_msg))
        end

        it { is_expected.to fail_with(/#{error_msg}/) }
      end
    end

    context "when an exception is raised" do
      let(:cask) { instance_double(Cask::Cask) }

      before do
        expect(cask).to receive(:version).and_raise(StandardError.new)
      end

      it { is_expected.to fail_with(/exception while auditing/) }
    end
  end
end

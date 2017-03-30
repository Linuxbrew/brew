describe "brew prune", :integration_test do
  it "removes empty directories and broken symlinks" do
    share = (HOMEBREW_PREFIX/"share")

    (share/"pruneable/directory/here").mkpath
    (share/"notpruneable/file").write "I'm here"
    FileUtils.ln_s "/i/dont/exist/no/really/i/dont", share/"pruneable_symlink"

    expect { brew "prune", "--dry-run" }
      .to output(%r{Would remove \(empty directory\): .*/pruneable/directory/here}).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect { brew "prune" }
      .to output(/Pruned 1 symbolic links and 3 directories/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success

    expect(share/"pruneable").not_to be_a_directory
    expect(share/"notpruneable").to be_a_directory
    expect(share/"pruneable_symlink").not_to be_a_symlink

    expect { brew "prune", "--verbose" }
      .to output(/Nothing pruned/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end

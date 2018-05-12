require "diagnostic"

describe Homebrew::Diagnostic::Checks do
  specify "#check_for_other_package_managers" do
    allow(MacOS).to receive(:macports_or_fink).and_return(["fink"])
    expect(subject.check_for_other_package_managers)
      .to match("You have MacPorts or Fink installed:")
  end

  specify "#check_for_unsupported_macos" do
    ENV.delete("HOMEBREW_DEVELOPER")
    allow(OS::Mac).to receive(:prerelease?).and_return(true)

    expect(subject.check_for_unsupported_macos)
      .to match("We do not provide support for this pre-release version.")
  end

  specify "#check_for_beta_xquartz" do
    allow(MacOS::XQuartz).to receive(:version).and_return("2.7.10_beta2")

    expect(subject.check_for_beta_xquartz)
      .to match("The following beta release of XQuartz is installed: 2.7.10_beta2")
  end

  specify "#check_if_xcode_needs_clt_installed" do
    allow(MacOS).to receive(:version).and_return(OS::Mac::Version.new("10.11"))
    allow(MacOS::Xcode).to receive(:installed?).and_return(true)
    allow(MacOS::Xcode).to receive(:version).and_return("8.0")
    allow(MacOS::Xcode).to receive(:without_clt?).and_return(true)

    expect(subject.check_if_xcode_needs_clt_installed)
      .to match("Xcode alone is not sufficient on El Capitan")
  end

  specify "#check_homebrew_prefix" do
    # the integration tests are run in a special prefix
    expect(subject.check_homebrew_prefix)
      .to match("Your Homebrew's prefix is not /usr/local.")
  end

  specify "#check_ruby_version" do
    allow(MacOS).to receive(:version).and_return(OS::Mac::Version.new("10.12"))
    stub_const("RUBY_VERSION", "1.8.6")

    expect(subject.check_ruby_version)
      .to match "Ruby version 1.8.6 is unsupported on 10.12"
  end

  specify "#check_dyld_insert" do
    ENV["DYLD_INSERT_LIBRARIES"] = "foo"
    expect(subject.check_ld_vars).to match("Setting DYLD_INSERT_LIBRARIES")
  end
end

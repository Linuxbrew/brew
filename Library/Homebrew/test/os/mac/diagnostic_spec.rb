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

  specify "#check_for_unsupported_curl_vars" do
    allow(MacOS).to receive(:version).and_return(OS::Mac::Version.new("10.10"))
    ENV["SSL_CERT_DIR"] = "/some/path"

    expect(subject.check_for_unsupported_curl_vars)
      .to match("SSL_CERT_DIR support was removed from Apple's curl.")
  end

  specify "#check_for_beta_xquartz" do
    allow(MacOS::XQuartz).to receive(:version).and_return("2.7.10_beta2")

    expect(subject.check_for_beta_xquartz)
      .to match("The following beta release of XQuartz is installed: 2.7.10_beta2")
  end

  specify "#check_xcode_8_without_clt_on_el_capitan" do
    allow(MacOS).to receive(:version).and_return(OS::Mac::Version.new("10.11"))
    allow(MacOS::Xcode).to receive(:installed?).and_return(true)
    allow(MacOS::Xcode).to receive(:version).and_return("8.0")
    allow(MacOS::Xcode).to receive(:without_clt?).and_return(true)

    expect(subject.check_xcode_8_without_clt_on_el_capitan)
      .to match("You have Xcode 8 installed without the CLT")
  end
end

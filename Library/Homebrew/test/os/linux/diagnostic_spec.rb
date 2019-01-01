require "diagnostic"

describe Homebrew::Diagnostic::Checks do
  specify "#check_glibc_minimum_version" do
    allow(OS::Linux::Glibc).to receive(:below_minimum_version?).and_return(true)

    expect(subject.check_glibc_minimum_version)
      .to match(/Your system glibc .+ is too old/)
  end

  specify "#check_kernel_minimum_version" do
    allow(OS::Linux::Kernel).to receive(:below_minimum_version?).and_return(true)

    expect(subject.check_kernel_minimum_version)
      .to match(/Your Linux kernel .+ is too old/)
  end
end

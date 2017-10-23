require "test/support/helper/spec/shared_examples/hbc_dsl_base"

describe Hbc::DSL::UninstallPostflight, :cask do
  let(:cask) { Hbc::CaskLoader.load(cask_path("basic-cask")) }
  let(:dsl) { Hbc::DSL::UninstallPostflight.new(cask, Hbc::FakeSystemCommand) }

  it_behaves_like Hbc::DSL::Base
end

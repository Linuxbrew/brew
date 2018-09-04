require "test/support/helper/spec/shared_examples/cask_dsl_base"

describe Hbc::DSL::UninstallPostflight, :cask do
  let(:cask) { Hbc::CaskLoader.load(cask_path("basic-cask")) }
  let(:dsl) { Hbc::DSL::UninstallPostflight.new(cask, FakeSystemCommand) }

  it_behaves_like Hbc::DSL::Base
end

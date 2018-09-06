require "test/support/helper/spec/shared_examples/cask_dsl_base"

describe Cask::DSL::UninstallPostflight, :cask do
  let(:cask) { Cask::CaskLoader.load(cask_path("basic-cask")) }
  let(:dsl) { Cask::DSL::UninstallPostflight.new(cask, FakeSystemCommand) }

  it_behaves_like Cask::DSL::Base
end

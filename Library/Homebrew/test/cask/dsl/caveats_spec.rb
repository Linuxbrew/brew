require "test/support/helper/spec/shared_examples/cask_dsl_base"

describe Cask::DSL::Caveats, :cask do
  let(:cask) { Cask::CaskLoader.load(cask_path("basic-cask")) }
  let(:dsl) { Cask::DSL::Caveats.new(cask) }

  it_behaves_like Cask::DSL::Base

  # TODO: add tests for Caveats DSL methods
end

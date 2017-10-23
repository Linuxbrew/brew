require "test/support/helper/spec/shared_examples/hbc_dsl_base"

describe Hbc::DSL::Caveats, :cask do
  let(:cask) { Hbc::CaskLoader.load(cask_path("basic-cask")) }
  let(:dsl) { Hbc::DSL::Caveats.new(cask) }

  it_behaves_like Hbc::DSL::Base

  # TODO: add tests for Caveats DSL methods
end

require "test/support/helper/spec/shared_examples/hbc_dsl_base"

describe Hbc::DSL::Caveats, :cask do
  let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/basic-cask.rb") }
  let(:dsl) { Hbc::DSL::Caveats.new(cask) }

  it_behaves_like Hbc::DSL::Base

  # TODO: add tests for Caveats DSL methods
end

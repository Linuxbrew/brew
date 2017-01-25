require "test_helper"

describe Hbc::DSL::Caveats do
  let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/basic-cask.rb") }
  let(:dsl) { Hbc::DSL::Caveats.new(cask) }

  it_behaves_like Hbc::DSL::Base

  # TODO: add tests for Caveats DSL methods
end

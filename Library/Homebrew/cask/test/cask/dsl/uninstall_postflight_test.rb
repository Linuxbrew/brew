require "test_helper"

describe Hbc::DSL::UninstallPostflight do
  let(:cask) { Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/basic-cask.rb") }
  let(:dsl) { Hbc::DSL::UninstallPostflight.new(cask, Hbc::FakeSystemCommand) }

  it_behaves_like Hbc::DSL::Base
end

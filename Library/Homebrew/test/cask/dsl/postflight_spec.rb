require "test/cask/dsl/shared_examples/base"
require "test/cask/dsl/shared_examples/staged"

describe Cask::DSL::Postflight, :cask do
  let(:cask) { Cask::CaskLoader.load(cask_path("basic-cask")) }
  let(:dsl) { Cask::DSL::Postflight.new(cask, FakeSystemCommand) }

  it_behaves_like Cask::DSL::Base

  it_behaves_like Cask::Staged do
    let(:staged) { dsl }
  end
end

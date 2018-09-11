require "test/support/helper/spec/shared_examples/cask_dsl_base"
require "test/support/helper/spec/shared_examples/cask_staged"

describe Cask::DSL::Preflight, :cask do
  let(:cask) { Cask::CaskLoader.load(cask_path("basic-cask")) }
  let(:dsl) { Cask::DSL::Preflight.new(cask, FakeSystemCommand) }

  it_behaves_like Cask::DSL::Base

  it_behaves_like Cask::Staged do
    let(:staged) { dsl }
  end
end

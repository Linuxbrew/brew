require_relative "shared_examples"

describe UnpackStrategy::Subversion do
  let(:repo) {
    mktmpdir.tap do |repo|
      system "svnadmin", "create", repo
    end
  }
  let(:working_copy) {
    mktmpdir.tap do |working_copy|
      system "svn", "checkout", "file://#{repo}", working_copy

      FileUtils.touch working_copy/"test"
      system "svn", "add", working_copy/"test"
      system "svn", "commit", working_copy, "-m", "Add `test` file."
    end
  }
  let(:path) { working_copy }

  include_examples "UnpackStrategy::detect"
  include_examples "#extract", children: ["test"]
end

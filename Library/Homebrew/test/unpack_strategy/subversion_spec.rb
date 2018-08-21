require_relative "shared_examples"

describe UnpackStrategy::Subversion, :needs_svn do
  let(:repo) { mktmpdir }
  let(:working_copy) { mktmpdir }
  let(:path) { working_copy }

  before(:each) do
    system "svnadmin", "create", repo

    system "svn", "checkout", "file://#{repo}", working_copy

    FileUtils.touch working_copy/"test"
    system "svn", "add", working_copy/"test"
    system "svn", "commit", working_copy, "-m", "Add `test` file."
  end

  context "when svn is available", :needs_svn do
    include_examples "UnpackStrategy::detect"
    include_examples "#extract", children: ["test"]

    context "when the directory name contains an '@' symbol" do
      let(:working_copy) { mktmpdir(["", "@1.2.3"])  }

      include_examples "#extract", children: ["test"]
    end
  end
end

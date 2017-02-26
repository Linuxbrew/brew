require "cmd/info"

describe "brew info", :integration_test do
  it "prints information about a given Formula" do
    setup_test_formula "testball"

    expect { brew "info", "testball" }
      .to output(/testball: stable 0.1/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end

describe Homebrew do
  let(:remote) { "https://github.com/Homebrew/homebrew-core" }

  specify "::github_remote_path" do
    expect(subject.github_remote_path(remote, "Formula/git.rb"))
      .to eq("https://github.com/Homebrew/homebrew-core/blob/master/Formula/git.rb")

    expect(subject.github_remote_path("#{remote}.git", "Formula/git.rb"))
      .to eq("https://github.com/Homebrew/homebrew-core/blob/master/Formula/git.rb")

    expect(subject.github_remote_path("git@github.com:user/repo", "foo.rb"))
      .to eq("https://github.com/user/repo/blob/master/foo.rb")

    expect(subject.github_remote_path("https://mywebsite.com", "foo/bar.rb"))
      .to eq("https://mywebsite.com/foo/bar.rb")
  end
end

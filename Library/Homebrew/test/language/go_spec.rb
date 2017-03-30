require "language/go"

describe Language::Go do
  specify "#stage_deps" do
    ENV.delete("HOMEBREW_DEVELOPER")

    expect(described_class).to receive(:opoo).once

    mktmpdir do |path|
      shutup do
        described_class.stage_deps [], path
      end
    end
  end
end

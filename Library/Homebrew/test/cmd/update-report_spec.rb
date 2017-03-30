require "cmd/update-report"
require "formula_versions"
require "yaml"

describe Reporter do
  def perform_update(fixture_name = "")
    allow(Formulary).to receive(:factory).and_return(double(pkg_version: "1.0"))
    allow(FormulaVersions).to receive(:new).and_return(double(formula_at_revision: "2.0"))

    diff = YAML.load_file("#{TEST_FIXTURE_DIR}/updater_fixture.yaml")[fixture_name]
    allow(subject).to receive(:diff).and_return(diff || "")

    hub.add(subject) if subject.updated?
  end

  let(:reporter_class) do
    Class.new(described_class) do
      def initialize(tap)
        @tap = tap

        ENV["HOMEBREW_UPDATE_BEFORE#{repo_var}"] = "12345678"
        ENV["HOMEBREW_UPDATE_AFTER#{repo_var}"] = "abcdef00"

        super(tap)
      end
    end
  end
  subject { reporter_class.new(tap) }
  let(:tap) { CoreTap.new }
  let(:hub) { ReporterHub.new }

  specify "without revision variable" do
    ENV.delete_if { |k, _v| k.start_with? "HOMEBREW_UPDATE" }

    expect {
      described_class.new(tap)
    }.to raise_error(Reporter::ReporterRevisionUnsetError)
  end

  specify "without any changes" do
    perform_update
    expect(hub).to be_empty
  end

  specify "without Formula changes" do
    perform_update("update_git_diff_output_without_formulae_changes")

    expect(hub.select_formula(:M)).to be_empty
    expect(hub.select_formula(:A)).to be_empty
    expect(hub.select_formula(:D)).to be_empty
  end

  specify "with Formula changes" do
    perform_update("update_git_diff_output_with_formulae_changes")

    expect(hub.select_formula(:M)).to eq(%w[xar yajl])
    expect(hub.select_formula(:A)).to eq(%w[antiword bash-completion ddrescue dict lua])
  end

  specify "with removed Formulae" do
    perform_update("update_git_diff_output_with_removed_formulae")

    expect(hub.select_formula(:D)).to eq(%w[libgsasl])
  end

  specify "with changed file type" do
    perform_update("update_git_diff_output_with_changed_filetype")

    expect(hub.select_formula(:M)).to eq(%w[elixir])
    expect(hub.select_formula(:A)).to eq(%w[libbson])
    expect(hub.select_formula(:D)).to eq(%w[libgsasl])
  end

  specify "with renamed Formula" do
    allow(tap).to receive(:formula_renames).and_return("cv" => "progress")
    perform_update("update_git_diff_output_with_formula_rename")

    expect(hub.select_formula(:A)).to be_empty
    expect(hub.select_formula(:D)).to be_empty
    expect(hub.select_formula(:R)).to eq([["cv", "progress"]])
  end

  context "when updating a Tap other than the core Tap" do
    let(:tap) { Tap.new("foo", "bar") }

    before(:each) do
      (tap.path/"Formula").mkpath
    end

    after(:each) do
      tap.path.parent.rmtree
    end

    specify "with restructured Tap" do
      perform_update("update_git_diff_output_with_restructured_tap")

      expect(hub.select_formula(:A)).to be_empty
      expect(hub.select_formula(:D)).to be_empty
      expect(hub.select_formula(:R)).to be_empty
    end

    specify "with renamed Formula and restructured Tap" do
      allow(tap).to receive(:formula_renames).and_return("xchat" => "xchat2")
      perform_update("update_git_diff_output_with_formula_rename_and_restructuring")

      expect(hub.select_formula(:A)).to be_empty
      expect(hub.select_formula(:D)).to be_empty
      expect(hub.select_formula(:R)).to eq([%w[foo/bar/xchat foo/bar/xchat2]])
    end

    specify "with simulated 'homebrew/php' restructuring" do
      perform_update("update_git_diff_simulate_homebrew_php_restructuring")

      expect(hub.select_formula(:A)).to be_empty
      expect(hub.select_formula(:D)).to be_empty
      expect(hub.select_formula(:R)).to be_empty
    end

    specify "with Formula changes" do
      perform_update("update_git_diff_output_with_tap_formulae_changes")

      expect(hub.select_formula(:A)).to eq(%w[foo/bar/lua])
      expect(hub.select_formula(:M)).to eq(%w[foo/bar/git])
      expect(hub.select_formula(:D)).to be_empty
    end
  end
end

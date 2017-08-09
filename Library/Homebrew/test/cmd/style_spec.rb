require "cmd/style"

describe "brew style" do
  around(:each) do |example|
    begin
      FileUtils.ln_s HOMEBREW_LIBRARY_PATH, HOMEBREW_LIBRARY/"Homebrew"
      FileUtils.ln_s HOMEBREW_LIBRARY_PATH.parent/".rubocop.yml", HOMEBREW_LIBRARY/".auditcops.yml"

      example.run
    ensure
      FileUtils.rm_f HOMEBREW_LIBRARY/"Homebrew"
      FileUtils.rm_f HOMEBREW_LIBRARY/".auditcops.yml"
    end
  end

  describe "Homebrew::check_style_json" do
    let(:dir) { mktmpdir }

    it "returns RubocopResults when RuboCop reports offenses" do
      formula = dir/"my-formula.rb"

      formula.write <<-'EOS'.undent
        class MyFormula < Formula

        end
      EOS

      rubocop_result = Homebrew.check_style_json([formula])

      expect(rubocop_result.file_offenses(formula.realpath.to_s).map(&:message))
        .to include("Extra empty line detected at class body beginning.")
    end
  end
end

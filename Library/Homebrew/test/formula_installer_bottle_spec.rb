require "formula"
require "formula_installer"
require "keg"
require "tab"
require "test/support/fixtures/testball"
require "test/support/fixtures/testball_bottle"

describe FormulaInstaller do
  alias_matcher :pour_bottle, :be_pour_bottle

  matcher :be_poured_from_bottle do
    match(&:poured_from_bottle)
  end

  def temporarily_install_bottle(formula)
    expect(formula).not_to be_installed
    expect(formula).to be_bottled
    expect(formula).to pour_bottle

    described_class.new(formula).install

    keg = Keg.new(formula.prefix)

    expect(formula).to be_installed

    begin
      expect(Tab.for_keg(keg)).to be_poured_from_bottle

      yield formula
    ensure
      keg.unlink
      keg.uninstall
      formula.clear_cache
      formula.bottle.clear_cache
    end

    expect(keg).not_to exist
    expect(formula).not_to be_installed
  end

  specify "basic bottle install" do
    allow(DevelopmentTools).to receive(:installed?).and_return(false)

    temporarily_install_bottle(TestballBottle.new) do |f|
      # Copied directly from formula_installer_spec.rb
      # as we expect the same behavior.

      # Test that things made it into the Keg
      expect(f.bin).to be_a_directory

      expect(f.libexec).to be_a_directory

      expect(f.prefix/"main.c").not_to exist

      # Test that things made it into the Cellar
      keg = Keg.new f.prefix
      keg.link

      bin = HOMEBREW_PREFIX/"bin"
      expect(bin).to be_a_directory
    end
  end

  specify "build tools error" do
    allow(DevelopmentTools).to receive(:installed?).and_return(false)

    # Testball doesn't have a bottle block, so use it to test this behavior
    formula = Testball.new

    expect(formula).not_to be_installed
    expect(formula).not_to be_bottled

    expect {
      FormulaInstaller.new(formula).install
    }.to raise_error(BuildToolsError)

    expect(formula).not_to be_installed
  end
end

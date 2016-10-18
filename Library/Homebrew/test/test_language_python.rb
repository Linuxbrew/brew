require "testing_env"
require "language/python"
require "resource"

class LanguagePythonTests < Homebrew::TestCase
  def setup
    @dir = Pathname.new(mktmpdir)
    resource = stub("resource", stage: true)
    formula_bin = @dir/"formula_bin"
    @formula = mock("formula") do
      stubs(:resource).returns(resource)
      stubs(:bin).returns(formula_bin)
    end
    @venv = Language::Python::Virtualenv::Virtualenv.new(@formula, @dir, "python")
  end

  def teardown
    FileUtils.rm_rf @dir
  end

  def test_virtualenv_creation
    @formula.expects(:resource).with("homebrew-virtualenv").returns(
      mock("resource", stage: true)
    )
    @venv.create
  end

  # or at least doesn't crash the second time
  def test_virtualenv_creation_is_idempotent
    @formula.expects(:resource).with("homebrew-virtualenv").returns(
      mock("resource", stage: true)
    )
    @venv.create
    FileUtils.mkdir_p @dir/"bin"
    FileUtils.touch @dir/"bin/python"
    @venv.create
    FileUtils.rm @dir/"bin/python"
  end

  def test_pip_install_accepts_string
    @formula.expects(:system).returns(true).with do |*params|
      params.first == @dir/"bin/pip" && params.last == "foo"
    end
    @venv.pip_install "foo"
  end

  def test_pip_install_accepts_multiline_string
    @formula.expects(:system).returns(true).with do |*params|
      params.first == @dir/"bin/pip" && params[-2..-1] == ["foo", "bar"]
    end
    @venv.pip_install <<-EOS.undent
      foo
      bar
    EOS
  end

  def test_pip_install_accepts_array
    @formula.expects(:system).returns(true).with do |*params|
      params.first == @dir/"bin/pip" && params.last == "foo"
    end
    @formula.expects(:system).returns(true).with do |*params|
      params.first == @dir/"bin/pip" && params.last == "bar"
    end
    @venv.pip_install ["foo", "bar"]
  end

  def test_pip_install_accepts_resource
    res = Resource.new "test"
    res.expects(:stage).yields(nil)
    @formula.expects(:system).returns(true).with do |*params|
      params.first == @dir/"bin/pip" && params.last == Pathname.pwd
    end
    @venv.pip_install res
  end

  def test_pip_install_and_link_links_scripts
    bin = @dir/"bin"
    bin.mkpath
    dest = @formula.bin

    refute_predicate bin/"kilroy", :exist?
    refute_predicate dest/"kilroy", :exist?

    FileUtils.touch bin/"irrelevant"
    bin_before = Dir[bin/"*"]
    FileUtils.touch bin/"kilroy"
    bin_after = Dir[bin/"*"]
    @venv.expects(:pip_install).with("foo")
    Dir.expects(:[]).twice.returns(bin_before, bin_after)

    @venv.pip_install_and_link "foo"

    assert_predicate bin/"kilroy", :exist?
    assert_predicate dest/"kilroy", :exist?
    assert_predicate dest/"kilroy", :symlink?
    assert_equal((bin/"kilroy").realpath, (dest/"kilroy").realpath)
    refute_predicate dest/"irrelevant", :exist?
  end
end

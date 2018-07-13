require "fileutils"
require "etc"

# Homebrew extends Ruby's `FileUtils` to make our code more readable.
# @see https://ruby-doc.org/stdlib-2.0.0/libdoc/fileutils/rdoc/FileUtils.html Ruby's FileUtils API
module FileUtils
  # @private
  alias old_mkdir mkdir

  # A version of mkdir that also changes to that folder in a block.
  def mkdir(name, mode: nil, noop: nil, verbose: nil, &_block)
    result = mkdir_p(name, mode: mode, noop: noop, verbose: verbose)
    return result unless block_given?
    chdir name do
      yield
    end
  end
  module_function :mkdir

  # Run `scons` using a Homebrew-installed version rather than whatever is in the `PATH`.
  def scons(*args)
    system Formulary.factory("scons").opt_bin/"scons", *args
  end

  # Run `make` 3.81 or newer.
  # Uses the system make on Leopard and newer, and the
  # path to the actually-installed make on Tiger or older.
  def make(*args)
    if Utils.popen_read("/usr/bin/make", "--version").match(/Make (\d\.\d+)/)[1] > "3.80"
      make_path = "/usr/bin/make"
    else
      make = Formula["make"].opt_bin/"make"
      make_path = make.exist? ? make.to_s : (Formula["make"].opt_bin/"gmake").to_s
    end

    if superenv?
      make_name = File.basename(make_path)
      with_env(HOMEBREW_MAKE: make_name) do
        system "make", *args
      end
    else
      system make_path, *args
    end
  end

  if method_defined?(:ruby)
    # @private
    alias old_ruby ruby
  end

  # Run the `ruby` Homebrew is using rather than whatever is in the `PATH`.
  def ruby(*args)
    system RUBY_PATH, *args
  end

  # Run `xcodebuild` without Homebrew's compiler environment variables set.
  def xcodebuild(*args)
    removed = ENV.remove_cc_etc
    system "xcodebuild", *args
  ensure
    ENV.update(removed)
  end
end

require "language/python"

class PythonRequirement < Requirement
  fatal true
  default_formula "python"

  satisfy build_env: false do
    python = which_python
    next unless python
    version = python_short_version
    next unless version
    # Always use Python 2.7 for consistency on older versions of Mac OS X.
    version == Version.create("2.7")
  end

  env do
    short_version = python_short_version

    if !system_python? && short_version == Version.create("2.7")
      ENV.prepend_path "PATH", which_python.dirname
    # Homebrew Python should take precedence over older Pythons in the PATH
    elsif short_version != Version.create("2.7")
      ENV.prepend_path "PATH", Formula["python"].opt_bin
    end

    ENV["PYTHONPATH"] = "#{HOMEBREW_PREFIX}/lib/python#{short_version}/site-packages"
  end

  def python_short_version
    @short_version ||= Language::Python.major_minor_version which_python
  end

  def which_python
    python = which python_binary
    return unless python
    python_executable = Pathname.new Utils.popen_read(python, "-c", "import sys; print(sys.executable)").strip
    return python_executable if OS.mac?

    short_version = Language::Python.major_minor_version python_executable
    python_config = Pathname.new python_executable/"../python#{short_version}-config"
    return unless python_config.executable?

    python_prefix = Pathname.new Utils.popen_read(python_config, "--prefix").strip
    return unless (python_prefix/"include/python#{short_version}/Python.h").readable?

    # some versions of python-config don't include a --configdir option,
    # so have to do two checks for libpython
    libpython = "libpython#{short_version}.so"
    python_configdir = Utils.popen_read(python_config, "--configdir")
    return python_executable if $?.zero? && (Pathname.new(python_configdir.strip)/libpython).readable?
    exec_prefix = Pathname.new Utils.popen_read(python_config, "--exec-prefix").strip
    return python_executable if (exec_prefix/"lib/"/libpython).readable?
  end

  def system_python
    "/usr/bin/#{python_binary}"
  end

  def system_python?
    system_python == which_python.to_s
  end

  def python_binary
    "python"
  end

  # Deprecated
  alias to_s python_binary
end

class Python3Requirement < PythonRequirement
  fatal true
  default_formula "python3"

  satisfy(build_env: false) { which_python }

  def python_binary
    "python3"
  end
end

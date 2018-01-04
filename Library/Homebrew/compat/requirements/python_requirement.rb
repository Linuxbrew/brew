require "language/python"

class PythonRequirement < Requirement
  fatal true
  default_formula "python"

  satisfy build_env: false do
    python = which_python
    next unless python
    next unless short_version
    # Always use Python 2.7 for consistency on older versions of Mac OS X.
    short_version == Version.create("2.7")
  end

  env do
    if !system_python? && short_version == Version.create("2.7")
      ENV.prepend_path "PATH", which_python.dirname
    end

    # Homebrew Python should take precedence over other Pythons in the PATH
    ENV.prepend_path "PATH", Formula["python"].opt_bin
    ENV.prepend_path "PATH", Formula["python"].opt_libexec/"bin"

    if system_python?
      ENV["PYTHONPATH"] = "#{HOMEBREW_PREFIX}/lib/python#{short_version}/site-packages"
    end
  end

  private

  def short_version
    @short_version ||= Language::Python.major_minor_version which_python
  end

  def which_python
    @python_executable ||= find_python
  end

  def find_python
    python = which python_binary
    return unless python
    python_executable = Pathname.new Utils.popen_read(python, "-c", "import sys; print(sys.executable)").strip
    return python_executable if OS.mac? || devel_installed?(python_executable)
  end

  def devel_installed?(python_executable)
    short_version = Language::Python.major_minor_version python_executable
    python_prefix = Pathname.new Utils.popen_read(python_executable, "-c", "import sys; print(sys.#{sys_prefix_name})").strip
    (python_prefix/"include/python#{short_version}#{include_suffix}/Python.h").readable?
  end

  def system_python
    "/usr/bin/#{python_binary}"
  end

  def system_python?
    system_python == which_python.to_s
  end

  def python_binary
    "python2.7"
  end

  def sys_prefix_name
    "prefix"
  end

  def include_suffix
    ""
  end

  # Deprecated
  alias to_s python_binary
end

class Python3Requirement < PythonRequirement
  fatal true
  default_formula "python3"

  satisfy(build_env: false) { which_python }

  private

  def python_binary
    "python3"
  end

  def sys_prefix_name
    "base_prefix"
  end

  def include_suffix
    "m"
  end
end

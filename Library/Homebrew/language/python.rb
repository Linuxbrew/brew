require "utils"
require "language/python_virtualenv_constants"

module Language
  module Python
    def self.major_minor_version(python)
      version = /\d\.\d/.match `#{python} --version 2>&1`
      return unless version
      Version.create(version.to_s)
    end

    def self.homebrew_site_packages(version = "2.7")
      HOMEBREW_PREFIX/"lib/python#{version}/site-packages"
    end

    def self.each_python(build, &block)
      original_pythonpath = ENV["PYTHONPATH"]
      ["python", "python3"].each do |python|
        next if build.without? python
        version = major_minor_version python
        ENV["PYTHONPATH"] = if Formulary.factory(python).installed?
          nil
        else
          homebrew_site_packages(version)
        end
        block.call python, version if block
      end
      ENV["PYTHONPATH"] = original_pythonpath
    end

    def self.reads_brewed_pth_files?(python)
      version = major_minor_version python
      return unless homebrew_site_packages(version).directory?
      return unless homebrew_site_packages(version).writable_real?
      probe_file = homebrew_site_packages(version)/"homebrew-pth-probe.pth"
      begin
        probe_file.atomic_write("import site; site.homebrew_was_here = True")
        quiet_system python, "-c", "import site; assert(site.homebrew_was_here)"
      ensure
        probe_file.unlink if probe_file.exist?
      end
    end

    def self.user_site_packages(python)
      Pathname.new(`#{python} -c "import site; print(site.getusersitepackages())"`.chomp)
    end

    def self.in_sys_path?(python, path)
      script = <<-EOS.undent
        import os, sys
        [os.path.realpath(p) for p in sys.path].index(os.path.realpath("#{path}"))
      EOS
      quiet_system python, "-c", script
    end

    # deprecated; use system "python", *setup_install_args(prefix) instead
    def self.setup_install(python, prefix, *args)
      opoo <<-EOS.undent
        Language::Python.setup_install is deprecated.
        If you are a formula author, please use
          system "python", *Language::Python.setup_install_args(prefix)
        instead.
      EOS

      # force-import setuptools, which monkey-patches distutils, to make
      # sure that we always call a setuptools setup.py. trick borrowed from pip:
      # https://github.com/pypa/pip/blob/043af83/pip/req/req_install.py#L743-L780
      shim = <<-EOS.undent
        import setuptools, tokenize
        __file__ = 'setup.py'
        exec(compile(getattr(tokenize, 'open', open)(__file__).read()
          .replace('\\r\\n', '\\n'), __file__, 'exec'))
      EOS
      args += %w[--single-version-externally-managed --record=installed.txt]
      args << "--prefix=#{prefix}"
      system python, "-c", shim, "install", *args
    end

    def self.setup_install_args(prefix)
      shim = <<-EOS.undent
        import setuptools, tokenize
        __file__ = 'setup.py'
        exec(compile(getattr(tokenize, 'open', open)(__file__).read()
          .replace('\\r\\n', '\\n'), __file__, 'exec'))
      EOS
      %W[
        -c
        #{shim}
        --no-user-cfg
        install
        --prefix=#{prefix}
        --single-version-externally-managed
        --record=installed.txt
      ]
    end

    def self.package_available?(python, module_name)
      quiet_system python, "-c", "import #{module_name}"
    end

    # Mixin module for {Formula} adding virtualenv support features.
    module Virtualenv
      def self.included(base)
        base.class_eval do
          resource "homebrew-virtualenv" do
            url PYTHON_VIRTUALENV_URL
            sha256 PYTHON_VIRTUALENV_SHA256
          end
        end
      end

      # Instantiates, creates, and yields a {Virtualenv} object for use from
      # Formula#install, which provides helper methods for instantiating and
      # installing packages into a Python virtualenv.
      # @param venv_root [Pathname, String] the path to the root of the virtualenv
      #   (often `libexec/"venv"`)
      # @param python [String] which interpreter to use (e.g. "python"
      #   or "python3")
      # @param formula [Formula] the active Formula
      # @return [Virtualenv] a {Virtualenv} instance
      def virtualenv_create(venv_root, python = "python", formula = self)
        ENV.refurbish_args
        venv = Virtualenv.new formula, venv_root, python
        venv.create

        # Find any Python bindings provided by recursive dependencies
        formula_deps = formula.recursive_dependencies
        xy = Language::Python.major_minor_version python
        pth_contents = formula_deps.map do |d|
          next if d.build?
          dep_site_packages = Formula[d.name].opt_lib/"python#{xy}/site-packages"
          next unless dep_site_packages.exist?
          "import site; site.addsitedir('#{dep_site_packages}')\n"
        end.compact
        unless pth_contents.empty?
          (venv_root/"lib/python#{xy}/site-packages/homebrew_deps.pth").write pth_contents.join
        end

        venv
      end

      # Returns true if a formula option for the specified python is currently
      # active or if the specified python is required by the formula. Valid
      # inputs are "python", "python3", :python, and :python3. Note that
      # "with-python", "without-python", "with-python3", and "without-python3"
      # formula options are handled correctly even if not associated with any
      # corresponding depends_on statement.
      # @api private
      def needs_python?(python)
        return true if build.with?(python)
        (requirements.to_a | deps).any? { |r| r.name == python && r.required? }
      end

      # Helper method for the common case of installing a Python application.
      # Creates a virtualenv in `libexec`, installs all `resource`s defined
      # on the formula, and then installs the formula. An options hash may be
      # passed (e.g., :using => "python3") to override the default, guessed
      # formula preference for python or python3, or to resolve an ambiguous
      # case where it's not clear whether python or python3 should be the
      # default guess.
      def virtualenv_install_with_resources(options = {})
        python = options[:using]
        if python.nil?
          wanted = %w[python python3].select { |py| needs_python?(py) }
          raise FormulaAmbiguousPythonError, self if wanted.size > 1
          python = wanted.first || "python"
        end
        venv = virtualenv_create(libexec, python)
        venv.pip_install resources
        venv.pip_install_and_link buildpath
        venv
      end

      # Convenience wrapper for creating and installing packages into Python
      # virtualenvs.
      class Virtualenv
        # Initializes a Virtualenv instance. This does not create the virtualenv
        # on disk; {#create} does that.
        # @param formula [Formula] the active Formula
        # @param venv_root [Pathname, String] the path to the root of the
        #   virtualenv
        # @param python [String] which interpreter to use; i.e. "python" or
        #   "python3"
        def initialize(formula, venv_root, python)
          @formula = formula
          @venv_root = Pathname.new(venv_root)
          @python = python
        end

        # Obtains a copy of the virtualenv library and creates a new virtualenv
        # on disk.
        # @return [void]
        def create
          return if (@venv_root/"bin/python").exist?

          @formula.resource("homebrew-virtualenv").stage do |stage|
            old_pythonpath = ENV.delete "PYTHONPATH"
            begin
              xy = Language::Python.major_minor_version(@python)
              staging = Pathname.new(stage.staging.tmpdir)
              ENV.prepend_create_path "PYTHONPATH", staging/"target/lib/python#{xy}/site-packages"
              @formula.system @python, *Language::Python.setup_install_args(staging/"target")
              @formula.system @python, "-s", staging/"target/bin/virtualenv", "-p", @python, @venv_root
            ensure
              ENV["PYTHONPATH"] = old_pythonpath
            end
          end

          # Robustify symlinks to survive python3 patch upgrades
          @venv_root.find do |f|
            next unless f.symlink?
            next unless (rp = f.realpath.to_s).start_with? HOMEBREW_CELLAR
            python = rp.include?("python3") ? "python3" : "python"
            new_target = rp.sub %r{#{HOMEBREW_CELLAR}/#{python}/[^/]+}, Formula[python].opt_prefix
            f.unlink
            f.make_symlink new_target
          end

          Pathname.glob(@venv_root/"lib/python*/orig-prefix.txt").each do |prefix_file|
            prefix_path = prefix_file.read
            python = prefix_path.include?("python3") ? "python3" : "python"
            prefix_path.sub! %r{^#{HOMEBREW_CELLAR}/#{python}/[^/]+}, Formula[python].opt_prefix
            prefix_file.atomic_write prefix_path
          end
        end

        # Installs packages represented by `targets` into the virtualenv.
        # @param targets [String, Pathname, Resource,
        #   Array<String, Pathname, Resource>] (A) token(s) passed to pip
        #   representing the object to be installed. This can be a directory
        #   containing a setup.py, a {Resource} which will be staged and
        #   installed, or a package identifier to be fetched from PyPI.
        #   Multiline strings are allowed and treated as though they represent
        #   the contents of a `requirements.txt`.
        # @return [void]
        def pip_install(targets)
          targets = [targets] unless targets.is_a? Array
          targets.each do |t|
            if t.respond_to? :stage
              next if t.name == "homebrew-virtualenv"
              t.stage { do_install Pathname.pwd }
            else
              t = t.lines.map(&:strip) if t.respond_to?(:lines) && t =~ /\n/
              do_install t
            end
          end
        end

        # Installs packages represented by `targets` into the virtualenv, but
        #   unlike {#pip_install} also links new scripts to {Formula#bin}.
        # @param (see #pip_install)
        # @return (see #pip_install)
        def pip_install_and_link(targets)
          bin_before = Dir[@venv_root/"bin/*"].to_set

          pip_install(targets)

          bin_after = Dir[@venv_root/"bin/*"].to_set
          bin_to_link = (bin_after - bin_before).to_a
          @formula.bin.install_symlink(bin_to_link)
        end

        private

        def do_install(targets)
          targets = [targets] unless targets.is_a? Array
          @formula.system @venv_root/"bin/pip", "install",
                          "-v", "--no-deps", "--no-binary", ":all:",
                          "--ignore-installed", *targets
        end
      end # class Virtualenv
    end # module Virtualenv
  end # module Python
end # module Language

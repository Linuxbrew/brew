require "os/mac/linkage_checker"

module FormulaCellarChecks
  def check_shadowed_headers
    return if ["libtool", "subversion", "berkeley-db"].any? do |formula_name|
      formula.name.start_with?(formula_name)
    end

    return if formula.name =~ /^php(@?\d+\.?\d*?)?$/

    return if MacOS.version < :mavericks && formula.name.start_with?("postgresql")
    return if MacOS.version < :yosemite  && formula.name.start_with?("memcached")

    return if formula.keg_only? || !formula.include.directory?

    files  = relative_glob(formula.include, "**/*.h")
    files &= relative_glob("#{MacOS.sdk_path}/usr/include", "**/*.h")
    files.map! { |p| File.join(formula.include, p) }

    return if files.empty?

    <<-EOS.undent
      Header files that shadow system header files were installed to "#{formula.include}"
      The offending files are:
        #{files * "\n        "}
    EOS
  end

  def check_openssl_links
    return unless formula.prefix.directory?
    keg = Keg.new(formula.prefix)
    system_openssl = keg.mach_o_files.select do |obj|
      dlls = obj.dynamically_linked_libraries
      dlls.any? { |dll| %r{/usr/lib/lib(crypto|ssl|tls)\..*dylib}.match dll }
    end
    return if system_openssl.empty?

    <<-EOS.undent
      object files were linked against system openssl
      These object files were linked against the deprecated system OpenSSL or
      the system's private LibreSSL.
      Adding `depends_on "openssl"` to the formula may help.
        #{system_openssl * "\n        "}
    EOS
  end

  def check_python_framework_links(lib)
    python_modules = Pathname.glob lib/"python*/site-packages/**/*.so"
    framework_links = python_modules.select do |obj|
      dlls = obj.dynamically_linked_libraries
      dlls.any? { |dll| /Python\.framework/.match dll }
    end
    return if framework_links.empty?

    <<-EOS.undent
      python modules have explicit framework links
      These python extension modules were linked directly to a Python
      framework binary. They should be linked with -undefined dynamic_lookup
      instead of -lpython or -framework Python.
        #{framework_links * "\n        "}
    EOS
  end

  def check_linkage
    return unless formula.prefix.directory?
    keg = Keg.new(formula.prefix)
    checker = LinkageChecker.new(keg, formula)

    return unless checker.broken_dylibs?
    output = <<-EOS.undent
      #{formula} has broken dynamic library links:
        #{checker.broken_dylibs.to_a * "\n  "}
    EOS
    tab = Tab.for_keg(keg)
    if tab.poured_from_bottle
      output += <<-EOS.undent
        Rebuild this from source with:
          brew reinstall --build-from-source #{formula}
        If that's successful, file an issue#{formula.tap ? " here:\n  #{formula.tap.issues_url}" : "."}
      EOS
    end
    problem_if_output output
  end

  def audit_installed
    generic_audit_installed
    problem_if_output(check_shadowed_headers)
    problem_if_output(check_openssl_links)
    problem_if_output(check_python_framework_links(formula.lib))
    check_linkage
  end
end

require "requirement"

class AprRequirement < Requirement
  fatal true
  default_formula "apr-util"

  # APR shipped in Tiger is too old, but Leopard+ is usable.
  # The *-config scripts were removed in Sierra, which is widely breaking.
  satisfy(build_env: false) do
    MacOS.version > :leopard && MacOS.version < :sierra &&
      MacOS::CLT.installed? || Formula["apr-util"].installed?
  end

  env do
    ENV.prepend_path "PATH", Formula["apr-util"].opt_bin
    ENV.prepend_path "PATH", Formula["apr"].opt_bin
    ENV.prepend_path "PKG_CONFIG_PATH", "#{Formula["apr"].opt_libexec}/lib/pkgconfig"
    ENV.prepend_path "PKG_CONFIG_PATH", "#{Formula["apr-util"].opt_libexec}/lib/pkgconfig"
  end

  def to_dependency
    super.extend Module.new {
      def tags
        super - [:build]
      end
    }
  end
end

class Formula
  module Compat
    # Run `scons` using a Homebrew-installed version rather than whatever is
    # in the `PATH`.
    # TODO: deprecate
    def scons(*args)
      odeprecated("scons", 'system "scons"')

      system Formulary.factory("scons").opt_bin/"scons", *args
    end

    # Run `make` 3.81 or newer.
    # Uses the system make on Leopard and newer, and the
    # path to the actually-installed make on Tiger or older.
    # TODO: deprecate
    def make(*args)
      odeprecated("make", 'system "make"')

      if Utils.popen_read("/usr/bin/make", "--version")
              .match(/Make (\d\.\d+)/)[1] > "3.80"
        make_path = "/usr/bin/make"
      else
        make = Formula["make"].opt_bin/"make"
        make_path = if make.exist?
          make.to_s
        else
          (Formula["make"].opt_bin/"gmake").to_s
        end
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
  end

  prepend Compat
end

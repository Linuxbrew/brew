require "keg"
require "language/python"
require "formula"
require "version"
require "development_tools"
require "utils/shell"

module Homebrew
  module Diagnostic
    def self.missing_deps(ff, hide = nil)
      missing = {}
      ff.each do |f|
        missing_dependencies = f.missing_dependencies(hide: hide)
        next if missing_dependencies.empty?

        yield f.full_name, missing_dependencies if block_given?
        missing[f.full_name] = missing_dependencies
      end
      missing
    end

    class Volumes
      def initialize
        @volumes = get_mounts
      end

      def which(path)
        vols = get_mounts path

        # no volume found
        return -1 if vols.empty?

        vol_index = @volumes.index(vols[0])
        # volume not found in volume list
        return -1 if vol_index.nil?

        vol_index
      end

      def get_mounts(path = nil)
        vols = []
        # get the volume of path, if path is nil returns all volumes

        args = %w[/bin/df -P]
        args << path if path

        Utils.popen_read(*args) do |io|
          io.each_line do |line|
            case line.chomp
              # regex matches: /dev/disk0s2   489562928 440803616  48247312    91%    /
            when /^.+\s+[0-9]+\s+[0-9]+\s+[0-9]+\s+[0-9]{1,3}%\s+(.+)/
              vols << Regexp.last_match(1)
            end
          end
        end
        vols
      end
    end

    class Checks
      ############# HELPERS
      # Finds files in HOMEBREW_PREFIX *and* /usr/local.
      # Specify paths relative to a prefix eg. "include/foo.h".
      # Sets @found for your convenience.
      def find_relative_paths(*relative_paths)
        @found = [HOMEBREW_PREFIX, "/usr/local"].uniq.reduce([]) do |found, prefix|
          found + relative_paths.map { |f| File.join(prefix, f) }.select { |f| File.exist? f }
        end
      end

      def inject_file_list(list, string)
        list.reduce(string) { |acc, elem| acc << "  #{elem}\n" }
      end
      ############# END HELPERS

      def fatal_install_checks
        %w[
          check_access_directories
        ].freeze
      end

      def development_tools_checks
        %w[
          check_for_installed_developer_tools
        ].freeze
      end

      def fatal_development_tools_checks
        %w[
        ].freeze
      end

      def build_error_checks
        (development_tools_checks + %w[
        ]).freeze
      end

      def check_for_installed_developer_tools
        return if DevelopmentTools.installed?

        <<~EOS
          No developer tools installed.
          #{DevelopmentTools.installation_instructions}
        EOS
      end

      def check_build_from_source
        return unless ENV["HOMEBREW_BUILD_FROM_SOURCE"]

        <<~EOS
          You have HOMEBREW_BUILD_FROM_SOURCE set. This environment variable is
          intended for use by Homebrew developers. If you are encountering errors,
          please try unsetting this. Please do not file issues if you encounter
          errors when using this environment variable.
        EOS
      end

      # Anaconda installs multiple system & brew dupes, including OpenSSL, Python,
      # sqlite, libpng, Qt, etc. Regularly breaks compile on Vim, MacVim and others.
      # Is flagged as part of the *-config script checks below, but people seem
      # to ignore those as warnings rather than extremely likely breakage.
      def check_for_anaconda
        return unless which("anaconda")
        return unless which("python")

        anaconda_directory = which("anaconda").realpath.dirname
        python_binary = Utils.popen_read(which("python"), "-c", "import sys; sys.stdout.write(sys.executable)")
        python_directory = Pathname.new(python_binary).realpath.dirname

        # Only warn if Python lives with Anaconda, since is most problematic case.
        return unless python_directory == anaconda_directory

        <<~EOS
          Anaconda is known to frequently break Homebrew builds, including Vim and
          MacVim, due to bundling many duplicates of system and Homebrew-available
          tools.

          If you encounter a build failure please temporarily remove Anaconda
          from your $PATH and attempt the build again prior to reporting the
          failure to us. Thanks!
        EOS
      end

      def __check_stray_files(dir, pattern, white_list, message)
        return unless File.directory?(dir)

        files = Dir.chdir(dir) do
          (Dir.glob(pattern) - Dir.glob(white_list))
            .select { |f| File.file?(f) && !File.symlink?(f) }
            .map { |f| File.join(dir, f) }
        end
        return if files.empty?

        inject_file_list(files.sort, message)
      end

      def check_for_stray_dylibs
        # Dylibs which are generally OK should be added to this list,
        # with a short description of the software they come with.
        white_list = [
          "libfuse.2.dylib", # MacFuse
          "libfuse_ino64.2.dylib", # MacFuse
          "libmacfuse_i32.2.dylib", # OSXFuse MacFuse compatibility layer
          "libmacfuse_i64.2.dylib", # OSXFuse MacFuse compatibility layer
          "libosxfuse_i32.2.dylib", # OSXFuse
          "libosxfuse_i64.2.dylib", # OSXFuse
          "libosxfuse.2.dylib", # OSXFuse
          "libTrAPI.dylib", # TrAPI/Endpoint Security VPN
          "libntfs-3g.*.dylib", # NTFS-3G
          "libntfs.*.dylib", # NTFS-3G
          "libublio.*.dylib", # NTFS-3G
          "libUFSDNTFS.dylib", # Paragon NTFS
          "libUFSDExtFS.dylib", # Paragon ExtFS
          "libecomlodr.dylib", # Symantec Endpoint Protection
          "libsymsea*.dylib", # Symantec Endpoint Protection
          "sentinel.dylib", # SentinelOne
          "sentinel-*.dylib", # SentinelOne
        ]

        __check_stray_files "/usr/local/lib", "*.dylib", white_list, <<~EOS
          Unbrewed dylibs were found in /usr/local/lib.
          If you didn't put them there on purpose they could cause problems when
          building Homebrew formulae, and may need to be deleted.

          Unexpected dylibs:
        EOS
      end

      def check_for_stray_static_libs
        # Static libs which are generally OK should be added to this list,
        # with a short description of the software they come with.
        white_list = [
          "libsecurity_agent_client.a", # OS X 10.8.2 Supplemental Update
          "libsecurity_agent_server.a", # OS X 10.8.2 Supplemental Update
          "libntfs-3g.a", # NTFS-3G
          "libntfs.a", # NTFS-3G
          "libublio.a", # NTFS-3G
          "libappfirewall.a", # Symantec Endpoint Protection
          "libautoblock.a", # Symantec Endpoint Protection
          "libautosetup.a", # Symantec Endpoint Protection
          "libconnectionsclient.a", # Symantec Endpoint Protection
          "liblocationawareness.a", # Symantec Endpoint Protection
          "libpersonalfirewall.a", # Symantec Endpoint Protection
          "libtrustedcomponents.a", # Symantec Endpoint Protection
        ]

        __check_stray_files "/usr/local/lib", "*.a", white_list, <<~EOS
          Unbrewed static libraries were found in /usr/local/lib.
          If you didn't put them there on purpose they could cause problems when
          building Homebrew formulae, and may need to be deleted.

          Unexpected static libraries:
        EOS
      end

      def check_for_stray_pcs
        # Package-config files which are generally OK should be added to this list,
        # with a short description of the software they come with.
        white_list = [
          "fuse.pc", # OSXFuse/MacFuse
          "macfuse.pc", # OSXFuse MacFuse compatibility layer
          "osxfuse.pc", # OSXFuse
          "libntfs-3g.pc", # NTFS-3G
          "libublio.pc", # NTFS-3G
        ]

        __check_stray_files "/usr/local/lib/pkgconfig", "*.pc", white_list, <<~EOS
          Unbrewed .pc files were found in /usr/local/lib/pkgconfig.
          If you didn't put them there on purpose they could cause problems when
          building Homebrew formulae, and may need to be deleted.

          Unexpected .pc files:
        EOS
      end

      def check_for_stray_las
        white_list = [
          "libfuse.la", # MacFuse
          "libfuse_ino64.la", # MacFuse
          "libosxfuse_i32.la", # OSXFuse
          "libosxfuse_i64.la", # OSXFuse
          "libosxfuse.la", # OSXFuse
          "libntfs-3g.la", # NTFS-3G
          "libntfs.la", # NTFS-3G
          "libublio.la", # NTFS-3G
        ]

        __check_stray_files "/usr/local/lib", "*.la", white_list, <<~EOS
          Unbrewed .la files were found in /usr/local/lib.
          If you didn't put them there on purpose they could cause problems when
          building Homebrew formulae, and may need to be deleted.

          Unexpected .la files:
        EOS
      end

      def check_for_stray_headers
        white_list = [
          "fuse.h", # MacFuse
          "fuse/**/*.h", # MacFuse
          "macfuse/**/*.h", # OSXFuse MacFuse compatibility layer
          "osxfuse/**/*.h", # OSXFuse
          "ntfs/**/*.h", # NTFS-3G
          "ntfs-3g/**/*.h", # NTFS-3G
        ]

        __check_stray_files "/usr/local/include", "**/*.h", white_list, <<~EOS
          Unbrewed header files were found in /usr/local/include.
          If you didn't put them there on purpose they could cause problems when
          building Homebrew formulae, and may need to be deleted.

          Unexpected header files:
        EOS
      end

      def check_for_broken_symlinks
        broken_symlinks = []

        Keg::MUST_EXIST_SUBDIRECTORIES.each do |d|
          next unless d.directory?

          d.find do |path|
            if path.symlink? && !path.resolved_path_exists?
              broken_symlinks << path
            end
          end
        end
        return if broken_symlinks.empty?

        inject_file_list broken_symlinks, <<~EOS
          Broken symlinks were found. Remove them with `brew prune`:
        EOS
      end

      def check_tmpdir_sticky_bit
        world_writable = HOMEBREW_TEMP.stat.mode & 0777 == 0777
        return if !world_writable || HOMEBREW_TEMP.sticky?

        <<~EOS
          #{HOMEBREW_TEMP} is world-writable but does not have the sticky bit set.
          Please execute `sudo chmod +t #{HOMEBREW_TEMP}` in your Terminal.
        EOS
      end

      def check_exist_directories
        not_exist_dirs = Keg::MUST_EXIST_DIRECTORIES.reject(&:exist?)
        return if not_exist_dirs.empty?

        <<~EOS
          The following directories do not exist:
          #{not_exist_dirs.join("\n")}

          You should create these directories and change their ownership to your account.
            sudo mkdir -p #{not_exist_dirs.join(" ")}
            sudo chown -R $(whoami) #{not_exist_dirs.join(" ")}
        EOS
      end

      def check_access_directories
        not_writable_dirs =
          Keg::MUST_BE_WRITABLE_DIRECTORIES.select(&:exist?)
                                           .reject(&:writable_real?)
        return if not_writable_dirs.empty?

        <<~EOS
          The following directories are not writable by your user:
          #{not_writable_dirs.join("\n")}

          You should change the ownership of these directories to your user.
            sudo chown -R $(whoami) #{not_writable_dirs.join(" ")}
        EOS
      end

      def check_multiple_cellars
        return if HOMEBREW_PREFIX.to_s == HOMEBREW_REPOSITORY.to_s
        return unless (HOMEBREW_REPOSITORY/"Cellar").exist?
        return unless (HOMEBREW_PREFIX/"Cellar").exist?

        <<~EOS
          You have multiple Cellars.
          You should delete #{HOMEBREW_REPOSITORY}/Cellar:
            rm -rf #{HOMEBREW_REPOSITORY}/Cellar
        EOS
      end

      def check_user_path_1
        @seen_prefix_bin = false
        @seen_prefix_sbin = false

        message = ""

        paths.each do |p|
          case p
          when "/usr/bin"
            unless @seen_prefix_bin
              # only show the doctor message if there are any conflicts
              # rationale: a default install should not trigger any brew doctor messages
              conflicts = Dir["#{HOMEBREW_PREFIX}/bin/*"]
                          .map { |fn| File.basename fn }
                          .select { |bn| File.exist? "/usr/bin/#{bn}" }

              unless conflicts.empty?
                message = inject_file_list conflicts, <<~EOS
                  /usr/bin occurs before #{HOMEBREW_PREFIX}/bin
                  This means that system-provided programs will be used instead of those
                  provided by Homebrew. The following tools exist at both paths:
                EOS

                message += <<~EOS

                  Consider setting your PATH so that #{HOMEBREW_PREFIX}/bin
                  occurs before /usr/bin. Here is a one-liner:
                    #{Utils::Shell.prepend_path_in_profile("#{HOMEBREW_PREFIX}/bin")}
                EOS
              end
            end
          when "#{HOMEBREW_PREFIX}/bin"
            @seen_prefix_bin = true
          when "#{HOMEBREW_PREFIX}/sbin"
            @seen_prefix_sbin = true
          end
        end

        message unless message.empty?
      end

      def check_user_path_2
        return if @seen_prefix_bin

        <<~EOS
          Homebrew's bin was not found in your PATH.
          Consider setting the PATH for example like so
            #{Utils::Shell.prepend_path_in_profile("#{HOMEBREW_PREFIX}/bin")}
        EOS
      end

      def check_user_path_3
        return if @seen_prefix_sbin

        # Don't complain about sbin not being in the path if it doesn't exist
        sbin = HOMEBREW_PREFIX/"sbin"
        return unless sbin.directory? && !sbin.children.empty?

        <<~EOS
          Homebrew's sbin was not found in your PATH but you have installed
          formulae that put executables in #{HOMEBREW_PREFIX}/sbin.
          Consider setting the PATH for example like so
            #{Utils::Shell.prepend_path_in_profile("#{HOMEBREW_PREFIX}/sbin")}
        EOS
      end

      def check_for_config_scripts
        return unless HOMEBREW_CELLAR.exist?

        real_cellar = HOMEBREW_CELLAR.realpath

        scripts = []

        whitelist = %W[
          /usr/bin /usr/sbin
          /usr/X11/bin /usr/X11R6/bin /opt/X11/bin
          #{HOMEBREW_PREFIX}/bin #{HOMEBREW_PREFIX}/sbin
          /Applications/Server.app/Contents/ServerRoot/usr/bin
          /Applications/Server.app/Contents/ServerRoot/usr/sbin
        ].map(&:downcase)

        paths.each do |p|
          next if whitelist.include?(p.downcase) || !File.directory?(p)

          realpath = Pathname.new(p).realpath.to_s
          next if realpath.start_with?(real_cellar.to_s, HOMEBREW_CELLAR.to_s)

          scripts += Dir.chdir(p) { Dir["*-config"] }.map { |c| File.join(p, c) }
        end

        return if scripts.empty?

        inject_file_list scripts, <<~EOS
          "config" scripts exist outside your system or Homebrew directories.
          `./configure` scripts often look for *-config scripts to determine if
          software packages are installed, and what additional flags to use when
          compiling and linking.

          Having additional scripts in your path can confuse software installed via
          Homebrew if the config script overrides a system or Homebrew provided
          script of the same name. We found the following "config" scripts:
        EOS
      end

      def check_ld_vars
        ld_vars = ENV.keys.grep(/^(|DY)LD_/)
        return if ld_vars.empty?

        values = ld_vars.map { |var| "#{var}: #{ENV.fetch(var)}" }
        message = inject_file_list values, <<~EOS
          Setting DYLD_* or LD_* variables can break dynamic linking.
          Set variables:
        EOS

        if ld_vars.include? "DYLD_INSERT_LIBRARIES"
          message += <<~EOS

            Setting DYLD_INSERT_LIBRARIES can cause Go builds to fail.
            Having this set is common if you use this software:
              #{Formatter.url("https://asepsis.binaryage.com/")}
          EOS
        end

        message
      end

      def check_for_symlinked_cellar
        return unless HOMEBREW_CELLAR.exist?
        return unless HOMEBREW_CELLAR.symlink?

        <<~EOS
          Symlinked Cellars can cause problems.
          Your Homebrew Cellar is a symlink: #{HOMEBREW_CELLAR}
                          which resolves to: #{HOMEBREW_CELLAR.realpath}

          The recommended Homebrew installations are either:
          (A) Have Cellar be a real directory inside of your HOMEBREW_PREFIX
          (B) Symlink "bin/brew" into your prefix, but don't symlink "Cellar".

          Older installations of Homebrew may have created a symlinked Cellar, but this can
          cause problems when two formula install to locations that are mapped on top of each
          other during the linking step.
        EOS
      end

      def check_git_version
        # System Git version on macOS Sierra.
        minimum_version = "2.14.3".freeze
        return unless Utils.git_available?
        return if Version.create(Utils.git_version) >= Version.create(minimum_version)

        git = Formula["git"]
        git_upgrade_cmd = git.any_version_installed? ? "upgrade" : "install"
        <<~EOS
          An outdated version (#{Utils.git_version}) of Git was detected in your PATH.
          Git #{minimum_version} or newer is required for Homebrew.
          Please upgrade:
            brew #{git_upgrade_cmd} git
        EOS
      end

      def check_for_git
        return if Utils.git_available?

        <<~EOS
          Git could not be found in your PATH.
          Homebrew uses Git for several internal functions, and some formulae use Git
          checkouts instead of stable tarballs. You may want to install Git:
            brew install git
        EOS
      end

      def check_git_newline_settings
        return unless Utils.git_available?

        autocrlf = HOMEBREW_REPOSITORY.cd { `git config --get core.autocrlf`.chomp }
        return unless autocrlf == "true"

        <<~EOS
          Suspicious Git newline settings found.

          The detected Git newline settings will cause checkout problems:
            core.autocrlf = #{autocrlf}

          If you are not routinely dealing with Windows-based projects,
          consider removing these by running:
            git config --global core.autocrlf input
        EOS
      end

      def check_brew_git_origin
        return if !Utils.git_available? || !(HOMEBREW_REPOSITORY/".git").exist?

        origin = HOMEBREW_REPOSITORY.git_origin

        if origin.nil?
          <<~EOS
            Missing Homebrew/brew git origin remote.

            Without a correctly configured origin, Homebrew won't update
            properly. You can solve this by adding the Homebrew remote:
              git -C "#{HOMEBREW_REPOSITORY}" remote add origin #{Formatter.url("https://github.com/Homebrew/brew.git")}
          EOS
        elsif origin !~ %r{Homebrew/brew(\.git|/)?$}
          <<~EOS
            Suspicious Homebrew/brew git origin remote found.

            With a non-standard origin, Homebrew won't pull updates from
            the main repository. The current git origin is:
              #{origin}

            Unless you have compelling reasons, consider setting the
            origin remote to point at the main repository by running:
              git -C "#{HOMEBREW_REPOSITORY}" remote set-url origin #{Formatter.url("https://github.com/Homebrew/brew.git")}
          EOS
        end
      end

      def check_coretap_git_origin
        coretap_path = CoreTap.instance.path
        return if !Utils.git_available? || !(coretap_path/".git").exist?

        origin = coretap_path.git_origin

        if origin.nil?
          <<~EOS
            Missing #{CoreTap.instance} git origin remote.

            Without a correctly configured origin, Homebrew won't update
            properly. You can solve this by adding the Homebrew remote:
              git -C "#{coretap_path}" remote add origin #{Formatter.url("https://github.com/Homebrew/homebrew-core.git")}
          EOS
        elsif origin !~ %r{Homebrew/homebrew-core(\.git|/)?$}
          return if ENV["CI"] && origin.include?("Homebrew/homebrew-test-bot")

          <<~EOS
            Suspicious #{CoreTap.instance} git origin remote found.

            With a non-standard origin, Homebrew won't pull updates from
            the main repository. The current git origin is:
              #{origin}

            Unless you have compelling reasons, consider setting the
            origin remote to point at the main repository by running:
              git -C "#{coretap_path}" remote set-url origin #{Formatter.url("https://github.com/Homebrew/homebrew-core.git")}
          EOS
        end

        return if ENV["CI"]

        branch = coretap_path.git_branch
        return if branch.nil? || branch =~ /master/

        <<~EOS
          Homebrew/homebrew-core is not on the master branch

          Check out the master branch by running:
            git -C "$(brew --repo homebrew/core)" checkout master
        EOS
      end

      def __check_linked_brew(f)
        f.installed_prefixes.each do |prefix|
          prefix.find do |src|
            next if src == prefix

            dst = HOMEBREW_PREFIX + src.relative_path_from(prefix)
            return true if dst.symlink? && src == dst.resolved_path
          end
        end

        false
      end

      def check_for_other_frameworks
        # Other frameworks that are known to cause problems when present
        frameworks_to_check = %w[
          expat.framework
          libexpat.framework
          libcurl.framework
        ]
        frameworks_found = frameworks_to_check
                           .map { |framework| "/Library/Frameworks/#{framework}" }
                           .select { |framework| File.exist? framework }
        return if frameworks_found.empty?

        inject_file_list frameworks_found, <<~EOS
          Some frameworks can be picked up by CMake's build system and likely
          cause the build to fail. To compile CMake, you may wish to move these
          out of the way:
        EOS
      end

      def check_tmpdir
        tmpdir = ENV["TMPDIR"]
        return if tmpdir.nil? || File.directory?(tmpdir)

        <<~EOS
          TMPDIR #{tmpdir.inspect} doesn't exist.
        EOS
      end

      def check_missing_deps
        return unless HOMEBREW_CELLAR.exist?

        missing = Set.new
        Homebrew::Diagnostic.missing_deps(Formula.installed).each_value do |deps|
          missing.merge(deps)
        end
        return if missing.empty?

        <<~EOS
          Some installed formulae are missing dependencies.
          You should `brew install` the missing dependencies:
            brew install #{missing.sort_by(&:full_name) * " "}

          Run `brew missing` for more details.
        EOS
      end

      def check_git_status
        return unless Utils.git_available?

        HOMEBREW_REPOSITORY.cd do
          return if `git status --untracked-files=all --porcelain -- Library/Homebrew/ 2>/dev/null`.chomp.empty?
        end

        <<~EOS
          You have uncommitted modifications to Homebrew
          If this is a surprise to you, then you should stash these modifications.
          Stashing returns Homebrew to a pristine state but can be undone
          should you later need to do so for some reason.
            cd #{HOMEBREW_LIBRARY} && git stash && git clean -d -f
        EOS
      end

      def check_for_bad_python_symlink
        return unless which "python"

        `python -V 2>&1` =~ /Python (\d+)\./
        # This won't be the right warning if we matched nothing at all
        return if Regexp.last_match(1).nil?
        return if Regexp.last_match(1) == "2"

        <<~EOS
          python is symlinked to python#{Regexp.last_match(1)}
          This will confuse build scripts and in general lead to subtle breakage.
        EOS
      end

      def check_for_non_prefixed_coreutils
        coreutils = Formula["coreutils"]
        return unless coreutils.any_version_installed?

        gnubin = %W[#{coreutils.opt_libexec}/gnubin #{coreutils.libexec}/gnubin]
        return if (paths & gnubin).empty?

        <<~EOS
          Putting non-prefixed coreutils in your path can cause gmp builds to fail.
        EOS
      rescue FormulaUnavailableError
        nil
      end

      def check_for_pydistutils_cfg_in_home
        return unless File.exist? "#{ENV["HOME"]}/.pydistutils.cfg"

        <<~EOS
          A .pydistutils.cfg file was found in $HOME, which may cause Python
          builds to fail. See:
            #{Formatter.url("https://bugs.python.org/issue6138")}
            #{Formatter.url("https://bugs.python.org/issue4655")}
        EOS
      end

      def check_for_unlinked_but_not_keg_only
        unlinked = Formula.racks.reject do |rack|
          if !(HOMEBREW_LINKED_KEGS/rack.basename).directory?
            begin
              Formulary.from_rack(rack).keg_only?
            rescue FormulaUnavailableError, TapFormulaAmbiguityError, TapFormulaWithOldnameAmbiguityError
              false
            end
          else
            true
          end
        end.map(&:basename)
        return if unlinked.empty?

        inject_file_list unlinked, <<~EOS
          You have unlinked kegs in your Cellar
          Leaving kegs unlinked can lead to build-trouble and cause brews that depend on
          those kegs to fail to run properly once built. Run `brew link` on these:
        EOS
      end

      def check_for_external_cmd_name_conflict
        cmds = Tap.cmd_directories.flat_map { |p| Dir["#{p}/brew-*"] }.uniq
        cmds = cmds.select { |cmd| File.file?(cmd) && File.executable?(cmd) }
        cmd_map = {}
        cmds.each do |cmd|
          cmd_name = File.basename(cmd, ".rb")
          cmd_map[cmd_name] ||= []
          cmd_map[cmd_name] << cmd
        end
        cmd_map.reject! { |_cmd_name, cmd_paths| cmd_paths.size == 1 }
        return if cmd_map.empty?

        if ENV["CI"] && cmd_map.keys.length == 1 &&
           cmd_map.keys.first == "brew-test-bot"
          return
        end

        message = "You have external commands with conflicting names.\n"
        cmd_map.each do |cmd_name, cmd_paths|
          message += inject_file_list cmd_paths, <<~EOS
            Found command `#{cmd_name}` in following places:
          EOS
        end

        message
      end

      def check_for_tap_ruby_files_locations
        bad_tap_files = {}
        Tap.each do |tap|
          unused_formula_dirs = tap.potential_formula_dirs - [tap.formula_dir]
          unused_formula_dirs.each do |dir|
            next unless dir.exist?

            dir.children.each do |path|
              next unless path.extname == ".rb"

              bad_tap_files[tap] ||= []
              bad_tap_files[tap] << path
            end
          end
        end
        return if bad_tap_files.empty?

        bad_tap_files.keys.map do |tap|
          <<~EOS
            Found Ruby file outside #{tap} tap formula directory
            (#{tap.formula_dir}):
              #{bad_tap_files[tap].join("\n  ")}
          EOS
        end.join("\n")
      end

      def all
        methods.map(&:to_s).grep(/^check_/)
      end
    end
  end
end

require "extend/os/diagnostic"

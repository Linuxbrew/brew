require "tempfile"

module UnpackStrategy
  class Dmg
    include UnpackStrategy

    module Bom
      DMG_METADATA = Set.new %w[
        .background
        .com.apple.timemachine.donotpresent
        .com.apple.timemachine.supported
        .DocumentRevisions-V100
        .DS_Store
        .fseventsd
        .MobileBackups
        .Spotlight-V100
        .TemporaryItems
        .Trashes
        .VolumeIcon.icns
      ].freeze
      private_constant :DMG_METADATA

      refine Pathname do
        def dmg_metadata?
          DMG_METADATA.include?(cleanpath.ascend.to_a.last.to_s)
        end

        # symlinks to system directories (commonly to /Applications)
        def system_dir_symlink?
          symlink? && MacOS.system_dir?(readlink)
        end

        def bom
          # rubocop:disable Style/AsciiComments
          # We need to use `find` here instead of Ruby in order to properly handle
          # file names containing special characters, such as “e” + “´” vs. “é”.
          # rubocop:enable Style/AsciiComments
          system_command("find", args: [".", "-print0"], chdir: self, print_stderr: false)
            .stdout
            .split("\0")
            .reject { |path| Pathname(path).dmg_metadata? }
            .reject { |path| (self/path).system_dir_symlink? }
            .join("\n")
        end
      end
    end
    private_constant :Bom

    using Bom

    class Mount
      include UnpackStrategy

      def eject(verbose: false)
        tries ||= 3

        return unless path.exist?

        if tries > 1
          system_command! "diskutil",
                          args:         ["eject", path],
                          print_stderr: false,
                          verbose:      verbose
        else
          system_command! "diskutil",
                          args:         ["unmount", "force", path],
                          print_stderr: false,
                          verbose:      verbose
        end
      rescue ErrorDuringExecution => e
        raise e if (tries -= 1).zero?

        sleep 1
        retry
      end

      private

      def extract_to_dir(unpack_dir, basename:, verbose:)
        Tempfile.open(["", ".bom"]) do |bomfile|
          bomfile.close

          Tempfile.open(["", ".list"]) do |filelist|
            filelist.puts(path.bom)
            filelist.close

            system_command! "mkbom",
                            args:    ["-s", "-i", filelist.path, "--", bomfile.path],
                            verbose: verbose
          end

          system_command! "ditto",
                          args:    ["--bom", bomfile.path, "--", path, unpack_dir],
                          verbose: verbose

          FileUtils.chmod "u+w", Pathname.glob(unpack_dir/"**/*", File::FNM_DOTMATCH).reject(&:symlink?)
        end
      end
    end
    private_constant :Mount

    def self.extensions
      [".dmg"]
    end

    def self.can_extract?(path)
      imageinfo = system_command("hdiutil",
                                 args:         ["imageinfo", path],
                                 print_stderr: false).stdout

      !imageinfo.empty?
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      mount(verbose: verbose) do |mounts|
        raise "No mounts found in '#{path}'; perhaps it is a bad disk image?" if mounts.empty?

        mounts.each do |mount|
          mount.extract(to: unpack_dir, verbose: verbose)
        end
      end
    end

    def mount(verbose: false)
      Dir.mktmpdir do |mount_dir|
        mount_dir = Pathname(mount_dir)

        without_eula = system_command(
          "hdiutil",
          args:         [
            "attach", "-plist", "-nobrowse", "-readonly", "-noidme",
            "-mountrandom", mount_dir, path
          ],
          input:        "qn\n",
          print_stderr: false,
          verbose:      verbose,
        )

        # If mounting without agreeing to EULA succeeded, there is none.
        plist = if without_eula.success?
          without_eula.plist
        else
          cdr_path = mount_dir/path.basename.sub_ext(".cdr")

          quiet_flag = "-quiet" unless verbose

          system_command!(
            "hdiutil",
            args:    [
              "convert", *quiet_flag, "-format", "UDTO", "-o", cdr_path, path
            ],
            verbose: verbose,
          )

          with_eula = system_command!(
            "hdiutil",
            args:    [
              "attach", "-plist", "-nobrowse", "-readonly", "-noidme",
              "-mountrandom", mount_dir, cdr_path
            ],
            verbose: verbose,
          )

          if verbose && !(eula_text = without_eula.stdout).empty?
            ohai "Software License Agreement for '#{path}':"
            puts eula_text
          end

          with_eula.plist
        end

        mounts = if plist.respond_to?(:fetch)
          plist.fetch("system-entities", [])
               .map { |entity| entity["mount-point"] }
               .compact
               .map { |path| Mount.new(path) }
        else
          []
        end

        begin
          yield mounts
        ensure
          mounts.each do |mount|
            mount.eject(verbose: verbose)
          end
        end
      end
    end
  end
end

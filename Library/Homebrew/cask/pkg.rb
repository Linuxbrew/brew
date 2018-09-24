module Cask
  class Pkg
    def self.all_matching(regexp, command)
      command.run("/usr/sbin/pkgutil", args: ["--pkgs=#{regexp}"]).stdout.split("\n").map do |package_id|
        new(package_id.chomp, command)
      end
    end

    attr_reader :package_id

    def initialize(package_id, command = SystemCommand)
      @package_id = package_id
      @command = command
    end

    def uninstall
      unless pkgutil_bom_files.empty?
        odebug "Deleting pkg files"
        @command.run!(
          "/usr/bin/xargs",
          args: [
            "-0", "--", "/bin/rm", "--"
          ],
          input: pkgutil_bom_files.join("\0"),
          sudo: true,
        )
      end

      unless pkgutil_bom_specials.empty?
        odebug "Deleting pkg symlinks and special files"
        @command.run!(
          "/usr/bin/xargs",
          args: [
            "-0", "--", "/bin/rm", "--"
          ],
          input: pkgutil_bom_specials.join("\0"),
          sudo: true,
        )
      end

      unless pkgutil_bom_dirs.empty?
        odebug "Deleting pkg directories"
        deepest_path_first(pkgutil_bom_dirs).each do |dir|
          with_full_permissions(dir) do
            clean_broken_symlinks(dir)
            clean_ds_store(dir)
            rmdir(dir)
          end
        end
      end

      if root.directory? && !MacOS.undeletable?(root)
        clean_ds_store(root)
        rmdir(root)
      end

      forget
    end

    def forget
      odebug "Unregistering pkg receipt (aka forgetting)"
      @command.run!("/usr/sbin/pkgutil", args: ["--forget", package_id], sudo: true)
    end

    def pkgutil_bom_files
      @pkgutil_bom_files ||= pkgutil_bom_all.select(&:file?) - pkgutil_bom_specials
    end

    def pkgutil_bom_specials
      @pkgutil_bom_specials ||= pkgutil_bom_all.select(&method(:special?))
    end

    def pkgutil_bom_dirs
      @pkgutil_bom_dirs ||= pkgutil_bom_all.select(&:directory?) - pkgutil_bom_specials
    end

    def pkgutil_bom_all
      @pkgutil_bom_all ||= @command.run!("/usr/sbin/pkgutil", args: ["--files", package_id])
                                   .stdout
                                   .split("\n")
                                   .map { |path| root.join(path) }
                                   .reject(&MacOS.public_method(:undeletable?))
    end

    def root
      @root ||= Pathname.new(info.fetch("volume")).join(info.fetch("install-location"))
    end

    def info
      @info ||= @command.run!("/usr/sbin/pkgutil", args: ["--pkg-info-plist", package_id])
                        .plist
    end

    private

    def special?(path)
      path.symlink? || path.chardev? || path.blockdev?
    end

    def rmdir(path)
      return unless path.children.empty?

      if path.symlink?
        @command.run!("/bin/rm", args: ["-f", "--", path], sudo: true)
      else
        @command.run!("/bin/rmdir", args: ["--", path], sudo: true)
      end
    end

    def with_full_permissions(path)
      original_mode = (path.stat.mode % 01000).to_s(8)
      original_flags = @command.run!("/usr/bin/stat", args: ["-f", "%Of", "--", path]).stdout.chomp

      @command.run!("/bin/chmod", args: ["--", "777", path], sudo: true)
      yield
    ensure
      if path.exist? # block may have removed dir
        @command.run!("/bin/chmod", args: ["--", original_mode, path], sudo: true)
        @command.run!("/usr/bin/chflags", args: ["--", original_flags, path], sudo: true)
      end
    end

    def deepest_path_first(paths)
      paths.sort_by { |path| -path.to_s.split(File::SEPARATOR).count }
    end

    def clean_ds_store(dir)
      return unless (ds_store = dir.join(".DS_Store")).exist?

      @command.run!("/bin/rm", args: ["--", ds_store], sudo: true)
    end

    # Some packages leave broken symlinks around; we clean them out before
    # attempting to `rmdir` to prevent extra cruft from lying around.
    def clean_broken_symlinks(dir)
      dir.children.select(&method(:broken_symlink?)).each do |path|
        @command.run!("/bin/rm", args: ["--", path], sudo: true)
      end
    end

    def broken_symlink?(path)
      path.symlink? && !path.exist?
    end
  end
end

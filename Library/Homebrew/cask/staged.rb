require "utils/user"

module Cask
  module Staged
    def set_permissions(paths, permissions_str)
      full_paths = remove_nonexistent(paths)
      return if full_paths.empty?

      @command.run!("/bin/chmod", args: ["-R", "--", permissions_str] + full_paths,
                                  sudo: false)
    end

    def set_ownership(paths, user: User.current, group: "staff")
      full_paths = remove_nonexistent(paths)
      return if full_paths.empty?

      ohai "Changing ownership of paths required by #{@cask}; your password may be necessary"
      @command.run!("/usr/sbin/chown", args: ["-R", "--", "#{user}:#{group}"] + full_paths,
                                       sudo: true)
    end

    private

    def remove_nonexistent(paths)
      Array(paths).map { |p| Pathname(p).expand_path }.select(&:exist?)
    end
  end
end

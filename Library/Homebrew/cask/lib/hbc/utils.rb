require "yaml"
require "open3"
require "stringio"

require "hbc/utils/file"

PREBUG_URL = "https://github.com/caskroom/homebrew-cask/blob/master/doc/reporting_bugs/pre_bug_report.md".freeze
ISSUES_URL = "https://github.com/caskroom/homebrew-cask#reporting-bugs".freeze

# monkeypatch Object - not a great idea
class Object
  def utf8_inspect
    return inspect unless defined?(Encoding)
    return map(&:utf8_inspect) if respond_to?(:map)
    inspect.force_encoding("UTF-8").sub(/\A"(.*)"\Z/, '\1')
  end
end

class Buffer < StringIO
  def initialize(tty = false)
    super()
    @tty = tty
  end

  def tty?
    @tty
  end
end

# global methods

def odebug(title, *sput)
  return unless Hbc.respond_to?(:debug)
  return unless Hbc.debug
  puts Formatter.headline(title, color: :magenta)
  puts sput unless sput.empty?
end

module Hbc
  module Utils
    def self.gain_permissions_remove(path, command: SystemCommand)
      if path.respond_to?(:rmtree) && path.exist?
        gain_permissions(path, ["-R"], command, &:rmtree)
      elsif File.symlink?(path)
        gain_permissions(path, ["-h"], command, &FileUtils.method(:rm_f))
      end
    end

    def self.gain_permissions(path, command_args, command)
      tried_permissions = false
      tried_ownership = false
      begin
        yield path
      rescue StandardError
        # in case of permissions problems
        unless tried_permissions
          # TODO: Better handling for the case where path is a symlink.
          #       The -h and -R flags cannot be combined, and behavior is
          #       dependent on whether the file argument has a trailing
          #       slash.  This should do the right thing, but is fragile.
          command.run("/usr/bin/chflags",
                      must_succeed: false,
                      args:         command_args + ["--", "000", path])
          command.run("/bin/chmod",
                      must_succeed: false,
                      args:         command_args + ["--", "u+rwx", path])
          command.run("/bin/chmod",
                      must_succeed: false,
                      args:         command_args + ["-N", path])
          tried_permissions = true
          retry # rmtree
        end
        unless tried_ownership
          # in case of ownership problems
          # TODO: Further examine files to see if ownership is the problem
          #       before using sudo+chown
          ohai "Using sudo to gain ownership of path '#{path}'"
          command.run("/usr/sbin/chown",
                      args: command_args + ["--", current_user, path],
                      sudo: true)
          tried_ownership = true
          # retry chflags/chmod after chown
          tried_permissions = false
          retry # rmtree
        end
      end
    end

    def self.current_user
      Etc.getpwuid(Process.euid).name
    end

    # paths that "look" descendant (textually) will still
    # return false unless both the given paths exist
    def self.file_is_descendant(file, dir)
      file = Pathname.new(file)
      dir  = Pathname.new(dir)
      return false unless file.exist? && dir.exist?
      unless dir.directory?
        onoe "Argument must be a directory: '#{dir}'"
        return false
      end
      unless file.absolute? && dir.absolute?
        onoe "Both arguments must be absolute: '#{file}', '#{dir}'"
        return false
      end
      while file.parent != file
        return true if File.identical?(file, dir)
        file = file.parent
      end
      false
    end

    def self.path_occupied?(path)
      File.exist?(path) || File.symlink?(path)
    end

    def self.error_message_with_suggestions
      <<-EOS.undent
        Follow the instructions here:
          #{Formatter.url(PREBUG_URL)}

        If this doesn’t fix the problem, please report this bug:
          #{Formatter.url(ISSUES_URL)}

      EOS
    end

    def self.method_missing_message(method, token, section = nil)
      poo = []
      poo << "Unexpected method '#{method}' called"
      poo << "during #{section}" if section
      poo << "on Cask #{token}."

      opoo(poo.join(" ") + "\n" + error_message_with_suggestions)
    end

    def self.nowstamp_metadata_path(container_path)
      @timenow ||= Time.now.gmtime
      return unless container_path.respond_to?(:join)

      precision = 3
      timestamp = @timenow.strftime("%Y%m%d%H%M%S")
      fraction = format("%.#{precision}f", @timenow.to_f - @timenow.to_i)[1..-1]
      timestamp.concat(fraction)
      container_path.join(timestamp)
    end

    def self.size_in_bytes(files)
      Array(files).reduce(0) { |acc, elem| acc + (File.size?(elem) || 0) }
    end

    def self.capture_stderr
      previous_stderr = $stderr
      $stderr = StringIO.new
      yield
      $stderr.string
    ensure
      $stderr = previous_stderr
    end
  end
end

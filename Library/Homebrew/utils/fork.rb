require "fcntl"
require "socket"

module Utils
  def self.safe_fork(&_block)
    Dir.mktmpdir("homebrew", HOMEBREW_TEMP) do |tmpdir|
      UNIXServer.open("#{tmpdir}/socket") do |server|
        read, write = IO.pipe

        pid = fork do
          begin
            ENV["HOMEBREW_ERROR_PIPE"] = server.path
            server.close
            read.close
            write.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
            yield
          rescue Exception => e # rubocop:disable Lint/RescueException
            Marshal.dump(e, write)
            write.close
            exit!
          else
            exit!(true)
          end
        end

        ignore_interrupts(:quietly) do # the child will receive the interrupt and marshal it back
          begin
            socket = server.accept_nonblock
          # rubocop:disable Lint/ShadowedException
          # FIXME: https://github.com/bbatsov/rubocop/issues/4843
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
            retry unless Process.waitpid(pid, Process::WNOHANG)
          # rubocop:enable Lint/ShadowedException
          else
            socket.send_io(write)
            socket.close
          end
          write.close
          data = read.read
          read.close
          Process.wait(pid) unless socket.nil?
          raise Marshal.load(data) unless data.nil? || data.empty? # rubocop:disable Security/MarshalLoad
          raise Interrupt if $CHILD_STATUS.exitstatus == 130
          raise "Forked child process failed: #{$CHILD_STATUS}" unless $CHILD_STATUS.success?
        end
      end
    end
  end
end

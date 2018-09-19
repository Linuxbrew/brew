require "fcntl"
require "socket"

module Utils
  def self.rewrite_child_error(child_error)
    error = if child_error.inner_class == ErrorDuringExecution
      ErrorDuringExecution.new(child_error.inner["cmd"],
                               status: child_error.inner["status"],
                               output: child_error.inner["output"])
    elsif child_error.inner_class == BuildError
      # We fill `BuildError#formula` and `BuildError#options` in later,
      # when we rescue this in `FormulaInstaller#build`.
      BuildError.new(nil, child_error.inner["cmd"],
                     child_error.inner["args"], child_error.inner["env"])
    elsif child_error.inner_class == Interrupt
      Interrupt.new
    else
      # Everything other error in the child just becomes a RuntimeError.
      RuntimeError.new(child_error.message)
    end

    error.set_backtrace child_error.backtrace

    error
  end

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
            error_hash = JSON.parse e.to_json

            # Special case: We need to recreate ErrorDuringExecutions
            # for proper error messages and because other code expects
            # to rescue them further down.
            if e.is_a?(ErrorDuringExecution)
              error_hash["cmd"] = e.cmd
              error_hash["status"] = e.status.exitstatus
              error_hash["output"] = e.output
            end

            write.puts error_hash.to_json
            write.close

            exit!
          else
            exit!(true)
          end
        end

        ignore_interrupts(:quietly) do # the child will receive the interrupt and marshal it back
          begin
            socket = server.accept_nonblock
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
            retry unless Process.waitpid(pid, Process::WNOHANG)
          else
            socket.send_io(write)
            socket.close
          end
          write.close
          data = read.read
          read.close
          Process.wait(pid) unless socket.nil?

          # 130 is the exit status for a process interrupted via Ctrl-C.
          # We handle it here because of the possibility of an interrupted process terminating
          # without writing its Interrupt exception to the error pipe.
          raise Interrupt if $CHILD_STATUS.exitstatus == 130

          if data && !data.empty?
            error_hash = JSON.parse(data.lines.first)

            e = ChildProcessError.new(error_hash)

            raise rewrite_child_error(e)
          end

          raise "Forked child process failed: #{$CHILD_STATUS}" unless $CHILD_STATUS.success?
        end
      end
    end
  end
end

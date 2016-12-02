module Test
  module Helper
    module Shutup
      def shutup
        if ENV.key?("VERBOSE_TESTS")
          yield
        else
          begin
            tmperr = $stderr.clone
            tmpout = $stdout.clone
            $stderr.reopen("/dev/null")
            $stdout.reopen("/dev/null")
            yield
          ensure
            $stderr.reopen(tmperr)
            $stdout.reopen(tmpout)
            tmperr.close
            tmpout.close
          end
        end
      end
    end
  end
end

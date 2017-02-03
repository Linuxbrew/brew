module Test
  module Helper
    module FSLeakLogger
      def self.included(klass)
        require "find"
        logdir = HOMEBREW_LIBRARY_PATH.join("tmp")
        logdir.mkpath
        @@log = File.open(logdir.join("fs_leak.log"), "w")
        klass.make_my_diffs_pretty!
      end

      def setup
        @__files_before_test = []
        Find.find(TEST_TMPDIR) { |f| @__files_before_test << f.sub(TEST_TMPDIR, "") }
        super
      end

      def teardown
        super
        files_after_test = []
        Find.find(TEST_TMPDIR) { |f| files_after_test << f.sub(TEST_TMPDIR, "") }
        return if @__files_before_test == files_after_test
        @@log.puts location, diff(@__files_before_test, files_after_test)
      end
    end
  end
end

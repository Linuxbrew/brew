module Test
  module Helper
    module Env
      def copy_env
        ENV.to_hash
      end

      def restore_env(env)
        ENV.replace(env)
      end

      def with_environment(partial_env)
        old = copy_env
        ENV.update partial_env
        yield
      ensure
        restore_env old
      end

      def using_git_env
        initial_env = copy_env
        %w[AUTHOR COMMITTER].each do |role|
          ENV["GIT_#{role}_NAME"] = "brew tests"
          ENV["GIT_#{role}_EMAIL"] = "brew-tests@localhost"
          ENV["GIT_#{role}_DATE"] = "Thu May 21 00:04:11 2009 +0100"
        end
        yield
      ensure
        restore_env initial_env
      end
    end
  end
end

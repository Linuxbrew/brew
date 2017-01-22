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
        git_env = ["AUTHOR", "COMMITTER"].each_with_object({}) do |role, env|
          env["GIT_#{role}_NAME"]  = "brew tests"
          env["GIT_#{role}_EMAIL"] = "brew-tests@localhost"
          env["GIT_#{role}_DATE"]  = "Sun Jan 22 19:59:13 2017 +0000"
        end

        with_environment(git_env) do
          yield
        end
      end
    end
  end
end

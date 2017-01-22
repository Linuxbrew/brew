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
    end
  end
end

module Gpg
  class << self
    module Compat
      def executable
        odisabled "Gpg.executable", 'which "gpg"'
      end

      def available?
        odisabled "Gpg.available?", 'which "gpg"'
      end

      def create_test_key(*)
        odisabled "Gpg.create_test_key"
      end

      def cleanup_test_processes!
        odisabled "Gpg.cleanup_test_processes!"
      end

      def test(*)
        odisabled "Gpg.test"
      end
    end

    prepend Compat
  end
end

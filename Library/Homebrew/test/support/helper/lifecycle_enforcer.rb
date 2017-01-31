module Test
  module Helper
    module LifecycleEnforcer
      def setup
        @__setup_called = true
        super
      end

      def teardown
        @__teardown_called = true
        super
      end

      def after_teardown
        assert @__setup_called, "Expected setup to call `super` but didn't"
        assert @__teardown_called, "Expected teardown to call `super` but didn't"

        super
      end
    end
  end
end

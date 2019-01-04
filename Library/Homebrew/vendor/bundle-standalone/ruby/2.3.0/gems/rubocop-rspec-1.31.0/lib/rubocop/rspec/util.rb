# frozen_string_literal: true

module RuboCop
  module RSpec
    # Utility methods
    module Util
      # Error raised by `Util.one` if size is less than zero or greater than one
      SizeError = Class.new(IndexError)

      # Return only element in array if it contains exactly one member
      def one(array)
        return array.first if array.one?

        raise SizeError,
              "expected size to be exactly 1 but size was #{array.size}"
      end
    end
  end
end

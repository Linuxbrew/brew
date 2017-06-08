module Test
  module Helper
    module RuboCop
      def expect_offense(expected, actual)
        expect(actual).to_not be_nil
        expect(actual.message).to eq(expected[:message])
        expect(actual.severity).to eq(expected[:severity])
        expect(actual.line).to eq(expected[:line])
        expect(actual.column).to eq(expected[:column])
      end
    end
  end
end

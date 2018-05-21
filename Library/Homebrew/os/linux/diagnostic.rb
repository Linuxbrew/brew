module Homebrew
  module Diagnostic
    class Checks
      alias generic_check_tmpdir_sticky_bit check_tmpdir_sticky_bit
    end
  end
end

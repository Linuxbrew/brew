module Dependable
  module Compat
    def run?
      odeprecated "Dependable#run?"
      tags.include? :run
    end
  end

  prepend Compat
end

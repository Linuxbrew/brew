module Dependable
  module Compat
    def run?
      odisabled "Dependable#run?"
      tags.include? :run
    end
  end

  prepend Compat
end

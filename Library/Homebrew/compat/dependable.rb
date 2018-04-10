module Dependable
  def run?
    odeprecated "Dependable#run?"
    tags.include? :run
  end
end

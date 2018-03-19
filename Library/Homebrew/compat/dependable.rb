module Dependable
  def run?
    tags.include? :run
  end
end

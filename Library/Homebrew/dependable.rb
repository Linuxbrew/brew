require "options"

module Dependable
  RESERVED_TAGS = [:build, :optional, :recommended, :run, :linked].freeze

  def build?
    tags.include? :build
  end

  def optional?
    tags.include? :optional
  end

  def recommended?
    tags.include? :recommended
  end

  def run?
    tags.include? :run
  end

  def required?
    !build? && !optional? && !recommended?
  end

  def option_tags
    tags - RESERVED_TAGS
  end

  def options
    Options.create(option_tags)
  end
end

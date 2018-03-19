require "options"

module Dependable
  # :run and :linked are no longer used but keep them here to avoid them being
  # misused in future.
  RESERVED_TAGS = [:build, :optional, :recommended, :run, :test, :linked].freeze

  def build?
    tags.include? :build
  end

  def optional?
    tags.include? :optional
  end

  def recommended?
    tags.include? :recommended
  end

  def test?
    tags.include? :test
  end

  def required?
    !build? && !test? && !optional? && !recommended?
  end

  def option_tags
    tags - RESERVED_TAGS
  end

  def options
    Options.create(option_tags)
  end
end

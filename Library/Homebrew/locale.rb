class Locale
  class ParserError < ::RuntimeError
  end

  LANGUAGE_REGEX = /(?:[a-z]{2})/
  REGION_REGEX = /(?:[A-Z]{2})/
  SCRIPT_REGEX = /(?:[A-Z][a-z]{3})/

  LOCALE_REGEX = /^(#{LANGUAGE_REGEX})?(?:(?:^|-)(#{REGION_REGEX}))?(?:(?:^|-)(#{SCRIPT_REGEX}))?$/

  def self.parse(string)
    language, region, script = string.to_s.scan(LOCALE_REGEX)[0]

    if language.nil? && region.nil? && script.nil?
      raise ParserError, "'#{string}' cannot be parsed to a #{self.class}"
    end

    new(language, region, script)
  end

  attr_reader :language, :region, :script

  def initialize(language, region, script)
    if language.nil? && region.nil? && script.nil?
      raise ArgumentError, "#{self.class} cannot be empty"
    end

    {
      language: language,
      region:   region,
      script:   script,
    }.each do |key, value|
      next if value.nil?

      regex = self.class.const_get("#{key.upcase}_REGEX")
      raise ParserError, "'#{value}' does not match #{regex}" unless value =~ regex
      instance_variable_set(:"@#{key}", value)
    end

    self
  end

  def include?(other)
    other = self.class.parse(other) unless other.is_a?(self.class)

    [:language, :region, :script].all? { |var|
      if other.public_send(var).nil?
        true
      else
        public_send(var) == other.public_send(var)
      end
    }
  end

  def eql?(other)
    other = self.class.parse(other) unless other.is_a?(self.class)
    [:language, :region, :script].all? { |var|
      public_send(var) == other.public_send(var)
    }
  rescue ParserError
    false
  end
  alias == eql?

  def to_s
    [@language, @region, @script].compact.join("-")
  end
end

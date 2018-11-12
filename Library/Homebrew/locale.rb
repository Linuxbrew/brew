class Locale
  class ParserError < StandardError
  end

  LANGUAGE_REGEX = /(?:[a-z]{2,3})/.freeze     # ISO 639-1 or ISO 639-2
  REGION_REGEX   = /(?:[A-Z]{2}|\d{3})/.freeze # ISO 3166-1 or UN M.49
  SCRIPT_REGEX   = /(?:[A-Z][a-z]{3})/.freeze  # ISO 15924

  LOCALE_REGEX = /\A((?:#{LANGUAGE_REGEX}|#{REGION_REGEX}|#{SCRIPT_REGEX})(?:\-|$)){1,3}\Z/.freeze

  def self.parse(string)
    string = string.to_s

    if string !~ LOCALE_REGEX
      raise ParserError, "'#{string}' cannot be parsed to a #{self}"
    end

    scan = proc do |regex|
      string.scan(/(?:\-|^)(#{regex})(?:\-|$)/).flatten.first
    end

    language = scan.call(LANGUAGE_REGEX)
    region   = scan.call(REGION_REGEX)
    script   = scan.call(SCRIPT_REGEX)

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
  end

  def include?(other)
    other = self.class.parse(other) unless other.is_a?(self.class)

    [:language, :region, :script].all? do |var|
      if other.public_send(var).nil?
        true
      else
        public_send(var) == other.public_send(var)
      end
    end
  end

  def eql?(other)
    other = self.class.parse(other) unless other.is_a?(self.class)
    [:language, :region, :script].all? do |var|
      public_send(var) == other.public_send(var)
    end
  rescue ParserError
    false
  end
  alias == eql?

  def detect(locale_groups)
    locale_groups.find { |locales| locales.any? { |locale| eql?(locale) } } ||
      locale_groups.find { |locales| locales.any? { |locale| include?(locale) } }
  end

  def to_s
    [@language, @region, @script].compact.join("-")
  end
end

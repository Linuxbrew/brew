class Version
  NULL = Class.new do
    include Comparable

    def <=>(_other)
      -1
    end

    def eql?(_other)
      # Makes sure that the same instance of Version::NULL
      # will never equal itself; normally Comparable#==
      # will return true for this regardless of the return
      # value of #<=>
      false
    end

    def detected_from_url?
      false
    end

    def head?
      false
    end

    def null?
      true
    end

    def to_f
      Float::NAN
    end

    def to_i
      0
    end

    def to_s
      ""
    end
    alias_method :to_str, :to_s

    def inspect
      "#<Version::NULL>".freeze
    end
  end.new
end

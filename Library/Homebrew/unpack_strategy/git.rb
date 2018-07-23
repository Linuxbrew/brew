require_relative "directory"

module UnpackStrategy
  class Git < Directory
    def self.can_extract?(path:, magic_number:)
      super && (path/".git").directory?
    end
  end
end

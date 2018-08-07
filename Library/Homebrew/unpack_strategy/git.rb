require_relative "directory"

module UnpackStrategy
  class Git < Directory
    using Magic

    def self.can_extract?(path)
      super && (path/".git").directory?
    end
  end
end

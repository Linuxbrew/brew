require_relative "directory"

module UnpackStrategy
  class Cvs < Directory
    using Magic

    def self.can_extract?(path)
      super && (path/"CVS").directory?
    end
  end
end

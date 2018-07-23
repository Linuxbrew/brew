require_relative "directory"

module UnpackStrategy
  class Cvs < Directory
    def self.can_extract?(path:, magic_number:)
      super && (path/"CVS").directory?
    end
  end
end

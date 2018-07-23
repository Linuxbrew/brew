module UnpackStrategy
  class Directory
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      path.directory?
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      path.children.each do |child|
        FileUtils.copy_entry child, unpack_dir/child.basename, true, false
      end
    end
  end
end

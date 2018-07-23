module UnpackStrategy
  class Fossil
    include UnpackStrategy

    def self.can_extract?(path:, magic_number:)
      return false unless magic_number.match?(/\ASQLite format 3\000/n)

      # Fossil database is made up of artifacts, so the `artifact` table must exist.
      query = "select count(*) from sqlite_master where type = 'view' and name = 'artifact'"
      Utils.popen_read("sqlite3", path, query).to_i == 1
    end

    private

    def extract_to_dir(unpack_dir, basename:, verbose:)
      args = if @ref_type && @ref
        [@ref]
      else
        []
      end

      with_env "PATH" => PATH.new(Formula["fossil"].opt_bin, ENV["PATH"]) do
        safe_system "fossil", "open", path, *args, chdir: unpack_dir
      end
    end
  end
end

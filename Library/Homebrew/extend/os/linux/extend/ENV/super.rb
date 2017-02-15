module Superenv
  # @private
  def self.bin
    (HOMEBREW_SHIMS_PATH/"linux/super").realpath
  end

  def determine_rpath_paths
    paths = ["#{HOMEBREW_PREFIX}/lib"]
    paths += run_time_deps.map { |d| d.opt_lib.to_s }
    paths += homebrew_extra_library_paths
    paths.to_path_s
  end
end

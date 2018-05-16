module Superenv
  # @private
  def self.bin
    (HOMEBREW_SHIMS_PATH/"linux/super").realpath
  end

  def homebrew_extra_paths
    paths = []
    paths += %w[binutils make].map do |f|
      begin
        bin = Formula[f].opt_bin
        bin if bin.directory?
      rescue FormulaUnavailableError
        nil
      end
    end.compact
    paths
  end

  def determine_extra_rpath_paths(formula)
    PATH.new(
      formula&.lib,
      "#{HOMEBREW_PREFIX}/lib",
      PATH.new(run_time_deps.map { |dep| dep.opt_lib.to_s }).existing,
    )
  end

  def determine_dynamic_linker_path
    path = "#{HOMEBREW_PREFIX}/lib/ld.so"
    return unless File.readable? path
    path
  end
end

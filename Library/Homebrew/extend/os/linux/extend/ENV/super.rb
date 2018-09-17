module Superenv
  # @private
  def self.bin
    (HOMEBREW_SHIMS_PATH/"linux/super").realpath
  end

  # @private
  def setup_build_environment(formula = nil)
    generic_setup_build_environment(formula)
    self["HOMEBREW_OPTIMIZATION_LEVEL"] = "O2"
    self["HOMEBREW_DYNAMIC_LINKER"] = determine_dynamic_linker_path
    self["HOMEBREW_RPATH_PATHS"] = determine_rpath_paths(formula)
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

  def determine_rpath_paths(formula)
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

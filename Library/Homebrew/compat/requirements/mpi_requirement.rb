require "requirement"

# There are multiple implementations of MPI-2 available.
# http://www.mpi-forum.org/
# This requirement is used to find an appropriate one.
class MPIRequirement < Requirement
  attr_reader :lang_list

  fatal true

  default_formula "open-mpi"

  env :userpaths

  # This method must accept varargs rather than an array for
  # backwards compatibility with formulae that call it directly.
  def initialize(*tags)
    @non_functional = []
    @unknown_langs = []
    @lang_list = [:cc, :cxx, :f77, :f90] & tags
    tags -= @lang_list
    super(tags)
  end

  def mpi_wrapper_works?(compiler)
    compiler = which compiler
    return false if compiler.nil? || !compiler.executable?

    # Some wrappers are non-functional and will return a non-zero exit code
    # when invoked for version info.
    #
    # NOTE: A better test may be to do a small test compilation a la autotools.
    quiet_system compiler, "--version"
  end

  def inspect
    "#<#{self.class.name}: #{name.inspect} #{tags.inspect} lang_list=#{@lang_list.inspect}>"
  end

  satisfy do
    @lang_list.each do |lang|
      case lang
      when :cc, :cxx, :f90, :f77
        compiler = "mpi" + lang.to_s
        @non_functional << compiler unless mpi_wrapper_works? compiler
      else
        @unknown_langs << lang.to_s
      end
    end
    @unknown_langs.empty? && @non_functional.empty?
  end

  env do
    # Set environment variables to help configure scripts find MPI compilers.
    # Variable names taken from:
    # https://www.gnu.org/software/autoconf-archive/ax_mpi.html
    @lang_list.each do |lang|
      compiler = "mpi" + lang.to_s
      mpi_path = which compiler

      # Fortran 90 environment var has a different name
      compiler = "MPIFC" if lang == :f90
      ENV[compiler.upcase] = mpi_path
    end
  end
end

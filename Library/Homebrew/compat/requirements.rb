require "requirements"
require "compat/requirements/language_module_requirement"

class CVSRequirement < Requirement
  fatal true
  satisfy do
    odeprecated("CVSRequirement", "'depends_on \"cvs\"'")
    which "cvs"
  end
end

class EmacsRequirement < Requirement
  fatal true
  satisfy do
    odeprecated("EmacsRequirement", "'depends_on \"cvs\"'")
    which "emacs"
  end
end

class FortranRequirement < Requirement
  fatal true
  satisfy do
    odeprecated("FortranRequirement", "'depends_on \"cvs\"'")
    which "gfortran"
  end
end

class GitRequirement < Requirement
  fatal true
  satisfy do
    odeprecated("GitRequirement", "'depends_on \"cvs\"'")
    which "git"
  end
end

class GPG2Requirement < Requirement
  fatal true
  satisfy do
    odeprecated("GPG2Requirement", "'depends_on \"cvs\"'")
    which "gpg"
  end
end

class MercurialRequirement < Requirement
  fatal true
  satisfy do
    odeprecated("MercurialRequirement", "'depends_on \"cvs\"'")
    which "hg"
  end
end

class MPIRequirement < Requirement
  fatal true
  satisfy do
    odeprecated("MPIRequirement", "'depends_on \"cvs\"'")
    which "mpicc"
  end
end

class MysqlRequirement < Requirement
  fatal true
  satisfy do
    odeprecated("MysqlRequirement", "'depends_on \"cvs\"'")
    which "mysql_config"
  end
end

class PerlRequirement < Requirement
  fatal true
  satisfy do
    odeprecated("PerlRequirement", "'depends_on \"cvs\"'")
    which "perl"
  end
end

class PostgresqlRequirement < Requirement
  fatal true
  satisfy do
    odeprecated("PostgresqlRequirement", "'depends_on \"cvs\"'")
    which "pg_config"
  end
end

class PythonRequirement < Requirement
  fatal true
  satisfy do
    odeprecated("PythonRequirement", "'depends_on \"cvs\"'")
    which "python"
  end
end

class Python3Requirement < Requirement
  fatal true
  satisfy do
    odeprecated("Python3Requirement", "'depends_on \"cvs\"'")
    which "python3"
  end
end

class RbenvRequirement < Requirement
  fatal true
  satisfy do
    odeprecated("RbenvRequirement", "'depends_on \"cvs\"'")
    which "rbenv"
  end
end

class RubyRequirement < Requirement
  fatal true
  satisfy do
    odeprecated("RubyRequirement", "'depends_on \"cvs\"'")
    which "ruby"
  end
end

class SubversionRequirement < Requirement
  fatal true
  satisfy do
    odeprecated("SubversionRequirement", "'depends_on \"cvs\"'")
    which "svn"
  end
end

class TeXRequirement < Requirement
  fatal true
  cask "mactex"
  download "https://www.tug.org/mactex/"
  satisfy do
    odeprecated("TeXRequirement", "'depends_on \"cvs\"'")
    which("tex") || which("latex")
  end
end

MinimumMacOSRequirement = MacOSRequirement

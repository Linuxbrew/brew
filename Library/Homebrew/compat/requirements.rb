require "requirements"

class CVSRequirement < Requirement
  fatal true
  satisfy do
    odisabled("CVSRequirement", "'depends_on \"cvs\"'")
  end
end

class EmacsRequirement < Requirement
  fatal true
  satisfy do
    odisabled("EmacsRequirement", "'depends_on \"emacs\"'")
  end
end

class FortranRequirement < Requirement
  fatal true
  satisfy do
    odisabled("FortranRequirement", "'depends_on \"gcc\"'")
  end
end

class GitRequirement < Requirement
  fatal true
  satisfy do
    odisabled("GitRequirement", "'depends_on \"git\"'")
  end
end

class GPG2Requirement < Requirement
  fatal true
  satisfy do
    odisabled("GPG2Requirement", "'depends_on \"gnupg\"'")
  end
end

class MercurialRequirement < Requirement
  fatal true
  satisfy do
    odisabled("MercurialRequirement", "'depends_on \"mercurial\"'")
  end
end

class MPIRequirement < Requirement
  fatal true
  satisfy do
    odisabled("MPIRequirement", "'depends_on \"open-mpi\"'")
  end
end

class MysqlRequirement < Requirement
  fatal true
  satisfy do
    odisabled("MysqlRequirement", "'depends_on \"mysql\"'")
  end
end

class PerlRequirement < Requirement
  fatal true
  satisfy do
    odisabled("PerlRequirement", "'depends_on \"perl\"'")
  end
end

class PostgresqlRequirement < Requirement
  fatal true
  satisfy do
    odisabled("PostgresqlRequirement", "'depends_on \"postgresql\"'")
  end
end

class PythonRequirement < Requirement
  fatal true
  satisfy do
    odisabled("PythonRequirement", "'depends_on \"python@2\"'")
  end
end

class Python3Requirement < Requirement
  fatal true
  satisfy do
    odisabled("Python3Requirement", "'depends_on \"python\"'")
  end
end

class RbenvRequirement < Requirement
  fatal true
  satisfy do
    odisabled("RbenvRequirement", "'depends_on \"rbenv\"'")
  end
end

class RubyRequirement < Requirement
  fatal true
  satisfy do
    odisabled("RubyRequirement", "'depends_on \"ruby\"'")
  end
end

class SubversionRequirement < Requirement
  fatal true
  satisfy do
    odisabled("SubversionRequirement", "'depends_on \"subversion\"'")
  end
end

class TeXRequirement < Requirement
  fatal true
  cask "mactex"
  download "https://www.tug.org/mactex/"
  satisfy do
    odisabled("TeXRequirement")
  end
end

MinimumMacOSRequirement = MacOSRequirement

require "requirements"
require "compat/requirements/language_module_requirement"
require "compat/requirements/tex_requirement"

class MysqlRequirement < Requirement
  fatal true
  default_formula "mysql"
  satisfy { which "mysql_config" }
end

class PostgresqlRequirement < Requirement
  fatal true
  default_formula "postgresql"
  satisfy { which "pg_config" }
end

class RbenvRequirement < Requirement
  fatal true
  default_formula "rbenv"
  satisfy { which "rbenv" }
end

class CVSRequirement < Requirement
  fatal true
  default_formula "cvs"
  satisfy { which "cvs" }
end

class MercurialRequirement < Requirement
  fatal true
  default_formula "mercurial"
  satisfy { which "hg" }
end

class GPG2Requirement < Requirement
  fatal true
  default_formula "gnupg"
  satisfy { which "gpg" }
end

XcodeDependency            = XcodeRequirement
MysqlDependency            = MysqlRequirement
PostgresqlDependency       = PostgresqlRequirement
GPGDependency              = GPG2Requirement
GPGRequirement             = GPG2Requirement
TeXDependency              = TeXRequirement
MercurialDependency        = MercurialRequirement
GitDependency              = GitRequirement
FortranDependency          = FortranRequirement
JavaDependency             = JavaRequirement
LanguageModuleDependency   = LanguageModuleRequirement
MPIDependency              = MPIRequirement
OsxfuseDependency          = OsxfuseRequirement
PythonDependency           = PythonRequirement
TuntapDependency           = TuntapRequirement
X11Dependency              = X11Requirement
ConflictsWithBinaryOsxfuse = NonBinaryOsxfuseRequirement
MinimumMacOSRequirement    = MacOSRequirement

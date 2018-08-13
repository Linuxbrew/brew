require "hardware"
require "extend/ENV/shared"
require "extend/ENV/std"
require "extend/ENV/super"

def superenv?
  ARGV.env != "std" && Superenv.bin
end

module EnvActivation
  def activate_extensions!
    if superenv?
      extend(Superenv)
    else
      extend(Stdenv)
    end
  end

  def with_build_environment(formula = nil)
    old_env = to_hash.dup
    tmp_env = to_hash.dup.extend(EnvActivation)
    tmp_env.activate_extensions!
    tmp_env.setup_build_environment(formula)
    replace(tmp_env)
    yield
  ensure
    replace(old_env)
  end

  def clear_sensitive_environment!
    each_key do |key|
      next unless /(cookie|key|token|password)/i =~ key
      delete key
    end
  end
end

ENV.extend(EnvActivation)

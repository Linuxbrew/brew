module FileHelper
  module_function

  def valid_alias?(candidate)
    return false unless candidate.symlink?
    candidate.readlink.exist?
  end
end

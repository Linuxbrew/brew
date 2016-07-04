class Cleaner
  private

  def executable_path?(path)
    path.mach_o_executable? || path.text_executable?
  end
end

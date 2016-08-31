class Cleaner
  private

  def executable_path?(path)
    path.text_executable? || path.mach_o_executable? || path.dylib?
  end
end

module SharedEnvExtension
  def j1
    odeprecated "ENV.j1", "ENV.deparallelize"
    deparallelize
  end

  def java_cache
    # odeprecated "ENV.java_cache"
  end
end

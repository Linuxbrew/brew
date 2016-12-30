module SharedEnvExtension
  def j1
    odeprecated "ENV.j1", "ENV.deparallelize"
    deparallelize
  end
end

module SharedEnvExtension
  # @private
  def effective_arch
    if ARGV.build_bottle?
      ARGV.bottle_arch || Hardware.oldest_cpu
    else
      :native
    end
  end
end

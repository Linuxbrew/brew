require "rspec/core/formatters/progress_formatter"

class NoSeedProgressFormatter < RSpec::Core::Formatters::ProgressFormatter
  RSpec::Core::Formatters.register self, :seed

  def seed(notification); end
end

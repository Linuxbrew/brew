class DevelopmentTools
  class << self
    def locate(tool)
      (@locate ||= {}).fetch(tool) do |key|
        @locate[key] = if (path = HOMEBREW_PREFIX/"bin/#{tool}").executable?
          path
        elsif File.executable?(path = "/usr/bin/#{tool}")
          Pathname.new path
        end
      end
    end

    def default_compiler
      :gcc
    end
  end
end

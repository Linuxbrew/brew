module Hbc
  module Checkable
    def errors
      Array(@errors)
    end

    def warnings
      Array(@warnings)
    end

    def add_error(message)
      @errors ||= []
      @errors << message
    end

    def add_warning(message)
      @warnings ||= []
      @warnings << message
    end

    def errors?
      Array(@errors).any?
    end

    def warnings?
      Array(@warnings).any?
    end

    def result
      if errors?
        Formatter.error("failed")
      elsif warnings?
        Formatter.warning("warning")
      else
        Formatter.success("passed")
      end
    end

    def summary
      summary = ["#{summary_header}: #{result}"]

      errors.each do |error|
        summary << " #{Formatter.error("-")} #{error}"
      end

      warnings.each do |warning|
        summary << " #{Formatter.warning("-")} #{warning}"
      end

      summary.join("\n")
    end
  end
end

# A Messages object collects messages that may need to be displayed together
# at the end of a multi-step `brew` command run
class Messages
  attr_reader :caveats, :formula_count

  def initialize
    @caveats = []
    @formula_count = 0
  end

  def record_caveats(f, caveats)
    @caveats.push(formula: f.name, caveats: caveats)
  end

  def formula_installed(_f)
    @formula_count += 1
  end

  def display_messages
    display_caveats
  end

  def display_caveats
    return if @formula_count <= 1
    return if @caveats.empty?
    oh1 "Caveats"
    @caveats.each do |c|
      ohai c[:formula], c[:caveats]
    end
  end
end

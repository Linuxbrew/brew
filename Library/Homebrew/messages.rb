# A Messages object collects messages that may need to be displayed together
# at the end of a multi-step `brew` command run.
class Messages
  attr_reader :caveats, :formula_count, :install_times

  def initialize
    @caveats = []
    @formula_count = 0
    @install_times = []
  end

  def record_caveats(f, caveats)
    @caveats.push(formula: f.name, caveats: caveats)
  end

  def formula_installed(f, elapsed_time)
    @formula_count += 1
    @install_times.push(formula: f.name, time: elapsed_time)
  end

  def display_messages
    display_caveats
    display_install_times if ARGV.include?("--display-times")
  end

  def display_caveats
    return if @formula_count <= 1
    return if @caveats.empty?

    oh1 "Caveats"
    @caveats.each do |c|
      ohai c[:formula], c[:caveats]
    end
  end

  def display_install_times
    return if install_times.empty?

    oh1 "Installation times"
    install_times.each do |t|
      puts format("%-20s %10.3f s", t[:formula], t[:time])
    end
  end
end

module Cask
  class Config
    def self.global
      @global ||= new
    end

    attr_reader :binarydir

    def initialize(
      appdir:               "/Applications",
      prefpanedir:          "~/Library/PreferencePanes",
      qlplugindir:          "~/Library/QuickLook",
      dictionarydir:        "~/Library/Dictionaries",
      fontdir:              "~/Library/Fonts",
      colorpickerdir:       "~/Library/ColorPickers",
      servicedir:           "~/Library/Services",
      input_methoddir:      "~/Library/Input Methods",
      internet_plugindir:   "~/Library/Internet Plug-Ins",
      audio_unit_plugindir: "~/Library/Audio/Plug-Ins/Components",
      vst_plugindir:        "~/Library/Audio/Plug-Ins/VST",
      vst3_plugindir:       "~/Library/Audio/Plug-Ins/VST3",
      screen_saverdir:      "~/Library/Screen Savers"
    )

      self.appdir               = appdir
      self.prefpanedir          = prefpanedir
      self.qlplugindir          = qlplugindir
      self.dictionarydir        = dictionarydir
      self.fontdir              = fontdir
      self.colorpickerdir       = colorpickerdir
      self.servicedir           = servicedir
      self.input_methoddir      = input_methoddir
      self.internet_plugindir   = internet_plugindir
      self.audio_unit_plugindir = audio_unit_plugindir
      self.vst_plugindir        = vst_plugindir
      self.vst3_plugindir       = vst3_plugindir
      self.screen_saverdir      = screen_saverdir

      # `binarydir` is not customisable.
      @binarydir = HOMEBREW_PREFIX/"bin"
    end

    [
      :appdir,
      :prefpanedir,
      :qlplugindir,
      :dictionarydir,
      :fontdir,
      :colorpickerdir,
      :servicedir,
      :input_methoddir,
      :internet_plugindir,
      :audio_unit_plugindir,
      :vst_plugindir,
      :vst3_plugindir,
      :screen_saverdir,
    ].each do |dir|
      attr_reader dir

      define_method(:"#{dir}=") do |path|
        instance_variable_set(:"@#{dir}", Pathname(path).expand_path)
      end
    end
  end
end

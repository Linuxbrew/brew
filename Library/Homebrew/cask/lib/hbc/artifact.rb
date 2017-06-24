require "hbc/artifact/app"
require "hbc/artifact/artifact" # generic 'artifact' stanza
require "hbc/artifact/binary"
require "hbc/artifact/colorpicker"
require "hbc/artifact/dictionary"
require "hbc/artifact/font"
require "hbc/artifact/input_method"
require "hbc/artifact/installer"
require "hbc/artifact/internet_plugin"
require "hbc/artifact/audio_unit_plugin"
require "hbc/artifact/vst_plugin"
require "hbc/artifact/vst3_plugin"
require "hbc/artifact/nested_container"
require "hbc/artifact/pkg"
require "hbc/artifact/postflight_block"
require "hbc/artifact/preflight_block"
require "hbc/artifact/prefpane"
require "hbc/artifact/qlplugin"
require "hbc/artifact/screen_saver"
require "hbc/artifact/service"
require "hbc/artifact/stage_only"
require "hbc/artifact/suite"
require "hbc/artifact/uninstall"
require "hbc/artifact/zap"

module Hbc
  module Artifact
    # NOTE: Order is important here!
    #
    # The `uninstall` stanza should be run first, as it may
    # depend on other artifacts still being installed.
    #
    # We want to extract nested containers before we
    # handle any other artifacts.
    #
    TYPES = [
      PreflightBlock,
      Uninstall,
      NestedContainer,
      Installer,
      App,
      Suite,
      Artifact, # generic 'artifact' stanza
      Colorpicker,
      Pkg,
      Prefpane,
      Qlplugin,
      Dictionary,
      Font,
      Service,
      StageOnly,
      Binary,
      InputMethod,
      InternetPlugin,
      AudioUnitPlugin,
      VstPlugin,
      Vst3Plugin,
      ScreenSaver,
      PostflightBlock,
      Zap,
    ].freeze

    def self.for_cask(cask, options = {})
      odebug "Determining which artifacts are present in Cask #{cask}"

      TYPES
        .select { |klass| klass.me?(cask) }
        .map { |klass| klass.new(cask, options) }
    end
  end
end

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
    # NOTE: order is important here, since we want to extract nested containers
    #       before we handle any other artifacts
    def self.artifacts
      [
        PreflightBlock,
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
        Uninstall,
        PostflightBlock,
        Zap,
      ]
    end

    def self.for_cask(cask)
      odebug "Determining which artifacts are present in Cask #{cask}"
      artifacts.select do |artifact|
        odebug "Checking for artifact class #{artifact}"
        artifact.me?(cask)
      end
    end
  end
end

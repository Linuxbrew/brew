module RuboCop
  module Cask
    # Constants available globally for use in all Cask cops.
    module Constants
      STANZA_GROUPS = [
        [:version, :sha256],
        [:url, :appcast, :name, :homepage],
        [
          :auto_updates,
          :conflicts_with,
          :depends_on,
          :container,
        ],
        [
          :suite,
          :app,
          :pkg,
          :installer,
          :binary,
          :colorpicker,
          :dictionary,
          :font,
          :input_method,
          :internet_plugin,
          :prefpane,
          :qlplugin,
          :screen_saver,
          :service,
          :audio_unit_plugin,
          :vst_plugin,
          :artifact,
          :stage_only,
        ],
        [:preflight],
        [:postflight],
        [:uninstall_preflight],
        [:uninstall_postflight],
        [:uninstall],
        [:zap],
        [:caveats],
      ].freeze

      STANZA_GROUP_HASH =
        STANZA_GROUPS.each_with_object({}) do |stanza_group, hash|
          stanza_group.each { |stanza| hash[stanza] = stanza_group }
        end.freeze

      STANZA_ORDER = STANZA_GROUPS.flatten.freeze
    end
  end
end

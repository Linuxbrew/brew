require "forwardable"
require "uri"

module RuboCop
  module Cop
    module Cask
      # This cop checks that a cask's homepage ends with a slash
      # if it does not have a path component.
      class HomepageUrlTrailingSlash < Cop
        include OnHomepageStanza

        MSG_NO_SLASH = "'%{url}' must have a slash after the domain.".freeze

        def on_homepage_stanza(stanza)
          url_node = stanza.stanza_node.first_argument
          url = url_node.str_content

          return if url !~ %r{^.+://[^/]+$}

          add_offense(url_node, location: :expression,
                                message:  format(MSG_NO_SLASH, url: url))
        end

        def autocorrect(node)
          domain = URI(node.str_content).host

          # This also takes URLs like 'https://example.org?path'
          # and 'https://example.org#path' into account.
          corrected_source = node.source.sub("://#{domain}", "://#{domain}/")

          lambda do |corrector|
            corrector.replace(node.source_range, corrected_source)
          end
        end
      end
    end
  end
end

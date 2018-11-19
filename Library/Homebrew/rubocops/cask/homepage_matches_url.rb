require "forwardable"

module RuboCop
  module Cop
    module Cask
      # This cop checks that a cask's homepage matches the download url,
      # or if it doesn't, checks if a comment in the form
      # `# example.com was verified as official when first introduced to the cask`
      # is present.
      class HomepageMatchesUrl < Cop # rubocop:disable Metrics/ClassLength
        extend Forwardable
        include CaskHelp

        REFERENCE_URL =
          "https://github.com/Homebrew/homebrew-cask/blob/master/doc/" \
          "cask_language_reference/stanzas/url.md#when-url-and-homepage-hostnames-differ-add-a-comment".freeze

        COMMENT_FORMAT = /# [^ ]+ was verified as official when first introduced to the cask/.freeze

        MSG_NO_MATCH = "`%{url}` does not match `%{full_url}`".freeze

        MSG_MISSING = "`%{domain}` does not match `%{homepage}`, a comment has to be added " \
                      "above the `url` stanza. For details, see " + REFERENCE_URL

        MSG_WRONG_FORMAT = "`%{comment}` does not match the expected comment format. " \
                           "For details, see " + REFERENCE_URL

        MSG_UNNECESSARY = "The URL's domain `%{domain}` matches the homepage `%{homepage}`, " \
                          "the comment above the `url` stanza is unnecessary".freeze

        def on_cask(cask_block)
          @cask_block = cask_block
          return unless homepage_stanza

          add_offenses
        end

        private

        attr_reader :cask_block
        def_delegators :cask_block, :cask_node, :toplevel_stanzas,
                       :sorted_toplevel_stanzas

        def add_offenses
          toplevel_stanzas.select(&:url?).each do |url|
            next if add_offense_unnecessary_comment(url)
            next if add_offense_missing_comment(url)
            next if add_offense_no_match(url)
            next if add_offense_wrong_format(url)
          end
        end

        def add_offense_unnecessary_comment(stanza)
          return unless comment?(stanza)
          return unless url_match_homepage?(stanza)
          return unless comment_matches_format?(stanza)
          return unless comment_matches_url?(stanza)

          comment = comment(stanza).loc.expression
          add_offense(comment,
                      location: comment,
                      message:  format(MSG_UNNECESSARY, domain: domain(stanza), homepage: homepage))
        end

        def add_offense_missing_comment(stanza)
          return if url_match_homepage?(stanza)
          return if !url_match_homepage?(stanza) && comment?(stanza)

          range = stanza.source_range
          url_domain = domain(stanza)
          add_offense(range, location: range, message: format(MSG_MISSING, domain: url_domain, homepage: homepage))
        end

        def add_offense_no_match(stanza)
          return if url_match_homepage?(stanza)
          return unless comment?(stanza)
          return if !url_match_homepage?(stanza) && comment_matches_url?(stanza)

          comment = comment(stanza).loc.expression
          add_offense(comment,
                      location: comment,
                      message:  format(MSG_NO_MATCH, url: url_from_comment(stanza), full_url: full_url(stanza)))
        end

        def add_offense_wrong_format(stanza)
          return if url_match_homepage?(stanza)
          return unless comment?(stanza)
          return if comment_matches_format?(stanza)

          comment = comment(stanza).loc.expression
          add_offense(comment,
                      location: comment,
                      message:  format(MSG_WRONG_FORMAT, comment: comment(stanza).text))
        end

        def comment?(stanza)
          !stanza.comments.empty?
        end

        def comment(stanza)
          stanza.comments.last
        end

        def comment_matches_format?(stanza)
          comment(stanza).text =~ COMMENT_FORMAT
        end

        def url_from_comment(stanza)
          comment(stanza).text
                         .sub(/[^ ]*# ([^ ]+) .*/, '\1')
        end

        def comment_matches_url?(stanza)
          full_url(stanza).include?(url_from_comment(stanza))
        end

        def strip_url_scheme(url)
          url.sub(%r{^.*://(www\.)?}, "")
        end

        def domain(stanza)
          strip_url_scheme(extract_url(stanza)).gsub(%r{^([^/]+).*}, '\1')
        end

        def extract_url(stanza)
          string = stanza.stanza_node.children[2]
          return string.str_content if string.str_type?

          string.to_s.gsub(%r{.*"([a-z0-9]+\:\/\/[^"]+)".*}m, '\1')
        end

        def url_match_homepage?(stanza)
          host = extract_url(stanza).downcase
          host_uri = URI(remove_non_ascii(host))
          host = if host.match?(/:\d/) && host_uri.port != 80
            "#{host_uri.host}:#{host_uri.port}"
          else
            host_uri.host
          end
          home = homepage.downcase
          if (split_host = host.split(".")).length >= 3
            host = split_host[-2..-1].join(".")
          end
          if (split_home = homepage.split(".")).length >= 3
            home = split_home[-2..-1].join(".")
          end
          host == home
        end

        def full_url(stanza)
          strip_url_scheme(extract_url(stanza))
        end

        def homepage
          URI(remove_non_ascii(extract_url(homepage_stanza))).host
        end

        def homepage_stanza
          toplevel_stanzas.find(&:homepage?)
        end

        def remove_non_ascii(string)
          string.gsub(/\P{ASCII}/, "")
        end
      end
    end
  end
end
